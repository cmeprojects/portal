// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireTaskAccess } from "@/lib/session";
import { flushOutbox } from "@/lib/email/outbox";
import { friendlyError } from "@/lib/db-error";
import { isPriority } from "@/lib/tasks";
import { detailsFromForm, FIELD_COLUMNS, type RegistryField } from "@/lib/registers";
import { text, type FormState } from "@/lib/form";

const DATE = /^\d{4}-\d{2}-\d{2}$/;

function date(form: FormData, name: string): string | null | "bad" {
  const v = text(form, name);
  if (!v) return null;
  return DATE.test(v) ? v : "bad";
}

async function fieldsOf(registryId: string): Promise<RegistryField[]> {
  const supabase = await createClient();
  const { data } = await supabase.from("registry_fields").select(FIELD_COLUMNS).eq("registry_id", registryId).returns<RegistryField[]>();
  return data ?? [];
}

export async function createTask(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const title = text(form, "title");
  const registryId = text(form, "registry_id");
  const assignedTo = text(form, "assigned_to");
  const priority = text(form, "priority");
  const due = date(form, "due_date");
  const reported = date(form, "date_reported");
  const review = date(form, "review_date");
  const helpers = form.getAll("helpers").map(String).filter(Boolean);

  if (!registryId) return { error: "Choose a register." };
  if (!title) return { error: "Give the task a title." };
  if (!assignedTo) return { error: "Choose who will look after it." };
  if (!isPriority(priority)) return { error: "Choose a priority." };
  if (due === "bad" || reported === "bad" || review === "bad") return { error: "Check the dates." };

  const supabase = await createClient();
  const { data: id, error } = await supabase.rpc("create_task", {
    p_title: title,
    p_registry_id: registryId,
    p_assigned_to: assignedTo,
    p_description: text(form, "description"),
    p_priority: priority,
    p_due_date: due,
    p_helpers: helpers,
    p_details: detailsFromForm(form, await fieldsOf(registryId)),
    p_date_reported: reported,
    p_review_date: review,
  });
  if (error || !id) return { error: friendlyError(error, "We couldn't create the task. Please try again.") };

  await flushOutbox(id);
  revalidatePath("/");
  redirect(`/tasks/${id}?created=1`);
}

export async function updateTaskDetails(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const taskId = text(form, "task_id");
  const priority = text(form, "priority");
  const due = date(form, "due_date");
  const reported = date(form, "date_reported");
  const review = date(form, "review_date");
  if (!text(form, "title")) return { error: "Give the task a title." };
  if (!isPriority(priority)) return { error: "Choose a priority." };
  if (due === "bad" || reported === "bad" || review === "bad") return { error: "Check the dates." };

  const supabase = await createClient();
  const { data: task } = await supabase.from("tasks").select("registry_id").eq("id", taskId).single();
  if (!task) return { error: "Task not found." };

  const { error } = await supabase.rpc("update_task_details", {
    p_task_id: taskId,
    p_title: text(form, "title"),
    p_description: text(form, "description"),
    p_priority: priority,
    p_due_date: due,
    p_date_reported: reported,
    p_review_date: review,
    p_outcome: text(form, "outcome"),
    p_details: detailsFromForm(form, await fieldsOf(task.registry_id)),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/tasks/${taskId}`);
  return { message: "Saved." };
}

export async function addFollowUpAction(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const parentId = text(form, "parent_id");
  const title = text(form, "title");
  const assignedTo = text(form, "assigned_to");
  const due = date(form, "due_date");
  if (!title) return { error: "Say what needs doing." };
  if (!assignedTo) return { error: "Choose who will do it." };
  if (due === "bad") return { error: "Check the due date." };

  const supabase = await createClient();
  const { data: id, error } = await supabase.rpc("create_task", {
    p_title: title,
    p_registry_id: null,
    p_assigned_to: assignedTo,
    p_due_date: due,
    p_parent_task_id: parentId,
  });
  if (error || !id) return { error: friendlyError(error, "We couldn't add the action.") };
  await flushOutbox(id);
  revalidatePath(`/tasks/${parentId}`);
  return { message: "Action added. We've emailed them." };
}

export async function addHelper(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const taskId = text(form, "task_id");
  const userId = text(form, "user_id");
  if (!userId) return { error: "Choose someone to help." };

  const supabase = await createClient();
  const { error } = await supabase.rpc("add_task_helper", { p_task_id: taskId, p_user_id: userId });
  if (error) return { error: friendlyError(error) };

  await flushOutbox(taskId);
  revalidatePath(`/tasks/${taskId}`);
  return { message: "Helper added. We've let them know." };
}

// ---------------------------------------------------------------------------
// Working on a task (the database checks who may do what)
// ---------------------------------------------------------------------------

async function afterChange(taskId: string) {
  await flushOutbox();
  revalidatePath(`/tasks/${taskId}`);
  revalidatePath("/", "layout");
}

const STATUS_MESSAGES: Record<string, string> = {
  in_progress: "Marked as in progress.",
  awaiting_approval: "Sent to a manager for approval.",
  completed: "Marked as completed.",
  closed: "Task closed.",
};

export async function changeStatus(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const taskId = text(form, "task_id");
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("set_task_status", {
    p_task_id: taskId,
    p_status: text(form, "status"),
    p_note: text(form, "note"),
  });
  if (error) return { error: friendlyError(error) };
  await afterChange(taskId);
  return { message: STATUS_MESSAGES[String(data)] ?? "Saved." };
}

export async function addComment(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const taskId = text(form, "task_id");
  const supabase = await createClient();
  const { error } = await supabase.rpc("add_task_comment", { p_task_id: taskId, p_body: text(form, "body") });
  if (error) return { error: friendlyError(error) };
  await afterChange(taskId);
  return { message: "Comment added." };
}

export async function escalateTask(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const taskId = text(form, "task_id");
  const supabase = await createClient();
  const { error } = await supabase.rpc("escalate_task", { p_task_id: taskId, p_reason: text(form, "reason") });
  if (error) return { error: friendlyError(error) };
  await afterChange(taskId);
  return { message: "Escalated. The managers have been told." };
}

export async function reassignTask(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireTaskAccess();
  const taskId = text(form, "task_id");
  const supabase = await createClient();
  const takeOver = form.get("take_over") === "1";
  const { error } = takeOver
    ? await supabase.rpc("take_over_task", { p_task_id: taskId, p_reason: text(form, "reason") })
    : await supabase.rpc("reassign_task", { p_task_id: taskId, p_to: text(form, "to"), p_reason: text(form, "reason") });
  if (error) return { error: friendlyError(error) };
  await afterChange(taskId);
  return { message: takeOver ? `You're now looking after this task, ${profile.full_name.split(" ")[0] || "there"}.` : "Reassigned. They've been emailed." };
}

export async function addAttachment(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const taskId = text(form, "task_id");
  const path = text(form, "file_path");
  if (!path) return { error: "Choose a file and wait for it to upload." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("add_task_attachment", {
    p_task_id: taskId,
    p_path: path,
    p_name: text(form, "file_name"),
    p_size: null,
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/tasks/${taskId}`);
  return { message: "File added." };
}

export type TaskSnapshot = {
  description: string;
  helpers: { id: string; name: string }[];
  history: { who: string; what: string; note: string | null; at: string }[];
  canEdit: boolean;
  files: number;
};


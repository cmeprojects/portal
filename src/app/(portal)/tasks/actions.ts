// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
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
  await requireSession();
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
  await requireSession();
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
  await requireSession();
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
  await requireSession();
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

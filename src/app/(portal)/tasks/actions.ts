// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { flushOutbox } from "@/lib/email/outbox";
import { friendlyError } from "@/lib/db-error";
import { isPriority } from "@/lib/tasks";
import { text, type FormState } from "@/lib/form";

const DATE = /^\d{4}-\d{2}-\d{2}$/;

export async function createTask(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const title = text(form, "title");
  const registryId = text(form, "registry_id");
  const assignedTo = text(form, "assigned_to");
  const priority = text(form, "priority");
  const due = text(form, "due_date");
  const helpers = form.getAll("helpers").map(String).filter(Boolean);

  if (!title) return { error: "Give the task a title." };
  if (!registryId) return { error: "Choose a registry." };
  if (!assignedTo) return { error: "Choose who will look after it." };
  if (!isPriority(priority)) return { error: "Choose a priority." };
  if (due && !DATE.test(due)) return { error: "Choose a valid due date." };

  const supabase = await createClient();
  const { data: id, error } = await supabase.rpc("create_task", {
    p_title: title,
    p_registry_id: registryId,
    p_assigned_to: assignedTo,
    p_description: text(form, "description"),
    p_priority: priority,
    p_due_date: due || null,
    p_helpers: helpers,
  });
  if (error || !id) return { error: friendlyError(error, "We couldn't create the task. Please try again.") };

  await flushOutbox(id);
  revalidatePath("/");
  redirect(`/tasks/${id}?created=1`);
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

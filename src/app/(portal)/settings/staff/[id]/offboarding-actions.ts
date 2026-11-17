// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 119): offboarding. The database checks who may
// (Offboarding, for that person), keeps who did what, and never deletes.
async function requireOffboarding() {
  await requireSession();
  if (!(await canDo("hr.offboarding", "edit"))) throw new Error("You can't manage offboarding.");
}
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const REASONS = ["resigned", "contract_ended", "dismissed", "retired", "redundancy", "other"];

export async function startOffboarding(_: FormState, form: FormData): Promise<FormState> {
  await requireOffboarding();
  const userId = String(form.get("user_id") ?? "");
  const reason = String(form.get("reason") ?? "");
  const lastDay = String(form.get("last_day") ?? "");
  if (!isId(userId)) return { error: "Choose a person." };
  if (!REASONS.includes(reason)) return { error: "Choose why they're leaving." };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(lastDay)) return { error: "Choose their last day." };
  const { error } = await (await createClient())
    .from("offboardings")
    .insert({ user_id: userId, reason, last_day: lastDay, note: String(form.get("note") ?? "").trim().slice(0, 1000) });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/staff/${userId}`);
  revalidatePath("/settings/staff");
  return { message: "Offboarding started." };
}

export async function setOffboardingStep(form: FormData) {
  await requireOffboarding();
  const id = String(form.get("id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const state = String(form.get("state") ?? "");
  if (!isId(id) || !isId(userId) || !["todo", "done", "not_needed"].includes(state)) return;
  await (await createClient()).from("offboarding_steps").update({ state }).eq("id", id);
  revalidatePath(`/settings/staff/${userId}`);
}

export async function addOffboardingStep(_: FormState, form: FormData): Promise<FormState> {
  await requireOffboarding();
  const offboardingId = String(form.get("offboarding_id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const title = String(form.get("title") ?? "").trim().slice(0, 120);
  if (!isId(offboardingId) || !isId(userId) || !title) return { error: "Write the step." };
  const { error } = await (await createClient()).from("offboarding_steps").insert({ offboarding_id: offboardingId, step: "other", title, sort_order: 100 });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/staff/${userId}`);
  return { message: "Added." };
}

export async function saveOffboarding(_: FormState, form: FormData): Promise<FormState> {
  await requireOffboarding();
  const id = String(form.get("id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const status = String(form.get("status") ?? "open");
  if (!isId(id) || !isId(userId) || !["open", "completed", "cancelled"].includes(status)) return { error: "That didn't save. Please reload the page." };
  const lastDay = String(form.get("last_day") ?? "");
  const { error } = await (await createClient())
    .from("offboardings")
    .update({
      exit_notes: String(form.get("exit_notes") ?? "").trim().slice(0, 3000),
      ...(/^\d{4}-\d{2}-\d{2}$/.test(lastDay) ? { last_day: lastDay } : {}),
      status,
    })
    .eq("id", id);
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/staff/${userId}`);
  revalidatePath("/settings/staff");
  return { message: status === "completed" ? "Offboarding completed." : status === "cancelled" ? "Offboarding cancelled." : "Saved." };
}

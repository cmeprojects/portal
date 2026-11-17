// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 121): performance and development reviews. The database
// checks who may (Performance and development, or their team leader), keeps
// held reviews as they were, and never deletes.
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: FormDataEntryValue | null) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);

export async function planReview(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const userId = String(form.get("user_id") ?? "");
  const kind = String(form.get("kind") ?? "");
  const reviewer = String(form.get("reviewer_id") ?? "");
  const due = ymd(form.get("due_on"));
  if (!isId(userId) || !["probation", "annual", "check_in"].includes(kind)) return { error: "Choose the kind of review." };
  if (!due) return { error: "Choose when it's due." };
  const { error } = await (await createClient()).from("staff_reviews").insert({ user_id: userId, kind, due_on: due, reviewer_id: isId(reviewer) ? reviewer : null });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/staff/${userId}`);
  return { message: "Review planned." };
}

export async function closeReview(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const status = String(form.get("status") ?? "held");
  if (!isId(id) || !isId(userId) || !["held", "cancelled"].includes(status)) return { error: "That didn't save. Please reload the page." };
  const outcome = String(form.get("outcome") ?? "");
  const values =
    status === "held"
      ? {
          status,
          held_on: ymd(form.get("held_on")),
          summary: String(form.get("summary") ?? "").trim().slice(0, 5000),
          goals: String(form.get("goals") ?? "").trim().slice(0, 3000),
          development: String(form.get("development") ?? "").trim().slice(0, 3000),
          outcome: ["", "passed", "extended", "not_passed", "on_track", "needs_support"].includes(outcome) ? outcome : "",
        }
      : { status };
  if (status === "held" && (!values.held_on || !("summary" in values && values.summary))) return { error: "Record when it was held and a summary." };
  const { error } = await (await createClient()).from("staff_reviews").update(values).eq("id", id).eq("user_id", userId);
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/staff/${userId}`);
  return { message: status === "held" ? "Review recorded." : "Review cancelled." };
}

// The person acknowledges their own held review.
export async function acknowledgeReview(form: FormData) {
  const { profile } = await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("staff_reviews").update({ acknowledged_at: new Date().toISOString() }).eq("id", id).eq("user_id", profile.id);
  revalidatePath("/account");
}

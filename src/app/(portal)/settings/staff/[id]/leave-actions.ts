// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { managesStaffFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 120): set a person's leave balance. The database checks
// who may (Staff, change; never their own) and records who changed it.
export async function setLeaveBalance(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  if (!(await managesStaffFor())) return { error: "You can't change leave balances." };
  const userId = String(form.get("user_id") ?? "");
  const type = String(form.get("leave_type") ?? "");
  const num = (k: string) => Number(String(form.get(k) ?? "").trim() || "0");
  const asAt = String(form.get("as_at") ?? "");
  if (!/^[0-9a-f-]{36}$/.test(userId) || !["annual", "personal", "long_service"].includes(type)) return { error: "Choose the leave type." };
  if (!Number.isFinite(num("opening_days")) || !Number.isFinite(num("accrual_days_per_year"))) return { error: "Use numbers of days." };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(asAt)) return { error: "Choose the date the balance was correct." };
  const { error } = await (await createClient())
    .from("leave_balances")
    .upsert(
      { user_id: userId, leave_type: type, opening_days: num("opening_days"), accrual_days_per_year: num("accrual_days_per_year"), as_at: asAt, note: String(form.get("note") ?? "").trim().slice(0, 300) },
      { onConflict: "user_id,leave_type" },
    );
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/staff/${userId}`);
  return { message: "Balance saved." };
}

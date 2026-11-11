// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { RECORDS_BUCKET } from "@/lib/staff-records";

const UUID = /^[0-9a-f-]{36}$/;
type Area = "payroll_tax" | "identity_docs";

// cmeprojects Phase 3: anything shown from someone else's sensitive record is
// recorded first. A refused attempt is recorded too.
async function log(subject: string, area: Area, action: string, detail: string) {
  await (await createClient()).from("sensitive_access_log").insert({ subject_id: subject, area, action, detail });
}

// The full account number, once, for someone with Payroll and tax access.
export async function revealAccount(subject: string): Promise<{ value?: string; error?: string }> {
  const { profile } = await requireSession();
  if (!UUID.test(subject)) return { error: "Something went wrong." };
  const { data } = await (await createClient()).from("staff_bank").select("account_number").eq("user_id", subject).maybeSingle();
  if (!data) {
    await log(subject, "payroll_tax", "refused", "Reveal account number");
    return { error: "You don't have access to this." };
  }
  if (subject !== profile.id) await log(subject, "payroll_tax", "reveal", "Account number");
  return { value: data.account_number };
}

// A short-lived link to one of the person's documents (60 seconds).
export async function openRecordFile(subject: string, which: "choice" | "visa" | "vevo"): Promise<{ url?: string; error?: string }> {
  const { profile } = await requireSession();
  if (!UUID.test(subject)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const area: Area = which === "choice" ? "payroll_tax" : "identity_docs";
  const { data } =
    which === "choice"
      ? await supabase.from("staff_super").select("path:choice_doc").eq("user_id", subject).maybeSingle()
      : await supabase.from("staff_work_rights").select(which === "visa" ? "path:visa_doc" : "path:vevo_doc").eq("user_id", subject).maybeSingle();
  const path = (data as { path?: string } | null)?.path;
  if (!path) {
    await log(subject, area, "refused", `Open ${which} document`);
    return { error: "You don't have access to this, or there's no file." };
  }
  const { data: signed, error } = await supabase.storage.from(RECORDS_BUCKET).createSignedUrl(path, 60);
  if (error || !signed) return { error: "The file couldn't be opened. Please try again." };
  if (subject !== profile.id) await log(subject, area, "download", which === "choice" ? "Choice of fund form" : which === "visa" ? "Visa grant notice" : "VEVO check");
  return { url: signed.signedUrl };
}

// Mark a record checked (not your own; the database checks access and logs it).
export async function verifyRecord(subject: string, table: "staff_bank" | "staff_super" | "staff_work_rights"): Promise<{ error?: string; message?: string }> {
  await requireSession();
  if (!UUID.test(subject) || !["staff_bank", "staff_super", "staff_work_rights"].includes(table)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from(table).update({ verified_at: new Date().toISOString() }).eq("user_id", subject).select("user_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have access to check this." };
  revalidatePath("/people");
  return { message: "Marked as checked." };
}

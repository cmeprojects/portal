// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { RECORDS_BUCKET } from "@/lib/staff-records";

const UUID = /^[0-9a-f-]{36}$/;
const refresh = () => {
  revalidatePath("/people");
  revalidatePath("/account/records");
  revalidatePath("/onboarding");
  revalidatePath("/settings/access");
};
async function log(subject: string, action: string, detail: string) {
  await (await createClient()).from("sensitive_access_log").insert({ subject_id: subject, area: "payroll_tax", action, detail });
}

// cmeprojects: the person saves their completed TFN declaration (a file; no TFN number is stored).
export async function saveTaxForm(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const path = String(form.get("tfn_form_path") ?? "");
  const name = String(form.get("tfn_form_name") ?? "").slice(0, 200);
  if (!path) return { error: "Choose your completed form and wait for it to upload." };
  if (!path.startsWith(`tax/${profile.id}/`)) return { error: "Something went wrong with the file. Please upload it again." };
  const { error } = await (await createClient()).from("staff_tax").upsert({ user_id: profile.id, form_path: path, form_name: name }, { onConflict: "user_id" });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Your TFN declaration is uploaded. The office will check it and send it to the ATO." };
}

// The blank form for staff to download (a 60-second link).
export async function openTfnTemplate(): Promise<{ url?: string; error?: string }> {
  await requireSession();
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("value").eq("key", "records.tfn_template").maybeSingle();
  const path = typeof data?.value === "string" ? data.value : "";
  if (!path) return { error: "The blank form hasn't been added yet. Ask the office for a copy." };
  const { data: signed } = await supabase.storage.from(RECORDS_BUCKET).createSignedUrl(path, 60, { download: true });
  return signed ? { url: signed.signedUrl } : { error: "The blank form couldn't be opened." };
}

// A manager or staff admin with Payroll and tax access (or the system admin) adds the blank form.
export async function saveTfnTemplate(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const path = String(form.get("template_path") ?? "");
  if (!path.startsWith("templates/")) return { error: "Choose the blank form and wait for it to upload." };
  const { data, error } = await (await createClient()).from("app_settings").update({ value: path }).eq("key", "records.tfn_template").select("key");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have access to change the blank form." };
  revalidatePath("/compliance");
  return { message: "Blank form saved. Staff can download it in My onboarding." };
}

// Open someone's TFN declaration (recorded first).
export async function openTaxForm(subject: string): Promise<{ url?: string; error?: string }> {
  const { profile } = await requireSession();
  if (!UUID.test(subject)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data } = await supabase.from("staff_tax").select("form_path").eq("user_id", subject).maybeSingle();
  if (!data?.form_path) {
    await log(subject, "refused", "Open TFN declaration");
    return { error: "You don't have access to this, or there's no form." };
  }
  if (subject !== profile.id) await log(subject, "download", "TFN declaration");
  const { data: signed } = await supabase.storage.from(RECORDS_BUCKET).createSignedUrl(data.form_path, 60);
  return signed ? { url: signed.signedUrl } : { error: "The form couldn't be opened." };
}

// Checked, and/or the date it was sent to the ATO.
export async function updateTax(subject: string, change: { checked?: boolean; lodgedOn?: string }): Promise<FormState> {
  await requireSession();
  if (!UUID.test(subject)) return { error: "Something went wrong." };
  const row: Record<string, string> = {};
  if (change.checked) row.verified_at = new Date().toISOString();
  if (change.lodgedOn) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(change.lodgedOn)) return { error: "Choose a valid date." };
    row.lodged_on = change.lodgedOn;
  }
  const { data, error } = await (await createClient()).from("staff_tax").update(row).eq("user_id", subject).select("user_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have access to this." };
  refresh();
  return { message: change.lodgedOn ? "Recorded as sent to the ATO." : "Marked as checked." };
}

// Delete someone's TFN declaration (the file and the record). Logged.
export async function deleteTaxForm(subject: string): Promise<FormState> {
  await requireSession();
  if (!UUID.test(subject)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data } = await supabase.from("staff_tax").select("form_path").eq("user_id", subject).maybeSingle();
  if (!data) return { error: "You don't have access to this, or it's already gone." };
  const { data: files } = await supabase.storage.from(RECORDS_BUCKET).list(`tax/${subject}`);
  if (files?.length) await supabase.storage.from(RECORDS_BUCKET).remove(files.map((f) => `tax/${subject}/${f.name}`));
  const { data: gone, error } = await supabase.from("staff_tax").delete().eq("user_id", subject).select("user_id");
  if (error) return { error: friendlyError(error) };
  if (!gone?.length) return { error: "You don't have access to delete this." };
  refresh();
  return { message: "TFN declaration deleted. The deletion is recorded." };
}

// The system admin deletes all of a leaver's private records and files. Logged.
export async function deletePrivateRecords(subject: string): Promise<FormState> {
  const { profile } = await requireSession();
  if (profile.role !== "system_admin") return { error: "Only the system admin can do this." };
  if (!UUID.test(subject) || subject === profile.id) return { error: "Something went wrong." };
  const supabase = await createClient();
  for (const folder of ["payroll_tax", "identity_docs", "tax"]) {
    const { data: files } = await supabase.storage.from(RECORDS_BUCKET).list(`${folder}/${subject}`);
    if (files?.length) await supabase.storage.from(RECORDS_BUCKET).remove(files.map((f) => `${folder}/${subject}/${f.name}`));
  }
  for (const table of ["staff_tax", "staff_bank", "staff_super", "staff_work_rights"]) {
    const { error } = await supabase.from(table).delete().eq("user_id", subject);
    if (error) return { error: friendlyError(error) };
  }
  refresh();
  return { message: "Their private records and files are deleted. The deletion is recorded." };
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { cleanAbn, cleanAccount, cleanBsb, cleanUsi } from "@/lib/staff-records";

const str = (form: FormData, k: string, max = 200) => String(form.get(k) ?? "").trim().slice(0, max);
const UUID = /^[0-9a-f-]{36}$/;

// The person whose record this is: yourself, or someone your access covers
// (the database checks access; this only picks who).
async function subject(form: FormData): Promise<string> {
  const { profile } = await requireSession();
  const id = String(form.get("user_id") ?? "");
  return UUID.test(id) ? id : profile.id;
}

// A file path must be in this person's own folder for that area.
const ownPath = (path: string, area: string, userId: string) => path === "" || path.startsWith(`${area}/${userId}/`);

export async function saveBank(_: FormState, form: FormData): Promise<FormState> {
  const userId = await subject(form);
  const bsb = cleanBsb(str(form, "bsb", 20));
  const account = cleanAccount(str(form, "account_number", 20));
  const name = str(form, "account_name", 100);
  if (bsb === null) return { error: "BSB: 6 digits, for example 062-000." };
  if (account === null) return { error: "Account number: 5 to 9 digits." };
  if ((bsb || account) && !name) return { error: "Add the name on the account." };
  const { error } = await (await createClient())
    .from("staff_bank")
    .upsert({ user_id: userId, account_name: name, bsb, account_number: account }, { onConflict: "user_id" });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/account/records");
  revalidatePath("/people");
  return { message: "Bank details saved. Payroll will check them." };
}

export async function saveSuper(_: FormState, form: FormData): Promise<FormState> {
  const userId = await subject(form);
  const abn = cleanAbn(str(form, "fund_abn", 20));
  const usi = cleanUsi(str(form, "usi", 20));
  if (abn === null) return { error: "Fund ABN: that isn't a valid 11-digit ABN." };
  if (usi === null) return { error: "USI: letters and numbers only (it's on your fund's website)." };
  const doc = str(form, "choice_doc_path", 300);
  if (!ownPath(doc, "payroll_tax", userId)) return { error: "Something went wrong with the file. Please upload it again." };
  const row: Record<string, string> = {
    user_id: userId,
    fund_name: str(form, "fund_name", 120),
    fund_abn: abn,
    usi,
    member_number: str(form, "member_number", 30),
  };
  if (doc) {
    row.choice_doc = doc;
    row.choice_name = str(form, "choice_doc_name", 200);
  }
  const { error } = await (await createClient()).from("staff_super").upsert(row, { onConflict: "user_id" });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/account/records");
  revalidatePath("/people");
  return { message: "Super details saved. Payroll will check them." };
}

export async function saveWorkRights(_: FormState, form: FormData): Promise<FormState> {
  const userId = await subject(form);
  const status = str(form, "status", 30);
  if (!["citizen", "permanent_resident", "nz_citizen", "visa"].includes(status)) return { error: "Choose your work rights." };
  const visa = status === "visa";
  const subclass = str(form, "visa_subclass", 20);
  const expiry = str(form, "visa_expiry", 10);
  if (visa && !subclass) return { error: "Add your visa subclass (for example 482)." };
  if (expiry && !/^\d{4}-\d{2}-\d{2}$/.test(expiry)) return { error: "Choose a valid visa expiry date." };
  const visaDoc = str(form, "visa_doc_path", 300);
  const vevoDoc = str(form, "vevo_doc_path", 300);
  if (!ownPath(visaDoc, "identity_docs", userId) || !ownPath(vevoDoc, "identity_docs", userId)) return { error: "Something went wrong with the file. Please upload it again." };
  const vevoOn = str(form, "vevo_checked_on", 10);
  const row: Record<string, string | null> = {
    user_id: userId,
    status,
    visa_subclass: visa ? subclass : "",
    visa_conditions: visa ? str(form, "visa_conditions", 500) : "",
    visa_expiry: visa && expiry ? expiry : null,
  };
  if (/^\d{4}-\d{2}-\d{2}$/.test(vevoOn)) row.vevo_checked_on = vevoOn;
  if (visaDoc) Object.assign(row, { visa_doc: visaDoc, visa_doc_name: str(form, "visa_doc_name", 200) });
  if (vevoDoc) Object.assign(row, { vevo_doc: vevoDoc, vevo_doc_name: str(form, "vevo_doc_name", 200) });
  const { error } = await (await createClient()).from("staff_work_rights").upsert(row, { onConflict: "user_id" });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/account/records");
  revalidatePath("/people");
  return { message: "Work rights saved. They'll be checked." };
}

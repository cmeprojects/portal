// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";

export async function confirmItem(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const supabase = await createClient();
  const { error } = await supabase.rpc("confirm_compliance_item", { p_item_id: text(form, "item_id") });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/onboarding");
  revalidatePath("/", "layout");
  return { message: "Thanks, that's recorded." };
}

export async function submitUpload(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const path = text(form, "file_path");
  if (!path) return { error: "Choose a file and wait for it to upload." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("submit_compliance_upload", {
    p_item_id: text(form, "item_id"),
    p_path: path,
    p_name: text(form, "file_name"),
    p_expires: text(form, "expires_on") || null,
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/onboarding");
  revalidatePath("/", "layout");
  return { message: "Uploaded. A staff admin will check it." };
}

// cmeprojects (update 58): the onboarding steps.
const done = () => {
  revalidatePath("/onboarding");
  revalidatePath("/", "layout");
};

// Opening a policy or agreement is recorded before it can be acknowledged or signed.
export async function openItem(itemId: string): Promise<{ error?: string }> {
  await requireSession();
  const { error } = await (await createClient()).rpc("open_compliance_item", { p_item_id: itemId });
  return error ? { error: friendlyError(error) } : {};
}

export async function acknowledgePolicy(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  if (form.get("agree") !== "on") return { error: "Tick the box to confirm you've read and understood it." };
  const { error } = await (await createClient()).rpc("acknowledge_policy", { p_item_id: text(form, "item_id"), p_name: text(form, "name") });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Acknowledged. Thank you." };
}

export async function completeTraining(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const path = text(form, "file_path");
  const { error } = await (await createClient()).rpc("complete_training", {
    p_item_id: text(form, "item_id"),
    p_completed_on: text(form, "completed_on") || null,
    p_provider: text(form, "provider"),
    p_path: path || null,
    p_name: text(form, "file_name") || null,
    p_expires: text(form, "expires_on") || null,
  });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: path ? "Recorded. Your certificate will be checked." : "Training recorded." };
}

export async function submitDocument(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const path = text(form, "file_path");
  if (!path) return { error: "Choose a file and wait for it to upload." };
  const { error } = await (await createClient()).rpc("submit_document", {
    p_item_id: text(form, "item_id"),
    p_path: path,
    p_name: text(form, "file_name"),
    p_expires: text(form, "expires_on") || null,
    p_issued: text(form, "issued_on") || null,
    p_number: text(form, "doc_number"),
  });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Uploaded. It will be checked before it counts as verified." };
}

export async function signAgreement(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  if (form.get("agree") !== "on") return { error: "Tick the box to confirm you agree." };
  const { error } = await (await createClient()).rpc("sign_agreement", {
    p_item_id: text(form, "item_id"),
    p_name: text(form, "name"),
    p_signature_path: text(form, "signature_path"),
    p_device: text(form, "device").slice(0, 120),
  });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Signed. A copy is kept with your records." };
}

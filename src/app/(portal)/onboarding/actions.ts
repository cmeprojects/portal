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

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireTaskAccess } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { detailsFromForm, FIELD_COLUMNS, type RegistryField } from "@/lib/registers";
import { text, type FormState } from "@/lib/form";

async function fieldsOf(registryId: string): Promise<RegistryField[]> {
  const supabase = await createClient();
  const { data } = await supabase.from("registry_fields").select(FIELD_COLUMNS).eq("registry_id", registryId).returns<RegistryField[]>();
  return data ?? [];
}

export async function saveRecord(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const recordId = text(form, "record_id");
  const registryId = text(form, "registry_id");
  const title = text(form, "title");
  if (!title) return { error: "Give it a name or description." };
  const details = detailsFromForm(form, await fieldsOf(registryId));
  const supabase = await createClient();

  if (!recordId) {
    const { data: id, error } = await supabase.rpc("create_record", { p_registry_id: registryId, p_title: title, p_details: details });
    if (error || !id) return { error: friendlyError(error, "We couldn't save it.") };
    revalidatePath(`/registers/${registryId}`);
    redirect(`/records/${id}?saved=1`);
  }

  const { error } = await supabase.rpc("update_record", {
    p_record_id: recordId,
    p_title: title,
    p_details: details,
    p_archived: form.get("archived") === "on",
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/records/${recordId}`);
  return { message: "Saved." };
}

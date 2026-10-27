// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireRole, STAFF_ADMINS } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";

const PAGE = "/settings/registries";

export async function saveRegistry(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(STAFF_ADMINS);
  const id = text(form, "id");
  const fields = {
    name: text(form, "name"),
    description: text(form, "description"),
    requires_approval: form.get("requires_approval") === "on",
    active: id ? form.get("active") === "on" : true,
  };
  const managers = form.getAll("managers").map(String);
  if (!fields.name) return { error: "Give the registry a name." };

  const supabase = await createClient();
  const saved = id
    ? await supabase.from("registries").update(fields).eq("id", id).select("id").single()
    : await supabase.from("registries").insert(fields).select("id").single();
  if (saved.error) return { error: friendlyError(saved.error) };
  const registryId = saved.data.id;

  const { error: clearError } = await supabase.from("registry_managers").delete().eq("registry_id", registryId);
  if (clearError) return { error: friendlyError(clearError) };
  if (managers.length) {
    const { error } = await supabase
      .from("registry_managers")
      .insert(managers.map((user_id) => ({ registry_id: registryId, user_id })));
    if (error) return { error: friendlyError(error) };
  }

  revalidatePath(PAGE);
  return { message: id ? "Saved." : `Registry "${fields.name}" added.` };
}

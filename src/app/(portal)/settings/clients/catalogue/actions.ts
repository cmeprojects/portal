// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 143): the service catalogue, managed by Manager
// Administrators (and the system admin). The database refuses anyone else.
export async function mayManageCatalogue(): Promise<boolean> {
  const { profile } = await requireSession();
  if (profile.role === "system_admin") return true;
  const { data } = await (await createClient()).rpc("is_manager_admin");
  return data === true;
}

export async function saveCatalogueService(_: FormState, form: FormData): Promise<FormState> {
  if (!(await mayManageCatalogue())) return { error: "Only Manager Administrators can change the service catalogue." };
  const id = String(form.get("id") ?? "");
  const row = {
    name: String(form.get("name") ?? "").trim().slice(0, 80),
    description: String(form.get("description") ?? "").trim().slice(0, 1000),
    classification: String(form.get("classification") ?? "").trim().slice(0, 60),
    schemes: [...new Set(form.getAll("schemes").map(String).filter((k) => /^[a-z_]{1,40}$/.test(k)))],
    shift_types: [...new Set(form.getAll("shift_types").map(String).filter((k) => /^[a-z][a-z0-9_]{1,40}$/.test(k)))],
    active: id ? form.get("active") === "on" : true,
  };
  if (!row.name) return { error: "Give the service a name." };
  if (!row.shift_types.length) return { error: "Choose at least one shift type it covers." };
  const supabase = await createClient();
  const { error } = id
    ? await supabase.from("service_catalogue").update(row).eq("id", id)
    : await supabase.from("service_catalogue").insert({ ...row, sort_order: 500 });
  if (error) return { error: error.code === "23505" ? "There's already a service with that name." : friendlyError(error) };
  revalidatePath("/settings/clients/catalogue");
  return { message: id ? "Saved." : "Service added to the catalogue." };
}

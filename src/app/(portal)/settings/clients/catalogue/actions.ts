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
    // cmeprojects (update 167): the service code (blank: given automatically) and the Support at Home service type.
    ...(form.has("code") ? { code: String(form.get("code") ?? "").trim().toUpperCase().slice(0, 21) || null } : {}),
    ...(form.has("sah_service_type") ? { sah_service_type: String(form.get("sah_service_type") ?? "").trim().slice(0, 200) } : {}),
  };
  if (row.code && !/^[A-Z0-9]{1,10}-[A-Z0-9]{1,10}$/.test(row.code)) return { error: "A service code is letters or numbers, a dash, then letters or numbers (for example SERV-0019)." };
  if (!row.name) return { error: "Give the service a name." };
  if (!row.shift_types.length) return { error: "Choose at least one shift type it covers." };
  const supabase = await createClient();
  const { error } = id
    ? await supabase.from("service_catalogue").update(row).eq("id", id)
    : await supabase.from("service_catalogue").insert({ ...row, sort_order: 500 });
  if (error) return { error: error.code === "23505" ? (/code/.test(error.message) ? "Another service already has that code." : "There's already a service with that name.") : friendlyError(error) };
  revalidatePath("/settings/clients/catalogue");
  return { message: id ? "Saved." : "Service added to the catalogue." };
}

// cmeprojects (update 167): the letters at the start of new service codes.
export async function saveCodePrefix(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const prefix = String(form.get("prefix") ?? "").trim().toUpperCase();
  if (!/^[A-Z0-9]{1,10}$/.test(prefix)) return { error: "Use 1 to 10 letters or numbers." };
  const { data, error } = await (await createClient()).from("app_settings").update({ value: prefix }).eq("key", "billing.service_code_prefix").select("key");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change the code prefix." };
  revalidatePath("/settings/clients/catalogue");
  return { message: `New services will be coded ${prefix}-0001 onwards (existing codes stay).` };
}

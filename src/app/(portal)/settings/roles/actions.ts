// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireRole } from "@/lib/session";
import { isRole } from "@/lib/roles";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";

const PAGE = "/settings/roles";
// Managers (and the system admin) look after job titles.
// The database checks the "Roles" delegation (cmeprojects); these roles may try.
const TITLE_EDITORS = ["manager", "staff_admin", "system_admin"] as const;

function fields(form: FormData) {
  const access_level = text(form, "access_level");
  return {
    name: text(form, "name"),
    access_level,
    description: text(form, "description"),
    sort_order: Number(text(form, "sort_order")) || 0,
  };
}

export async function addJobTitle(_: FormState, form: FormData): Promise<FormState> {
  await requireRole([...TITLE_EDITORS]);
  const title = fields(form);
  if (!title.name) return { error: "Give the role a name." };
  if (!isRole(title.access_level) || title.access_level === "system_admin") return { error: "Choose an access level." };
  const supabase = await createClient();
  const { error } = await supabase.from("job_titles").insert(title);
  if (error) return { error: error.code === "23505" ? "There's already a role with that name." : friendlyError(error) };
  revalidatePath(PAGE);
  return { message: `Role "${title.name}" added.` };
}

export async function saveJobTitle(_: FormState, form: FormData): Promise<FormState> {
  await requireRole([...TITLE_EDITORS]);
  const id = text(form, "id");
  const title = { ...fields(form), active: form.get("active") === "on" };
  if (!title.name) return { error: "Give the role a name." };
  if (!isRole(title.access_level) || title.access_level === "system_admin") return { error: "Choose an access level." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("job_titles").update(title).eq("id", id).select("id");
  if (error) return { error: error.code === "23505" ? "There's already a role with that name." : friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change roles." };
  revalidatePath(PAGE);
  revalidatePath("/settings/staff");
  return { message: "Saved." };
}

// cmeprojects (function-based access, Stage 1, update 92): Function Groups.
// Add, rename, describe or deactivate (never delete; the key never changes).
// The database checks the "Roles" settings area; every change is logged here.
export async function saveFunctionGroup(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole([...TITLE_EDITORS]);
  const id = text(form, "id");
  const name = text(form, "name").slice(0, 80);
  const description = text(form, "description").slice(0, 500);
  if (!name) return { error: "Enter the group's name." };
  const supabase = await createClient();
  let error;
  let action = "function_group_changed";
  if (id) {
    if (!/^[0-9a-f-]{36}$/.test(id)) return { error: "Choose a group." };
    ({ error } = await supabase.from("function_groups").update({ name, description, active: form.get("active") === "on" }).eq("id", id));
  } else {
    // A short, permanent key from the name (letters, numbers, underscores).
    const key = name.toLowerCase().replace(/&/g, "and").replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 40) || "group";
    const { data: last } = await supabase.from("function_groups").select("sort_order").order("sort_order", { ascending: false }).limit(1);
    ({ error } = await supabase.from("function_groups").insert({ key: /^[a-z]/.test(key) ? key : `g_${key}`, name, description, sort_order: (last?.[0]?.sort_order ?? 0) + 10 }));
    action = "function_group_added";
  }
  if (error) return { error: error.code === "23505" ? "There's already a group with that name." : friendlyError(error) };
  const { createAdminClient } = await import("@/lib/supabase/admin");
  await createAdminClient().from("audit_log").insert({ actor_id: profile.id, action, entity: "function_group", entity_id: id || null, details: { name, active: id ? form.get("active") === "on" : true } });
  revalidatePath(PAGE);
  return { message: id ? "Saved." : `${name} added.` };
}

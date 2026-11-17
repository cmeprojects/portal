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

// cmeprojects (Stage 2, update 93): the function groups ticked for a role.
// Only checked when the page showed the choices (after update 93).
function chosenGroups(form: FormData): { shown: boolean; ids: string[] } {
  return { shown: form.get("fg_shown") === "1", ids: form.getAll("function_groups").map(String).filter((v) => /^[0-9a-f-]{36}$/.test(v)) };
}

async function linkGroups(supabase: Awaited<ReturnType<typeof createClient>>, titleId: string, ids: string[], actor: string, name: string): Promise<string | null> {
  const { data: current, error: readError } = await supabase.from("job_title_functions").select("function_group_id").eq("job_title_id", titleId);
  if (readError) return friendlyError(readError);
  const have = new Set((current ?? []).map((r) => r.function_group_id as string));
  const add = ids.filter((id) => !have.has(id));
  const remove = [...have].filter((id) => !ids.includes(id));
  if (add.length) {
    const { error } = await supabase.from("job_title_functions").insert(add.map((function_group_id) => ({ job_title_id: titleId, function_group_id })));
    if (error) return friendlyError(error);
  }
  if (remove.length) {
    const { error } = await supabase.from("job_title_functions").delete().eq("job_title_id", titleId).in("function_group_id", remove);
    if (error) return friendlyError(error);
  }
  if (add.length || remove.length) {
    const { data: names } = await supabase.from("function_groups").select("id, name").in("id", [...add, ...remove]);
    const nameOf = (id: string) => names?.find((n) => n.id === id)?.name ?? id;
    const { createAdminClient } = await import("@/lib/supabase/admin");
    await createAdminClient().from("audit_log").insert({ actor_id: actor, action: "role_function_groups_changed", entity: "job_title", entity_id: titleId, details: { role: name, added: add.map(nameOf), removed: remove.map(nameOf) } });
  }
  return null;
}

export async function addJobTitle(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole([...TITLE_EDITORS]);
  const groups = chosenGroups(form);
  if (groups.shown && !groups.ids.length) return { error: "Choose at least one function group." };
  const title = fields(form);
  if (!title.name) return { error: "Give the role a name." };
  if (!isRole(title.access_level) || title.access_level === "system_admin") return { error: "Choose an access level." };
  const supabase = await createClient();
  const { data: made, error } = await supabase.from("job_titles").insert(title).select("id").single();
  if (error) return { error: error.code === "23505" ? "There's already a role with that name." : friendlyError(error) };
  if (groups.shown && made?.id) {
    const linkError = await linkGroups(supabase, made.id as string, groups.ids, profile.id, title.name);
    if (linkError) return { error: `Role added, but its function groups didn't save: ${linkError}` };
  }
  revalidatePath(PAGE);
  return { message: `Role "${title.name}" added.` };
}

export async function saveJobTitle(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole([...TITLE_EDITORS]);
  const id = text(form, "id");
  const groups = chosenGroups(form);
  if (groups.shown && !groups.ids.length) return { error: "Choose at least one function group." };
  const title = { ...fields(form), active: form.get("active") === "on" };
  if (!title.name) return { error: "Give the role a name." };
  if (!isRole(title.access_level) || title.access_level === "system_admin") return { error: "Choose an access level." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("job_titles").update(title).eq("id", id).select("id");
  if (error) return { error: error.code === "23505" ? "There's already a role with that name." : friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change roles." };
  if (groups.shown) {
    const linkError = await linkGroups(supabase, id, groups.ids, profile.id, title.name);
    if (linkError) return { error: linkError };
  }
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
  // Stage 4 (update 104): the parts this group looks after (no access given).
  let partsChange: { added: string[]; removed: string[] } | null = null;
  if (id && form.get("parts_shown") === "1") {
    const want = [...new Set(form.getAll("parts").map(String))].filter((p) => /^[a-z_]+(\.[a-z_]+)*$/.test(p));
    const { data: have, error: readError } = await supabase.from("function_group_modules").select("module_id").eq("function_group_id", id);
    if (readError) return { error: friendlyError(readError) };
    const current = (have ?? []).map((r) => r.module_id as string);
    const added = want.filter((p) => !current.includes(p));
    const removed = current.filter((p) => !want.includes(p));
    if (removed.length) {
      const { error: delError } = await supabase.from("function_group_modules").delete().eq("function_group_id", id).in("module_id", removed);
      if (delError) return { error: friendlyError(delError) };
    }
    if (added.length) {
      const { error: addError } = await supabase.from("function_group_modules").insert(added.map((module_id) => ({ function_group_id: id, module_id })));
      if (addError) return { error: friendlyError(addError) };
    }
    if (added.length || removed.length) partsChange = { added, removed };
  }
  const { createAdminClient } = await import("@/lib/supabase/admin");
  await createAdminClient().from("audit_log").insert({ actor_id: profile.id, action, entity: "function_group", entity_id: id || null, details: { name, active: id ? form.get("active") === "on" : true, ...(partsChange ? { parts: partsChange } : {}) } });
  revalidatePath(PAGE);
  return { message: id ? "Saved." : `${name} added.` };
}

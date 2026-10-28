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
const TITLE_EDITORS = ["manager", "system_admin"] as const;

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

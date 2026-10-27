// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";

const PAGE = "/settings/teams";

export async function createTeam(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const name = text(form, "name");
  if (!name) return { error: "Give the team a name." };
  const supabase = await createClient();
  const { error } = await supabase.from("teams").insert({ name });
  if (error) return { error: friendlyError(error) };
  revalidatePath(PAGE);
  return { message: `Team "${name}" added.` };
}

export async function saveTeam(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const name = text(form, "name");
  const active = form.get("active") === "on";
  const leaders = form.getAll("leaders").map(String);
  if (!name) return { error: "Give the team a name." };

  const supabase = await createClient();
  const { error } = await supabase.from("teams").update({ name, active }).eq("id", id);
  if (error) return { error: friendlyError(error) };

  const { error: clearError } = await supabase.from("team_leaders").delete().eq("team_id", id);
  if (clearError) return { error: friendlyError(clearError) };
  if (leaders.length) {
    const { error: addError } = await supabase
      .from("team_leaders")
      .insert(leaders.map((user_id) => ({ team_id: id, user_id })));
    if (addError) return { error: friendlyError(addError) };
  }
  revalidatePath(PAGE);
  return { message: "Saved." };
}

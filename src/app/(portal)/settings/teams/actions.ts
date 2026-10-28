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
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const name = text(form, "name");
  const active = form.get("active") === "on";
  const leader = text(form, "leader") || null;
  const members = [...new Set([...form.getAll("members").map(String), ...(leader ? [leader] : [])])].sort();
  if (!name) return { error: "Give the team a name." };

  const supabase = await createClient();
  const { error } = await supabase.from("teams").update({ name, active }).eq("id", id).eq("is_core", false);
  if (error) return { error: friendlyError(error) };

  const [{ data: current }, { data: currentLeader }] = await Promise.all([
    supabase.from("team_members").select("user_id").eq("team_id", id),
    supabase.from("team_leaders").select("user_id").eq("team_id", id).maybeSingle(),
  ]);
  const before = (current ?? []).map((m) => m.user_id).sort();
  const changed = before.join() !== members.join() || (currentLeader?.user_id ?? null) !== leader;

  if (changed) {
    // Staff admins (HR) send who's in the team to a manager to approve.
    if (me.role === "staff_admin") {
      const { error: requestError } = await supabase.rpc("request_team_change", {
        p_team_id: id,
        p_members: members,
        p_leader: leader,
        p_reason: text(form, "reason"),
      });
      if (requestError) return { error: friendlyError(requestError) };
      revalidatePath(PAGE);
      return { message: "Saved. The change to who's in the team has gone to a manager for approval." };
    }
    const { error: setError } = await supabase.rpc("set_team", { p_team_id: id, p_members: members, p_leader: leader });
    if (setError) return { error: friendlyError(setError) };
  }
  revalidatePath(PAGE);
  revalidatePath("/settings/staff");
  return { message: "Saved." };
}

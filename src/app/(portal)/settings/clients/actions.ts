// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects: which team(s) look after a client (people who manage staff).
export async function setClientTeams(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const clientId = String(form.get("client_id") ?? "");
  if (!/^[0-9a-f-]{36}$/.test(clientId)) return { error: "Choose a client." };
  const teamIds = form.getAll("team_ids").map(String).filter((t) => /^[0-9a-f-]{36}$/.test(t));
  const supabase = await createClient();
  const { error: removeError } = await supabase.from("client_teams").delete().eq("client_id", clientId);
  if (removeError) return { error: friendlyError(removeError) };
  if (teamIds.length) {
    const { error } = await supabase.from("client_teams").insert(teamIds.map((team_id) => ({ client_id: clientId, team_id })));
    if (error) return { error: friendlyError(error) };
  }
  revalidatePath("/settings/clients");
  return { message: teamIds.length ? "Teams saved." : "No team looks after this client now." };
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole, requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";

// Clients: the Access page (update 107); the database checks each client and part.
async function requireClients() {
  const session = await requireSession();
  if (!(await seesClientsFor())) throw new Error("You can't change clients.");
  return session;
}
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects: which team(s) look after a client (people who manage staff).
export async function setClientTeams(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
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

const STATUSES = ["pending", "active", "suspended", "discharged"];
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);

// cmeprojects (Clients step 1): preferred name and status. The database keeps
// who changed the status and when, and writes it to the change log.
export async function saveClientCare(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!isId(id)) return { error: "Choose a client." };
  if (!STATUSES.includes(status)) return { error: "Choose a status." };
  const preferred = String(form.get("preferred_name") ?? "").trim().slice(0, 80);
  const supabase = await createClient();
  const { error } = await supabase.from("car_clients").update({ preferred_name: preferred, status }).eq("id", id);
  if (error) return { error: friendlyError(error) };
  revalidatePath("/settings/clients");
  return { message: "Saved." };
}

// Programs (NDIS, Support at Home ...): the system admin adds, renames and
// deactivates them. They're never deleted.
export async function saveProgram(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const id = String(form.get("id") ?? "");
  const name = String(form.get("name") ?? "").trim().slice(0, 80);
  if (!name) return { error: "Enter the program's name." };
  const values = { name, needs_dob: form.get("needs_dob") === "on", active: id ? form.get("active") === "on" : true };
  const supabase = await createClient();
  let error;
  if (id) {
    if (!isId(id)) return { error: "Choose a program." };
    ({ error } = await supabase.from("client_programs").update(values).eq("id", id));
  } else {
    const { data: last } = await supabase.from("client_programs").select("sort_order").order("sort_order", { ascending: false }).limit(1);
    ({ error } = await supabase.from("client_programs").insert({ ...values, sort_order: (last?.[0]?.sort_order ?? 0) + 10 }));
  }
  if (error) return { error: error.code === "23505" ? "That program is already on the list." : friendlyError(error) };
  revalidatePath("/settings/clients");
  return { message: id ? "Saved." : `${name} added.` };
}

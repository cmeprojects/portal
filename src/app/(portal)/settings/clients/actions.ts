// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { getMyAdminAreas } from "@/lib/settings";
import { requireSession } from "@/lib/session";
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

const SCHEMES = ["ndis", "support_at_home", "private", "other"];

// Care settings (update 110): the system admin, or whoever has the Care
// settings area (the database checks too).
async function requireCareSettings() {
  const session = await requireSession();
  if (session.profile.role !== "system_admin" && !(await getMyAdminAreas(session.profile.role)).includes("care")) throw new Error("You can't change Care settings.");
  return session;
}

// Programs (NDIS, Support at Home ...): added, renamed and deactivated in Care
// settings; each sits under one scheme. They're never deleted.
export async function saveProgram(_: FormState, form: FormData): Promise<FormState> {
  await requireCareSettings();
  const id = String(form.get("id") ?? "");
  const name = String(form.get("name") ?? "").trim().slice(0, 80);
  if (!name) return { error: "Enter the program's name." };
  const scheme = String(form.get("scheme") ?? "");
  if (!SCHEMES.includes(scheme)) return { error: "Choose the program's scheme." };
  const values = { name, scheme, needs_dob: form.get("needs_dob") === "on", active: id ? form.get("active") === "on" : true };
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

// A scheme's wording and rules (Care settings). The list of schemes is fixed.
export async function saveScheme(_: FormState, form: FormData): Promise<FormState> {
  await requireCareSettings();
  const key = String(form.get("key") ?? "");
  if (!SCHEMES.includes(key)) return { error: "Choose a scheme." };
  const word = String(form.get("person_word") ?? "").trim().slice(0, 30);
  const days = String(form.get("review_lead_days") ?? "")
    .split(/[\s,]+/)
    .map((d) => Number(d))
    .filter((d) => Number.isInteger(d) && d > 0 && d <= 365);
  const values = {
    label: String(form.get("label") ?? "").trim().slice(0, 60),
    person_word: word || null,
    review_label: String(form.get("review_label") ?? "").trim().slice(0, 60),
    change_review_label: String(form.get("change_review_label") ?? "").trim().slice(0, 60),
    review_lead_days: [...new Set(days)].sort((a, b) => b - a).slice(0, 5),
    needs_dob: form.get("needs_dob") === "on",
  };
  if (!values.label || !values.review_label || !values.change_review_label) return { error: "Fill in the name and both review names." };
  if (!values.review_lead_days.length) return { error: "Enter at least one reminder day, for example 30." };
  const { error } = await (await createClient()).from("client_schemes").update(values).eq("key", key);
  if (error) return { error: friendlyError(error) };
  revalidatePath("/settings/clients");
  return { message: "Saved." };
}

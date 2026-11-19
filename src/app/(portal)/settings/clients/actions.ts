// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { managesPrograms } from "@/lib/programs-access";
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
import { checkAuPhone, checkDob, checkEmail, checkFullAddress } from "@/lib/validate";
import { MAC_SCHEMES } from "@/lib/client-sections";

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
  // Archiving has its own step (with the reason); this only keeps an archived client archived.
  const { data: now } = await supabase.from("car_clients").select("status").eq("id", id).maybeSingle();
  if (status === "discharged" && now?.status !== "discharged") return { error: "Use Archive to archive a client (it asks for the reason)." };
  const names: Record<string, string> = {};
  if (form.has("given_name")) {
    const title = String(form.get("title") ?? "");
    names.title = ["", "mr", "mrs", "ms", "miss", "mx", "dr"].includes(title) ? title : "";
    names.given_name = String(form.get("given_name") ?? "").trim().slice(0, 40);
    names.middle_name = String(form.get("middle_name") ?? "").trim().slice(0, 40);
    names.family_name = String(form.get("family_name") ?? "").trim().slice(0, 40);
    if (!names.given_name || !names.family_name) return { error: "Fill in the first and last name." };
  }
  const { error } = await supabase.from("car_clients").update({ preferred_name: preferred, status, ...names }).eq("id", id);
  if (error) return { error: friendlyError(error) };
  revalidatePath("/settings/clients");
  return { message: "Saved." };
}

// cmeprojects (update 118): archive a client with the reason. The database
// checks who may (Clients, change) and records who and when.
const ARCHIVE = ["transferred", "moved_away", "no_longer_needed", "funding_ended", "passed_away", "client_choice", "other"];
export async function archiveClient(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const reason = String(form.get("archive_reason") ?? "");
  const note = String(form.get("archive_note") ?? "").trim().slice(0, 500);
  if (!isId(id)) return { error: "Choose a client." };
  if (!ARCHIVE.includes(reason)) return { error: "Choose why they're being archived." };
  if (reason === "other" && !note) return { error: "Say why they're being archived." };
  const { data, error } = await (await createClient())
    .from("car_clients")
    .update({ status: "discharged", archive_reason: reason, archive_note: note })
    .eq("id", id)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't archive this client." };
  revalidatePath("/settings/clients");
  revalidatePath(`/settings/clients/${id}`);
  return { message: "Archived." };
}

const SCHEMES = ["ndis", "support_at_home", "chsp", "private", "other"];

// Care settings (update 110): the system admin, or whoever has the Care
// settings area (the database checks too).
async function requireCareSettings() {
  const session = await requireSession();
  // update 152: also Manager Administrators (the database checks too).
  if (!(await managesPrograms())) throw new Error("You can't change programs and schemes.");
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
  revalidatePath("/settings/clients/programs");
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
  revalidatePath("/settings/clients/programs");
  return { message: "Saved." };
}

// cmeprojects (Care block, owner: a new client is given its care manager or
// support coordinator when it's added). Adds the client, then the first
// assignment. The database checks both (Clients change; Assigning staff).
export async function addClientWithManager(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const name = String(form.get("name") ?? "").trim().slice(0, 80);
  if (!name) return { error: "Enter their name." };
  const managerId = String(form.get("manager_id") ?? "");
  const as = String(form.get("assigned_as") ?? "case_manager");
  if (managerId && !isId(managerId)) return { error: "Choose who manages them." };
  if (!["case_manager", "support_coordinator"].includes(as)) return { error: "Choose care manager or support coordinator." };
  const supabase = await createClient();
  // update 148: the scheme they're registered under (skipped before it runs), and its
  // identifier, which is required: an NDIS number (9 digits) or a My Aged Care ID (AC + 8 digits).
  const scheme = String(form.get("scheme") ?? "");
  const ndis = String(form.get("ndis_number") ?? "").replace(/\s/g, "");
  const mac = String(form.get("aged_care_id") ?? "").replace(/\s/g, "").toUpperCase();
  if (scheme === "ndis" && !/^\d{9}$/.test(ndis)) return { error: "Enter their NDIS number (9 digits)." };
  if (MAC_SCHEMES.includes(scheme) && !/^AC\d{8}$/.test(mac)) return { error: "Enter their My Aged Care ID (AC followed by 8 numbers, for example AC12345678)." };
  const row: Record<string, string> = { name, reference: String(form.get("reference") ?? "").trim().slice(0, 60) };
  let res = await supabase.from("car_clients").insert(/^[a-z_]{1,40}$/.test(scheme) ? { ...row, scheme } : row).select("id").single();
  if (res.error?.code === "42703" || res.error?.code === "PGRST204") res = await supabase.from("car_clients").insert(row).select("id").single();
  const { data, error } = res;
  if (error || !data) return { error: friendlyError(error) };
  if (scheme === "ndis" || MAC_SCHEMES.includes(scheme)) {
    const { error: dError } = await supabase.from("client_details").upsert({ client_id: data.id, ...(scheme === "ndis" ? { ndis_number: ndis } : { aged_care_id: mac }) }, { onConflict: "client_id" });
    if (dError) {
      revalidatePath("/settings/clients");
      return { error: `${name} was added, but the ${scheme === "ndis" ? "NDIS number" : "My Aged Care ID"} wasn't saved: ${friendlyError(dError)} Add it on their page.`, spotlight: data.id };
    }
  }
  if (managerId) {
    const { error: aError } = await supabase.from("client_assignments").insert({ client_id: data.id, user_id: managerId, assigned_as: as });
    if (aError) {
      revalidatePath("/settings/clients");
      return { error: `${name} was added, but not assigned: ${friendlyError(aError)} Assign them on their page.`, spotlight: data.id };
    }
  }
  revalidatePath("/settings/clients");
  // The new client's id comes back, so the screen can open their details next.
  return { message: managerId ? `${name} added and assigned.` : `${name} added.`, spotlight: data.id };
}

// cmeprojects (owner, 19 Nov 2026): the full New participant page. Nothing is
// saved until here: the client, their details and who manages them, together.
// Contact details are checked (standing rule); the database checks who may.
export async function createClientFull(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const t = (k: string, max = 200) => String(form.get(k) ?? "").trim().slice(0, max);
  const given = t("given_name", 40);
  const family = t("family_name", 40);
  if (!given || !family) return { error: "Fill in the first and last name." };
  const title = t("title", 10);
  const scheme = t("scheme", 40);
  if (!/^[a-z_]{1,40}$/.test(scheme)) return { error: "Choose who funds them." };
  const ndis = t("ndis_number", 20).replace(/\s/g, "");
  const mac = t("aged_care_id", 20).replace(/\s/g, "").toUpperCase();
  if (scheme === "ndis" && !/^\d{9}$/.test(ndis)) return { error: "Enter their NDIS number (9 digits)." };
  if (MAC_SCHEMES.includes(scheme) && !/^AC\d{8}$/.test(mac)) return { error: "Enter their My Aged Care ID (AC followed by 8 numbers, for example AC12345678)." };
  const phone = checkAuPhone(t("phone", 30));
  const email = checkEmail(t("email", 120));
  const address = checkFullAddress(t("home_address", 300));
  // Mandatory (owner, 19 Nov 2026): date of birth, mobile, email, home address and state.
  const missing = [["date_of_birth", "date of birth"], ["phone", "mobile"], ["email", "email"], ["home_address", "home address"], ["state", "state"]].filter(([k]) => !t(k)).map(([, l]) => l);
  if (missing.length) return { error: `Fill in the ${missing.join(", ")}. If they don't have a mobile or email, enter the family carer's or the person assisting them.` };
  const dobCheck = checkDob(t("date_of_birth", 10));
  const problems = [dobCheck.ok ? "" : `Date of birth: ${dobCheck.error}`, phone.ok ? "" : `Phone: ${phone.error}`, email.ok ? "" : `Email: ${email.error}`, address.ok ? "" : `Home address: ${address.error}`].filter(Boolean);
  const state = t("state", 3);
  const inAddress = address.ok ? address.value.match(/ (NSW|VIC|QLD|WA|SA|TAS|ACT|NT) \d{4}$/)?.[1] : null;
  if (inAddress && state && state !== inAddress) problems.push(`State: the home address is in ${inAddress}, but ${state} is chosen.`);
  if (problems.length) return { error: problems.join(" ") };
  const dob = t("date_of_birth", 10);
  const managerId = t("manager_id", 36);
  const as = t("assigned_as", 30) || "case_manager";
  if (managerId && !isId(managerId)) return { error: "Choose who manages them." };
  if (!["case_manager", "support_coordinator"].includes(as)) return { error: "Choose care manager or support coordinator." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("car_clients")
    .insert({
      name: `${given} ${family}`.slice(0, 80),
      title: ["", "mr", "mrs", "ms", "miss", "mx", "dr"].includes(title) ? title : "",
      given_name: given,
      middle_name: t("middle_name", 40),
      family_name: family,
      preferred_name: t("preferred_name", 80),
      reference: t("reference", 60),
      scheme,
    })
    .select("id")
    .single();
  if (error || !data) return { error: friendlyError(error) };
  const details: Record<string, string | null> = {
    date_of_birth: /^\d{4}-\d{2}-\d{2}$/.test(dob) ? dob : null,
    gender: t("gender", 30),
    phone: phone.ok ? phone.value : "",
    email: email.ok ? email.value : "",
    home_address: address.ok ? address.value : "",
    state: state || inAddress || "",
  };
  if (scheme === "ndis") details.ndis_number = ndis;
  if (MAC_SCHEMES.includes(scheme)) details.aged_care_id = mac;
  const { error: dError } = await supabase.from("client_details").upsert({ client_id: data.id, ...details }, { onConflict: "client_id" });
  if (dError) {
    revalidatePath("/settings/clients");
    return { error: `They were added, but their details weren't saved: ${friendlyError(dError)} Add them on their page.`, spotlight: data.id };
  }
  if (managerId) {
    const { error: aError } = await supabase.from("client_assignments").insert({ client_id: data.id, user_id: managerId, assigned_as: as });
    if (aError) {
      revalidatePath("/settings/clients");
      return { error: `They were added, but not assigned: ${friendlyError(aError)} Assign them on their page.`, spotlight: data.id };
    }
  }
  revalidatePath("/settings/clients");
  return { message: `${given} ${family} added.`, spotlight: data.id };
}

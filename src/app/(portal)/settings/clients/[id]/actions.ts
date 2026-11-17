// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
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
import { SECTION_FIELDS, type SectionTable } from "@/lib/client-sections";

const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);

// cmeprojects (Clients & Care steps 2 to 5): saves one item in a client's
// profile (a location, their details, a person, an alert or a service). Only
// the fields listed for that section are accepted; the database checks the
// rest (who may save, approvals, readiness) and logs the change.
export async function saveClientSection(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const table = String(form.get("table") ?? "") as SectionTable;
  const fields = SECTION_FIELDS[table];
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  if (!fields || !isId(clientId) || (id && !isId(id))) return { error: "That didn't save. Please reload the page." };

  const values: Record<string, unknown> = {};
  let notes: string | null = null;
  for (const f of fields) {
    const raw = String(form.get(f.name) ?? "").trim();
    if (f.name === "notes") {
      notes = raw.slice(0, f.max ?? 5000);
      continue;
    }
    if (f.type === "checkbox") values[f.name] = form.get(f.name) === "on";
    else if (f.type === "date") values[f.name] = /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : null;
    else if (f.type === "select" && f.options) values[f.name] = f.options.some(([k]) => k === raw) ? raw : f.options[0][0];
    else if (f.type === "select") values[f.name] = isId(raw) ? raw : null;
    else values[f.name] = raw.slice(0, f.max ?? 200);
    if (f.required && !values[f.name]) return { error: `Fill in ${f.label.toLowerCase()}.` };
  }

  const supabase = await createClient();
  let error;
  let savedId = id;
  if (table === "client_details") {
    ({ error } = await supabase.from("client_details").upsert({ client_id: clientId, ...values }, { onConflict: "client_id" }));
  } else if (id) {
    ({ error } = await supabase.from(table).update(values).eq("id", id).eq("client_id", clientId));
  } else {
    const res = await supabase.from(table).insert({ client_id: clientId, ...values }).select("id").single();
    error = res.error;
    savedId = (res.data?.id as string) ?? "";
  }
  if (!error && table === "client_alerts" && savedId && notes !== null) {
    ({ error } = await supabase.from("client_alert_notes").upsert({ alert_id: savedId, client_id: clientId, details: notes }, { onConflict: "alert_id" }));
  }
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: id || table === "client_details" ? "Saved." : "Added." };
}

// "No known safety alerts": answers the safety step when there's nothing to record.
export async function recordNoAlerts(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "Choose a client." };
  const supabase = await createClient();
  const { error } = await supabase
    .from("client_alerts")
    .insert({ client_id: clientId, kind: "no_known_alerts", severity: "low", title: "No known safety alerts", worker_instructions: "" });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Recorded: no known safety alerts." };
}

// cmeprojects (Stage 5, update 106): assign a staff member to this client, or
// end an assignment. The database checks who may (Assigning staff), stops
// self-assignment, and keeps every assignment (ended, never deleted).
export async function assignStaff(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const as = String(form.get("assigned_as") ?? "case_manager");
  const startsOn = String(form.get("starts_on") ?? "");
  const endsOn = String(form.get("ends_on") ?? "");
  if (!isId(clientId) || !isId(userId)) return { error: "Choose a staff member." };
  if (!["case_manager", "intake", "key_worker", "other"].includes(as)) return { error: "Choose what they're assigned as." };
  const day = /^\d{4}-\d{2}-\d{2}$/;
  const { error } = await (await createClient()).from("client_assignments").insert({
    client_id: clientId,
    user_id: userId,
    assigned_as: as,
    ...(day.test(startsOn) ? { starts_on: startsOn } : {}),
    ...(day.test(endsOn) ? { ends_on: endsOn } : {}),
    note: String(form.get("note") ?? "").slice(0, 300),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Assigned." };
}

export async function endAssignment(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_assignments").update({ ended_at: new Date().toISOString() }).eq("id", id);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (Care block C2, update 111): communication preferences. The
// database checks who may (Communication preferences, edit, for this client).
export async function saveComms(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  const contact = String(form.get("preferred_contact") ?? "");
  if (!["", "phone", "sms", "email", "in_person", "through_representative"].includes(contact)) return { error: "Choose how to contact them." };
  const values = {
    client_id: clientId,
    preferred_contact: contact,
    language: String(form.get("language") ?? "").trim().slice(0, 60),
    interpreter_needed: form.get("interpreter_needed") === "on",
    accessibility_needs: String(form.get("accessibility_needs") ?? "").trim().slice(0, 1000),
    notes: String(form.get("notes") ?? "").trim().slice(0, 1000),
  };
  const { error } = await (await createClient()).from("client_comms").upsert(values, { onConflict: "client_id" });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Saved." };
}

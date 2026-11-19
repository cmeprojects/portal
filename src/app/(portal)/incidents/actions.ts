// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { after } from "next/server";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, REPORTABLE } from "@/lib/incidents";
import { sydneyInstant } from "@/lib/sydney-time";

// cmeprojects (update 149): client incidents, the usual flow (report, triage,
// investigation, sign-off). The database checks who may take each step and
// keeps the timeline; nothing is deleted.
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const isLocal = (v: string) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(v);
const instant = (v: string) => (isLocal(v) ? sydneyInstant(v.slice(0, 10), v.slice(11, 16)) : null);
const text = (form: FormData, key: string, max: number) => String(form.get(key) ?? "").trim().slice(0, max);
// Notices go out straight after the response (and each hour from the cron job).
const tell = () =>
  after(async () => {
    const { error } = await createAdminClient().rpc("run_incident_alerts");
    if (error && error.code !== "PGRST202") console.error("incident alerts", error.message);
  });
const refresh = (id?: string, clientId?: string) => {
  revalidatePath("/incidents");
  if (id) revalidatePath(`/incidents/${id}`);
  if (clientId) revalidatePath(`/settings/clients/${clientId}`);
  revalidatePath("/settings/clients");
};
async function patch(id: string, values: Record<string, unknown>) {
  const { data, error } = await (await createClient()).from("client_incidents").update(values).eq("id", id).select("client_id").maybeSingle();
  if (error) return { error: friendlyError(error) };
  if (!data) return { error: "You can't change this incident." };
  refresh(id, data.client_id);
  return null;
}

export async function reportIncident(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const clientId = String(form.get("client_id") ?? "");
  const kind = String(form.get("kind") ?? "");
  const severity = String(form.get("severity") ?? "");
  const summary = text(form, "summary", 4000);
  if (!isId(clientId)) return { error: "Choose the client." };
  if (!INCIDENT_KINDS.some(([k]) => k === kind)) return { error: "Choose what kind of incident it was." };
  if (!INCIDENT_SEVERITY.some(([k]) => k === severity)) return { error: "Choose how serious it was." };
  if (!summary) return { error: "Describe what happened." };
  const { data, error } = await (await createClient())
    .from("client_incidents")
    .insert({
      client_id: clientId,
      kind,
      severity,
      summary,
      occurred_at: instant(String(form.get("occurred_at") ?? "")) ?? new Date().toISOString(),
      location: text(form, "location", 200),
      immediate_action: text(form, "immediate_action", 2000),
    })
    .select("id")
    .single();
  if (error || !data) return { error: friendlyError(error) };
  tell();
  refresh(data.id, clientId);
  return { message: "Incident reported. Managers and the case manager have been told.", spotlight: data.id };
}

// Triage (a manager): what it is, how serious, NDIS reportable or not, and who investigates.
export async function triageIncident(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const kind = String(form.get("kind") ?? "");
  const severity = String(form.get("severity") ?? "");
  const reportable = form.get("reportable") === "on";
  const category = String(form.get("reportable_category") ?? "");
  const investigator = String(form.get("investigator_id") ?? "");
  const start = form.get("start") === "1";
  if (reportable && !REPORTABLE.some(([k]) => k === category)) return { error: "Choose the reportable incident category." };
  if (start && !isId(investigator)) return { error: "Choose who will investigate." };
  const values: Record<string, unknown> = {
    kind: INCIDENT_KINDS.some(([k]) => k === kind) ? kind : "other",
    severity: INCIDENT_SEVERITY.some(([k]) => k === severity) ? severity : "medium",
    immediate_action: text(form, "immediate_action", 2000),
    location: text(form, "location", 200),
    reportable,
    reportable_category: reportable ? category : null,
    investigator_id: isId(investigator) ? investigator : null,
  };
  if (start) values.status = "investigating";
  const res = await patch(id, values);
  if (res) return res;
  tell();
  return { message: start ? "Triaged. The investigator has been told." : "Saved." };
}

// The investigation (the investigator or a manager); send=1 sends it for sign-off.
export async function saveInvestigation(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const staff = String(form.get("staff_involved") ?? "");
  const send = form.get("send") === "1";
  const values: Record<string, unknown> = {
    staff_involved: isId(staff) ? staff : null,
    witnesses: text(form, "witnesses", 1000),
    findings: text(form, "findings", 4000),
    contributing_factors: text(form, "contributing_factors", 2000),
    family_told_at: instant(String(form.get("family_told_at") ?? "")),
    family_told_note: text(form, "family_told_note", 1000),
  };
  if (send) values.status = "review";
  const res = await patch(id, values);
  if (res) return res;
  if (send) tell();
  return { message: send ? "Sent for sign-off. Managers have been told." : "Saved." };
}

// The NDIS Commission report (a manager, any open stage).
export async function saveCommissionReport(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const at = instant(String(form.get("reported_to_regulator_at") ?? ""));
  if (!at) return { error: "Enter when it was reported to the Commission." };
  const res = await patch(id, { reported_to_regulator_at: at, regulator_ref: text(form, "regulator_ref", 60) });
  return res ?? { message: "Commission report recorded." };
}

// Sign-off (Incidents: approve): close with the outcome, or send it back with a reason.
export async function signOffIncident(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const decision = String(form.get("decision") ?? "");
  const outcome = text(form, "outcome", 4000);
  if (decision === "back") {
    const why = text(form, "back_reason", 2000);
    if (!why) return { error: "Say what more is needed before sending it back." };
    const res = await patch(id, { status: "investigating", outcome });
    if (res) return res;
    await (await createClient()).from("client_incident_events").insert({ incident_id: id, kind: "note", body: `Sent back: ${why}` });
    return { message: "Sent back to the investigator." };
  }
  if (!outcome) return { error: "Write the outcome before signing off." };
  const res = await patch(id, { status: "closed", outcome });
  return res ?? { message: "Signed off and closed." };
}

export async function reopenIncident(form: FormData) {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (isId(id)) await patch(id, { status: "investigating" });
}

export async function addIncidentAction(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("incident_id") ?? "");
  const action = text(form, "action", 500);
  const owner = String(form.get("owner_id") ?? "");
  const due = String(form.get("due_on") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  if (!action) return { error: "Say what needs to be done." };
  if (!isId(owner)) return { error: "Choose who will do it." };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(due)) return { error: "Choose the due date." };
  const { error } = await (await createClient()).from("client_incident_actions").insert({ incident_id: id, action, owner_id: owner, due_on: due });
  if (error) return { error: friendlyError(error) };
  tell();
  refresh(id);
  return { message: "Action added. They've been told." };
}

// The owner (or the investigator or a manager) marks an action done, or not done.
export async function setActionDone(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  const incident = String(form.get("incident_id") ?? "");
  const done = form.get("done") === "1";
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const { error } = await (await createClient())
    .from("client_incident_actions")
    .update(done ? { done_at: new Date().toISOString(), done_note: text(form, "done_note", 1000) } : { done_at: null })
    .eq("id", id);
  if (error) return { error: friendlyError(error) };
  refresh(isId(incident) ? incident : undefined);
  revalidatePath("/my-shifts");
  return { message: done ? "Marked done." : "Marked not done." };
}

export async function addIncidentNote(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  const body = text(form, "body", 4000);
  if (!isId(id) || !body) return { error: "Write the note." };
  const { error } = await (await createClient()).from("client_incident_events").insert({ incident_id: id, body, kind: "note" });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  return { message: "Note added." };
}

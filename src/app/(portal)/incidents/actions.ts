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

// cmeprojects (update 149): incidents. The database checks who may report
// and manage them, every step, and keeps the timeline; nothing is deleted.
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
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

export async function reportIncident(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const clientId = String(form.get("client_id") ?? "");
  const kind = String(form.get("kind") ?? "");
  const severity = String(form.get("severity") ?? "");
  const summary = String(form.get("summary") ?? "").trim().slice(0, 4000);
  const at = String(form.get("occurred_at") ?? "");
  if (!isId(clientId)) return { error: "Choose the client." };
  if (!INCIDENT_KINDS.some(([k]) => k === kind)) return { error: "Choose what kind of incident it was." };
  if (!INCIDENT_SEVERITY.some(([k]) => k === severity)) return { error: "Choose how serious it was." };
  if (!summary) return { error: "Describe what happened." };
  const occurred = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(at) ? sydneyInstant(at.slice(0, 10), at.slice(11, 16)) : new Date().toISOString();
  const { data, error } = await (await createClient())
    .from("client_incidents")
    .insert({ client_id: clientId, kind, severity, summary, occurred_at: occurred, immediate_action: String(form.get("immediate_action") ?? "").trim().slice(0, 2000) })
    .select("id")
    .single();
  if (error || !data) return { error: friendlyError(error) };
  tell();
  refresh(data.id, clientId);
  return { message: "Incident reported. Managers and the case manager have been told.", spotlight: data.id };
}

// One step: acknowledge, investigate, close (needs an outcome), or reopen.
export async function setIncidentStatus(form: FormData) {
  await requireSession();
  const id = String(form.get("id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!isId(id) || !["acknowledged", "investigating", "closed"].includes(status)) return;
  const { data } = await (await createClient()).from("client_incidents").update({ status }).eq("id", id).select("client_id").maybeSingle();
  refresh(id, data?.client_id);
}

export async function updateIncident(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const kind = String(form.get("kind") ?? "");
  const severity = String(form.get("severity") ?? "");
  const reportable = form.get("reportable") === "on";
  const category = String(form.get("reportable_category") ?? "");
  const regAt = String(form.get("reported_to_regulator_at") ?? "");
  const close = form.get("close") === "1";
  const patch: Record<string, unknown> = {
    kind: INCIDENT_KINDS.some(([k]) => k === kind) ? kind : "other",
    severity: INCIDENT_SEVERITY.some(([k]) => k === severity) ? severity : "medium",
    immediate_action: String(form.get("immediate_action") ?? "").trim().slice(0, 2000),
    reportable,
    reportable_category: reportable && REPORTABLE.some(([k]) => k === category) ? category : null,
    regulator_ref: String(form.get("regulator_ref") ?? "").trim().slice(0, 60),
    reported_to_regulator_at: /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(regAt) ? sydneyInstant(regAt.slice(0, 10), regAt.slice(11, 16)) : null,
    outcome: String(form.get("outcome") ?? "").trim().slice(0, 4000),
  };
  if (reportable && !patch.reportable_category) return { error: "Choose the reportable incident category." };
  if (close) patch.status = "closed";
  const { data, error } = await (await createClient()).from("client_incidents").update(patch).eq("id", id).select("client_id").maybeSingle();
  if (error) return { error: friendlyError(error) };
  if (reportable) tell();
  refresh(id, data?.client_id);
  return { message: close ? "Incident closed." : "Saved." };
}

export async function addIncidentNote(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  const body = String(form.get("body") ?? "").trim().slice(0, 4000);
  if (!isId(id) || !body) return { error: "Write the note." };
  const { error } = await (await createClient()).from("client_incident_events").insert({ incident_id: id, body, kind: "note" });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  return { message: "Note added." };
}

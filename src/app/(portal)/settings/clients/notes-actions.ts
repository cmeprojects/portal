// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { ALERT_KINDS, CLIENT_STATUS } from "@/lib/client-sections";

export type ClientNotes = {
  shiftNotes: { when: string; at: string; worker: string; wellbeing: string; concern: boolean; concernNote: string; text: string }[] | null;
  practitionerNotes: { when: string; who: string; text: string }[] | null;
  comms: { contact: string; language: string; interpreter: boolean; needs: string; notes: string } | null;
  log: { when: string; who: string; what: string }[] | null;
  reviews: { label: string; due: string; status: string; reason: string }[] | null;
  alerts: { kind: string; severity: string; title: string; instructions: string; escalation: string }[] | null;
};

const when = (iso: string) => new Date(iso).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" });
const day = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" });

// cmeprojects: what the client list's notes pop-up shows for one client. Each
// part is read as the signed-in person, so the database limits it to what they
// may see; a part they can't see comes back empty (null), never someone else's data.
export async function loadClientNotes(clientId: string): Promise<ClientNotes | { error: string }> {
  await requireSession();
  if (!(await seesClientsFor()) || !/^[0-9a-f-]{36}$/.test(clientId)) return { error: "You can't see this client." };
  const supabase = await createClient();
  const since = new Date(Date.parse(new Date().toISOString()) - 90 * 86_400_000).toISOString();
  const [sn, pn, cm, lg, rv, schemes, al] = await Promise.all([
    supabase.from("shift_service_records").select("worker_id, delivered, client_wellbeing, concern, concern_note, created_at").eq("client_id", clientId).gte("created_at", since).order("created_at", { ascending: false }).limit(50),
    supabase.from("client_practitioner_notes").select("author_id, note_date, body, created_at").eq("client_id", clientId).order("note_date", { ascending: false }).limit(30),
    supabase.from("client_comms").select("preferred_contact, language, interpreter_needed, accessibility_needs, notes").eq("client_id", clientId).maybeSingle(),
    supabase.from("audit_log").select("action, created_at, actor_id, details").eq("entity", "client").eq("entity_id", clientId).order("created_at", { ascending: false }).limit(40),
    supabase.from("client_reviews").select("scheme, kind, due_on, status, reason").eq("client_id", clientId).order("due_on"),
    supabase.from("client_schemes").select("key, label, review_label, change_review_label"),
    supabase.from("client_alerts").select("kind, severity, title, worker_instructions, escalation").eq("client_id", clientId).eq("active", true).neq("kind", "no_known_alerts").order("severity"),
  ]);
  const people = [...new Set([...((sn.data ?? []) as { worker_id: string }[]).map((r) => r.worker_id), ...((pn.data ?? []) as { author_id: string | null }[]).map((r) => r.author_id), ...((lg.data ?? []) as { actor_id: string | null }[]).map((r) => r.actor_id)].filter((v): v is string => !!v))];
  const { data: names } = people.length ? await supabase.from("profiles").select("id, full_name, email").in("id", people) : { data: [] };
  const nameOf = new Map(((names ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const sch = new Map(((schemes.data ?? []) as { key: string; label: string; review_label: string; change_review_label: string }[]).map((s) => [s.key, s]));
  const what = (a: string, d: Record<string, unknown>) =>
    a === "client_status"
      ? `Status changed from ${CLIENT_STATUS[String(d.from)] ?? d.from} to ${CLIENT_STATUS[String(d.to)] ?? d.to}`
      : a.replace(/^client_/, "").replace(/_(added|changed)$/, " $1").replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase());
  return {
    shiftNotes: sn.error ? null : ((sn.data ?? []) as { worker_id: string; delivered: string; client_wellbeing: string; concern: boolean; concern_note: string; created_at: string }[]).map((r) => ({ when: when(r.created_at), at: r.created_at, worker: nameOf.get(r.worker_id) ?? "Staff member", wellbeing: r.client_wellbeing, concern: r.concern, concernNote: r.concern_note, text: r.delivered })),
    practitionerNotes: pn.error ? null : ((pn.data ?? []) as { author_id: string | null; note_date: string; body: string }[]).map((r) => ({ when: day(r.note_date), who: (r.author_id && nameOf.get(r.author_id)) || "Practitioner", text: r.body })),
    comms: cm.error || !cm.data ? null : { contact: String(cm.data.preferred_contact ?? ""), language: String(cm.data.language ?? ""), interpreter: Boolean(cm.data.interpreter_needed), needs: String(cm.data.accessibility_needs ?? ""), notes: String(cm.data.notes ?? "") },
    log: lg.error ? null : ((lg.data ?? []) as { action: string; created_at: string; actor_id: string | null; details: Record<string, unknown> | null }[]).map((r) => ({ when: when(r.created_at), who: (r.actor_id && nameOf.get(r.actor_id)) || "The portal", what: what(r.action, r.details ?? {}) })),
    alerts: al.error ? null : ((al.data ?? []) as { kind: string; severity: string; title: string; worker_instructions: string | null; escalation: string | null }[]).map((a) => ({ kind: ALERT_KINDS.find(([k]) => k === a.kind)?.[1] ?? a.kind, severity: a.severity, title: a.title, instructions: a.worker_instructions ?? "", escalation: a.escalation ?? "" })),
    reviews: rv.error ? null : ((rv.data ?? []) as { scheme: string; kind: string; due_on: string; status: string; reason: string | null }[]).map((r) => {
      const w = sch.get(r.scheme);
      return { label: `${w ? (r.kind === "scheduled" ? w.review_label : w.change_review_label) : "Review"} (${w?.label ?? r.scheme})`, due: r.due_on, status: r.status, reason: r.reason ?? "" };
    }),
  };
}

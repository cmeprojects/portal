// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Check } from "lucide-react";
import { requireSession } from "@/lib/session";
import { canDoFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Button, Card, PageHeader } from "@/components/ui";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, INCIDENT_STAGES, INCIDENT_STATUS, REPORTABLE, label } from "@/lib/incidents";
import { reopenIncident } from "../actions";
import { ActionAddForm, ActionDoneForm, CommissionForm, IncidentNoteForm, InvestigationForm, SignOffForm, TriageForm, type IncidentRow } from "../forms";

export const metadata: Metadata = { title: "Incident" };

const when = (iso: string | null) => (iso ? new Date(iso).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" }) : "");
const day = (d: string) => new Date(`${d}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });

type Incident = IncidentRow & {
  ref: string;
  client_id: string;
  shift_id: string | null;
  source: string;
  summary: string;
  occurred_at: string;
  reported_at: string;
  reported_by: string | null;
  report_due_at: string | null;
  triaged_by: string | null;
  triaged_at: string | null;
  sent_for_review_by: string | null;
  sent_for_review_at: string | null;
  closed_by: string | null;
  closed_at: string | null;
  car_clients: { name: string; preferred_name: string | null } | null;
};
type Action = { id: string; action: string; owner_id: string; due_on: string; done_at: string | null; done_by: string | null; done_note: string };

// cmeprojects (update 149): one incident, worked through the usual flow:
// reported, triage, investigation, manager sign-off, closed.
export default async function IncidentPage({ params }: PageProps<"/incidents/[id]">) {
  const { profile } = await requireSession();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data } = await supabase.from("client_incidents").select("*, car_clients(name, preferred_name)").eq("id", id).maybeSingle();
  if (!data) notFound();
  const inc = data as Incident;
  const [canEdit, canApprove, evRes, actRes, staffRes] = await Promise.all([
    canDoFor("clients.incidents", "edit", inc.client_id),
    canDoFor("clients.incidents", "approve", inc.client_id),
    supabase.from("client_incident_events").select("id, actor, kind, body, created_at").eq("incident_id", id).order("created_at", { ascending: false }),
    supabase.from("client_incident_actions").select("id, action, owner_id, due_on, done_at, done_by, done_note").eq("incident_id", id).order("due_on"),
    supabase.from("profiles").select("id, full_name, email, role").eq("active", true).not("role", "in", "(new_starter,external)").order("full_name"),
  ]);
  const events = (evRes.data ?? []) as { id: number; actor: string | null; kind: string; body: string; created_at: string }[];
  const actions = (actRes.data ?? []) as Action[];
  const staffRows = (staffRes.data ?? []) as { id: string; full_name: string | null; email: string }[];
  const staff: [string, string][] = staffRows.map((p) => [p.id, p.full_name || p.email]);
  const names = new Map(staff);
  const who = (pid: string | null) => (pid ? (names.get(pid) ?? "Staff member") : "The system");
  const isInvestigator = inc.investigator_id === profile.id;
  const mayInvestigate = (canEdit || isInvestigator) && inc.status === "investigating";
  const [st, stClass] = INCIDENT_STATUS[inc.status] ?? [inc.status, ""];
  const client = inc.car_clients?.preferred_name || inc.car_clients?.name || "Client";
  const now = Date.parse(new Date().toISOString());
  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
  const commissionDue = inc.reportable && !inc.reported_to_regulator_at && inc.report_due_at && inc.status !== "closed";
  const overdue = commissionDue && Date.parse(inc.report_due_at as string) < now;
  // Where it is in the flow (triage is done once it's under investigation).
  const at = { new: 1, investigating: 2, review: 3, closed: 4 }[inc.status] ?? 0;
  const openActions = actions.filter((a) => !a.done_at).length;

  return (
    <div className="flex flex-col gap-4">
      <Link href="/incidents" className="text-sm text-muted hover:text-ink">
        ← All incidents
      </Link>
      <PageHeader eyebrow={inc.ref} title={`${client} · ${label(INCIDENT_KINDS, inc.kind)}`} />
      <ol className="flex flex-wrap items-center gap-1 text-xs font-medium">
        {INCIDENT_STAGES.map(([k, l], i) => {
          const done = i < at || inc.status === "closed";
          const current = i === at && inc.status !== "closed";
          return (
            <li key={k} className="flex items-center gap-1">
              <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 ${done ? "bg-good-soft text-good" : current ? "bg-brand text-brand-fg" : "bg-line text-muted"}`}>
                {done ? <Check className="size-3" aria-hidden /> : null}
                {l}
              </span>
              {i < INCIDENT_STAGES.length - 1 ? <span className="text-muted">›</span> : null}
            </li>
          );
        })}
      </ol>
      <div className="flex flex-wrap items-center gap-2">
        <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${stClass}`}>{st}</span>
        <span className={`text-sm font-medium ${inc.severity === "high" || inc.severity === "critical" ? "text-danger" : "text-muted"}`}>{label(INCIDENT_SEVERITY, inc.severity)}</span>
        {inc.reportable ? <span className="rounded-full bg-danger-soft px-2.5 py-0.5 text-xs font-semibold text-danger">NDIS reportable · {label(REPORTABLE, inc.reportable_category)}</span> : null}
        {inc.investigator_id ? <span className="text-sm text-muted">Investigator: {who(inc.investigator_id)}</span> : null}
        {inc.status === "closed" && canApprove ? (
          <form action={reopenIncident} className="ml-auto">
            <input type="hidden" name="id" value={inc.id} />
            <Button size="sm" variant="outline">
              Reopen
            </Button>
          </form>
        ) : null}
      </div>
      {commissionDue ? (
        <div className={`rounded-xl px-4 py-3 text-sm font-medium ${overdue ? "bg-danger text-white" : "bg-danger-soft text-danger"}`}>
          {overdue ? "The NDIS Commission report is overdue. It was due" : "Report to the NDIS Commission by"} {when(inc.report_due_at)}.
        </div>
      ) : null}
      <div className="grid gap-4 lg:grid-cols-[1fr_22rem]">
        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="text-sm font-semibold text-ink">1. Reported</h2>
            <p className="whitespace-pre-wrap text-sm text-ink">{inc.summary}</p>
            {inc.immediate_action && inc.status !== "new" ? (
              <>
                <h3 className="text-xs font-semibold text-muted">Done straight away</h3>
                <p className="whitespace-pre-wrap text-sm text-ink">{inc.immediate_action}</p>
              </>
            ) : null}
            <dl className="grid gap-x-4 gap-y-1 text-sm sm:grid-cols-[12rem_1fr]">
              <dt className="text-muted">When it happened</dt>
              <dd>{when(inc.occurred_at)}</dd>
              {inc.location ? (
                <>
                  <dt className="text-muted">Where</dt>
                  <dd>{inc.location}</dd>
                </>
              ) : null}
              <dt className="text-muted">Reported by</dt>
              <dd>
                {who(inc.reported_by)}, {when(inc.reported_at)}
                {inc.source === "shift_note" ? " (shift note)" : ""}
              </dd>
              {inc.triaged_at ? (
                <>
                  <dt className="text-muted">Triaged</dt>
                  <dd>
                    {who(inc.triaged_by)}, {when(inc.triaged_at)}
                  </dd>
                </>
              ) : null}
            </dl>
            <div className="flex gap-3 text-sm">
              <Link href={`/settings/clients/${inc.client_id}?tab=incidents`} className="font-medium text-brand hover:underline">
                Open {client}&apos;s page
              </Link>
              {inc.shift_id ? (
                <Link href={`/settings/clients/${inc.client_id}?tab=shifts&shift=${inc.shift_id}`} className="font-medium text-brand hover:underline">
                  View the shift
                </Link>
              ) : null}
            </div>
          </Card>

          {canEdit && inc.status !== "closed" ? (
            <Card className="p-4">
              <h2 className="text-sm font-semibold text-ink">2. Triage</h2>
              <p className="mb-3 text-xs text-muted">{inc.status === "new" ? "Check what happened, decide if it's NDIS reportable, and choose who investigates." : "You can still correct the triage while the incident is open."}</p>
              {inc.status === "new" ? (
                <TriageForm inc={inc} staff={staff} />
              ) : (
                <details>
                  <summary className="cursor-pointer text-sm font-medium text-brand">Change the triage</summary>
                  <div className="mt-3">
                    <TriageForm inc={inc} staff={staff} />
                  </div>
                </details>
              )}
            </Card>
          ) : null}

          {inc.reportable && canEdit && inc.status !== "closed" ? (
            <Card className="flex flex-col gap-2 p-4">
              <h2 className="text-sm font-semibold text-ink">NDIS Commission report</h2>
              <CommissionForm inc={inc} />
            </Card>
          ) : null}

          {at >= 2 ? (
            <Card className="flex flex-col gap-3 p-4">
              <h2 className="text-sm font-semibold text-ink">3. Investigation</h2>
              {mayInvestigate ? (
                <InvestigationForm inc={inc} staff={staff} canSend />
              ) : (
                <dl className="grid gap-x-4 gap-y-2 text-sm sm:grid-cols-[12rem_1fr]">
                  <dt className="text-muted">Staff member involved</dt>
                  <dd>{inc.staff_involved ? who(inc.staff_involved) : "None recorded"}</dd>
                  {inc.witnesses ? (
                    <>
                      <dt className="text-muted">Witnesses</dt>
                      <dd>{inc.witnesses}</dd>
                    </>
                  ) : null}
                  <dt className="text-muted">Findings</dt>
                  <dd className="whitespace-pre-wrap">{inc.findings || "Not written yet"}</dd>
                  {inc.contributing_factors ? (
                    <>
                      <dt className="text-muted">Contributing factors</dt>
                      <dd className="whitespace-pre-wrap">{inc.contributing_factors}</dd>
                    </>
                  ) : null}
                  <dt className="text-muted">Client or family told</dt>
                  <dd>{[when(inc.family_told_at), inc.family_told_note].filter(Boolean).join(" · ") || "Not recorded"}</dd>
                  {inc.sent_for_review_at ? (
                    <>
                      <dt className="text-muted">Sent for sign-off</dt>
                      <dd>
                        {who(inc.sent_for_review_by)}, {when(inc.sent_for_review_at)}
                      </dd>
                    </>
                  ) : null}
                </dl>
              )}
              <div className="flex flex-col gap-2 border-t border-line pt-3">
                <h3 className="text-xs font-semibold text-ink">Actions {openActions ? <span className="text-muted">({openActions} open)</span> : null}</h3>
                {actions.length ? (
                  <ul className="flex flex-col divide-y divide-line">
                    {actions.map((a) => {
                      const late = !a.done_at && a.due_on < today;
                      const mine = a.owner_id === profile.id;
                      return (
                        <li key={a.id} className="flex flex-wrap items-center gap-2 py-2 text-sm">
                          <span className={`min-w-0 flex-1 ${a.done_at ? "text-muted line-through" : "text-ink"}`}>{a.action}</span>
                          <span className="text-xs text-muted">{who(a.owner_id)}</span>
                          <span className={`text-xs ${late ? "font-semibold text-danger" : "text-muted"}`}>{a.done_at ? `Done ${when(a.done_at)}` : `${late ? "Overdue, due" : "Due"} ${day(a.due_on)}`}</span>
                          {inc.status !== "closed" && (mine || canEdit || isInvestigator) ? <ActionDoneForm id={a.id} incidentId={inc.id} done={!!a.done_at} /> : null}
                          {a.done_note ? <p className="w-full text-xs text-muted">{a.done_note}</p> : null}
                        </li>
                      );
                    })}
                  </ul>
                ) : (
                  <p className="text-sm text-muted">No actions yet. Add what needs to change so it doesn&apos;t happen again.</p>
                )}
                {inc.status !== "closed" && (canEdit || isInvestigator) ? <ActionAddForm incidentId={inc.id} staff={staff} /> : null}
              </div>
            </Card>
          ) : null}

          {at >= 3 ? (
            <Card className="flex flex-col gap-3 p-4">
              <h2 className="text-sm font-semibold text-ink">4. Manager sign-off</h2>
              {inc.status === "review" && canApprove ? (
                <>
                  {openActions ? <p className="text-sm text-danger">{openActions} action{openActions === 1 ? " is" : "s are"} still open. Every action needs to be done before sign-off.</p> : null}
                  <SignOffForm inc={inc} />
                </>
              ) : inc.status === "review" ? (
                <p className="text-sm text-muted">Waiting for a manager to sign it off.</p>
              ) : (
                <dl className="grid gap-x-4 gap-y-2 text-sm sm:grid-cols-[12rem_1fr]">
                  <dt className="text-muted">Outcome</dt>
                  <dd className="whitespace-pre-wrap">{inc.outcome}</dd>
                  <dt className="text-muted">Signed off</dt>
                  <dd>
                    {who(inc.closed_by)}, {when(inc.closed_at)}
                  </dd>
                  {inc.reported_to_regulator_at ? (
                    <>
                      <dt className="text-muted">Reported to the Commission</dt>
                      <dd>
                        {when(inc.reported_to_regulator_at)}
                        {inc.regulator_ref ? ` · ${inc.regulator_ref}` : ""}
                      </dd>
                    </>
                  ) : null}
                </dl>
              )}
            </Card>
          ) : null}
        </div>
        <Card className="flex flex-col gap-3 self-start p-4">
          <h2 className="text-sm font-semibold text-ink">Timeline</h2>
          {(canEdit || isInvestigator) && inc.status !== "closed" ? <IncidentNoteForm id={inc.id} /> : null}
          <ol className="flex flex-col gap-3">
            {events.map((e) => (
              <li key={e.id} className={`border-l-2 pl-3 ${e.kind === "step" ? "border-brand" : "border-line"}`}>
                <p className="whitespace-pre-wrap text-sm text-ink">
                  {e.kind === "step" ? <span className="font-medium">{who(e.actor)} </span> : null}
                  {e.body}
                </p>
                <p className="text-xs text-muted">
                  {e.kind === "note" ? `${who(e.actor)} · ` : ""}
                  {when(e.created_at)}
                </p>
              </li>
            ))}
          </ol>
        </Card>
      </div>
    </div>
  );
}

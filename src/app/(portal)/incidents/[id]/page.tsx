// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Button, Card, PageHeader } from "@/components/ui";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, INCIDENT_STATUS, REPORTABLE, label } from "@/lib/incidents";
import { setIncidentStatus } from "../actions";
import { IncidentEditForm, IncidentNoteForm, type IncidentRow } from "../forms";

export const metadata: Metadata = { title: "Incident" };

const when = (iso: string | null) => (iso ? new Date(iso).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" }) : "");

// cmeprojects (update 149): one incident, its steps and its timeline.
export default async function IncidentPage({ params }: PageProps<"/incidents/[id]">) {
  await requireSession();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data } = await supabase.from("client_incidents").select("*, car_clients(name, preferred_name)").eq("id", id).maybeSingle();
  if (!data) notFound();
  const inc = data as IncidentRow & {
    ref: string;
    client_id: string;
    shift_id: string | null;
    source: string;
    summary: string;
    occurred_at: string;
    reported_at: string;
    reported_by: string | null;
    report_due_at: string | null;
    acknowledged_by: string | null;
    acknowledged_at: string | null;
    closed_by: string | null;
    closed_at: string | null;
    car_clients: { name: string; preferred_name: string | null } | null;
  };
  const canEdit = await canDo("clients.incidents", "edit");
  const { data: evs } = await supabase.from("client_incident_events").select("id, actor, kind, body, created_at").eq("incident_id", id).order("created_at", { ascending: false });
  const events = (evs ?? []) as { id: number; actor: string | null; kind: string; body: string; created_at: string }[];
  const ids = [...new Set([inc.reported_by, inc.acknowledged_by, inc.closed_by, ...events.map((e) => e.actor)].filter(Boolean))] as string[];
  const { data: people } = ids.length ? await supabase.from("profiles").select("id, full_name, email").in("id", ids) : { data: [] };
  const who = (pid: string | null) => {
    const p = ((people ?? []) as { id: string; full_name: string | null; email: string }[]).find((x) => x.id === pid);
    return p ? p.full_name || p.email : pid ? "Staff member" : "The system";
  };
  const [st, stClass] = INCIDENT_STATUS[inc.status] ?? [inc.status, ""];
  const client = inc.car_clients?.preferred_name || inc.car_clients?.name || "Client";
  const now = Date.parse(new Date().toISOString());
  const overdue = inc.reportable && !inc.reported_to_regulator_at && inc.report_due_at && Date.parse(inc.report_due_at) < now;
  const step = (status: string, text: string, variant: "primary" | "outline" = "outline") => (
    <form action={setIncidentStatus}>
      <input type="hidden" name="id" value={inc.id} />
      <input type="hidden" name="status" value={status} />
      <Button size="sm" variant={variant}>
        {text}
      </Button>
    </form>
  );

  return (
    <div className="flex flex-col gap-4">
      <Link href="/incidents" className="text-sm text-muted hover:text-ink">
        ← All incidents
      </Link>
      <PageHeader eyebrow={inc.ref} title={`${client} · ${label(INCIDENT_KINDS, inc.kind)}`} />
      <div className="flex flex-wrap items-center gap-2">
        <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${stClass}`}>{st}</span>
        <span className={`text-sm font-medium ${inc.severity === "high" || inc.severity === "critical" ? "text-danger" : "text-muted"}`}>{label(INCIDENT_SEVERITY, inc.severity)}</span>
        {inc.reportable ? <span className="rounded-full bg-danger-soft px-2.5 py-0.5 text-xs font-semibold text-danger">NDIS reportable · {label(REPORTABLE, inc.reportable_category)}</span> : null}
        {canEdit ? (
          <span className="ml-auto flex flex-wrap gap-2">
            {inc.status === "new" ? step("acknowledged", "Acknowledge", "primary") : null}
            {inc.status === "new" || inc.status === "acknowledged" ? step("investigating", "Start investigating") : null}
            {inc.status === "closed" ? step("investigating", "Reopen") : null}
          </span>
        ) : null}
      </div>
      {inc.reportable && !inc.reported_to_regulator_at && inc.report_due_at && inc.status !== "closed" ? (
        <div className={`rounded-xl px-4 py-3 text-sm font-medium ${overdue ? "bg-danger text-white" : "bg-danger-soft text-danger"}`}>
          {overdue ? "The NDIS Commission report is overdue." : "Report to the NDIS Commission by"} {when(inc.report_due_at)}. Record the date and reference below once it&apos;s done.
        </div>
      ) : null}
      <div className="grid gap-4 lg:grid-cols-[1fr_22rem]">
        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="text-sm font-semibold text-ink">What happened</h2>
            <p className="whitespace-pre-wrap text-sm text-ink">{inc.summary}</p>
            {inc.immediate_action ? (
              <>
                <h3 className="text-xs font-semibold text-muted">Done straight away</h3>
                <p className="whitespace-pre-wrap text-sm text-ink">{inc.immediate_action}</p>
              </>
            ) : null}
            <dl className="grid gap-x-4 gap-y-1 text-sm sm:grid-cols-2">
              <dt className="text-muted">When it happened</dt>
              <dd>{when(inc.occurred_at)}</dd>
              <dt className="text-muted">Reported by</dt>
              <dd>
                {who(inc.reported_by)}, {when(inc.reported_at)}
                {inc.source === "shift_note" ? " (shift note)" : ""}
              </dd>
              {inc.acknowledged_at ? (
                <>
                  <dt className="text-muted">Acknowledged</dt>
                  <dd>
                    {who(inc.acknowledged_by)}, {when(inc.acknowledged_at)}
                  </dd>
                </>
              ) : null}
              {inc.closed_at && inc.status === "closed" ? (
                <>
                  <dt className="text-muted">Closed</dt>
                  <dd>
                    {who(inc.closed_by)}, {when(inc.closed_at)}
                  </dd>
                </>
              ) : null}
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
          {canEdit ? (
            <Card className="p-4">
              <h2 className="mb-3 text-sm font-semibold text-ink">{inc.status === "closed" ? "Details (closed, reopen to change)" : "Follow up"}</h2>
              <IncidentEditForm inc={inc} />
            </Card>
          ) : inc.outcome ? (
            <Card className="p-4">
              <h2 className="mb-2 text-sm font-semibold text-ink">Outcome</h2>
              <p className="whitespace-pre-wrap text-sm">{inc.outcome}</p>
            </Card>
          ) : null}
        </div>
        <Card className="flex flex-col gap-3 self-start p-4">
          <h2 className="text-sm font-semibold text-ink">Timeline</h2>
          {canEdit && inc.status !== "closed" ? <IncidentNoteForm id={inc.id} /> : null}
          <ol className="flex flex-col gap-3">
            {events.map((e) => (
              <li key={e.id} className={`border-l-2 pl-3 ${e.kind === "step" ? "border-brand" : "border-line"}`}>
                <p className="whitespace-pre-wrap text-sm text-ink">{e.body}</p>
                <p className="text-xs text-muted">
                  {who(e.actor)} · {when(e.created_at)}
                </p>
              </li>
            ))}
          </ol>
        </Card>
      </div>
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader } from "@/components/ui";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, INCIDENT_STATUS, label } from "@/lib/incidents";
import { ReportIncidentForm } from "./forms";

export const metadata: Metadata = { title: "Incidents" };

type Row = {
  id: string;
  ref: string;
  client_id: string;
  kind: string;
  severity: string;
  summary: string;
  status: string;
  source: string;
  occurred_at: string;
  reportable: boolean;
  report_due_at: string | null;
  reported_to_regulator_at: string | null;
  investigator_id: string | null;
  car_clients: { name: string; preferred_name: string | null } | null;
};

const when = (iso: string) => new Date(iso).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });

function dueWords(due: string, now: number) {
  const mins = Math.round((Date.parse(due) - now) / 60000);
  if (mins < 0) return [`Overdue by ${Math.abs(mins) < 120 ? `${Math.abs(mins)} min` : `${Math.round(Math.abs(mins) / 60)} h`}`, "bg-danger text-white"] as const;
  return [`Due in ${mins < 120 ? `${mins} min` : mins < 2880 ? `${Math.round(mins / 60)} h` : `${Math.round(mins / 1440)} days`}`, mins < 360 ? "bg-danger-soft text-danger" : "bg-warn-soft text-ink"] as const;
}

// cmeprojects (update 149): every incident this person may see (the database
// decides which), open ones first, with the NDIS Commission deadline.
export default async function IncidentsPage({ searchParams }: PageProps<"/incidents">) {
  const { profile } = await requireSession();
  const sp = await searchParams;
  const show = sp.show === "closed" ? "closed" : sp.show === "all" ? "all" : sp.show === "mine" ? "mine" : "open";
  const canView = await canDo("clients.incidents", "view");
  const canReport = await canDo("clients.incidents", "edit");
  const supabase = await createClient();
  let q = supabase
    .from("client_incidents")
    .select("id, ref, client_id, kind, severity, summary, status, source, occurred_at, reportable, report_due_at, reported_to_regulator_at, investigator_id, car_clients(name, preferred_name)")
    .order("occurred_at", { ascending: false })
    .limit(300);
  if (show === "open") q = q.neq("status", "closed");
  if (show === "closed") q = q.eq("status", "closed");
  if (show === "mine") q = q.eq("investigator_id", profile.id).neq("status", "closed");
  const { data, error } = await q;
  if (error?.code === "42P01" || error?.code === "PGRST205") notFound();
  const rows = (data ?? []) as unknown as Row[];
  // Actions given to me on open incidents.
  const { data: myActs } = await supabase.from("client_incident_actions").select("id, action, due_on, incident_id, client_incidents(ref, status)").eq("owner_id", profile.id).is("done_at", null).order("due_on");
  const myActions = ((myActs ?? []) as unknown as { id: string; action: string; due_on: string; incident_id: string; client_incidents: { ref: string; status: string } | null }[]).filter((a) => a.client_incidents?.status !== "closed");
  if (!canView && !rows.length && !canReport && !myActions.length && show !== "mine") notFound();
  const order = { new: 0, review: 1, investigating: 2, closed: 3 } as Record<string, number>;
  rows.sort((a, b) => (order[a.status] ?? 9) - (order[b.status] ?? 9) || Number(b.reportable) - Number(a.reportable));
  const now = Date.parse(new Date().toISOString());
  const clients = canReport ? (((await supabase.from("car_clients").select("id, name").eq("active", true).neq("status", "discharged").order("name")).data ?? []) as { id: string; name: string }[]) : [];
  const tab = (k: string, t: string) => (
    <Link key={k} href={k === "open" ? "/incidents" : `/incidents?show=${k}`} className={`rounded-full px-3 py-1 text-sm font-medium ${show === k ? "bg-ink text-white" : "border border-line text-ink hover:bg-surface"}`}>
      {t}
    </Link>
  );

  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Clients" title="Incidents" action={<Link href="/settings/clients" className="text-sm font-semibold text-brand underline">Back to clients</Link>} intro="Client incidents: reported, triaged, investigated and signed off by a manager. NDIS reportable incidents show when the Commission report is due. Staff and workplace incidents stay in the Workplace Incident Register." />
      {canReport ? (
        <details className="rounded-xl border border-line bg-white p-4">
          <summary className="cursor-pointer text-sm font-semibold text-ink">+ Report an incident</summary>
          <div className="mt-3">
            <ReportIncidentForm clients={clients.map((c) => [c.id, c.name])} />
          </div>
        </details>
      ) : null}
      {myActions.length ? (
        <Card className="flex flex-col gap-2 border-warn p-4">
          <h2 className="text-sm font-semibold text-ink">Your incident actions</h2>
          <ul className="flex flex-col gap-1 text-sm">
            {myActions.map((a) => {
              const today = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
              return (
                <li key={a.id}>
                  <Link href={`/incidents/${a.incident_id}`} className="flex flex-wrap gap-2 hover:underline">
                    <span className="text-muted">{a.client_incidents?.ref}</span>
                    <span className="flex-1 text-ink">{a.action}</span>
                    <span className={a.due_on < today ? "font-semibold text-danger" : "text-muted"}>Due {new Date(`${a.due_on}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short" })}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </Card>
      ) : null}
      <div className="flex flex-wrap gap-2">
        {tab("open", "Open")}
        {tab("mine", "I'm investigating")}
        {tab("closed", "Closed")}
        {tab("all", "All")}
      </div>
      {rows.length ? (
        <Card className="divide-y divide-line p-0">
          {rows.map((r) => {
            const [st, stClass] = INCIDENT_STATUS[r.status] ?? [r.status, ""];
            const due = r.reportable && !r.reported_to_regulator_at && r.report_due_at && r.status !== "closed" ? dueWords(r.report_due_at, now) : null;
            return (
              <Link key={r.id} href={`/incidents/${r.id}`} className="flex flex-col gap-1 px-4 py-3 hover:bg-surface sm:flex-row sm:items-center sm:gap-4">
                <div className="flex shrink-0 items-center gap-2 sm:w-44">
                  <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${stClass}`}>{st}</span>
                  <span className="text-xs text-muted">{r.ref}</span>
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-ink">
                    {r.car_clients?.preferred_name || r.car_clients?.name || "Client"} · {label(INCIDENT_KINDS, r.kind)}
                    <span className={`ml-2 text-xs font-medium ${r.severity === "critical" || r.severity === "high" ? "text-danger" : "text-muted"}`}>{label(INCIDENT_SEVERITY, r.severity)}</span>
                    {r.source === "shift_note" ? <span className="ml-2 text-xs text-muted">from a shift note</span> : null}
                  </p>
                  <p className="truncate text-sm text-muted">{r.summary}</p>
                </div>
                <div className="flex shrink-0 flex-wrap items-center gap-2 text-xs text-muted">
                  {r.reportable ? <span className="rounded-full bg-danger-soft px-2 py-0.5 font-semibold text-danger">Reportable</span> : null}
                  {due ? <span className={`rounded-full px-2 py-0.5 font-semibold ${due[1]}`}>{due[0]}</span> : null}
                  {r.reportable && r.reported_to_regulator_at ? <span className="rounded-full bg-good-soft px-2 py-0.5 font-semibold text-good">Reported</span> : null}
                  <span>{when(r.occurred_at)}</span>
                </div>
              </Link>
            );
          })}
        </Card>
      ) : (
        <EmptyState title={show === "open" ? "No open incidents" : "No incidents here"} text="Incidents reported on a client, or flagged in a shift note, show here." />
      )}
    </div>
  );
}

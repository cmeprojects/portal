// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";
import { NewClientButton, type Scheme } from "./care-forms";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader } from "@/components/ui";
import { ClientTeamsForm } from "./team-form";
import { ClientList, type ListClient } from "./client-list";
import { PLAN_MANAGEMENT } from "@/lib/client-sections";

export const metadata: Metadata = { title: "Clients" };

// "4 Angaston Way, Truganina VIC 3029" -> "Truganina".
function suburbOf(address: string) {
  const parts = address.split(",").map((p) => p.trim()).filter(Boolean);
  const part = parts.length > 1 ? parts[1] : "";
  return part.replace(/\b(NSW|VIC|QLD|SA|WA|TAS|NT|ACT)\b.*$/i, "").replace(/\d{4}$/, "").trim();
}

// The company's client list, used by Cars and by built features (for example Fluid intake).
export default async function ClientsPage({ searchParams }: PageProps<"/settings/clients">) {
  // Who sees Clients: the Access page (update 107); which clients, the database.
  await requireSession();
  if (!(await seesClientsFor())) notFound();
  const supabase = await createClient();
  // cmeprojects (Clients step 1): reference, status and preferred name (after live update 85).
  const care = await supabase.from("car_clients").select("id, name, reference, active, client_ref, status, preferred_name").order("active", { ascending: false }).order("name");
  const { data } = care.error ? await supabase.from("car_clients").select("id, name, reference, active").order("active", { ascending: false }).order("name") : care;
  const clients = (data ?? []) as { id: string; name: string; reference: string; active: boolean; client_ref?: string; status?: string; preferred_name?: string }[];
  const toCheck = clients.filter((c) => c.status === "pending");
  // Programs and schemes are on their own settings page (owner, 19 Nov 2026).
  const schemeRes = await supabase.from("client_schemes").select("key, label, person_word, review_label, change_review_label, review_lead_days, needs_dob").order("sort_order");
  const schemes = schemeRes.error ? [] : ((schemeRes.data ?? []) as Scheme[]);
  const { data: wordRow } = await supabase.from("app_settings").select("value").eq("key", "wording.client").maybeSingle();
  const orgWord = typeof wordRow?.value === "string" && wordRow.value ? wordRow.value : "Client";
  // Who can manage a new client (when this person may assign staff).
  const canAssign = await canDo("clients.assign", "edit");
  // cmeprojects (update 127): people who only view clients (support workers, team leaders) don't see Add.
  const canAddClient = await canDo("clients.list", "edit");
  // Who can manage a new client: care partners (Case Managers, by main or extra job title) and managers.
  const [{ data: staffRows }, { data: cmTitles }] = canAssign
    ? await Promise.all([
        supabase.from("profiles").select("*").eq("active", true).not("role", "in", "(new_starter,system_admin,external)").order("full_name"),
        supabase.from("job_titles").select("id").ilike("name", "case manager%"),
      ])
    : [{ data: null }, { data: [] }];
  const cmIds = new Set(((cmTitles ?? []) as { id: string }[]).map((t) => t.id));
  const staff = staffRows
    ? (staffRows as { id: string; full_name: string | null; email: string; role: string; job_title_id: string | null; extra_job_title_ids?: string[] }[])
        .filter((p) => p.role === "manager" || (p.job_title_id && cmIds.has(p.job_title_id)) || (p.extra_job_title_ids ?? []).some((t) => cmIds.has(t)))
        .map((p) => ({ id: p.id, name: `${p.full_name || p.email}${p.role === "manager" ? " (Manager)" : " (Case Manager)"}` }))
    : null;
  // cmeprojects: which team looks after each client (hidden before live update 54).
  const [{ data: teams }, { data: links, error: linkError }] = await Promise.all([
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("client_teams").select("client_id, team_id"),
  ]);
  const setup = (await searchParams).view === "setup";

  // cmeprojects (owner's client list concept): one row per client with what
  // this person may already see (each query is limited by the database; a
  // part they can't see comes back empty, and its column is hidden).
  const today = new Date().toISOString().slice(0, 10);
  const [detailsRes, assignRes, servicesRes, fundingRes, reviewsRes, agreementsRes, alertsRes] = setup
    ? []
    : await Promise.all([
        supabase.from("client_details").select("client_id, date_of_birth, ndis_number, email, phone, home_address"),
        supabase.from("client_assignments").select("client_id, user_id, assigned_as, starts_on, ends_on").is("ended_at", null).in("assigned_as", ["case_manager", "support_coordinator"]),
        supabase.from("client_services").select("id, client_id, label, status, client_programs(scheme)").neq("status", "ended"),
        supabase.from("client_funding").select("client_id, service_id, scheme, total_amount, used_amount, used_as_of, period_start, period_end, plan_management, classification").eq("status", "active"),
        supabase.from("client_reviews").select("client_id, scheme, kind, due_on").eq("status", "open").order("due_on"),
        supabase.from("client_agreements").select("client_id, service_id, scheme, status, ends_on").neq("status", "ended"),
        supabase.from("client_alerts").select("client_id").eq("active", true).neq("kind", "no_known_alerts"),
      ]);
  // cmeprojects: next shifts (two weeks) and recent shift notes (two weeks) for the side panel.
  // The database limits both to what this person may see; either is left out when it can't be read.
  const roster = setup ? null : await canDo("ops.roster", "view");
  const [shiftsRes, notesRes] = setup
    ? [null, null]
    : await Promise.all([
        roster ? supabase.from("shifts").select("id, client_id, worker_id, starts_at, ends_at, status").not("client_id", "is", null).neq("status", "cancelled").gte("starts_at", new Date().toISOString()).lte("starts_at", new Date(Date.parse(new Date().toISOString()) + 14 * 86_400_000).toISOString()).order("starts_at").limit(2000) : null,
        supabase.from("shift_service_records").select("shift_id, client_id, worker_id, delivered, client_wellbeing, concern, created_at").gte("created_at", new Date(Date.parse(new Date().toISOString()) - 14 * 86_400_000).toISOString()).order("created_at", { ascending: false }).limit(2000),
      ]);
  // update 147: follow-ups due from the communication log (for the bell; empty if not visible).
  const { data: followRows } = setup ? { data: [] } : await supabase.from("client_communications").select("client_id").is("follow_up_done_at", null).lte("follow_up_by", new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" }));
  // update 149: open client incidents (for the bell); before 149 runs, shift-note incidents.
  const openInc = setup ? null : await supabase.from("client_incidents").select("client_id").neq("status", "closed");
  const openIncidents = openInc && !openInc.error ? ((openInc.data ?? []) as { client_id: string }[]) : null;
  type UpShift = { id: string; client_id: string; worker_id: string | null; starts_at: string; ends_at: string; status: string };
  type RecentNote = { shift_id: string; worker_id: string; delivered: string; client_wellbeing: string; concern: boolean; created_at: string; client_id: string | null };
  const upShifts = shiftsRes && !shiftsRes.error ? ((shiftsRes.data ?? []) as UpShift[]) : null;
  const recentNotes = notesRes && !notesRes.error ? ((notesRes.data ?? []) as unknown as RecentNote[]) : null;
  const schemeLabel = (k: string) => schemes.find((x) => x.key === k)?.label ?? k;
  const staffName = new Map<string, string>();
  {
    const ids = [...new Set([...(upShifts ?? []).map((x) => x.worker_id), ...(recentNotes ?? []).map((x) => x.worker_id)].filter((v): v is string => !!v))];
    if (ids.length) {
      const { data: people } = await supabase.from("profiles").select("id, full_name, email").in("id", ids);
      for (const p of (people ?? []) as { id: string; full_name: string | null; email: string }[]) staffName.set(p.id, p.full_name || p.email);
    }
  }
  const when = (iso: string) => new Date(iso).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
  if (assignRes?.data?.length) {
    const ids = [...new Set((assignRes.data as { user_id: string }[]).map((a) => a.user_id))];
    const { data: people } = await supabase.from("profiles").select("id, full_name, email").in("id", ids);
    for (const p of (people ?? []) as { id: string; full_name: string | null; email: string }[]) staffName.set(p.id, p.full_name || p.email);
  }
  const teamName = new Map(((teams ?? []) as { id: string; name: string }[]).map((t) => [t.id, t.name]));
  type Svc = { id: string; client_id: string; label: string; client_programs: { scheme: string } | null };
  const services = ((servicesRes?.data ?? []) as unknown as Svc[]);
  const svcLabel = new Map(services.map((v) => [v.id, v.label]));
  const ageOf = (dob: string | null) => {
    if (!dob) return null;
    const [y, m, d] = dob.split("-").map(Number);
    const [ty, tm, td] = today.split("-").map(Number);
    return ty - y - (tm < m || (tm === m && td < d) ? 1 : 0);
  };
  const details = new Map(((detailsRes?.data ?? []) as { client_id: string; date_of_birth: string | null; ndis_number: string | null; email: string | null; phone: string | null; home_address: string | null }[]).map((d) => [d.client_id, d]));
  const listClients: ListClient[] = clients.map((c) => {
    const mine = services.filter((v) => v.client_id === c.id);
    return {
      id: c.id,
      name: c.name,
      ref: c.client_ref ?? "",
      reference: c.reference ?? "",
      preferredName: c.preferred_name ?? "",
      status: c.status ?? (c.active ? "active" : "discharged"),
      active: c.active,
      age: ageOf(details.get(c.id)?.date_of_birth ?? null),
      ndisNumber: details.get(c.id)?.ndis_number ?? "",
      email: details.get(c.id)?.email ?? "",
      phone: details.get(c.id)?.phone ?? "",
      // The suburb only (the part before the state or postcode), not the full address.
      suburb: suburbOf(details.get(c.id)?.home_address ?? ""),
      schemes: [...new Set(mine.map((v) => v.client_programs?.scheme ?? "other"))],
      services: mine.map((v) => v.label),
      managers: ((assignRes?.data ?? []) as { client_id: string; user_id: string; assigned_as: string; starts_on: string; ends_on: string | null }[])
        .filter((a) => a.client_id === c.id && a.starts_on <= today && (!a.ends_on || a.ends_on >= today))
        .map((a) => ({ name: staffName.get(a.user_id) ?? "Staff member", as: a.assigned_as === "support_coordinator" ? "support coordinator" : "care manager" })),
      teams: ((links ?? []) as { client_id: string; team_id: string }[]).filter((l) => l.client_id === c.id).map((l) => teamName.get(l.team_id) ?? "").filter(Boolean),
      budgets: ((fundingRes?.data ?? []) as { client_id: string; service_id: string; scheme: string; total_amount: number; used_amount: number; used_as_of: string | null; period_start: string; period_end: string; plan_management: string | null; classification: number | null }[])
        .filter((f) => f.client_id === c.id)
        .map((f) => ({
          scheme: f.scheme,
          schemeLabel: schemeLabel(f.scheme),
          label: svcLabel.get(f.service_id) ?? "Service",
          total: Number(f.total_amount),
          used: Number(f.used_amount),
          usedAsOf: f.used_as_of,
          periodStart: f.period_start,
          periodEnd: f.period_end,
          management: f.plan_management ? (PLAN_MANAGEMENT.find(([k]) => k === f.plan_management)?.[1] ?? "") : f.classification ? `Classification ${f.classification}` : "",
        })),
      reviews: ((reviewsRes?.data ?? []) as { client_id: string; scheme: string; kind: string; due_on: string }[])
        .filter((r) => r.client_id === c.id)
        .map((r) => {
          const w = schemes.find((x) => x.key === r.scheme);
          return { label: w ? (r.kind === "scheduled" ? w.review_label : w.change_review_label) : "Review", due: r.due_on, overdue: r.due_on < today };
        }),
      agreements: ((agreementsRes?.data ?? []) as { client_id: string; service_id: string; scheme: string; status: string; ends_on: string | null }[])
        .filter((a) => a.client_id === c.id)
        .map((a) => ({ label: `${svcLabel.get(a.service_id) ?? "Service"} (${schemeLabel(a.scheme)})`, status: a.status === "sent" ? "sent for signing" : a.status, ends: a.ends_on })),
      alerts: ((alertsRes?.data ?? []) as { client_id: string }[]).filter((a) => a.client_id === c.id).length,
      shifts: upShifts
        ? upShifts
            .filter((x) => x.client_id === c.id)
            .slice(0, 5)
            .map((x) => ({ id: x.id, when: `${when(x.starts_at)} – ${new Date(x.ends_at).toLocaleTimeString("en-AU", { timeZone: "Australia/Sydney", hour: "numeric", minute: "2-digit" })}`, worker: x.worker_id ? (staffName.get(x.worker_id) ?? "Staff member") : "", draft: x.status === "draft", day: new Date(x.starts_at).toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" }) }))
        : null,
      // Open incidents (update 149), or before it runs, shift-note incidents in the last 14 days (for the bell).
      incidents: openIncidents ? openIncidents.filter((n) => n.client_id === c.id).length : (recentNotes ?? []).filter((n) => n.client_id === c.id && n.concern).length,
      followUps: ((followRows ?? []) as { client_id: string }[]).filter((f) => f.client_id === c.id).length,
      notes: recentNotes
        ? recentNotes
            .filter((n) => n.client_id === c.id)
            .slice(0, 5)
            .map((n) => ({ when: when(n.created_at), worker: staffName.get(n.worker_id) ?? "Staff member", wellbeing: n.client_wellbeing, concern: n.concern, text: n.delivered }))
        : null,
    };
  });
  const showContact = !detailsRes?.error && listClients.some((c) => c.email || c.suburb);
  const showNdis = !detailsRes?.error && listClients.some((c) => c.ndisNumber);
  const showBudget = !fundingRes?.error && (await canDo("clients.funding", "view"));
  return (
    <>
      <PageHeader
        title={orgWord.endsWith("s") ? orgWord : `${orgWord}s`}
        intro="The people you support. Click a name to see a summary; open the full profile for everything else."
        action={
          canAddClient && !setup ? <NewClientButton staff={staff} word={orgWord} schemes={schemes.map((x) => [x.key, x.label] as [string, string])} /> : undefined
        }
      />
      <nav className="flex gap-1 border-b border-line text-sm" aria-label="Client pages">
        <Link href="/settings/clients" className={`-mb-px border-b-2 px-3 py-2 font-semibold ${setup ? "border-transparent text-muted hover:text-ink" : "border-brand"}`}>
          List
        </Link>
        <Link href="/settings/clients?view=setup" className={`-mb-px border-b-2 px-3 py-2 font-semibold ${setup ? "border-brand" : "border-transparent text-muted hover:text-ink"}`}>
          Teams
        </Link>
      </nav>
      {setup ? null : (
        <>

          {toCheck.length ? (
            <Notice tone="info">
              {toCheck.length === 1 ? `1 ${orgWord.toLowerCase()} is` : `${toCheck.length} ${(orgWord.endsWith("s") ? orgWord : `${orgWord}s`).toLowerCase()} are`} <strong>to check</strong>: {toCheck.slice(0, 5).map((c) => c.name).join(", ")}
              {toCheck.length > 5 ? " and more" : ""}. Open them, check their details and set the status (for example Active).
            </Notice>
          ) : null}
          <ClientList clients={listClients} word={orgWord} schemes={schemes.map((x) => [x.key, x.label])} showNdis={showNdis} showBudget={showBudget} showContact={showContact} />
        </>
      )}
      {setup && !linkError && clients.some((c) => c.active) ? (
        <Card className="p-4">
          <h2 className="heading-sm">Which team looks after each client</h2>
          <p className="mb-2 text-sm text-muted">Team leaders see their team&apos;s clients, with their open tasks, on their dashboard.</p>
          {teams?.length ? (
            <div className="divide-y divide-line">
              {clients
                .filter((c) => c.active)
                .map((c) => (
                  <ClientTeamsForm key={c.id} clientId={c.id} name={c.name} teams={teams} chosen={(links ?? []).filter((l) => l.client_id === c.id).map((l) => l.team_id)} />
                ))}
            </div>
          ) : (
            <p className="text-sm text-muted">Add teams on the Teams page first.</p>
          )}
        </Card>
      ) : null}

    </>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import { canBill } from "@/lib/billing-access";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { mondayOf, sydneyParts } from "@/lib/sydney-time";
import { CancellationForm, TermsRow, type Terms } from "../settings/clients/[id]/billing-panels";
import { BudgetsTab, ExceptionsTab, ExportTab, LinesTab } from "./tabs";

export const metadata: Metadata = { title: "Billing" };

function Stat({ label, value, tone }: { label: string; value: string; tone: string }) {
  return (
    <Card className={`border-l-4 p-4 ${tone}`}>
      <p className="text-xs text-muted">{label}</p>
      <p className="font-display text-2xl font-semibold">{value}</p>
    </Card>
  );
}

// cmeprojects (update 161, owner 22 Nov 2026): the Billing module. Its own main
// menu item, separate from the client page and from Funding: set-up status,
// approvals (billing terms, cancellation charges) and exceptions, each linking
// to the client's existing pages. Billing lines and exports arrive in Phase 4B.
// What each person sees follows their Billing reach (the database decides).
const TABS: [string, string][] = [["overview", "Dashboard"], ["lines", "Billing lines"], ["exceptions", "Exceptions"], ["budgets", "Budgets and ledger"], ["export", "Export"]];

export default async function BillingPage({ searchParams }: PageProps<"/billing">) {
  await requireSession();
  if (!(await canBill("view"))) notFound();
  const sp = await searchParams;
  const str = (k: string) => (typeof sp[k] === "string" ? (sp[k] as string) : "");
  const tab = TABS.some(([k]) => k === str("tab")) ? str("tab") : "overview";
  return (
    <div className="flex flex-col gap-4">
      <PageHeader
        title="Billing"
        intro="Billing from delivered services, separate from funding: lines to review and approve, exceptions, Support at Home budgets and the funding ledger, and exports. Each item links to the client's own records."
        action={<Link href="/settings?open=system.settings.billing" className={buttonClass("outline")}>Billing set-up</Link>}
      />
      <nav aria-label="Billing" className="flex flex-wrap gap-1.5">
        {TABS.map(([k, l]) => (
          <Link key={k} href={`/billing?tab=${k}`} aria-current={tab === k ? "page" : undefined}
            className={`rounded-full px-3 py-1 text-sm font-semibold ring-1 ${tab === k ? "bg-brand text-brand-fg ring-brand" : "bg-surface text-muted ring-line hover:text-ink"}`}>{l}</Link>
        ))}
      </nav>
      {tab === "lines" ? <LinesTab sp={sp} /> : tab === "exceptions" ? <ExceptionsTab sp={sp} /> : tab === "budgets" ? <BudgetsTab /> : tab === "export" ? <ExportTab /> : <Overview />}
    </div>
  );
}

async function Overview() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const [rulesRes, checksRes, listsRes, termsRes, svcRes, cancRes, cdRes, canApprove, canPrepare] = await Promise.all([
    supabase.from("billing_scheme_rules").select("scheme, status"),
    supabase.from("billing_rule_checks").select("status"),
    supabase.from("price_list_versions").select("price_list_id, status"),
    supabase.from("client_service_terms").select("*").in("status", ["pending_review", "changes_required", "approved"]).order("submitted_at"),
    supabase.from("client_services").select("id, client_id, label, status, end_date, program_id").neq("status", "ended"),
    supabase.from("shifts").select("id, client_id, service_id, starts_at").eq("status", "cancelled").not("client_id", "is", null).order("starts_at", { ascending: false }).limit(300),
    supabase.from("shift_cancellations").select("shift_id, notified_at, cancelled_by, reason, reasonable_grounds, charge, charge_note, decided_by, decided_at"),
    canBill("approve"),
    canBill("prepare"),
  ]);
  if (rulesRes.error) return <Card className="p-5 text-sm text-muted">Billing isn&apos;t set up yet (update 161).</Card>;

  type T = Omit<Terms, "trail" | "mine"> & { client_id: string; service_id: string; created_by: string | null; submitted_by: string | null; submitted_at: string | null };
  const terms = (termsRes.data ?? []) as T[];
  const services = (svcRes.data ?? []) as { id: string; client_id: string; label: string; status: string; end_date: string | null; program_id: string }[];
  const clientIds = [...new Set([...services.map((s) => s.client_id), ...terms.map((t) => t.client_id), ...((cancRes.data ?? []) as { client_id: string }[]).map((c) => c.client_id)])];
  const peopleIds = [...new Set(terms.flatMap((t) => [t.created_by, t.submitted_by]).filter(Boolean))] as string[];
  const [{ data: clientRows }, { data: names }, { data: enrolRows }, { data: fundRows }, { data: agrRows }, { data: plRows }, { data: progRows }] = await Promise.all([
    clientIds.length ? supabase.from("car_clients").select("id, name").in("id", clientIds) : Promise.resolve({ data: [] }),
    peopleIds.length ? supabase.from("profiles").select("id, full_name, email").in("id", peopleIds) : Promise.resolve({ data: [] }),
    terms.length ? supabase.from("client_enrolments").select("id, scheme").in("id", terms.map((t) => t.enrolment_id)) : Promise.resolve({ data: [] }),
    terms.some((t) => t.funding_id) ? supabase.from("client_funding").select("id, period_start, period_end, total_amount").in("id", terms.map((t) => t.funding_id).filter(Boolean) as string[]) : Promise.resolve({ data: [] }),
    terms.some((t) => t.agreement_id) ? supabase.from("client_agreements").select("id, status, starts_on").in("id", terms.map((t) => t.agreement_id).filter(Boolean) as string[]) : Promise.resolve({ data: [] }),
    supabase.from("price_lists").select("id, name"),
    supabase.from("client_programs").select("id, name, scheme"),
  ]);
  const clientName = new Map(((clientRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const who = (id: string | null) => ((names ?? []) as { id: string; full_name: string | null; email: string }[]).find((p) => p.id === id)?.full_name ?? "someone";
  const serviceName = new Map(services.map((s) => [s.id, s.label]));
  const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
  const aud = (n: number) => Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" });
  const programScheme = new Map(((progRows ?? []) as { id: string; scheme: string }[]).map((p) => [p.id, p.scheme]));

  // Set-up status.
  const rules = (rulesRes.data ?? []) as { scheme: string; status: string }[];
  const checks = (checksRes.data ?? []) as { status: string }[];
  const published = new Set(((listsRes.data ?? []) as { price_list_id: string; status: string }[]).filter((v) => v.status === "published").map((v) => v.price_list_id)).size;
  // Approvals.
  const pending = terms.filter((t) => t.status === "pending_review" || t.status === "changes_required");
  // Exceptions: open services with no approved terms; cancelled shifts with no charge decision.
  const approvedFor = new Set(terms.filter((t) => t.status === "approved").map((t) => t.service_id));
  const noTerms = services.filter((s) => !approvedFor.has(s.id));
  const details = new Map(((cdRes.data ?? []) as { shift_id: string; notified_at: string; cancelled_by: string; reason: string; reasonable_grounds: boolean | null; charge: string; charge_note: string; decided_by: string | null; decided_at: string | null }[]).map((c) => [c.shift_id, c]));
  const cancellations = ((cancRes.data ?? []) as { id: string; client_id: string; service_id: string | null; starts_at: string }[]).filter((c) => !details.get(c.id) || details.get(c.id)?.charge === "undecided");
  const opt = (rows: unknown, f: (r: never) => [string, string]) => ((rows ?? []) as never[]).map(f);
  const enrolOpts = opt(enrolRows, (e: { id: string; scheme: string }) => [e.id, e.scheme === "support_at_home" ? "Support at Home" : e.scheme.toUpperCase()]);
  const fundOpts = opt(fundRows, (f: { id: string; period_start: string; period_end: string; total_amount: number }) => [f.id, `${dmy(f.period_start)} to ${dmy(f.period_end)}, ${aud(f.total_amount)}`]);
  const agrOpts = opt(agrRows, (a: { id: string; status: string; starts_on: string }) => [a.id, `${a.status} from ${dmy(a.starts_on)}`]);
  const plOpts = opt(plRows, (p: { id: string; name: string }) => [p.id, p.name]);

  return (
    <div className="flex flex-col gap-4">
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="Schemes with confirmed rules" value={`${rules.filter((r) => r.status === "confirmed").length} of ${rules.length}`} tone="border-l-brand" />
        <Stat label="Regulatory figures verified" value={`${checks.filter((c) => c.status === "verified").length} of ${checks.length}`} tone="border-l-brand" />
        <Stat label="Billing terms waiting for review" value={String(pending.filter((t) => t.status === "pending_review").length)} tone="border-l-warn" />
        <Stat label="Open services without approved terms" value={String(noTerms.length)} tone="border-l-danger" />
      </div>
      {rules.some((r) => r.status !== "confirmed") ? (
        <p className="rounded-lg bg-warn-soft px-4 py-2 text-sm">
          Billing stays off for {rules.filter((r) => r.status !== "confirmed").length} scheme(s) until their rules are confirmed in{" "}
          <Link href="/settings?open=system.settings.billing" className="font-semibold underline">Billing set-up</Link>. {published} price list(s) published.
        </p>
      ) : null}

      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Approvals: billing terms</h2>
          <p className="text-sm text-muted">Terms sent for review, or sent back for changes. Approve only terms you didn&apos;t make or send.</p>
        </div>
        {pending.length ? (
          <ul className="flex flex-col gap-3">
            {pending.map((t) => (
              <li key={t.id} className="flex flex-col gap-1">
                <p className="text-sm font-semibold">
                  <Link href={`/settings/clients/${t.client_id}?tab=services#services`} className="text-brand underline">{clientName.get(t.client_id) ?? "Client"}</Link>
                  {" · "}{serviceName.get(t.service_id) ?? "Service"}
                  {t.funding_id ? <> · <Link href={`/settings/clients/${t.client_id}?tab=funding`} className="text-brand underline">funding record</Link></> : null}
                  {t.agreement_id ? <> · <Link href={`/settings/clients/${t.client_id}?tab=agreements`} className="text-brand underline">agreement</Link></> : null}
                </p>
                <TermsRow
                  t={{ ...t, mine: t.created_by === profile.id || t.submitted_by === profile.id, trail: [t.created_by ? `Made by ${who(t.created_by)}` : "", t.submitted_by ? `sent for review by ${who(t.submitted_by)} ${dmy(t.submitted_at)}` : ""].filter(Boolean).join(" · ") }}
                  clientId={t.client_id} serviceId={t.service_id} scheme={programScheme.get(services.find((s) => s.id === t.service_id)?.program_id ?? "") ?? "other"}
                  enrolments={enrolOpts} funding={fundOpts} agreements={agrOpts} priceLists={plOpts} supportLines={[]}
                  canPrepare={false} canApprove={canApprove}
                />
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">Nothing waiting.</p>}
        {!canPrepare && !canApprove ? <p className="text-xs text-muted">You can view billing but not prepare or approve it.</p> : null}
      </Card>

      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Approvals: cancellation charges</h2>
          <p className="text-sm text-muted">Cancelled client shifts with no charge decision yet. Record the details, then decide with a reason.</p>
        </div>
        {cancellations.length ? (
          <ul className="flex flex-col gap-2">
            {cancellations.slice(0, 50).map((c) => {
              const d = details.get(c.id);
              const p = sydneyParts(c.starts_at);
              return (
                <li key={c.id} className="rounded-md border border-line px-3 py-2 text-sm">
                  <p className="font-semibold">
                    <Link href={`/settings/clients/${c.client_id}?tab=services#services`} className="text-brand underline">{clientName.get(c.client_id) ?? "Client"}</Link>
                    {" · "}{c.service_id ? serviceName.get(c.service_id) ?? "Service" : "No service"} · {dmy(p.date)} {p.time}
                    {" · "}<Link href={`/roster/timesheets?w=${mondayOf(p.date)}`} className="text-xs text-brand underline">Timesheets week</Link>
                  </p>
                  {canPrepare || canApprove ? (
                    <details className="mt-1">
                      <summary className="cursor-pointer text-xs font-semibold text-brand">{d ? `Details recorded (${d.reason}); charge not decided` : "Record details and decide"}</summary>
                      <div className="mt-2">
                        <CancellationForm shiftId={c.id} canDecide={canApprove} c={d ? { ...d, decided: "" } : null} />
                      </div>
                    </details>
                  ) : null}
                </li>
              );
            })}
          </ul>
        ) : <p className="text-sm text-muted">Nothing waiting.</p>}
      </Card>

      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Exceptions: services that can&apos;t be billed</h2>
          <p className="text-sm text-muted">Open approved services with no approved billing terms. Add terms on the client&apos;s Services tab.</p>
        </div>
        {noTerms.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {noTerms.slice(0, 100).map((s) => (
              <li key={s.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <Link href={`/settings/clients/${s.client_id}?tab=services#services`} className="min-w-40 flex-1 font-semibold text-brand underline">{clientName.get(s.client_id) ?? "Client"}</Link>
                <span>{s.label}</span>
                <span className="text-xs text-muted">{programScheme.get(s.program_id) === "support_at_home" ? "Support at Home" : (programScheme.get(s.program_id) ?? "").toUpperCase()}</span>
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">Every open service has approved billing terms.</p>}
        {noTerms.length > 100 ? <p className="text-xs text-muted">Showing the first 100 of {noTerms.length}.</p> : null}
      </Card>

    </div>
  );
}

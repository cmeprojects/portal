// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui";
import { addDays, sydneyToday } from "@/lib/sydney-time";
import { EndForm, FeeReductionForm, LinkPayerForm, PayerForm, PlanDetailsForm, PrepareClaimForm, PrepareInvoicesForm, StatementForm, ZoneForm } from "./claim-forms";

// cmeprojects (update 163): the Claims, Invoices and statements, and Client
// billing details tabs. What each person sees follows their Billing reach; the
// database decides every step and every amount.
type SP = Record<string, string | string[] | undefined>;
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));
export const CLAIM_STATUS: Record<string, string> = { draft: "Draft", approved: "Approved, not submitted", submitted: "Submitted", acknowledged: "Acknowledged", cancelled: "Cancelled" };
export const INVOICE_STATUS: Record<string, string> = { draft: "Draft", approved: "Approved", issued: "Issued", sent: "Sent", cancelled: "Cancelled" };
export const INVOICE_KIND: Record<string, string> = { sah_contribution: "Support at Home contribution", private: "Private", ndis_plan_managed: "NDIS plan-managed", ndis_self_managed: "NDIS self-managed" };
const PROGRAM: Record<string, string> = { support_at_home: "Support at Home", ndis: "NDIS (agency-managed)" };
const monthStart = (d: string) => `${d.slice(0, 7)}-01`;
const lastMonthEnd = (d: string) => addDays(monthStart(d), -1);

async function readiness() {
  const supabase = await createClient();
  const out: { program: string; problem: string | null }[] = [];
  for (const p of ["support_at_home", "ndis"]) {
    const { data } = await supabase.rpc("billing_scheme_ready", { p_scheme: p });
    out.push({ program: p, problem: (data as string | null) ?? null });
  }
  const { data: tpls } = await supabase.from("claim_templates").select("program, status, review_by").eq("status", "verified");
  const today = sydneyToday();
  return out.map((r) => ({ ...r, problem: r.problem ?? (((tpls ?? []) as { program: string; review_by: string | null }[]).some((t) => t.program === r.program && (!t.review_by || t.review_by >= today)) ? null : "Its official claim template isn't uploaded and verified (Billing set-up).") }));
}

export async function ClaimsTab() {
  const supabase = await createClient();
  const today = sydneyToday();
  const [{ data, error }, canPrepare, ready] = await Promise.all([
    supabase.from("claims").select("id, program, kind, status, period_from, period_to, item_count, total_claimed, total_expected, excluded, prepared_at").order("prepared_at", { ascending: false }).limit(200),
    canBill("claim_prepare"),
    readiness(),
  ]);
  if (error) return <Card className="p-5 text-sm text-muted">Claims aren&apos;t set up yet (update 163).</Card>;
  const claims = (data ?? []) as { id: string; program: string; kind: string; status: string; period_from: string; period_to: string; item_count: number; total_claimed: number; total_expected: number; excluded: unknown[]; prepared_at: string }[];
  const { data: subs } = claims.length ? await supabase.from("claim_submissions").select("claim_id, submitted_at, external_reference").in("claim_id", claims.map((c) => c.id)) : { data: [] };
  const sub = new Map(((subs ?? []) as { claim_id: string; submitted_at: string; external_reference: string }[]).map((s) => [s.claim_id, s]));
  const awaiting = claims.filter((c) => c.status === "approved");
  return (
    <div className="flex flex-col gap-4">
      <Card className="flex flex-col gap-2 p-4">
        <h2 className="heading-sm">Ready to claim?</h2>
        <ul className="flex flex-col gap-1 text-sm">
          {ready.map((r) => (
            <li key={r.program}><span className="font-semibold">{PROGRAM[r.program]}:</span> {r.problem ? <span className="text-danger">{r.problem}</span> : <span className="text-success">ready</span>}</li>
          ))}
        </ul>
        <p className="text-xs text-muted">Claims are uploaded by a person in the government portal (Aged Care Provider Portal for Support at Home, my NDIS provider portal for NDIS). The portal never sends claims itself. CHSP and Other stay blocked until their rules are confirmed.</p>
      </Card>
      {awaiting.length ? (
        <p className="rounded-lg bg-warn-soft px-4 py-2 text-sm">{awaiting.length} approved claim(s) not recorded as submitted yet. Upload the file in the government portal, then record the submission.</p>
      ) : null}
      {canPrepare ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Prepare a claim</h2>
          <PrepareClaimForm from={monthStart(lastMonthEnd(today))} to={lastMonthEnd(today)} programs={ready.map((r) => [r.program, PROGRAM[r.program]])} />
        </Card>
      ) : null}
      <Card className="flex flex-col gap-2 p-4">
        <h2 className="heading-sm">Claims</h2>
        {claims.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="text-left text-xs text-muted"><tr><th className="py-1">Period</th><th>Program</th><th>Status</th><th className="text-right">Lines</th><th className="text-right">Claimed</th><th className="text-right">Expected</th><th>Submitted</th></tr></thead>
              <tbody className="divide-y divide-line">
                {claims.map((c) => (
                  <tr key={c.id}>
                    <td className="py-1.5"><Link href={`/billing/claims/${c.id}`} className="font-semibold text-brand underline">{dmy(c.period_from)} to {dmy(c.period_to)}</Link></td>
                    <td>{PROGRAM[c.program] ?? c.program}{c.kind !== "original" ? ` (${c.kind})` : ""}</td>
                    <td>{CLAIM_STATUS[c.status] ?? c.status}</td>
                    <td className="text-right">{c.item_count}{c.excluded?.length ? <span className="text-xs text-warn"> +{c.excluded.length} excluded</span> : null}</td>
                    <td className="text-right">{aud(c.total_claimed)}</td>
                    <td className="text-right">{aud(c.total_expected)}</td>
                    <td className="text-xs">{sub.get(c.id) ? `${dmy(sub.get(c.id)?.submitted_at)} · ${sub.get(c.id)?.external_reference}` : ""}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No claims yet.</p>}
      </Card>
    </div>
  );
}

export async function InvoicesTab({ sp }: { sp: SP }) {
  const supabase = await createClient();
  const today = sydneyToday();
  const show = typeof sp.show === "string" && ["open", "all"].includes(sp.show) ? sp.show : "open";
  let q = supabase.from("invoices").select("id, number, kind, client_id, payer_id, status, period_from, period_to, total, issue_date, due_date, tax_invoice").order("prepared_at", { ascending: false }).limit(300);
  if (show === "open") q = q.in("status", ["draft", "approved", "issued"]);
  const [{ data, error }, canPrepare, canIssue, { data: stRows }, { data: enrolRows }, { data: biz }] = await Promise.all([
    q, canBill("invoice_prepare"), canBill("invoice_issue"),
    supabase.from("client_statements").select("id, client_id, month, issued_at, pdf_checksum").order("month", { ascending: false }).limit(100),
    supabase.from("client_enrolments").select("id, client_id, status").eq("scheme", "support_at_home").neq("status", "ended"),
    supabase.from("business_current").select("version, gst_verified, gst_registered").maybeSingle(),
  ]);
  if (error) return <Card className="p-5 text-sm text-muted">Invoices aren&apos;t set up yet (update 163).</Card>;
  const invoices = (data ?? []) as { id: string; number: string | null; kind: string; client_id: string; payer_id: string; status: string; period_from: string; period_to: string; total: number; issue_date: string | null; due_date: string | null; tax_invoice: boolean }[];
  const statements = (stRows ?? []) as { id: string; client_id: string; month: string; issued_at: string; pdf_checksum: string | null }[];
  const enrols = (enrolRows ?? []) as { id: string; client_id: string }[];
  const cIds = [...new Set([...invoices.map((i) => i.client_id), ...statements.map((s) => s.client_id), ...enrols.map((e) => e.client_id)])];
  const pIds = [...new Set(invoices.map((i) => i.payer_id))];
  const [{ data: cRows }, { data: pRows }] = await Promise.all([
    cIds.length ? supabase.from("car_clients").select("id, name").in("id", cIds) : Promise.resolve({ data: [] }),
    pIds.length ? supabase.from("billing_payers").select("id, name").in("id", pIds) : Promise.resolve({ data: [] }),
  ]);
  const cName = new Map(((cRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const pName = new Map(((pRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const b = biz as { version: number; gst_verified: boolean; gst_registered: boolean } | null;
  const overdue = invoices.filter((i) => i.status === "issued" && i.due_date && i.due_date < today);
  return (
    <div className="flex flex-col gap-4">
      {!b ? <p className="rounded-lg bg-warn-soft px-4 py-2 text-sm">Enter the business details in <Link href="/settings/billing#business" className="font-semibold underline">Billing set-up</Link> before invoices can be issued.</p>
        : !b.gst_verified ? <p className="rounded-lg bg-warn-soft px-4 py-2 text-sm">The GST position isn&apos;t verified by your accountant yet (<Link href="/settings/billing#business" className="font-semibold underline">Business details</Link>). Invoices can be prepared and approved but not issued.</p> : null}
      {overdue.length ? <p className="rounded-lg bg-danger-soft px-4 py-2 text-sm">{overdue.length} issued invoice(s) past their due date and not marked sent. Payments are recorded in a later stage (5B).</p> : null}
      {canPrepare ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Prepare invoices</h2>
          <PrepareInvoicesForm from={monthStart(lastMonthEnd(today))} to={lastMonthEnd(today)} />
        </Card>
      ) : null}
      <Card className="flex flex-col gap-2 p-4">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="heading-sm flex-1">Invoices</h2>
          <Link href="/billing?tab=invoices&show=open" className={`text-xs ${show === "open" ? "font-semibold" : "text-brand underline"}`}>Open</Link>
          <Link href="/billing?tab=invoices&show=all" className={`text-xs ${show === "all" ? "font-semibold" : "text-brand underline"}`}>All</Link>
        </div>
        {invoices.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="text-left text-xs text-muted"><tr><th className="py-1">Number</th><th>Client</th><th>Kind</th><th>Payer</th><th>Status</th><th className="text-right">Total</th><th>Due</th></tr></thead>
              <tbody className="divide-y divide-line">
                {invoices.map((i) => (
                  <tr key={i.id}>
                    <td className="py-1.5"><Link href={`/billing/invoices/${i.id}`} className="font-semibold text-brand underline">{i.number ?? `Draft ${dmy(i.period_from)}–${dmy(i.period_to)}`}</Link></td>
                    <td>{cName.get(i.client_id) ?? "Client"}</td>
                    <td className="text-xs">{INVOICE_KIND[i.kind]}</td>
                    <td className="text-xs">{pName.get(i.payer_id) ?? ""}</td>
                    <td>{INVOICE_STATUS[i.status]}</td>
                    <td className="text-right">{aud(i.total)}</td>
                    <td className={`text-xs ${i.status === "issued" && i.due_date && i.due_date < today ? "text-danger" : ""}`}>{dmy(i.due_date)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No invoices{show === "open" ? " open" : ""}.</p>}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Monthly statements (Support at Home)</h2>
          <p className="text-sm text-muted">Issued once a month has ended: the quarter&apos;s budget, services and contributions that month, and what&apos;s available. A statement never changes.</p>
        </div>
        {canIssue && enrols.length ? <StatementForm clients={enrols.map((e) => ({ id: e.client_id, name: cName.get(e.client_id) ?? "Client", enrolment: e.id }))} /> : null}
        {statements.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {statements.map((s) => (
              <li key={s.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <span className="min-w-40 flex-1 font-semibold">{cName.get(s.client_id) ?? "Client"}</span>
                <span>{s.month.slice(0, 7).split("-").reverse().join("/")}</span>
                {s.pdf_checksum ? <a href={`/billing/statements/${s.id}/pdf`} className="text-xs font-semibold text-brand underline">PDF</a> : <span className="text-xs text-muted">No PDF</span>}
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No statements yet.</p>}
      </Card>
    </div>
  );
}

export async function ClientBillingTab() {
  const supabase = await createClient();
  const [{ data: payers, error }, { data: links }, { data: fees }, { data: zones }, { data: plans }, canPrepare] = await Promise.all([
    supabase.from("billing_payers").select("id, kind, client_id, name, email, phone, active").order("name"),
    supabase.from("client_payer_links").select("id, client_id, role, funding_id, payer_id, starts_on, ends_on").order("starts_on", { ascending: false }),
    supabase.from("client_fee_reductions").select("id, client_id, starts_on, ends_on, source").order("starts_on", { ascending: false }),
    supabase.from("client_location_pricing").select("location_id, client_id, ndis_zone, mmm, source"),
    supabase.from("ndis_plan_details").select("funding_id, client_id, my_provider, recorded_on"),
    canBill("prepare"),
  ]);
  if (error) return <Card className="p-5 text-sm text-muted">Client billing details aren&apos;t set up yet (update 163).</Card>;
  const [{ data: clients }, { data: funding }, { data: locs }, { data: enrols }] = await Promise.all([
    supabase.from("car_clients").select("id, name").eq("status", "active").order("name").limit(2000),
    supabase.from("client_funding").select("id, client_id, period_start, period_end, plan_management, scheme").eq("scheme", "ndis"),
    supabase.from("client_locations").select("id, client_id, label, suburb, state").eq("approved", true),
    supabase.from("client_enrolments").select("id, client_id").eq("scheme", "support_at_home").neq("status", "ended"),
  ]);
  const C = (clients ?? []) as { id: string; name: string }[];
  const cName = new Map(C.map((c) => [c.id, c.name]));
  const P = (payers ?? []) as { id: string; kind: string; client_id: string | null; name: string; email: string; phone: string; active: boolean }[];
  const pName = new Map(P.map((p) => [p.id, p.name]));
  const F = (funding ?? []) as { id: string; client_id: string; period_start: string; period_end: string; plan_management: string | null }[];
  const L = (locs ?? []) as { id: string; client_id: string; label: string; suburb: string | null; state: string | null }[];
  const Z = new Map(((zones ?? []) as { location_id: string; ndis_zone: string; mmm: string }[]).map((z) => [z.location_id, z]));
  const PD = new Map(((plans ?? []) as { funding_id: string; my_provider: boolean; recorded_on: string }[]).map((p) => [p.funding_id, p]));
  const ndisClients = new Set(F.map((f) => f.client_id));
  const planLabel = (f: (typeof F)[number]) => `${cName.get(f.client_id) ?? "Client"}: ${dmy(f.period_start)} to ${dmy(f.period_end)} (${f.plan_management === "ndia" ? "agency" : f.plan_management === "plan" ? "plan-managed" : f.plan_management === "self" ? "self-managed" : "management not set"})`;
  const KIND: Record<string, string> = { services_australia: "Services Australia", ndia: "NDIA", plan_manager: "Plan manager", participant: "Participant", client: "Client contact", other: "Other" };
  const ZONE: Record<string, string> = { national: "National", remote: "Remote", very_remote: "Very remote" };
  const sahClients = ((enrols ?? []) as { id: string; client_id: string }[]).map((e) => ({ id: e.client_id, name: cName.get(e.client_id) ?? "Client", enrolment: e.id }));
  return (
    <div className="flex flex-col gap-4">
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Payers</h2>
          <p className="text-sm text-muted">Who each invoice or claim goes to. Services Australia and the NDIA are set up already; add plan managers, self-managed participants and client billing contacts, then link them to the client.</p>
        </div>
        <ul className="divide-y divide-line rounded-md border border-line text-sm">
          {P.map((p) => (
            <li key={p.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
              <span className="min-w-40 flex-1 font-semibold">{p.name}</span>
              <span className="text-xs text-muted">{KIND[p.kind]}{p.client_id ? ` · ${cName.get(p.client_id) ?? "client"}` : ""}</span>
              <span className="text-xs">{[p.email, p.phone].filter(Boolean).join(" · ")}</span>
            </li>
          ))}
        </ul>
        {canPrepare ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Add a payer</summary><div className="mt-2"><PayerForm clients={C.map((c) => [c.id, c.name])} /></div></details> : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <h2 className="heading-sm">Client payer links</h2>
        {(links ?? []).length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {((links ?? []) as { id: string; client_id: string; role: string; funding_id: string | null; payer_id: string; starts_on: string; ends_on: string | null }[]).map((k) => (
              <li key={k.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <span className="min-w-40 flex-1 font-semibold">{cName.get(k.client_id) ?? "Client"}</span>
                <span className="text-xs">{k.role === "client" ? "Client's share" : "NDIS plan"} → {pName.get(k.payer_id)}</span>
                <span className="text-xs text-muted">from {dmy(k.starts_on)}{k.ends_on ? ` to ${dmy(k.ends_on)}` : ""}</span>
                {canPrepare && !k.ends_on ? <EndForm table="client_payer_links" id={k.id} /> : null}
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No links yet.</p>}
        {canPrepare ? <LinkPayerForm clients={C.map((c) => [c.id, c.name])} payers={P.filter((p) => p.active && !["services_australia", "ndia"].includes(p.kind)).map((p) => ({ id: p.id, label: p.name, client_id: p.client_id }))}
          plans={F.filter((f) => f.plan_management === "plan" || f.plan_management === "self").map((f) => ({ id: f.id, label: planLabel(f), client_id: f.client_id }))} /> : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Support at Home fee reduction supplements</h2>
          <p className="text-sm text-muted">When Services Australia approves a full fee reduction supplement, contributions in those dates aren&apos;t invoiced.</p>
        </div>
        {(fees ?? []).length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {((fees ?? []) as { id: string; client_id: string; starts_on: string; ends_on: string | null; source: string }[]).map((f) => (
              <li key={f.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <span className="min-w-40 flex-1 font-semibold">{cName.get(f.client_id) ?? "Client"}</span>
                <span className="text-xs">from {dmy(f.starts_on)}{f.ends_on ? ` to ${dmy(f.ends_on)}` : ""}</span>
                <span className="text-xs text-muted">{f.source}</span>
                {canPrepare && !f.ends_on ? <EndForm table="client_fee_reductions" id={f.id} /> : null}
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">None recorded.</p>}
        {canPrepare && sahClients.length ? <FeeReductionForm clients={sahClients} /> : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">NDIS: pricing zones and &quot;my provider&quot;</h2>
          <p className="text-sm text-muted">The price limit is the one for the zone of the service delivery location (from its Modified Monash category). Agency-managed supports are claimed only when you&apos;re recorded as &quot;my provider&quot; on the plan.</p>
        </div>
        <ul className="divide-y divide-line rounded-md border border-line text-sm">
          {L.filter((l) => ndisClients.has(l.client_id)).map((l) => (
            <li key={l.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
              <span className="min-w-40 flex-1 font-semibold">{cName.get(l.client_id) ?? "Client"}</span>
              <span className="text-xs">{l.label}{l.suburb ? `, ${l.suburb}` : ""} {l.state ?? ""}</span>
              <span className={`text-xs ${Z.get(l.id) ? "" : "text-danger"}`}>{Z.get(l.id) ? `${ZONE[Z.get(l.id)!.ndis_zone]}${Z.get(l.id)!.mmm ? ` (${Z.get(l.id)!.mmm})` : ""}` : "No zone"}</span>
            </li>
          ))}
          {F.filter((f) => f.plan_management === "ndia").map((f) => (
            <li key={f.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
              <span className="min-w-40 flex-1">{planLabel(f)}</span>
              <span className={`text-xs ${PD.get(f.id)?.my_provider ? "" : "text-danger"}`}>{PD.get(f.id) ? (PD.get(f.id)!.my_provider ? `"My provider" (checked ${dmy(PD.get(f.id)!.recorded_on)})` : "Not \"my provider\"") : "Not recorded"}</span>
            </li>
          ))}
        </ul>
        {canPrepare ? (
          <>
            <ZoneForm locations={L.filter((l) => ndisClients.has(l.client_id)).map((l) => [l.id, `${cName.get(l.client_id) ?? "Client"}: ${l.label}${l.suburb ? `, ${l.suburb}` : ""}`])} />
            <PlanDetailsForm plans={F.filter((f) => f.plan_management === "ndia").map((f) => [f.id, planLabel(f)])} />
          </>
        ) : null}
      </Card>
    </div>
  );
}

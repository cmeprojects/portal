// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card, buttonClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { mondayOf, sydneyParts, sydneyToday, addDays } from "@/lib/sydney-time";
import { BudgetButtons, DecideEntry, DeliveryDecision, LedgerEntryForm, LinesTable, MakeLinesForm, QuarterBudgetForm, type LineRow } from "./forms";

// cmeprojects (update 162): the Billing module's tabs. What each person sees
// follows their Billing reach; every change goes through the database's rules.
type SP = Record<string, string | string[] | undefined>;
const str = (sp: SP, k: string) => (typeof sp[k] === "string" ? (sp[k] as string) : "");
const ymd = (v: string) => (/^\d{4}-\d{2}-\d{2}$/.test(v) ? v : "");
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));
const SCHEME: Record<string, string> = { support_at_home: "Support at Home", ndis: "NDIS", chsp: "CHSP", private: "Private", other: "Other" };
const monthStart = (d: string) => `${d.slice(0, 7)}-01`;

async function names(ids: string[]) {
  if (!ids.length) return new Map<string, string>();
  const { data } = await (await createClient()).from("profiles").select("id, full_name, email").in("id", ids);
  return new Map(((data ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
}
function PeriodFilter({ tab, from, to, status, extra }: { tab: string; from: string; to: string; status?: string; extra?: React.ReactNode }) {
  return (
    <form method="get" action="/billing" className="flex flex-wrap items-end gap-2">
      <input type="hidden" name="tab" value={tab} />
      <label className="flex flex-col gap-1 text-xs font-medium">From<DateInput name="from" defaultValue={from} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
      <label className="flex flex-col gap-1 text-xs font-medium">To<DateInput name="to" defaultValue={to} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
      {status !== undefined ? (
        <label className="flex flex-col gap-1 text-xs font-medium">Status
          <select name="status" defaultValue={status} className="h-10 rounded-lg border border-field bg-surface px-3 text-sm">
            <option value="draft">To review</option><option value="approved">Approved</option><option value="voided">Voided</option><option value="all">All</option>
          </select>
        </label>
      ) : null}
      {extra}
      <button className={buttonClass("outline")}>Show</button>
    </form>
  );
}

// ---- Billing lines ----
export async function LinesTab({ sp }: { sp: SP }) {
  const { profile } = await requireSession();
  const today = sydneyToday();
  const from = ymd(str(sp, "from")) || monthStart(addDays(today, -31));
  const to = ymd(str(sp, "to")) || today;
  const status = ["draft", "approved", "voided", "all"].includes(str(sp, "status")) ? str(sp, "status") : "draft";
  const supabase = await createClient();
  let q = supabase.from("billing_lines").select("*").gte("service_date", from).lte("service_date", to).order("service_date").order("starts_at").limit(1000);
  if (status !== "all") q = q.eq("status", status);
  const [{ data, error }, canPrepare, canApprove] = await Promise.all([q, canBill("prepare"), canBill("approve")]);
  if (error) return <Card className="p-5 text-sm text-muted">Billing lines aren&apos;t set up yet (update 162).</Card>;
  type L = { id: string; status: string; kind: string; client_id: string; service_id: string; service_date: string; starts_at: string; ends_at: string; band_label: string; quantity: number; unit: string; unit_price: number; amount: number;
    client_share: number | null; government_share: number | null; scheme: string; over_budget: boolean; calc: Record<string, unknown>; generated_by: string; generated_at: string; approved_by: string | null; approved_at: string | null;
    voided_by: string | null; voided_at: string | null; void_reason: string | null; void_note: string; approve_note: string; corrects_id: string | null; minutes_actual: number; minutes_billed: number; contribution_pct: number | null; holiday_state: string | null; funding_stream: string };
  const lines = (data ?? []) as L[];
  const clientIds = [...new Set(lines.map((l) => l.client_id))];
  const svcIds = [...new Set(lines.map((l) => l.service_id))];
  const [{ data: cRows }, { data: sRows }, who] = await Promise.all([
    clientIds.length ? supabase.from("car_clients").select("id, name").in("id", clientIds) : Promise.resolve({ data: [] }),
    svcIds.length ? supabase.from("client_services").select("id, label").in("id", svcIds) : Promise.resolve({ data: [] }),
    names([...new Set(lines.flatMap((l) => [l.generated_by, l.approved_by, l.voided_by]).filter(Boolean))] as string[]),
  ]);
  const cName = new Map(((cRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const sName = new Map(((sRows ?? []) as { id: string; label: string }[]).map((c) => [c.id, c.label]));
  const t = (iso: string) => sydneyParts(iso).time;
  const rows: LineRow[] = lines.map((l) => ({
    id: l.id, status: l.status, kind: l.kind, client: cName.get(l.client_id) ?? "Client", clientId: l.client_id, service: sName.get(l.service_id) ?? "Service",
    date: dmy(l.service_date), time: `${t(l.starts_at)}–${t(l.ends_at)}`, band: l.band_label, quantity: l.quantity, unit: l.unit, unit_price: l.unit_price, amount: l.amount,
    client_share: l.client_share, government_share: l.government_share, scheme: l.scheme, over_budget: l.over_budget, corrects: !!l.corrects_id, mine: l.generated_by === profile.id,
    calc: [
      `${SCHEME[l.scheme] ?? l.scheme} · ${l.funding_stream} · times from ${l.calc.times_from ?? "?"} · break ${l.calc.break_minutes ?? 0} min`,
      `${l.minutes_actual} min in this band → ${l.minutes_billed} min billed (unit ${l.calc.unit_minutes} min, rounding ${l.calc.rounding}${Number(l.calc.minimum_added) > 0 ? `, minimum added ${l.calc.minimum_added} min` : ""}; price list version ${l.calc.price_list_version}, band rule ${l.calc.crossing === "split" ? "split across bands" : "whole shift at the highest band"})`,
      `${Number(l.quantity)} × ${aud(l.unit_price)} = ${aud(l.amount)}${l.contribution_pct !== null ? `; client contribution ${Number(l.contribution_pct)}% = ${aud(l.client_share)}; funding ${aud(l.government_share)}` : l.client_share === null ? "; contribution per the scheme's confirmed rules (not calculated)" : ""}`,
      l.holiday_state ? `Public holidays: ${l.holiday_state}` : "",
      l.calc.available_before !== null && l.calc.available_before !== undefined ? `Available in the funding account before this line: ${aud(Number(l.calc.available_before))}` : "",
      l.approve_note ? `Approval note: ${l.approve_note}` : "",
      l.void_reason ? `Voided: ${l.void_reason}${l.void_note ? ` (${l.void_note})` : ""}` : "",
    ].filter(Boolean).join("\n"),
    made: `Made by ${who.get(l.generated_by) ?? "someone"} ${dmy(l.generated_at)}`,
    approved: l.approved_by ? `approved by ${who.get(l.approved_by) ?? "someone"} ${dmy(l.approved_at)}` : "",
    voided: l.voided_by ? `voided by ${who.get(l.voided_by) ?? "someone"} ${dmy(l.voided_at)}` : "",
  }));
  return (
    <>
      {canPrepare ? (
        <Card className="flex flex-col gap-2 p-4">
          <h2 className="heading-sm">Make billing lines</h2>
          <MakeLinesForm from={from} to={to} />
        </Card>
      ) : null}
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Billing lines</h2>
          <p className="text-sm text-muted">One line per shift and rate band. Approve lines someone else made; they&apos;re then charged to their funding account and never change. Mistakes are voided with a reason (kept) and made again.</p>
        </div>
        <PeriodFilter tab="lines" from={from} to={to} status={status} />
        <LinesTable lines={rows} canApprove={canApprove} />
      </Card>
    </>
  );
}

// ---- Exceptions ----
export async function ExceptionsTab({ sp }: { sp: SP }) {
  const today = sydneyToday();
  const from = ymd(str(sp, "from")) || monthStart(addDays(today, -31));
  const to = ymd(str(sp, "to")) || today;
  const supabase = await createClient();
  const [{ data, error }, canApprove] = await Promise.all([supabase.rpc("billing_exceptions", { p_from: from, p_to: to }), canBill("approve")]);
  if (error) return <Card className="p-5 text-sm text-muted">Exceptions aren&apos;t available yet (update 162).</Card>;
  const rows = (data ?? []) as { shift_id: string; client_id: string; service_id: string | null; starts_at: string; kind: string; problem: string }[];
  const clientIds = [...new Set(rows.map((r) => r.client_id))];
  const svcIds = [...new Set(rows.map((r) => r.service_id).filter(Boolean))] as string[];
  const [{ data: cRows }, { data: sRows }] = await Promise.all([
    clientIds.length ? supabase.from("car_clients").select("id, name").in("id", clientIds) : Promise.resolve({ data: [] }),
    svcIds.length ? supabase.from("client_services").select("id, label").in("id", svcIds) : Promise.resolve({ data: [] }),
  ]);
  const cName = new Map(((cRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const sName = new Map(((sRows ?? []) as { id: string; label: string }[]).map((c) => [c.id, c.label]));
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div>
        <h2 className="heading-sm">Exceptions</h2>
        <p className="text-sm text-muted">Shifts in the period that can&apos;t be billed yet, and why. Nothing is billed silently: fix the cause on the client&apos;s records (or record a delivery decision), then make lines again.</p>
      </div>
      <PeriodFilter tab="exceptions" from={from} to={to} />
      {rows.length ? (
        <ul className="flex flex-col gap-2">
          {rows.map((r) => {
            const p = sydneyParts(r.starts_at);
            return (
              <li key={`${r.shift_id}-${r.kind}`} className="rounded-md border border-line px-3 py-2 text-sm">
                <p className="font-semibold">
                  <Link href={`/settings/clients/${r.client_id}?tab=services#services`} className="text-brand underline">{cName.get(r.client_id) ?? "Client"}</Link>
                  {" · "}{r.service_id ? sName.get(r.service_id) ?? "Service" : "No service"} · {dmy(p.date)} {p.time}{r.kind === "cancellation" ? " · late cancellation" : ""}
                  {" · "}<Link href={`/roster/timesheets?w=${mondayOf(p.date)}`} className="text-xs text-brand underline">Timesheets week</Link>
                </p>
                <p className="text-danger">{r.problem}</p>
                {canApprove && r.problem.startsWith("Waiting for delivery evidence") ? <DeliveryDecision shiftId={r.shift_id} /> : null}
              </li>
            );
          })}
        </ul>
      ) : <p className="text-sm text-muted">No exceptions in this period.</p>}
    </Card>
  );
}

// ---- Phase 6 (update 170): rostered shifts, checked before they're delivered ----
export type ForecastRow = { shift_id: string; client_id: string; service_id: string | null; starts_at: string; shift_status: string; severity: string; problem: string | null; amount: number | null; client_share: number | null; account_kind: string | null; account_id: string | null; available_before: number | null; left_after: number | null };
export async function rosterForecast(from: string, to: string) {
  const { data, error } = await (await createClient()).rpc("roster_billing_forecast", { p_from: from, p_to: to });
  return error ? null : ((data ?? []) as ForecastRow[]);
}
const SEVERITY: Record<string, string> = { fix: "To fix before it can be billed", over_budget: "Would go over the budget", setup: "Waiting on set-up (scheme rules or a quarter budget)" };
export async function UpcomingTab({ sp }: { sp: SP }) {
  const today = sydneyToday();
  const from = ymd(str(sp, "ufrom")) || today;
  const to = ymd(str(sp, "uto")) || addDays(today, 27);
  const rows = await rosterForecast(from, to);
  if (rows === null) return <Card className="p-5 text-sm text-muted">Roster checks aren&apos;t available yet (update 170).</Card>;
  const supabase = await createClient();
  const clientIds = [...new Set(rows.map((r) => r.client_id))];
  const svcIds = [...new Set(rows.map((r) => r.service_id).filter(Boolean))] as string[];
  const qIds = [...new Set(rows.filter((r) => r.account_kind === "quarter_budget").map((r) => r.account_id!))];
  const fIds = [...new Set(rows.filter((r) => r.account_kind === "funding").map((r) => r.account_id!))];
  const [{ data: cRows }, { data: sRows }, { data: qRows }, { data: fRows }] = await Promise.all([
    clientIds.length ? supabase.from("car_clients").select("id, name").in("id", clientIds) : Promise.resolve({ data: [] }),
    svcIds.length ? supabase.from("client_services").select("id, label").in("id", svcIds) : Promise.resolve({ data: [] }),
    qIds.length ? supabase.from("client_quarter_budgets").select("id, quarter_start, quarter_end").in("id", qIds) : Promise.resolve({ data: [] }),
    fIds.length ? supabase.from("client_funding").select("id, scheme, period_start, period_end").in("id", fIds) : Promise.resolve({ data: [] }),
  ]);
  const cName = new Map(((cRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const sName = new Map(((sRows ?? []) as { id: string; label: string }[]).map((c) => [c.id, c.label]));
  const acctName = new Map<string, string>([
    ...((qRows ?? []) as { id: string; quarter_start: string; quarter_end: string }[]).map((q) => [q.id, `Support at Home quarter ${dmy(q.quarter_start)} to ${dmy(q.quarter_end)}`] as [string, string]),
    ...((fRows ?? []) as { id: string; scheme: string; period_start: string; period_end: string }[]).map((f) => [f.id, `${SCHEME[f.scheme] ?? f.scheme} funding ${dmy(f.period_start)} to ${dmy(f.period_end)}`] as [string, string]),
  ]);
  const problems = rows.filter((r) => r.severity !== "ok");
  // Budget forecast: per funding account, what the rostered shifts would use and what's left.
  const accounts = new Map<string, { client: string; id: string; before: number; used: number; left: number; shifts: number; firstOver: string | null }>();
  for (const r of rows) {
    if (!r.account_id || r.amount === null) continue;
    const a = accounts.get(r.account_id) ?? { client: r.client_id, id: r.account_id, before: Number(r.available_before), used: 0, left: 0, shifts: 0, firstOver: null };
    a.used += Number(r.amount); a.left = Number(r.left_after); a.shifts += 1;
    if (a.left < 0 && !a.firstOver) a.firstOver = r.starts_at;
    accounts.set(r.account_id, a);
  }
  const acctRows = [...accounts.values()].sort((x, y) => x.left - y.left);
  return (
    <>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Coming up: rostered shifts</h2>
          <p className="text-sm text-muted">Client shifts on the roster (draft or published) not billed yet, checked as if delivered as rostered: approved service, program, billing terms, prices, funding and budget. Rostering is never blocked; fix these before the shifts are delivered. Amounts are estimates from the roster, not billing lines.</p>
        </div>
        <form method="get" action="/billing" className="flex flex-wrap items-end gap-2">
          <input type="hidden" name="tab" value="upcoming" />
          <label className="flex flex-col gap-1 text-xs font-medium">From<DateInput name="ufrom" defaultValue={from} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
          <label className="flex flex-col gap-1 text-xs font-medium">To<DateInput name="uto" defaultValue={to} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
          <button className={buttonClass("outline")}>Show</button>
        </form>
        <p className="text-sm">{rows.length} rostered client shift{rows.length === 1 ? "" : "s"} checked: {rows.filter((r) => r.severity === "ok").length} ready, {problems.filter((r) => r.severity === "fix").length} to fix, {problems.filter((r) => r.severity === "over_budget").length} over budget, {problems.filter((r) => r.severity === "setup").length} waiting on set-up.</p>
        {(["fix", "over_budget", "setup"] as const).map((sev) => {
          const list = problems.filter((r) => r.severity === sev);
          if (!list.length) return null;
          return (
            <details key={sev} open={sev !== "setup"} className="rounded-md border border-line">
              <summary className="cursor-pointer px-3 py-2 text-sm font-semibold">{SEVERITY[sev]} ({list.length})</summary>
              <ul className="flex flex-col gap-1 px-3 pb-3">
                {list.map((r) => {
                  const p = sydneyParts(r.starts_at);
                  return (
                    <li key={r.shift_id} className="text-sm" data-upcoming={sev}>
                      <Link href={`/settings/clients/${r.client_id}?tab=services#services`} className="font-semibold text-brand underline">{cName.get(r.client_id) ?? "Client"}</Link>
                      {" · "}{r.service_id ? sName.get(r.service_id) ?? "Service" : "No service"} · {dmy(p.date)} {p.time}{r.shift_status === "draft" ? " · draft" : ""}
                      {" · "}<Link href={`/roster?d=${p.date}&shift=${r.shift_id}`} className="text-xs text-brand underline">Open on the roster</Link>
                      <span className={`block ${sev === "setup" ? "text-warn" : "text-danger"}`}>{r.problem}</span>
                    </li>
                  );
                })}
              </ul>
            </details>
          );
        })}
        {!rows.length ? <p className="text-sm text-muted">No rostered client shifts in this period.</p> : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Budget forecast</h2>
          <p className="text-sm text-muted">For each funding account: what&apos;s available now (approved balance, less draft lines), what the rostered shifts in the period would use, and what would be left. Billing lines over the budget need a note when approved.</p>
        </div>
        {acctRows.length ? (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="text-left text-xs text-muted"><th className="py-1 pr-3">Client</th><th className="pr-3">Account</th><th className="pr-3 text-right">Available now</th><th className="pr-3 text-right">Rostered shifts</th><th className="pr-3 text-right">Would use</th><th className="pr-3 text-right">Left after</th><th>Goes over on</th></tr></thead>
              <tbody>
                {acctRows.map((a) => (
                  <tr key={a.id} className="border-t border-line" data-forecast-row>
                    <td className="py-1 pr-3">{cName.get(a.client) ?? "Client"}</td>
                    <td className="pr-3">{acctName.get(a.id) ?? "Funding account"}</td>
                    <td className="pr-3 text-right">{aud(a.before)}</td>
                    <td className="pr-3 text-right">{a.shifts}</td>
                    <td className="pr-3 text-right">{aud(a.used)}</td>
                    <td className={`pr-3 text-right font-semibold ${a.left < 0 ? "text-danger" : ""}`}>{aud(a.left)}</td>
                    <td>{a.firstOver ? dmy(sydneyParts(a.firstOver).date) : "–"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No rostered shifts in the period draw on a funding account yet (they need approved terms, prices and funding first).</p>}
      </Card>
    </>
  );
}

// ---- Budgets and ledger ----
export async function BudgetsTab() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const today = sydneyToday();
  const [bRes, balRes, ledRes, enrRes, fundRes, canPrepare, canApprove] = await Promise.all([
    supabase.from("client_quarter_budgets").select("*").order("quarter_start", { ascending: false }).limit(300),
    supabase.from("funding_balances").select("account_kind, account_id, client_id, available"),
    supabase.from("funding_ledger").select("*").order("created_at", { ascending: false }).limit(300),
    supabase.from("client_enrolments").select("id, client_id, status").eq("scheme", "support_at_home").neq("status", "ended"),
    supabase.from("client_funding").select("id, client_id, scheme, period_start, period_end, total_amount, status"),
    canBill("prepare"),
    canBill("approve"),
  ]);
  if (bRes.error) return <Card className="p-5 text-sm text-muted">Budgets and the ledger aren&apos;t set up yet (update 162).</Card>;
  type B = { id: string; client_id: string; quarter_start: string; quarter_end: string; quarterly_amount: number; prorated_amount: number; start_date: string; carryover_in: number; care_management: number; spendable: number; status: string; created_by: string; approved_by: string | null; spent: number | null; carryover_out: number | null; lapsed: number | null; source: string };
  type E = { id: string; client_id: string; quarter_budget_id: string | null; funding_id: string | null; entry_kind: string; amount: number; entry_date: string; reason: string; status: string; created_by: string; decided_by: string | null };
  const budgets = (bRes.data ?? []) as B[];
  const ledger = (ledRes.data ?? []) as E[];
  const funding = (fundRes.data ?? []) as { id: string; client_id: string; scheme: string; period_start: string; period_end: string; total_amount: number; status: string }[];
  const enrol = (enrRes.data ?? []) as { id: string; client_id: string }[];
  const avail = new Map(((balRes.data ?? []) as { account_id: string; available: number }[]).map((b) => [b.account_id, b.available]));
  const clientIds = [...new Set([...budgets.map((b) => b.client_id), ...ledger.map((l) => l.client_id), ...enrol.map((e) => e.client_id), ...funding.map((f) => f.client_id)])];
  const [{ data: cRows }, who] = await Promise.all([
    clientIds.length ? supabase.from("car_clients").select("id, name").in("id", clientIds).order("name") : Promise.resolve({ data: [] }),
    names([...new Set([...budgets.flatMap((b) => [b.created_by, b.approved_by]), ...ledger.flatMap((l) => [l.created_by, l.decided_by])].filter(Boolean))] as string[]),
  ]);
  const clients = (cRows ?? []) as { id: string; name: string }[];
  const cName = new Map(clients.map((c) => [c.id, c.name]));
  const qLabel = (s: string) => { const d = new Date(`${s}T00:00:00Z`); const e = new Date(d); e.setUTCMonth(e.getUTCMonth() + 2); const m = (x: Date) => x.toLocaleDateString("en-AU", { month: "short", timeZone: "UTC" }); return `${m(d)}–${m(e)} ${e.getUTCFullYear()}`; };
  const q0 = (() => { const [y, m] = today.split("-").map(Number); const qm = Math.floor((m - 1) / 3) * 3 + 1; return `${y}-${String(qm).padStart(2, "0")}-01`; })();
  const quarters: [string, string][] = [-1, 0, 1].map((i) => { const d = new Date(`${q0}T00:00:00Z`); d.setUTCMonth(d.getUTCMonth() + i * 3); const v = d.toISOString().slice(0, 10); return [v, qLabel(v)]; });
  const fundLabel = (f: { scheme: string; period_start: string; period_end: string; total_amount: number }) => `${SCHEME[f.scheme] ?? f.scheme} funding ${dmy(f.period_start)} to ${dmy(f.period_end)} (${aud(f.total_amount)})`;
  const accounts: [string, string, string][] = [
    ...budgets.filter((b) => b.status === "approved").map((b) => [`q:${b.id}`, b.client_id, `Support at Home quarter ${qLabel(b.quarter_start)}`] as [string, string, string]),
    ...funding.map((f) => [`f:${f.id}`, f.client_id, fundLabel(f)] as [string, string, string]),
  ];
  const STATUS: Record<string, string> = { draft: "Draft", approved: "Open", closed: "Closed" };
  const KIND: Record<string, string> = { opening_balance: "Opening balance", charge: "Charge", reversal: "Reversal", adjustment: "Adjustment", carryover_out: "Carried over", lapse: "Lapsed" };
  return (
    <>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Support at Home quarter budgets</h2>
          <p className="text-sm text-muted">One per client program and quarter. Care management and carryover use the verified figures. Approved by someone other than the person who made it; closed once after the quarter ends (carryover up to the cap; the rest lapses).</p>
        </div>
        {budgets.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[56rem] text-left text-sm">
              <thead className="text-xs text-muted"><tr><th className="py-1 pr-2">Client</th><th className="py-1 pr-2">Quarter</th><th className="py-1 pr-2 text-right">Amount</th><th className="py-1 pr-2 text-right">Carryover in</th><th className="py-1 pr-2 text-right">Care mgmt</th><th className="py-1 pr-2 text-right">Spendable</th><th className="py-1 pr-2 text-right">Available</th><th className="py-1 pr-2">Status</th><th className="py-1"><span className="sr-only">Actions</span></th></tr></thead>
              <tbody className="divide-y divide-line">
                {budgets.map((b) => (
                  <tr key={b.id}>
                    <td className="py-1 pr-2"><Link href={`/settings/clients/${b.client_id}?tab=funding`} className="font-semibold text-brand underline">{cName.get(b.client_id) ?? "Client"}</Link><span className="block text-xs text-muted">{b.source}</span></td>
                    <td className="py-1 pr-2 text-xs">{qLabel(b.quarter_start)}{b.start_date !== b.quarter_start ? <span className="block text-muted">from {dmy(b.start_date)} (pro rata {aud(b.prorated_amount)})</span> : null}</td>
                    <td className="py-1 pr-2 text-right">{aud(b.quarterly_amount)}</td>
                    <td className="py-1 pr-2 text-right">{aud(b.carryover_in)}</td>
                    <td className="py-1 pr-2 text-right">{aud(b.care_management)}</td>
                    <td className="py-1 pr-2 text-right font-semibold">{aud(b.spendable)}</td>
                    <td className="py-1 pr-2 text-right">{b.status === "draft" ? "–" : aud(avail.get(b.id) ?? b.spendable)}{b.status === "closed" ? <span className="block text-[11px] text-muted">spent {aud(b.spent)}, carried {aud(b.carryover_out)}, lapsed {aud(b.lapsed)}</span> : null}</td>
                    <td className="py-1 pr-2 text-xs">{STATUS[b.status]}<span className="block text-muted">made by {who.get(b.created_by) ?? "someone"}{b.approved_by ? `, approved by ${who.get(b.approved_by) ?? "someone"}` : ""}</span></td>
                    <td className="py-1"><BudgetButtons id={b.id} status={b.status} canApprove={canApprove} mine={b.created_by === profile.id} ended={today > b.quarter_end} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No quarter budgets yet.</p>}
        {canPrepare && enrol.length ? (
          <details className="rounded-md border border-dashed border-line px-3 py-2">
            <summary className="cursor-pointer text-xs font-semibold text-brand">Add a quarter budget</summary>
            <div className="mt-2">
              <QuarterBudgetForm enrolments={enrol.map((e) => [e.id, e.client_id, `${cName.get(e.client_id) ?? "Client"} · Support at Home`])} funding={funding.filter((f) => f.scheme === "support_at_home").map((f) => [f.id, f.client_id, fundLabel(f)])} quarters={quarters} />
            </div>
          </details>
        ) : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Funding ledger</h2>
          <p className="text-sm text-muted">Every movement, never edited or deleted: charges from approved lines, reversals from voids, carryover and lapse from closing a quarter. Opening balances and adjustments are proposed and approved by someone else before they count. Funding records themselves aren&apos;t changed.</p>
        </div>
        {ledger.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[52rem] text-left text-sm">
              <thead className="text-xs text-muted"><tr><th className="py-1 pr-2">Date</th><th className="py-1 pr-2">Client</th><th className="py-1 pr-2">Account</th><th className="py-1 pr-2">Entry</th><th className="py-1 pr-2 text-right">Amount</th><th className="py-1 pr-2">Status</th><th className="py-1"><span className="sr-only">Decide</span></th></tr></thead>
              <tbody className="divide-y divide-line">
                {ledger.map((l) => (
                  <tr key={l.id} className={l.status === "rejected" ? "text-muted line-through" : ""}>
                    <td className="py-1 pr-2 text-xs">{dmy(l.entry_date)}</td>
                    <td className="py-1 pr-2">{cName.get(l.client_id) ?? "Client"}</td>
                    <td className="py-1 pr-2 text-xs">{accounts.find(([a]) => a === (l.quarter_budget_id ? `q:${l.quarter_budget_id}` : `f:${l.funding_id}`))?.[2] ?? (l.quarter_budget_id ? "Quarter budget (closed)" : "Funding record")}</td>
                    <td className="py-1 pr-2 text-xs">{KIND[l.entry_kind] ?? l.entry_kind}<span className="block text-muted">{l.reason}</span></td>
                    <td className={`py-1 pr-2 text-right font-semibold ${Number(l.amount) < 0 ? "text-danger" : ""}`}>{aud(l.amount)}</td>
                    <td className="py-1 pr-2 text-xs">{l.status === "proposed" ? "Proposed" : l.status === "approved" ? "Counted" : "Rejected"}<span className="block text-muted">by {who.get(l.created_by) ?? "someone"}{l.decided_by && l.entry_kind in { opening_balance: 1, adjustment: 1 } ? `, decided by ${who.get(l.decided_by) ?? "someone"}` : ""}</span></td>
                    <td className="py-1">{l.status === "proposed" && canApprove && l.created_by !== profile.id ? <DecideEntry id={l.id} /> : null}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No ledger entries yet.</p>}
        {canPrepare && clients.length ? (
          <details className="rounded-md border border-dashed border-line px-3 py-2">
            <summary className="cursor-pointer text-xs font-semibold text-brand">Propose an opening balance or adjustment</summary>
            <div className="mt-2"><LedgerEntryForm clients={clients.map((c) => [c.id, c.name])} accounts={accounts} /></div>
          </details>
        ) : null}
      </Card>
    </>
  );
}

// ---- Export ----
export async function ExportTab() {
  const canExport = await canBill("export");
  const today = sydneyToday();
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div>
        <h2 className="heading-sm">Export approved billing lines (CSV)</h2>
        <p className="text-sm text-muted">Approved lines for the period with their client, service, scheme, band, quantity, price, amount, contribution and funding, and the references that trace them. Each export is recorded in the download trail. Claims and invoices come in Phase 5.</p>
      </div>
      {canExport ? (
        <form method="get" action="/billing/export" className="flex flex-wrap items-end gap-2">
          <label className="flex flex-col gap-1 text-xs font-medium">From<DateInput name="from" required defaultValue={monthStart(today)} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
          <label className="flex flex-col gap-1 text-xs font-medium">To<DateInput name="to" required defaultValue={today} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
          <button className={buttonClass("primary")}>Download CSV</button>
        </form>
      ) : <p className="text-sm text-muted">You don&apos;t have the Billing export right.</p>}
    </Card>
  );
}

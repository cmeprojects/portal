// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";

// cmeprojects (update 166): consolidated financial reports for a period (Phase 5D). Each section is
// a table of rows worked out from what Phases 4 and 5 recorded, read with the person's own Billing
// reach. The same rows drive the screen and the CSV exports.
export type Section = { key: string; title: string; note: string; head: string[]; rows: (string | number)[][]; money: number[] };
const n2 = (v: unknown) => Math.round(Number(v ?? 0) * 100) / 100;
const STREAM: Record<string, string> = { ongoing: "Quarterly budget", at_hm: "AT-HM", restorative: "Restorative Care", end_of_life: "End-of-Life", hcp_unspent: "Unspent HCP funds", ndis_plan: "NDIS plan", private: "Private", grant: "Grant", other: "Other" };
const SCHEME: Record<string, string> = { support_at_home: "Support at Home", ndis: "NDIS", chsp: "CHSP", private: "Private", other: "Other" };
const PROGRAM: Record<string, string> = { support_at_home: "Support at Home", ndis: "NDIS" };
const KIND: Record<string, string> = { sah_contribution: "Support at Home contributions", private: "Private", ndis_plan_managed: "NDIS plan-managed", ndis_self_managed: "NDIS self-managed" };

export async function billingReports(supabase: SupabaseClient, from: string, to: string, today: string): Promise<Section[]> {
  const [rev, claims, items, outs, ibal, invs, pays, refunds, wos, sinv, slines, charges, qb, pb, checks, clients, payers] = await Promise.all([
    supabase.from("billing_revenue").select("source, client_id, scheme, funding_stream, amount, client_share, government_share").gte("service_date", from).lte("service_date", to).limit(50000),
    supabase.from("claims").select("id, program, status, period_from, period_to").neq("status", "cancelled").lte("period_from", to).gte("period_to", from),
    supabase.from("claim_items").select("id, claim_id, claimed_value, expected_amount, status").eq("status", "live").limit(50000),
    supabase.from("claim_item_balances").select("claim_item_id, claim_id, accepted, paid, written_off, outcome").limit(50000),
    supabase.from("invoice_balances").select("invoice_id, client_id, payer_id, number, total, credited, paid, written_off, refunded, balance, due_date").limit(20000),
    supabase.from("invoices").select("id, kind, issue_date, status").in("status", ["issued", "sent"]).gte("issue_date", from).lte("issue_date", to),
    supabase.from("payments").select("payer_id, method, amount, status, received_on").eq("status", "recorded").gte("received_on", from).lte("received_on", to),
    supabase.from("refunds").select("amount, status, paid_on").eq("status", "paid").gte("paid_on", from).lte("paid_on", to),
    supabase.from("write_offs").select("amount, status, approved_at, invoice_id").eq("status", "approved"),
    supabase.from("supplier_invoices").select("id, supplier_id, status, invoice_date, total, gst").neq("status", "rejected").gte("invoice_date", from).lte("invoice_date", to),
    supabase.from("supplier_invoice_lines").select("id, supplier_invoice_id, amount, gst_amount").limit(20000),
    supabase.from("client_charges").select("supplier_line_id, cost, markup_amount, amount, status").eq("status", "approved").not("supplier_line_id", "is", null),
    supabase.from("client_quarter_budgets").select("id, client_id, quarter_start, quarter_end, spendable, status").neq("status", "draft").lte("quarter_start", to).gte("quarter_end", from),
    supabase.from("pathway_balances").select("pathway_budget_id, client_id, stream, amount, used, available, starts_on, ends_on, status").lte("starts_on", to).gte("ends_on", from),
    supabase.rpc("billing_integrity_checks"),
    supabase.from("car_clients").select("id, name").limit(5000),
    supabase.from("billing_payers").select("id, name"),
  ]);
  const cName = new Map(((clients.data ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const pName = new Map(((payers.data ?? []) as { id: string; name: string }[]).map((p) => [p.id, p.name]));
  const out: Section[] = [];

  // 1. Revenue by scheme and funding stream (service dates in the period).
  const rv = new Map<string, { lines: number; charges: number; value: number; client: number; gov: number }>();
  for (const r of (rev.data ?? []) as { source: string; scheme: string; funding_stream: string; amount: number; client_share: number | null; government_share: number | null }[]) {
    const k = `${SCHEME[r.scheme] ?? r.scheme}|${STREAM[r.funding_stream] ?? r.funding_stream}`;
    const e = rv.get(k) ?? { lines: 0, charges: 0, value: 0, client: 0, gov: 0 };
    if (r.source === "line") e.lines++; else e.charges++;
    e.value += Number(r.amount); e.client += Number(r.client_share ?? 0); e.gov += Number(r.government_share ?? 0);
    rv.set(k, e);
  }
  out.push({ key: "revenue", title: "Revenue by scheme and funding", note: "Approved billing lines and client charges with a service date in the period (full value; the client's share and the government's share).",
    head: ["Scheme", "Funding", "Billing lines", "Charges", "Value", "Client share", "Government share"], money: [4, 5, 6],
    rows: [...rv.entries()].sort().map(([k, e]) => [...k.split("|"), e.lines, e.charges, n2(e.value), n2(e.client), n2(e.gov)]) });

  // 2. Government claims (claims whose period overlaps).
  const cmap = new Map(((claims.data ?? []) as { id: string; program: string; status: string }[]).map((c) => [c.id, c]));
  const bal = new Map(((outs.data ?? []) as { claim_item_id: string; accepted: number; paid: number; written_off: number; outcome: string | null }[]).map((b) => [b.claim_item_id, b]));
  const cg = new Map<string, { claims: Set<string>; claimed: number; expected: number; accepted: number; paid: number; wo: number; waiting: number }>();
  for (const i of (items.data ?? []) as { id: string; claim_id: string; claimed_value: number; expected_amount: number }[]) {
    const c = cmap.get(i.claim_id);
    if (!c) continue;
    const k = `${PROGRAM[c.program] ?? c.program}|${c.status}`;
    const e = cg.get(k) ?? { claims: new Set(), claimed: 0, expected: 0, accepted: 0, paid: 0, wo: 0, waiting: 0 };
    e.claims.add(c.id); e.claimed += Number(i.claimed_value); e.expected += Number(i.expected_amount);
    const b = bal.get(i.id);
    if (b) { e.accepted += Number(b.accepted); e.paid += Number(b.paid); e.wo += Number(b.written_off); if (!b.outcome) e.waiting += Number(i.claimed_value); }
    cg.set(k, e);
  }
  out.push({ key: "claims", title: "Government claims", note: "Claims whose period overlaps the dates chosen, by program and status: claimed (full value), expected from the government, accepted, paid, written off, and still waiting for a result.",
    head: ["Program", "Status", "Claims", "Claimed", "Expected", "Accepted", "Paid", "Written off", "Waiting for result"], money: [3, 4, 5, 6, 7, 8],
    rows: [...cg.entries()].sort().map(([k, e]) => [...k.split("|"), e.claims.size, n2(e.claimed), n2(e.expected), n2(e.accepted), n2(e.paid), n2(e.wo), n2(e.waiting)]) });

  // 3. Client invoices issued in the period, by kind.
  const issued = new Map(((invs.data ?? []) as { id: string; kind: string }[]).map((v) => [v.id, v.kind]));
  const ik = new Map<string, { n: number; total: number; credited: number; paid: number; wo: number; balance: number }>();
  for (const b of (ibal.data ?? []) as { invoice_id: string; total: number; credited: number; paid: number; written_off: number; refunded: number; balance: number }[]) {
    const kind = issued.get(b.invoice_id);
    if (!kind) continue;
    const e = ik.get(kind) ?? { n: 0, total: 0, credited: 0, paid: 0, wo: 0, balance: 0 };
    e.n++; e.total += Number(b.total); e.credited += Number(b.credited); e.paid += Number(b.paid); e.wo += Number(b.written_off); e.balance += Number(b.balance);
    ik.set(kind, e);
  }
  out.push({ key: "invoices", title: "Client invoices issued", note: "Invoices issued in the period, by kind: total, credited, paid, written off and still owing (negative is credit).",
    head: ["Kind", "Invoices", "Total", "Credited", "Paid", "Written off", "Owing"], money: [2, 3, 4, 5, 6],
    rows: [...ik.entries()].map(([k, e]) => [KIND[k] ?? k, e.n, n2(e.total), n2(e.credited), n2(e.paid), n2(e.wo), n2(e.balance)]) });

  // 4. Aged debtors today, by client and payer.
  const days = (d: string | null) => (d ? Math.floor((Date.parse(today) - Date.parse(d)) / 86400000) : 0);
  const ad = new Map<string, number[]>();
  for (const b of (ibal.data ?? []) as { client_id: string; payer_id: string; balance: number; due_date: string | null }[]) {
    if (Number(b.balance) <= 0) continue;
    const k = `${cName.get(b.client_id) ?? "Client"}|${pName.get(b.payer_id) ?? "Payer"}`;
    const e = ad.get(k) ?? [0, 0, 0, 0, 0];
    const d = days(b.due_date); const v = Number(b.balance);
    e[d <= 0 ? 0 : d <= 30 ? 1 : d <= 60 ? 2 : 3] += v; e[4] += v;
    ad.set(k, e);
  }
  out.push({ key: "aged", title: "Money owed by clients and payers (today)", note: "Open invoice balances by days past the due date, whatever the period chosen.",
    head: ["Client", "Payer", "Not yet due", "1-30 days", "31-60 days", "Over 60 days", "Total"], money: [2, 3, 4, 5, 6],
    rows: [...ad.entries()].sort().map(([k, e]) => [...k.split("|"), ...e.map(n2)]) });

  // 5. Cash: payments received and refunds paid in the period.
  const cash = new Map<string, number>();
  for (const p of (pays.data ?? []) as { payer_id: string; method: string; amount: number }[]) { const k = `${pName.get(p.payer_id) ?? "Payer"}|${p.method}`; cash.set(k, (cash.get(k) ?? 0) + Number(p.amount)); }
  const refundTotal = ((refunds.data ?? []) as { amount: number }[]).reduce((a, r) => a + Number(r.amount), 0);
  const woTotal = ((wos.data ?? []) as { amount: number; approved_at: string | null }[]).filter((w) => w.approved_at && w.approved_at.slice(0, 10) >= from && w.approved_at.slice(0, 10) <= to).reduce((a, w) => a + Number(w.amount), 0);
  out.push({ key: "cash", title: "Money in and out", note: `Payments received in the period by payer and method. Refunds paid in the period: $${refundTotal.toFixed(2)}. Write-offs approved in the period: $${woTotal.toFixed(2)}.`,
    head: ["Payer", "Method", "Received"], money: [2], rows: [...cash.entries()].sort().map(([k, v]) => [...k.split("|"), n2(v)]) });

  // 6. Supplier costs and what was charged to clients.
  const lineInv = new Map(((slines.data ?? []) as { id: string; supplier_invoice_id: string; amount: number; gst_amount: number }[]).map((l) => [l.id, l]));
  const inPeriod = new Set(((sinv.data ?? []) as { id: string }[]).map((s) => s.id));
  let cost = 0, gst = 0, charged = 0, markup = 0, chargedCost = 0;
  for (const s of (sinv.data ?? []) as { total: number; gst: number }[]) { cost += Number(s.total) - Number(s.gst); gst += Number(s.gst); }
  for (const c of (charges.data ?? []) as { supplier_line_id: string; cost: number; markup_amount: number; amount: number }[]) {
    const l = lineInv.get(c.supplier_line_id);
    if (!l || !inPeriod.has(l.supplier_invoice_id)) continue;
    chargedCost += Number(c.cost); markup += Number(c.markup_amount); charged += Number(c.amount);
  }
  out.push({ key: "suppliers", title: "Supplier costs and client charges", note: "Supplier invoices dated in the period (before GST) and the client charges made from them. Costs not charged are the provider's own costs.",
    head: ["Supplier costs (ex GST)", "GST on supplier invoices", "Cost charged to clients", "Markup", "Charged to clients", "Costs not charged"], money: [0, 1, 2, 3, 4, 5],
    rows: [[n2(cost), n2(gst), n2(chargedCost), n2(markup), n2(charged), n2(cost - chargedCost)]] });

  // 7. Budgets: quarter budgets and pathway budgets overlapping the period.
  const qids = ((qb.data ?? []) as { id: string }[]).map((q) => q.id);
  const { data: fb } = qids.length ? await supabase.from("funding_balances").select("account_id, available").eq("account_kind", "quarter_budget").in("account_id", qids) : { data: [] };
  const avail = new Map(((fb ?? []) as { account_id: string; available: number }[]).map((f) => [f.account_id, Number(f.available)]));
  out.push({ key: "budgets", title: "Support at Home budgets", note: "Quarter budgets and pathway budgets overlapping the period: what was available and what's left now (negative is over budget).",
    head: ["Client", "Budget", "From", "To", "Amount", "Left now"], money: [4, 5],
    rows: [
      ...((qb.data ?? []) as { id: string; client_id: string; quarter_start: string; quarter_end: string; spendable: number }[]).map((q) => [cName.get(q.client_id) ?? "Client", "Quarterly budget", q.quarter_start, q.quarter_end, n2(q.spendable), n2(avail.get(q.id) ?? q.spendable)]),
      ...((pb.data ?? []) as { client_id: string; stream: string; amount: number; available: number; starts_on: string; ends_on: string }[]).map((b) => [cName.get(b.client_id) ?? "Client", STREAM[b.stream] ?? b.stream, b.starts_on, b.ends_on, n2(b.amount), n2(b.available)]),
    ] });

  // 8. Integrity checks (today).
  out.push({ key: "checks", title: "Checks", note: "Consistency checks over all billing records (today). Errors should always be zero.",
    head: ["Check", "Severity", "Count", "What it means"], money: [],
    rows: ((checks.data ?? []) as { check_name: string; severity: string; problem_count: number; detail: string }[]).map((c) => [c.check_name, c.severity, Number(c.problem_count), c.detail]) });
  return out;
}

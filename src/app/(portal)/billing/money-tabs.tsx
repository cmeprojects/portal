// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui";
import { BankImport, BankLineActions, CompleteReconciliation, DecideButtons, PaymentForm, ReconciliationForm } from "./money-forms";

// cmeprojects (update 164): the Payments tab (payments received, refunds and write-offs to
// decide, money owed by age) and the Reconciliation tab (bank lines matched to payments).
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));
export const METHOD: Record<string, string> = { eft: "Bank transfer", bpay: "BPAY", card: "Card", cash: "Cash", cheque: "Cheque", government_remittance: "Remittance", other: "Other" };

export async function PaymentsTab() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const [{ data: pays, error }, { data: bal }, { data: payers }, { data: clients }, { data: wos }, { data: refs }, canPay, canWo, canRefund] = await Promise.all([
    supabase.from("payments").select("id, payer_id, client_id, received_on, amount, method, reference, receipt_number, status").order("received_on", { ascending: false }).limit(200),
    supabase.from("payment_balances").select("payment_id, unallocated"),
    supabase.from("billing_payers").select("id, name, client_id, active").eq("active", true).order("name"),
    supabase.from("car_clients").select("id, name").eq("status", "active").order("name").limit(2000),
    supabase.from("write_offs").select("id, invoice_id, claim_item_id, client_id, amount, reason, status, threshold, proposed_by, approved_by").in("status", ["proposed", "first_approved"]),
    supabase.from("refunds").select("id, payer_id, client_id, amount, reason, status, proposed_by").in("status", ["proposed", "approved"]),
    canBill("payment_record"), canBill("write_off"), canBill("refund"),
  ]);
  if (error) return <Card className="p-5 text-sm text-muted">Payments aren&apos;t set up yet (update 164).</Card>;
  const P = new Map(((payers ?? []) as { id: string; name: string }[]).map((p) => [p.id, p.name]));
  const C = new Map(((clients ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const left = new Map(((bal ?? []) as { payment_id: string; unallocated: number }[]).map((b) => [b.payment_id, Number(b.unallocated)]));
  const payments = (pays ?? []) as { id: string; payer_id: string; client_id: string | null; received_on: string; amount: number; method: string; reference: string; receipt_number: string | null; status: string }[];
  const writeOffs = (wos ?? []) as { id: string; invoice_id: string | null; claim_item_id: string | null; client_id: string; amount: number; reason: string; status: string; threshold: number | null; proposed_by: string; approved_by: string | null }[];
  const refunds = (refs ?? []) as { id: string; payer_id: string; client_id: string | null; amount: number; reason: string; status: string; proposed_by: string }[];
  return (
    <div className="flex flex-col gap-4">
      <AgedDebtors />
      {writeOffs.length || refunds.length ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Waiting for a decision</h2>
            <p className="text-sm text-muted">Write-offs and refunds are approved by someone other than who proposed them. Write-offs above the threshold need two different approvers.</p>
          </div>
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {writeOffs.map((w) => (
              <li key={w.id} className="flex flex-col gap-1 px-3 py-2">
                <p><span className="font-semibold">Write-off {aud(w.amount)}</span> · {C.get(w.client_id) ?? "Client"} · {w.invoice_id ? <Link href={`/billing/invoices/${w.invoice_id}`} className="text-brand underline">invoice</Link> : "claim line"} · {w.reason}
                  {w.status === "first_approved" ? " · first approval given; needs a second, different approver" : Number(w.amount) > Number(w.threshold ?? 500) ? ` · above the ${aud(w.threshold)} threshold: two approvers` : ""}</p>
                <DecideButtons kind="write_off" id={w.id} status={w.status} mine={w.proposed_by === profile.id || w.approved_by === profile.id} canDecide={canWo} />
              </li>
            ))}
            {refunds.map((r) => (
              <li key={r.id} className="flex flex-col gap-1 px-3 py-2">
                <p><span className="font-semibold">Refund {aud(r.amount)}</span> to {P.get(r.payer_id) ?? "payer"}{r.client_id ? ` · ${C.get(r.client_id) ?? "client"}` : ""} · {r.reason} · {r.status === "approved" ? "approved; record it paid once sent" : "proposed"}</p>
                <DecideButtons kind="refund" id={r.id} status={r.status} mine={r.proposed_by === profile.id} canDecide={canRefund || (r.status === "approved" && canPay)} />
              </li>
            ))}
          </ul>
        </Card>
      ) : null}
      {canPay ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Record a payment received</h2>
            <p className="text-sm text-muted">From Services Australia, the NDIA, a plan manager, a participant or a client. Then allocate it to invoices or to accepted claim lines. Client payments get a receipt number.</p>
          </div>
          <PaymentForm payers={((payers ?? []) as { id: string; name: string; client_id: string | null }[]).map((p) => ({ id: p.id, label: p.client_id ? `${p.name} (${C.get(p.client_id) ?? "client"})` : p.name, client_id: p.client_id }))} clients={[...C.entries()]} />
        </Card>
      ) : null}
      <Card className="flex flex-col gap-2 p-4">
        <h2 className="heading-sm">Payments</h2>
        {payments.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="text-left text-xs text-muted"><tr><th className="py-1">Received</th><th>From</th><th>How</th><th>Reference</th><th className="text-right">Amount</th><th className="text-right">Unallocated</th><th>Receipt</th></tr></thead>
              <tbody className="divide-y divide-line">
                {payments.map((p) => (
                  <tr key={p.id} className={p.status === "reversed" ? "text-muted line-through" : ""}>
                    <td className="py-1.5"><Link href={`/billing/payments/${p.id}`} className="font-semibold text-brand underline">{dmy(p.received_on)}</Link></td>
                    <td>{P.get(p.payer_id) ?? "Payer"}{p.client_id ? ` · ${C.get(p.client_id) ?? ""}` : ""}</td>
                    <td className="text-xs">{METHOD[p.method]}</td>
                    <td className="text-xs">{p.reference}</td>
                    <td className="text-right">{aud(p.amount)}</td>
                    <td className={`text-right ${p.status === "recorded" && (left.get(p.id) ?? 0) > 0 ? "font-semibold text-warn" : ""}`}>{p.status === "reversed" ? "Reversed" : aud(left.get(p.id) ?? 0)}</td>
                    <td className="text-xs">{p.receipt_number ?? ""}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No payments yet.</p>}
      </Card>
    </div>
  );
}

// Money owed on issued invoices by age (from the due date), and accepted claim amounts unpaid.
async function AgedDebtors() {
  const supabase = await createClient();
  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
  const [{ data: inv }, { data: ci }] = await Promise.all([
    supabase.from("invoice_balances").select("invoice_id, client_id, number, balance, due_date").gt("balance", 0),
    supabase.from("claim_item_balances").select("claim_id, accepted, paid, written_off, claimed_value, outcome"),
  ]);
  const rows = (inv ?? []) as { invoice_id: string; balance: number; due_date: string | null }[];
  const days = (d: string | null) => (d ? Math.floor((Date.parse(today) - Date.parse(d)) / 86400000) : 0);
  const b = { current: 0, d30: 0, d60: 0, d90: 0 };
  for (const r of rows) { const n = days(r.due_date); const v = Number(r.balance); if (n <= 0) b.current += v; else if (n <= 30) b.d30 += v; else if (n <= 60) b.d60 += v; else b.d90 += v; }
  const cl = (ci ?? []) as { accepted: number; paid: number; written_off: number; claimed_value: number; outcome: string | null }[];
  const awaitingResult = cl.filter((c) => !c.outcome).reduce((a, c) => a + Number(c.claimed_value), 0);
  const unpaid = cl.reduce((a, c) => a + Math.max(Number(c.accepted) - Number(c.paid) - Number(c.written_off), 0), 0);
  return (
    <Card className="flex flex-col gap-2 p-4">
      <h2 className="heading-sm">Money owed</h2>
      <div className="relative overflow-x-auto">
        <table className="w-full min-w-[560px] text-sm">
          <thead className="text-left text-xs text-muted"><tr><th className="py-1">Client invoices</th><th className="text-right">Not yet due</th><th className="text-right">1-30 days overdue</th><th className="text-right">31-60</th><th className="text-right">Over 60</th></tr></thead>
          <tbody><tr><td className="py-1.5">{rows.length} open</td><td className="text-right">{aud(b.current)}</td><td className="text-right">{aud(b.d30)}</td><td className="text-right">{aud(b.d60)}</td><td className={`text-right ${b.d90 > 0 ? "font-semibold text-danger" : ""}`}>{aud(b.d90)}</td></tr></tbody>
        </table>
      </div>
      <p className="text-sm">Government claims: <span className="font-semibold">{aud(awaitingResult)}</span> submitted and waiting for a result; <span className="font-semibold">{aud(unpaid)}</span> accepted and not yet paid.</p>
    </Card>
  );
}

export async function ReconciliationTab() {
  const supabase = await createClient();
  const [{ data: lines, error }, { data: recs }, { data: pays }, { data: refs }, canRec] = await Promise.all([
    supabase.from("bank_statement_lines").select("id, statement_date, amount, description, reference, status, payment_id, refund_id, exclude_reason").order("statement_date", { ascending: false }).limit(500),
    supabase.from("bank_reconciliations").select("id, period_from, period_to, opening_balance, closing_balance, status, completed_at").order("period_from", { ascending: false }),
    supabase.from("payments").select("id, amount, received_on, reference, payer_id").eq("status", "recorded").order("received_on", { ascending: false }).limit(1000),
    supabase.from("refunds").select("id, amount, paid_on, paid_reference").eq("status", "paid").limit(500),
    canBill("reconcile"),
  ]);
  if (error) return <Card className="p-5 text-sm text-muted">Reconciliation isn&apos;t set up yet (update 164).</Card>;
  const L = (lines ?? []) as { id: string; statement_date: string; amount: number; description: string; reference: string; status: string; payment_id: string | null; refund_id: string | null; exclude_reason: string }[];
  const usedPay = new Set(L.map((l) => l.payment_id).filter(Boolean));
  const usedRef = new Set(L.map((l) => l.refund_id).filter(Boolean));
  const P = (pays ?? []) as { id: string; amount: number; received_on: string; reference: string }[];
  const R = (refs ?? []) as { id: string; amount: number; paid_on: string; paid_reference: string }[];
  const label = (l: (typeof L)[number]) => l.payment_id ? `Payment ${P.find((p) => p.id === l.payment_id)?.reference || dmy(P.find((p) => p.id === l.payment_id)?.received_on)}` : l.refund_id ? "Refund paid" : l.exclude_reason;
  const R2 = (recs ?? []) as { id: string; period_from: string; period_to: string; opening_balance: number; closing_balance: number; status: string; completed_at: string | null }[];
  return (
    <div className="flex flex-col gap-4">
      {canRec ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Import a bank statement</h2>
            <p className="text-sm text-muted">Each line is matched to one payment or refund of the same amount, or excluded with a reason (bank fees, money that isn&apos;t billing). Lines already imported are skipped.</p>
          </div>
          <BankImport />
        </Card>
      ) : null}
      <Card className="flex flex-col gap-2 p-4">
        <h2 className="heading-sm">Bank lines ({L.filter((l) => l.status === "unmatched").length} to match)</h2>
        {L.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {L.map((l) => (
              <li key={l.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <span className="w-24">{dmy(l.statement_date)}</span>
                <span className={`w-28 text-right font-semibold ${Number(l.amount) < 0 ? "text-danger" : ""}`}>{aud(l.amount)}</span>
                <span className="min-w-40 flex-1 text-xs">{l.description}{l.reference ? ` · ${l.reference}` : ""}</span>
                <span className="text-xs">{l.status === "unmatched" ? "Unmatched" : l.status === "matched" ? `Matched: ${label(l)}` : `Excluded: ${l.exclude_reason}`}</span>
                {canRec ? <BankLineActions id={l.id} status={l.status} suggestions={[
                  ...P.filter((p) => !usedPay.has(p.id) && Number(p.amount) === Number(l.amount)).map((p) => ({ kind: "payment" as const, id: p.id, label: `Payment ${dmy(p.received_on)} ${p.reference}` })),
                  ...R.filter((r) => !usedRef.has(r.id) && -Number(r.amount) === Number(l.amount)).map((r) => ({ kind: "refund" as const, id: r.id, label: `Refund paid ${dmy(r.paid_on)} ${r.paid_reference}` })),
                ]} /> : null}
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No bank lines imported yet.</p>}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Reconciliations</h2>
          <p className="text-sm text-muted">A period is completed when every bank line in it is matched or excluded and the opening balance plus the lines equals the closing balance. Completed periods never change.</p>
        </div>
        {R2.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {R2.map((r) => (
              <li key={r.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <span className="min-w-48 flex-1 font-semibold">{dmy(r.period_from)} to {dmy(r.period_to)}</span>
                <span className="text-xs">opening {aud(r.opening_balance)} · closing {aud(r.closing_balance)}</span>
                <span className="text-xs font-semibold">{r.status === "completed" ? `Completed ${dmy(r.completed_at)}` : "Draft"}</span>
                {r.status === "draft" && canRec ? <CompleteReconciliation id={r.id} /> : null}
              </li>
            ))}
          </ul>
        ) : null}
        {canRec ? <ReconciliationForm /> : null}
      </Card>
    </div>
  );
}

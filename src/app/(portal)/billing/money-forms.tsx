// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { csvRows } from "@/lib/claim-fields";
import {
  acceptRemaining, allocate, completeReconciliation, creditNoteStep, decideWriteOff, importBankLines, issueReceipt, matchBankLine, prepareCreditNote, proposeRefund, proposeWriteOff,
  recordPayment, recordResult, refundStep, resubmitClaim, reversePayment, saveReconciliation,
} from "./money-actions";

// cmeprojects (update 164): forms for claim results, payments, credit notes, refunds,
// write-offs and bank reconciliation. The database enforces every rule.
const field = "flex flex-col gap-1 text-xs font-medium";
const linkBtn = "text-xs font-semibold text-brand underline disabled:opacity-50";
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));
function useRun() {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [state, setState] = useState<FormState>(null);
  const run = (fn: () => Promise<FormState>, after?: (r: FormState) => void) =>
    start(async () => {
      const r = await fn();
      setState(r);
      if (!r?.error) {
        after?.(r);
        router.refresh();
      }
    });
  return { pending, state, run };
}
function Msg({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

// ---- Claim results ----
export function ResultForm({ claimId, itemId, claimed, correctsId }: { claimId: string; itemId: string; claimed: number; correctsId?: string }) {
  const [f, setF] = useState({ outcome: "accepted", accepted: "", code: "", reason: "", reference: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-1">
      <div className="flex flex-wrap items-end gap-2">
        <label className={field}>{correctsId ? "Corrected result" : "Result"}
          <select value={f.outcome} onChange={(e) => setF((o) => ({ ...o, outcome: e.target.value }))} className={inputClass}>
            <option value="accepted">Accepted ({aud(claimed)})</option><option value="partly_accepted">Partly accepted</option><option value="rejected">Rejected</option>
          </select>
        </label>
        {f.outcome === "partly_accepted" ? <label className={field}>Amount accepted<input value={f.accepted} onChange={(e) => setF((o) => ({ ...o, accepted: e.target.value }))} inputMode="decimal" className={`${inputClass} w-28`} /></label> : null}
        {f.outcome !== "accepted" || correctsId ? (
          <>
            <label className={field}>Code<input value={f.code} maxLength={60} onChange={(e) => setF((o) => ({ ...o, code: e.target.value }))} className={`${inputClass} w-24`} /></label>
            <label className={`${field} min-w-48 flex-1`}>{correctsId ? "Why it's corrected" : "Reason given"}<input value={f.reason} maxLength={1000} onChange={(e) => setF((o) => ({ ...o, reason: e.target.value }))} className={inputClass} /></label>
          </>
        ) : null}
        <label className={field}>Remittance or result reference<input value={f.reference} maxLength={120} onChange={(e) => setF((o) => ({ ...o, reference: e.target.value }))} className={`${inputClass} w-40`} /></label>
        <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => recordResult(claimId, itemId, { ...f, correctsId: correctsId ?? "" }))}>Save</Button>
      </div>
      <Msg state={state} />
    </div>
  );
}

export function ClaimResultActions({ claimId, canSubmit, canPrepare, anyPending, anyRejected }: { claimId: string; canSubmit: boolean; canPrepare: boolean; anyPending: boolean; anyRejected: boolean }) {
  const router = useRouter();
  const [ref, setRef] = useState("");
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-end gap-2">
        {canSubmit && anyPending ? (
          <>
            <label className={field}>Remittance or result reference<input value={ref} maxLength={120} onChange={(e) => setRef(e.target.value)} className={`${inputClass} w-44`} /></label>
            <Button type="button" size="sm" variant="outline" disabled={pending}
              onClick={async () => { if (await askConfirm("Record every line without a result as accepted in full?", { action: "Accept all" })) run(() => acceptRemaining(claimId, ref)); }}>Accept the rest in full</Button>
          </>
        ) : null}
        {canPrepare && anyRejected ? (
          <Button type="button" size="sm" disabled={pending} onClick={() => run(() => resubmitClaim(claimId), (r) => { const id = (r as { id?: string })?.id; if (id) router.push(`/billing/claims/${id}`); })}>Claim rejected lines again</Button>
        ) : null}
      </div>
      <p className="text-xs text-muted">Only fully rejected lines are claimed again, in a replacement claim linked to this one, after the cause is fixed. Accepted amounts are never claimed twice. A shortfall that won&apos;t be recovered can be written off.</p>
      <Msg state={state} />
    </div>
  );
}

// ---- Payments ----
type Opt = [string, string];
export function PaymentForm({ payers, clients }: { payers: { id: string; label: string; client_id: string | null }[]; clients: Opt[] }) {
  const router = useRouter();
  const blank = { payer_id: "", client_id: "", received_on: "", amount: "", method: "eft", reference: "", notes: "" };
  const [f, setF] = useState(blank);
  const { pending, state, run } = useRun();
  const payer = payers.find((p) => p.id === f.payer_id);
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <label className={field}>Paid by
          <select value={f.payer_id} onChange={(e) => { const p = payers.find((x) => x.id === e.target.value); setF((o) => ({ ...o, payer_id: e.target.value, client_id: p?.client_id ?? "", method: p && !p.client_id && /Services Australia|National Disability/.test(p.label) ? "government_remittance" : o.method })); }} className={inputClass}>
            <option value="">Choose</option>{payers.map((p) => <option key={p.id} value={p.id}>{p.label}</option>)}
          </select>
        </label>
        {payer && !payer.client_id ? (
          <label className={field}>For one client (optional)
            <select value={f.client_id} onChange={(e) => setF((o) => ({ ...o, client_id: e.target.value }))} className={inputClass}><option value="">Several or none</option>{clients.map(([k, l]) => <option key={k} value={k}>{l}</option>)}</select>
          </label>
        ) : null}
        <label className={field}>Received on<DateInput value={f.received_on} onChange={(e) => setF((o) => ({ ...o, received_on: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Amount (AUD)<input value={f.amount} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, amount: e.target.value }))} className={inputClass} /></label>
        <label className={field}>How
          <select value={f.method} onChange={(e) => setF((o) => ({ ...o, method: e.target.value }))} className={inputClass}>
            <option value="eft">Bank transfer</option><option value="bpay">BPAY</option><option value="card">Card</option><option value="cash">Cash</option><option value="cheque">Cheque</option><option value="government_remittance">Government remittance</option><option value="other">Other</option>
          </select>
        </label>
        <label className={field}>Reference<input value={f.reference} maxLength={120} onChange={(e) => setF((o) => ({ ...o, reference: e.target.value }))} className={inputClass} /></label>
        <label className={`${field} sm:col-span-2`}>Notes<input value={f.notes} maxLength={1000} onChange={(e) => setF((o) => ({ ...o, notes: e.target.value }))} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => recordPayment(f), (r) => { const id = (r as { id?: string })?.id; if (id) router.push(`/billing/payments/${id}`); })}>Record payment</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function AllocateForm({ paymentId, left, targets }: { paymentId: string; left: number; targets: { kind: "invoice" | "claim_item"; id: string; label: string; owed: number }[] }) {
  const [amounts, setAmounts] = useState<Record<string, string>>({});
  const { pending, state, run } = useRun();
  const total = Object.values(amounts).reduce((a, v) => a + (Number(v) || 0), 0);
  const fill = () => {
    let rest = left;
    const next: Record<string, string> = {};
    for (const t of targets) { if (rest <= 0) break; const n = Math.min(rest, t.owed); next[t.id] = n.toFixed(2); rest = Math.round((rest - n) * 100) / 100; }
    setAmounts(next);
  };
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-3 text-sm">
        <span>Left to allocate: <span className="font-semibold">{aud(left)}</span> · entered {aud(total)}</span>
        <button type="button" className={linkBtn} onClick={fill}>Fill oldest first</button>
      </div>
      <ul className="divide-y divide-line rounded-md border border-line text-sm">
        {targets.map((t) => (
          <li key={t.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
            <span className="min-w-48 flex-1">{t.label}</span>
            <span className="text-xs text-muted">owes {aud(t.owed)}</span>
            <input value={amounts[t.id] ?? ""} onChange={(e) => setAmounts((a) => ({ ...a, [t.id]: e.target.value }))} inputMode="decimal" aria-label={`Amount for ${t.label}`} className={`${inputClass} w-28`} />
          </li>
        ))}
      </ul>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => allocate(paymentId, targets.filter((t) => amounts[t.id]).map((t) => ({ kind: t.kind, id: t.id, amount: amounts[t.id] }))), () => setAmounts({}))}>Save allocations</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function PaymentActions({ id, canReverse, canRefund, unallocated, receipt, hasReceiptPdf }: { id: string; canReverse: boolean; canRefund: boolean; unallocated: number; receipt: string | null; hasReceiptPdf: boolean }) {
  const [reason, setReason] = useState("");
  const [refund, setRefund] = useState({ amount: "", reason: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-3">
        {receipt && hasReceiptPdf ? <a href={`/billing/payments/${id}/receipt`} className="text-sm font-semibold text-brand underline">Download receipt {receipt}</a> : null}
        {receipt && !hasReceiptPdf ? <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => issueReceipt(id))}>Make receipt now</Button> : null}
      </div>
      {canRefund && unallocated > 0 ? (
        <details>
          <summary className={`${linkBtn} cursor-pointer`}>Propose a refund of the unallocated {aud(unallocated)}</summary>
          <div className="mt-2 flex flex-wrap items-end gap-2">
            <label className={field}>Amount<input value={refund.amount} inputMode="decimal" onChange={(e) => setRefund((o) => ({ ...o, amount: e.target.value }))} className={`${inputClass} w-28`} /></label>
            <label className={`${field} min-w-56 flex-1`}>Why<input value={refund.reason} maxLength={1000} onChange={(e) => setRefund((o) => ({ ...o, reason: e.target.value }))} className={inputClass} /></label>
            <Button type="button" size="sm" disabled={pending} onClick={() => run(() => proposeRefund({ payment_id: id }, refund.amount, refund.reason, `/billing/payments/${id}`))}>Propose refund</Button>
          </div>
        </details>
      ) : null}
      {canReverse ? (
        <details>
          <summary className={`${linkBtn} cursor-pointer`}>Reverse this payment (for example, dishonoured)</summary>
          <div className="mt-2 flex flex-wrap items-end gap-2">
            <label className={`${field} min-w-56 flex-1`}>Why<input value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} className={inputClass} /></label>
            <Button type="button" size="sm" variant="danger" disabled={pending}
              onClick={async () => { if (await askConfirm("Reverse this payment? It's kept, and its allocations no longer count.", { action: "Reverse", danger: true })) run(() => reversePayment(id, reason)); }}>Reverse payment</Button>
          </div>
        </details>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

// ---- Credit notes, write-offs, refunds on an invoice ----
export function CreditNoteForm({ invoiceId, lines }: { invoiceId: string; lines: { id: string; label: string; left: number }[] }) {
  const [reason, setReason] = useState("");
  const [amounts, setAmounts] = useState<Record<string, string>>({});
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <label className={field}>Why the credit is given<input value={reason} maxLength={1000} onChange={(e) => setReason(e.target.value)} className={inputClass} /></label>
      <ul className="divide-y divide-line rounded-md border border-line text-sm">
        {lines.map((l) => (
          <li key={l.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
            <span className="min-w-48 flex-1">{l.label}</span>
            <span className="text-xs text-muted">up to {aud(l.left)}</span>
            <button type="button" className={linkBtn} onClick={() => setAmounts((a) => ({ ...a, [l.id]: l.left.toFixed(2) }))}>All</button>
            <input value={amounts[l.id] ?? ""} onChange={(e) => setAmounts((a) => ({ ...a, [l.id]: e.target.value }))} inputMode="decimal" aria-label={`Credit for ${l.label}`} className={`${inputClass} w-28`} />
          </li>
        ))}
      </ul>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => prepareCreditNote(invoiceId, reason, lines.filter((l) => amounts[l.id]).map((l) => ({ id: l.id, amount: amounts[l.id] }))), () => { setAmounts({}); setReason(""); })}>Prepare credit note</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function CreditNoteActions({ id, invoiceId, status, canApprove, canIssue, canCancel, mine, hasPdf }: { id: string; invoiceId: string; status: string; canApprove: boolean; canIssue: boolean; canCancel: boolean; mine: boolean; hasPdf: boolean }) {
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-wrap items-center gap-2">
      {status === "draft" && canApprove ? (mine ? <span className="text-xs text-muted">Someone else approves your credit note.</span> : <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => creditNoteStep(id, invoiceId, "approved"))}>Approve</button>) : null}
      {status === "approved" && canIssue ? <button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Issue this credit note? It gets the next number and never changes after this.", { action: "Issue" })) run(() => creditNoteStep(id, invoiceId, "issued")); }}>Issue</button> : null}
      {(status === "draft" || status === "approved") && canCancel ? <button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Cancel this credit note? It's kept, never numbered.", { action: "Cancel", danger: true })) run(() => creditNoteStep(id, invoiceId, "cancelled", "Not needed")); }}>Cancel</button> : null}
      {hasPdf ? <a href={`/billing/credit-notes/${id}/pdf`} className="text-xs font-semibold text-brand underline">PDF</a> : null}
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

export function WriteOffForm({ target, owed, back }: { target: { invoice_id?: string; claim_item_id?: string }; owed: number; back: string }) {
  const [f, setF] = useState({ amount: "", reason: "" });
  const { pending, state, run } = useRun();
  return (
    <details>
      <summary className={`${linkBtn} cursor-pointer`}>Propose a write-off</summary>
      <div className="mt-2 flex flex-wrap items-end gap-2">
        <label className={field}>Amount (up to {aud(owed)})<input value={f.amount} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, amount: e.target.value }))} className={`${inputClass} w-28`} /></label>
        <label className={`${field} min-w-56 flex-1`}>Why<input value={f.reason} maxLength={1000} onChange={(e) => setF((o) => ({ ...o, reason: e.target.value }))} className={inputClass} /></label>
        <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => proposeWriteOff(target, f.amount, f.reason, back))}>Propose</Button>
      </div>
      <Msg state={state} />
    </details>
  );
}

export function InvoiceRefundForm({ invoiceId, credit }: { invoiceId: string; credit: number }) {
  const [f, setF] = useState({ amount: credit.toFixed(2), reason: "" });
  const { pending, state, run } = useRun();
  return (
    <details>
      <summary className={`${linkBtn} cursor-pointer`}>Propose a refund of the {aud(credit)} credit</summary>
      <div className="mt-2 flex flex-wrap items-end gap-2">
        <label className={field}>Amount<input value={f.amount} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, amount: e.target.value }))} className={`${inputClass} w-28`} /></label>
        <label className={`${field} min-w-56 flex-1`}>Why<input value={f.reason} maxLength={1000} onChange={(e) => setF((o) => ({ ...o, reason: e.target.value }))} className={inputClass} /></label>
        <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => proposeRefund({ invoice_id: invoiceId }, f.amount, f.reason, `/billing/invoices/${invoiceId}`))}>Propose refund</Button>
      </div>
      <Msg state={state} />
    </details>
  );
}

export function DecideButtons({ kind, id, status, mine, canDecide }: { kind: "write_off" | "refund"; id: string; status: string; mine: boolean; canDecide: boolean }) {
  const [paid, setPaid] = useState({ paid_on: "", reference: "" });
  const [reason, setReason] = useState("");
  const { pending, state, run } = useRun();
  if (!canDecide) return null;
  const waiting = kind === "write_off" ? ["proposed", "first_approved"].includes(status) : status === "proposed";
  return (
    <span className="inline-flex flex-col gap-1">
      <span className="inline-flex flex-wrap items-end gap-2">
        {waiting && !mine ? <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => (kind === "write_off" ? decideWriteOff(id, true) : refundStep(id, "approved")))}>Approve</button> : null}
        {waiting && mine ? <span className="text-xs text-muted">Someone else approves.</span> : null}
        {waiting ? (
          <>
            <input value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} placeholder="Reason to reject" aria-label="Reason to reject" className={`${inputClass} w-40`} />
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => (kind === "write_off" ? decideWriteOff(id, false, reason) : refundStep(id, "rejected", { reason })))}>Reject</button>
          </>
        ) : null}
        {kind === "refund" && status === "approved" ? (
          <>
            <DateInput value={paid.paid_on} onChange={(e) => setPaid((o) => ({ ...o, paid_on: e.target.value }))} className={`${inputClass} w-36`} aria-label="Date paid" />
            <input value={paid.reference} onChange={(e) => setPaid((o) => ({ ...o, reference: e.target.value }))} maxLength={120} placeholder="Payment reference" aria-label="Payment reference" className={`${inputClass} w-40`} />
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => refundStep(id, "paid", paid))}>Record paid</button>
          </>
        ) : null}
      </span>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : state?.message ? <span className="text-xs text-success">{state.message}</span> : null}
    </span>
  );
}

// ---- Bank reconciliation ----
function col(head: string[], ...res: RegExp[]) {
  const h = head.map((x) => x.toLowerCase().replace(/[^a-z]/g, ""));
  for (const re of res) { const i = h.findIndex((x) => re.test(x)); if (i >= 0) return i; }
  return -1;
}
function isoDate(s: string) {
  const t = s.trim();
  let m = t.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (m) return `${m[3]}-${m[2].padStart(2, "0")}-${m[1].padStart(2, "0")}`;
  m = t.match(/^(\d{4})-(\d{2})-(\d{2})/);
  return m ? `${m[1]}-${m[2]}-${m[3]}` : "";
}
export function BankImport() {
  const [lines, setLines] = useState<{ date: string; amount: number; description: string; reference: string }[]>([]);
  const [batch, setBatch] = useState("");
  const [found, setFound] = useState("");
  const { pending, state, run } = useRun();
  const onFile = async (file: File | undefined) => {
    if (!file) return;
    const rows = csvRows(await file.text());
    const head = rows[0] ?? [];
    const c = { date: col(head, /^date$/, /date/), amount: col(head, /^amount$/, /amount/), credit: col(head, /^credit$/, /deposit/), debit: col(head, /^debit$/, /withdrawal/), desc: col(head, /description|narrative|details/), ref: col(head, /reference/) };
    const num = (s: string | undefined) => Number(String(s ?? "").replace(/[$,\s]/g, "")) || 0;
    const list = rows.slice(1).map((r) => ({
      date: c.date >= 0 ? isoDate(r[c.date] ?? "") : "",
      amount: c.amount >= 0 ? num(r[c.amount]) : num(r[c.credit]) - Math.abs(num(r[c.debit])),
      description: c.desc >= 0 ? r[c.desc] ?? "" : "", reference: c.ref >= 0 ? r[c.ref] ?? "" : "",
    })).filter((l) => l.date && l.amount);
    setLines(list); setBatch(file.name);
    setFound(c.date < 0 ? "No date column found (the first row must hold the column names)." : `${list.length} lines found (dates as dd/mm/yyyy or yyyy-mm-dd; money in as positive, out as negative).`);
  };
  return (
    <div className="flex flex-col gap-2">
      <label className={field}>Bank statement (CSV from your bank)<input type="file" accept=".csv,text/csv" onChange={(e) => onFile(e.target.files?.[0])} className="text-sm" /></label>
      {found ? <p className="text-xs text-muted">{found}</p> : null}
      <div><Button type="button" size="sm" disabled={pending || !lines.length} onClick={() => run(() => importBankLines(batch, lines), () => setLines([]))}>Import lines</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function BankLineActions({ id, status, suggestions }: { id: string; status: string; suggestions: { kind: "payment" | "refund"; id: string; label: string }[] }) {
  const [pick, setPick] = useState(suggestions[0] ? `${suggestions[0].kind}:${suggestions[0].id}` : "");
  const [reason, setReason] = useState("");
  const { pending, state, run } = useRun();
  if (status !== "unmatched") {
    return (
      <span className="inline-flex flex-col">
        <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => matchBankLine(id, { status: "unmatched" }))}>Unmatch</button>
        {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
      </span>
    );
  }
  const [kind, target] = pick.split(":");
  return (
    <span className="inline-flex flex-col gap-1">
      <span className="inline-flex flex-wrap items-end gap-2">
        {suggestions.length ? (
          <>
            <select value={pick} onChange={(e) => setPick(e.target.value)} className={`${inputClass} w-64`} aria-label="Match to">
              {suggestions.map((s) => <option key={s.id} value={`${s.kind}:${s.id}`}>{s.label}</option>)}
            </select>
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => matchBankLine(id, { status: "matched", payment_id: kind === "payment" ? target : undefined, refund_id: kind === "refund" ? target : undefined }))}>Match</button>
          </>
        ) : <span className="text-xs text-muted">No payment or refund of this amount yet.</span>}
        <input value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} placeholder="Reason to exclude" aria-label="Reason to exclude" className={`${inputClass} w-40`} />
        <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => matchBankLine(id, { status: "excluded", reason }))}>Exclude</button>
      </span>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

export function ReconciliationForm() {
  const [f, setF] = useState({ period_from: "", period_to: "", opening: "", closing: "", notes: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-5">
        <label className={field}>From<DateInput value={f.period_from} onChange={(e) => setF((o) => ({ ...o, period_from: e.target.value }))} className={inputClass} /></label>
        <label className={field}>To<DateInput value={f.period_to} onChange={(e) => setF((o) => ({ ...o, period_to: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Opening balance<input value={f.opening} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, opening: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Closing balance<input value={f.closing} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, closing: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Notes<input value={f.notes} maxLength={1000} onChange={(e) => setF((o) => ({ ...o, notes: e.target.value }))} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => saveReconciliation(f))}>Start reconciliation</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function CompleteReconciliation({ id }: { id: string }) {
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-col">
      <button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Complete this reconciliation? Its bank lines and matches won't change after this.", { action: "Complete" })) run(() => completeReconciliation(id)); }}>Complete</button>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

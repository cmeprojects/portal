// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { addQuarterBudget, approveLines, approveQuarterBudget, closeQuarter, decideDelivery, decideLedgerEntry, makeLines, proposeLedgerEntry, verifyFigure, voidLine } from "./actions";

// cmeprojects (update 162): Billing module forms. The database enforces every rule.
const field = "flex flex-col gap-1 text-xs font-medium";
const linkBtn = "text-xs font-semibold text-brand underline disabled:opacity-50";
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));
function useRun() {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [state, setState] = useState<FormState>(null);
  const run = (fn: () => Promise<FormState>, after?: () => void) =>
    start(async () => {
      const r = await fn();
      setState(r);
      if (!r?.error) {
        after?.();
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

export function MakeLinesForm({ from, to }: { from: string; to: string }) {
  const [f, setF] = useState({ from, to });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-end gap-2">
        <label className={field}>From<DateInput value={f.from} onChange={(e) => setF((o) => ({ ...o, from: e.target.value }))} className={inputClass} /></label>
        <label className={field}>To<DateInput value={f.to} onChange={(e) => setF((o) => ({ ...o, to: e.target.value }))} className={inputClass} /></label>
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => makeLines(f.from, f.to))}>{pending ? "Making lines…" : "Make billing lines"}</Button>
      </div>
      <p className="text-xs text-muted">From delivered shifts (approved timesheet and service record, or a delivery decision) and chargeable cancellations, under each service&apos;s approved billing terms. Lines already made are skipped. Up to three months at a time.</p>
      <Msg state={state} />
    </div>
  );
}

export type LineRow = {
  id: string; status: string; kind: string; client: string; clientId: string; service: string; date: string; time: string; band: string; quantity: number; unit: string; unit_price: number;
  amount: number; client_share: number | null; government_share: number | null; scheme: string; over_budget: boolean; calc: string; made: string; approved: string; voided: string; corrects: boolean; mine: boolean;
};

export function LinesTable({ lines, canApprove }: { lines: LineRow[]; canApprove: boolean }) {
  const [sel, setSel] = useState<Set<string>>(new Set());
  const [note, setNote] = useState("");
  const { pending, state, run } = useRun();
  const drafts = lines.filter((l) => l.status === "draft" && !l.mine);
  const toggle = (id: string) => setSel((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  const total = lines.filter((l) => l.status !== "voided").reduce((t, l) => t + Number(l.amount), 0);
  return (
    <div className="flex flex-col gap-2">
      {canApprove && drafts.length ? (
        <div className="flex flex-wrap items-end gap-2 rounded-md bg-page px-3 py-2">
          <label className="flex items-center gap-2 text-xs font-medium">
            <input type="checkbox" checked={sel.size === drafts.length && drafts.length > 0} onChange={(e) => setSel(e.target.checked ? new Set(drafts.map((d) => d.id)) : new Set())} /> Select all I can approve ({drafts.length})
          </label>
          <label className={`${field} min-w-48 flex-1`}>Note (needed for over-budget lines)<input value={note} onChange={(e) => setNote(e.target.value)} maxLength={1000} className={inputClass} /></label>
          <Button type="button" size="sm" disabled={pending || sel.size === 0} onClick={async () => { if (await askConfirm(`Approve ${sel.size} line(s)? They're charged to their funding and never change after this.`, { action: "Approve" })) run(() => approveLines([...sel], note), () => setSel(new Set())); }}>
            Approve selected ({sel.size})
          </Button>
        </div>
      ) : null}
      <Msg state={state} />
      {lines.length ? (
        <div className="relative overflow-x-auto">
          <table className="w-full min-w-[60rem] text-left text-sm">
            <thead className="text-xs text-muted">
              <tr>
                {canApprove ? <th className="py-1 pr-2"><span className="sr-only">Select</span></th> : null}
                <th className="py-1 pr-2">Client · service</th><th className="py-1 pr-2">Date</th><th className="py-1 pr-2">Band</th>
                <th className="py-1 pr-2 text-right">Qty</th><th className="py-1 pr-2 text-right">Price</th><th className="py-1 pr-2 text-right">Amount</th>
                <th className="py-1 pr-2 text-right">Client</th><th className="py-1 pr-2 text-right">Funding</th><th className="py-1 pr-2">Status</th><th className="py-1"><span className="sr-only">Details</span></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {lines.map((l) => <LineRowView key={l.id} l={l} canApprove={canApprove} selected={sel.has(l.id)} toggle={() => toggle(l.id)} />)}
            </tbody>
            <tfoot><tr><td colSpan={canApprove ? 6 : 5} className="py-1 pr-2 text-right text-xs font-semibold">Total (not voided)</td><td className="py-1 pr-2 text-right font-semibold">{aud(total)}</td></tr></tfoot>
          </table>
        </div>
      ) : <p className="text-sm text-muted">No billing lines for this filter.</p>}
    </div>
  );
}

function LineRowView({ l, canApprove, selected, toggle }: { l: LineRow; canApprove: boolean; selected: boolean; toggle: () => void }) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("wrong_rate");
  const [vnote, setVnote] = useState("");
  const { pending, state, run } = useRun();
  const tone = l.status === "approved" ? "bg-good-soft" : l.status === "voided" ? "bg-line" : "bg-warn-soft";
  return (
    <>
      <tr className={l.status === "voided" ? "text-muted line-through" : ""}>
        {canApprove ? <td className="py-1 pr-2">{l.status === "draft" && !l.mine ? <input type="checkbox" aria-label={`Select ${l.client} ${l.date} ${l.band}`} checked={selected} onChange={toggle} /> : null}</td> : null}
        <td className="py-1 pr-2"><a href={`/settings/clients/${l.clientId}?tab=services#services`} className="font-semibold text-brand underline">{l.client}</a><span className="block text-xs text-muted">{l.service}{l.kind === "cancellation" ? " · late cancellation" : ""}{l.corrects ? " · corrected line" : ""}</span></td>
        <td className="py-1 pr-2 text-xs">{l.date}<span className="block text-muted">{l.time}</span></td>
        <td className="py-1 pr-2 text-xs">{l.band}</td>
        <td className="py-1 pr-2 text-right">{Number(l.quantity)} {l.unit === "hour" ? "h" : l.unit}</td>
        <td className="py-1 pr-2 text-right">{aud(l.unit_price)}</td>
        <td className="py-1 pr-2 text-right font-semibold">{aud(l.amount)}{l.over_budget ? <span className="block text-[11px] font-semibold text-danger">over budget</span> : null}</td>
        <td className="py-1 pr-2 text-right">{aud(l.client_share)}</td>
        <td className="py-1 pr-2 text-right">{aud(l.government_share)}</td>
        <td className="py-1 pr-2"><span className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${tone}`}>{l.status === "draft" ? "To review" : l.status === "approved" ? "Approved" : "Voided"}</span></td>
        <td className="py-1"><button type="button" className={linkBtn} onClick={() => setOpen((o) => !o)}>{open ? "Hide" : "Details"}</button></td>
      </tr>
      {open ? (
        <tr>
          <td colSpan={canApprove ? 11 : 10} className="bg-page px-3 py-2 text-xs">
            <p className="whitespace-pre-line">{l.calc}</p>
            <p className="mt-1 text-muted">{[l.made, l.approved, l.voided].filter(Boolean).join(" · ")}</p>
            {canApprove && l.status !== "voided" ? (
              <div className="mt-2 flex flex-wrap items-end gap-2">
                <label className={field}>Void because
                  <select value={reason} onChange={(e) => setReason(e.target.value)} className={inputClass}>
                    <option value="wrong_rate">Wrong rate or price</option><option value="data_entry">Data entry</option><option value="not_delivered">Not delivered</option>
                    <option value="wrong_client">Wrong client</option><option value="grounds_accepted">Reasonable grounds accepted</option><option value="wrong_terms">Wrong billing terms</option><option value="other">Other</option>
                  </select>
                </label>
                <label className={`${field} min-w-48 flex-1`}>Note{reason === "other" ? " (needed)" : " (optional)"}<input value={vnote} onChange={(e) => setVnote(e.target.value)} maxLength={1000} className={inputClass} /></label>
                <Button type="button" size="sm" variant="danger" disabled={pending} onClick={async () => { if (await askConfirm(`Void this line? It's kept.${l.status === "approved" ? " Its charge is reversed in the ledger." : ""}`, { action: "Void", danger: true })) run(() => voidLine(l.id, reason, vnote)); }}>Void line</Button>
              </div>
            ) : null}
            {l.mine && l.status === "draft" ? <p className="mt-1 text-muted">You made this line, so someone else with the Billing approve right approves it.</p> : null}
            <Msg state={state} />
          </td>
        </tr>
      ) : null}
    </>
  );
}

export function DeliveryDecision({ shiftId }: { shiftId: string }) {
  const [reason, setReason] = useState("");
  const { pending, state, run } = useRun();
  return (
    <div className="mt-1 flex flex-col gap-1">
      <div className="flex flex-wrap items-end gap-2">
        <label className={`${field} min-w-48 flex-1`}>Reason for the decision<input value={reason} onChange={(e) => setReason(e.target.value)} maxLength={1000} className={inputClass} /></label>
        <Button type="button" size="sm" variant="outline" disabled={pending || !reason.trim()} onClick={() => run(() => decideDelivery(shiftId, "delivered", reason))}>Delivered</Button>
        <Button type="button" size="sm" variant="outline" disabled={pending || !reason.trim()} onClick={() => run(() => decideDelivery(shiftId, "not_delivered", reason))}>Not delivered</Button>
      </div>
      <Msg state={state} />
    </div>
  );
}

type Opt = [string, string];
export function QuarterBudgetForm({ enrolments, funding, quarters }: { enrolments: [string, string, string][]; funding: [string, string, string][]; quarters: Opt[] }) {
  const blank = { pick: enrolments[0] ? `${enrolments[0][1]}|${enrolments[0][0]}` : "", quarter_start: quarters[0]?.[0] ?? "", quarterly_amount: "", classification: "", start_date: "", funding_id: "", source: "" };
  const [f, setF] = useState(blank);
  const set = (k: keyof typeof blank, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  const [clientId, enrolmentId] = f.pick.split("|");
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>Client and program<select value={f.pick} onChange={(e) => set("pick", e.target.value)} className={inputClass}>{enrolments.map(([e, c, l]) => <option key={e} value={`${c}|${e}`}>{l}</option>)}</select></label>
        <label className={field}>Quarter<select value={f.quarter_start} onChange={(e) => set("quarter_start", e.target.value)} className={inputClass}>{quarters.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select></label>
        <label className={field}>Quarterly amount (AUD, full quarter)<input value={f.quarterly_amount} onChange={(e) => set("quarterly_amount", e.target.value)} inputMode="decimal" className={inputClass} /></label>
        <label className={field}>Classification (1-8)<input value={f.classification} onChange={(e) => set("classification", e.target.value)} inputMode="numeric" className={inputClass} /></label>
        <label className={field}>Started in the quarter on (for a mid-quarter start)<DateInput value={f.start_date} onChange={(e) => set("start_date", e.target.value)} className={inputClass} /></label>
        <label className={field}>Funding record (optional)<select value={f.funding_id} onChange={(e) => set("funding_id", e.target.value)} className={inputClass}><option value="">None</option>{funding.filter(([, c]) => c === clientId).map(([id, , l]) => <option key={id} value={id}>{l}</option>)}</select></label>
      </div>
      <label className={field}>Source<input value={f.source} onChange={(e) => set("source", e.target.value)} maxLength={300} placeholder="e.g. Services Australia budget notice, 2 Oct 2026" className={inputClass} /></label>
      <p className="text-xs text-muted">Care management, carryover in and the spendable amount are worked out from the verified figures. A mid-quarter start is pro rata from its start date.</p>
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending || !enrolmentId} onClick={() => run(() => addQuarterBudget({ ...f, client_id: clientId, enrolment_id: enrolmentId }), () => setF(blank))}>Add draft budget</Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

export function BudgetButtons({ id, status, canApprove, mine, ended }: { id: string; status: string; canApprove: boolean; mine: boolean; ended: boolean }) {
  const { pending, state, run } = useRun();
  if (!canApprove) return null;
  return (
    <span className="inline-flex flex-wrap items-center gap-2">
      {status === "draft" && !mine ? <Button type="button" size="sm" disabled={pending} onClick={async () => { if (await askConfirm("Approve this quarter budget? It's not changed after this.", { action: "Approve" })) run(() => approveQuarterBudget(id)); }}>Approve</Button> : null}
      {status === "draft" && mine ? <span className="text-xs text-muted">Someone else approves your budget.</span> : null}
      {status === "approved" && ended ? <Button type="button" size="sm" variant="outline" disabled={pending} onClick={async () => { if (await askConfirm("Close this quarter? The carryover and lapse are worked out and it never changes after this.", { action: "Close quarter" })) run(() => closeQuarter(id)); }}>Close quarter</Button> : null}
      <Msg state={state} />
    </span>
  );
}

export function LedgerEntryForm({ clients, accounts }: { clients: Opt[]; accounts: [string, string, string][] }) {
  const blank = { client_id: clients[0]?.[0] ?? "", entry_kind: "opening_balance", account: "", amount: "", entry_date: "", reason: "" };
  const [f, setF] = useState(blank);
  const set = (k: keyof typeof blank, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  const accs = accounts.filter(([, c]) => c === f.client_id).filter(([a]) => f.entry_kind !== "opening_balance" || a.startsWith("f:"));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>Client<select value={f.client_id} onChange={(e) => setF((o) => ({ ...o, client_id: e.target.value, account: "" }))} className={inputClass}>{clients.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select></label>
        <label className={field}>Entry<select value={f.entry_kind} onChange={(e) => setF((o) => ({ ...o, entry_kind: e.target.value, account: "" }))} className={inputClass}><option value="opening_balance">Opening balance (funding record)</option><option value="adjustment">Adjustment (+ or −)</option></select></label>
        <label className={field}>Funding account<select value={f.account} onChange={(e) => set("account", e.target.value)} className={inputClass}><option value="">Choose…</option>{accs.map(([a, , l]) => <option key={a} value={a}>{l}</option>)}</select></label>
        <label className={field}>Amount (AUD){f.entry_kind === "adjustment" ? " — negative reduces" : ""}<input value={f.amount} onChange={(e) => set("amount", e.target.value)} inputMode="decimal" className={inputClass} /></label>
        <label className={field}>As at<DateInput value={f.entry_date} onChange={(e) => set("entry_date", e.target.value)} className={inputClass} /></label>
      </div>
      <label className={field}>Source or reason<input value={f.reason} onChange={(e) => set("reason", e.target.value)} maxLength={1000} placeholder="e.g. Balance from the funding statement as at 1 Nov 2026" className={inputClass} /></label>
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => proposeLedgerEntry(f), () => setF(blank))}>Propose</Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

export function DecideEntry({ id }: { id: string }) {
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-wrap items-center gap-2">
      <Button type="button" size="sm" disabled={pending} onClick={() => run(() => decideLedgerEntry(id, true))}>Approve</Button>
      <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => decideLedgerEntry(id, false))}>Reject</button>
      <Msg state={state} />
    </span>
  );
}

export function FigureRow({ f, canApprove }: { f: { id: string; label: string; value: number; effective_from: string; status: string; source: string; as_at: string | null; checked: string }; canApprove: boolean }) {
  const [source, setSource] = useState(f.source);
  const [asAt, setAsAt] = useState(f.as_at ?? "");
  const { pending, state, run } = useRun();
  const ok = f.status === "verified";
  return (
    <div className={`rounded-md border px-3 py-2 text-sm ${ok ? "border-good/40" : "border-warn/40"}`}>
      <p className="font-semibold">{f.label}: {Number(f.value)}{f.label.includes("$") ? "" : ""} <span className="text-xs font-normal text-muted">from {f.effective_from.split("-").reverse().join("/")} · {ok ? `verified ${f.checked}` : "not verified"}</span></p>
      {canApprove ? (
        <div className="mt-1 grid gap-2 sm:grid-cols-[1fr_10rem_auto] sm:items-end">
          <label className={field}>Official source<input value={source} onChange={(e) => setSource(e.target.value)} disabled={ok} maxLength={1000} className={inputClass} /></label>
          <label className={field}>As at<DateInput value={asAt} onChange={(e) => setAsAt(e.target.value)} disabled={ok} className={inputClass} /></label>
          {ok ? <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => verifyFigure(f.id, { verified: false, source, asAt }))}>Unverify</button>
              : <Button type="button" size="sm" disabled={pending} onClick={() => run(() => verifyFigure(f.id, { verified: true, source, asAt }))}>Mark verified</Button>}
        </div>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

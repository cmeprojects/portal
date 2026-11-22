// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { addMarkupRule, addPathwayBudget, addSupplier, chargeStep, makeCharge, pathwayStep, recordSupplierInvoice, supplierInvoiceStep } from "./supplier-actions";

// cmeprojects (update 165): forms for suppliers, supplier invoices, client charges, pathway
// budgets and markup rules. The database enforces every rule.
const field = "flex flex-col gap-1 text-xs font-medium";
const linkBtn = "text-xs font-semibold text-brand underline disabled:opacity-50";
type Opt = [string, string];
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
function Sel({ label, value, onChange, options, blank }: { label: string; value: string; onChange: (v: string) => void; options: Opt[]; blank?: string }) {
  return (
    <label className={field}>{label}
      <select value={value} onChange={(e) => onChange(e.target.value)} className={inputClass}>
        {blank !== undefined ? <option value="">{blank}</option> : null}
        {options.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
      </select>
    </label>
  );
}

export function SupplierForm() {
  const blank = { name: "", kind: "subcontractor", abn: "", gst_registered: false, email: "", phone: "", address: "", bsb: "", account: "", account_name: "" };
  const [f, setF] = useState(blank);
  const { pending, state, run } = useRun();
  const set = (k: keyof typeof blank) => (e: React.ChangeEvent<HTMLInputElement>) => setF((o) => ({ ...o, [k]: e.target.value }));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>Name<input value={f.name} maxLength={200} onChange={set("name")} className={inputClass} /></label>
        <Sel label="Kind" value={f.kind} onChange={(v) => setF((o) => ({ ...o, kind: v }))} options={[["subcontractor", "Subcontractor (services)"], ["equipment", "Equipment"], ["home_modifications", "Home modifications"], ["other", "Other"]]} />
        <label className={field}>ABN<input value={f.abn} maxLength={14} inputMode="numeric" onChange={set("abn")} className={inputClass} /></label>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={f.gst_registered} onChange={(e) => setF((o) => ({ ...o, gst_registered: e.target.checked }))} /> Registered for GST</label>
        <label className={field}>Email<input type="email" value={f.email} maxLength={200} onChange={set("email")} className={inputClass} /></label>
        <label className={field}>Phone<input type="tel" value={f.phone} maxLength={30} onChange={set("phone")} className={inputClass} /></label>
        <label className={`${field} sm:col-span-3`}>Address<input value={f.address} maxLength={400} onChange={set("address")} className={inputClass} /></label>
        <label className={field}>BSB<input value={f.bsb} maxLength={7} inputMode="numeric" onChange={set("bsb")} className={inputClass} /></label>
        <label className={field}>Account number<input value={f.account} maxLength={10} inputMode="numeric" onChange={set("account")} className={inputClass} /></label>
        <label className={field}>Account name<input value={f.account_name} maxLength={120} onChange={set("account_name")} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => addSupplier(f), () => setF(blank))}>Add supplier</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function SupplierInvoiceForm({ suppliers, clients }: { suppliers: Opt[]; clients: Opt[] }) {
  const line = { description: "", client_id: "", service_date: "", amount: "", gst: "" };
  const [f, setF] = useState({ supplier_id: "", ref: "", invoice_date: "", due_date: "", note: "" });
  const [lines, setLines] = useState([{ ...line }]);
  const { pending, state, run } = useRun();
  const setLine = (i: number, k: keyof typeof line, v: string) => setLines((ls) => ls.map((l, j) => (j === i ? { ...l, [k]: v } : l)));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <Sel label="Supplier" value={f.supplier_id} onChange={(v) => setF((o) => ({ ...o, supplier_id: v }))} options={suppliers} blank="Choose" />
        <label className={field}>Their invoice number<input value={f.ref} maxLength={60} onChange={(e) => setF((o) => ({ ...o, ref: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Invoice date<DateInput value={f.invoice_date} onChange={(e) => setF((o) => ({ ...o, invoice_date: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Due date<DateInput value={f.due_date} onChange={(e) => setF((o) => ({ ...o, due_date: e.target.value }))} className={inputClass} /></label>
      </div>
      <ul className="flex flex-col gap-2">
        {lines.map((l, i) => (
          <li key={i} className="grid gap-2 rounded-md border border-line p-2 sm:grid-cols-[2fr_1.5fr_9rem_7rem_6rem]">
            <label className={field}>Description<input value={l.description} maxLength={300} onChange={(e) => setLine(i, "description", e.target.value)} className={inputClass} /></label>
            <Sel label="For client" value={l.client_id} onChange={(v) => setLine(i, "client_id", v)} options={clients} blank="No client" />
            <label className={field}>Service date<DateInput value={l.service_date} onChange={(e) => setLine(i, "service_date", e.target.value)} className={inputClass} /></label>
            <label className={field}>Amount (ex GST)<input value={l.amount} inputMode="decimal" onChange={(e) => setLine(i, "amount", e.target.value)} className={inputClass} /></label>
            <label className={field}>GST<input value={l.gst} inputMode="decimal" onChange={(e) => setLine(i, "gst", e.target.value)} className={inputClass} /></label>
          </li>
        ))}
      </ul>
      <div className="flex flex-wrap gap-3">
        <button type="button" className={linkBtn} onClick={() => setLines((ls) => [...ls, { ...line }])}>Add a line</button>
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => recordSupplierInvoice({ ...f, lines }), () => { setLines([{ ...line }]); setF({ supplier_id: "", ref: "", invoice_date: "", due_date: "", note: "" }); })}>Record supplier invoice</Button>
      </div>
      <Msg state={state} />
    </div>
  );
}

export function SupplierInvoiceActions({ id, status, mine, canApprove, canPay }: { id: string; status: string; mine: boolean; canApprove: boolean; canPay: boolean }) {
  const [paid, setPaid] = useState({ paid_on: "", reference: "" });
  const [reason, setReason] = useState("");
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-col gap-1">
      <span className="inline-flex flex-wrap items-end gap-2">
        {status === "received" && canApprove ? (mine ? <span className="text-xs text-muted">Someone else approves.</span> : <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => supplierInvoiceStep(id, "approved"))}>Approve</button>) : null}
        {status === "approved" && canPay ? (
          <>
            <DateInput value={paid.paid_on} onChange={(e) => setPaid((o) => ({ ...o, paid_on: e.target.value }))} className={`${inputClass} w-36`} aria-label="Date paid" />
            <input value={paid.reference} onChange={(e) => setPaid((o) => ({ ...o, reference: e.target.value }))} maxLength={120} placeholder="Payment reference" aria-label="Payment reference" className={`${inputClass} w-40`} />
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => supplierInvoiceStep(id, "paid", paid))}>Record paid</button>
          </>
        ) : null}
        {(status === "received" || status === "approved") && canApprove ? (
          <>
            <input value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} placeholder="Reason to reject" aria-label="Reason to reject" className={`${inputClass} w-40`} />
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => supplierInvoiceStep(id, "rejected", { reason }))}>Reject</button>
          </>
        ) : null}
      </span>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

type Client = { id: string; name: string; sah: string | null; ndisFunding: Opt[]; locations: Opt[]; pathways: Opt[] };
export function ChargeForm({ clients, supplierLines, markups }: { clients: Client[]; supplierLines: { id: string; label: string; client_id: string; date: string | null }[]; markups: Record<string, number> }) {
  const blank = { client_id: "", scheme: "support_at_home", funding_stream: "ongoing", pathway_budget_id: "", funding_id: "", location_id: "", supplier_line_id: "", description: "", service_date: "", sah_category: "everyday_living", ndis_item: "", amount: "", markup_pct: "", markup_note: "", gst_code: "gst_free" };
  const [f, setF] = useState(blank);
  const { pending, state, run } = useRun();
  const c = clients.find((x) => x.id === f.client_id);
  const streams: Opt[] = f.scheme === "support_at_home" ? [["ongoing", "Quarterly budget (ongoing)"], ["at_hm", "AT-HM"], ["restorative", "Restorative Care Pathway"], ["end_of_life", "End-of-Life Pathway"], ["hcp_unspent", "Unspent HCP funds"]]
    : f.scheme === "ndis" ? [["ndis_plan", "NDIS plan"]] : [["private", "Private"]];
  const rule = markups[f.funding_stream] ?? markups.all ?? 0;
  const set = (k: keyof typeof blank, v: string) => setF((o) => ({ ...o, [k]: v }));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <Sel label="Client" value={f.client_id} onChange={(v) => setF({ ...blank, client_id: v })} options={clients.map((x) => [x.id, x.name])} blank="Choose" />
        <Sel label="Scheme" value={f.scheme} onChange={(v) => setF((o) => ({ ...o, scheme: v, funding_stream: v === "ndis" ? "ndis_plan" : v === "private" ? "private" : "ongoing" }))} options={[["support_at_home", "Support at Home"], ["ndis", "NDIS"], ["private", "Private"]]} />
        <Sel label="Funding" value={f.funding_stream} onChange={(v) => set("funding_stream", v)} options={streams} />
        {["at_hm", "restorative", "end_of_life", "hcp_unspent"].includes(f.funding_stream) ? <Sel label="Pathway budget" value={f.pathway_budget_id} onChange={(v) => set("pathway_budget_id", v)} options={c?.pathways ?? []} blank="Choose" /> : null}
        {f.scheme === "ndis" ? (
          <>
            <Sel label="NDIS plan" value={f.funding_id} onChange={(v) => set("funding_id", v)} options={c?.ndisFunding ?? []} blank="Choose" />
            <Sel label="Service delivery location" value={f.location_id} onChange={(v) => set("location_id", v)} options={c?.locations ?? []} blank="Choose" />
            <label className={field}>NDIS support item<input value={f.ndis_item} maxLength={40} onChange={(e) => set("ndis_item", e.target.value)} className={inputClass} /></label>
          </>
        ) : null}
        {f.scheme === "support_at_home" ? <Sel label="Category" value={f.sah_category} onChange={(v) => set("sah_category", v)} options={[["clinical", "Clinical (no contribution)"], ["independence", "Independence"], ["everyday_living", "Everyday living"]]} /> : null}
        <Sel label="From a supplier invoice line (optional)" value={f.supplier_line_id} onChange={(v) => setF((o) => ({ ...o, supplier_line_id: v, markup_pct: v ? String(rule) : "", description: o.description || supplierLines.find((s) => s.id === v)?.label.split(" · ")[0] || "" }))}
          options={supplierLines.filter((s) => s.client_id === f.client_id).map((s) => [s.id, s.label])} blank="No: enter the amount" />
        <label className={field}>Description (shown to the client)<input value={f.description} maxLength={300} onChange={(e) => set("description", e.target.value)} className={inputClass} /></label>
        {!f.supplier_line_id ? (
          <>
            <label className={field}>Date<DateInput value={f.service_date} onChange={(e) => set("service_date", e.target.value)} className={inputClass} /></label>
            <label className={field}>Amount (AUD)<input value={f.amount} inputMode="decimal" onChange={(e) => set("amount", e.target.value)} className={inputClass} /></label>
          </>
        ) : (
          <>
            <label className={field}>Markup % (rule: {rule}%)<input value={f.markup_pct} inputMode="decimal" onChange={(e) => set("markup_pct", e.target.value)} className={inputClass} /></label>
            {Number(f.markup_pct || 0) !== rule ? <label className={field}>Why a different markup<input value={f.markup_note} maxLength={500} onChange={(e) => set("markup_note", e.target.value)} className={inputClass} /></label> : null}
          </>
        )}
        <Sel label="GST" value={f.gst_code} onChange={(v) => set("gst_code", v)} options={[["gst_free", "GST-free"], ["taxable", "Taxable"], ["input_taxed", "Input taxed"]]} />
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => makeCharge({ ...f, enrolment_id: c?.sah ?? "" }), () => setF(blank))}>Make charge</Button></div>
      <p className="text-xs text-muted">Supplier costs never charge a client by themselves: a person makes the charge and someone else approves it. Support at Home contributions use the client&apos;s rate for the category.</p>
      <Msg state={state} />
    </div>
  );
}

export function ChargeActions({ id, status, mine, canApprove, canVoid, overBudget }: { id: string; status: string; mine: boolean; canApprove: boolean; canVoid: boolean; overBudget: boolean }) {
  const [note, setNote] = useState("");
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-col gap-1">
      <span className="inline-flex flex-wrap items-end gap-2">
        {status === "draft" && canApprove && !mine ? (
          <>
            {overBudget ? <input value={note} onChange={(e) => setNote(e.target.value)} maxLength={1000} placeholder="How it's covered (over budget)" aria-label="How it's covered" className={`${inputClass} w-56`} /> : null}
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => chargeStep(id, "approved", note))}>Approve</button>
          </>
        ) : null}
        {status === "draft" && mine ? <span className="text-xs text-muted">Someone else approves.</span> : null}
        {status !== "voided" && canVoid ? (
          <button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Void this charge? It's kept, and the budget gets it back.", { action: "Void", danger: true })) run(() => chargeStep(id, "voided", "Voided by billing")); }}>Void</button>
        ) : null}
      </span>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

export function PathwayForm({ clients }: { clients: { id: string; name: string; enrolment: string }[] }) {
  const blank = { client: "", stream: "at_hm", detail: "", amount: "", starts_on: "", ends_on: "", source: "" };
  const [f, setF] = useState(blank);
  const { pending, state, run } = useRun();
  const c = clients.find((x) => x.id === f.client);
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <Sel label="Client (Support at Home)" value={f.client} onChange={(v) => setF((o) => ({ ...o, client: v }))} options={clients.map((x) => [x.id, x.name])} blank="Choose" />
        <Sel label="Pathway or fund" value={f.stream} onChange={(v) => setF((o) => ({ ...o, stream: v }))} options={[["at_hm", "AT-HM"], ["restorative", "Restorative Care Pathway"], ["end_of_life", "End-of-Life Pathway"], ["hcp_unspent", "Unspent HCP funds"]]} />
        <label className={field}>Detail (for example, tier)<input value={f.detail} maxLength={200} onChange={(e) => setF((o) => ({ ...o, detail: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Amount (from the notice)<input value={f.amount} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, amount: e.target.value }))} className={inputClass} /></label>
        <label className={field}>From<DateInput value={f.starts_on} onChange={(e) => setF((o) => ({ ...o, starts_on: e.target.value }))} className={inputClass} /></label>
        <label className={field}>To<DateInput value={f.ends_on} onChange={(e) => setF((o) => ({ ...o, ends_on: e.target.value }))} className={inputClass} /></label>
        <label className={`${field} sm:col-span-2`}>Source (notice and date)<input value={f.source} maxLength={500} onChange={(e) => setF((o) => ({ ...o, source: e.target.value }))} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending || !c} onClick={() => c && run(() => addPathwayBudget({ client_id: c.id, enrolment_id: c.enrolment, stream: f.stream, detail: f.detail, amount: f.amount, starts_on: f.starts_on, ends_on: f.ends_on, source: f.source }), () => setF(blank))}>Add pathway budget</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function PathwayActions({ id, status, mine, canApprove }: { id: string; status: string; mine: boolean; canApprove: boolean }) {
  const [note, setNote] = useState("");
  const { pending, state, run } = useRun();
  if (!canApprove) return null;
  return (
    <span className="inline-flex flex-col gap-1">
      <span className="inline-flex flex-wrap items-end gap-2">
        {status === "draft" ? (mine ? <span className="text-xs text-muted">Someone else approves.</span> : <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => pathwayStep(id, "approved"))}>Approve</button>) : null}
        {status === "approved" ? (
          <>
            <input value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} placeholder="Why it's closed" aria-label="Why it's closed" className={`${inputClass} w-44`} />
            <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => pathwayStep(id, "closed", note))}>Close</button>
          </>
        ) : null}
      </span>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

export function MarkupRuleForm() {
  const [f, setF] = useState({ stream: "ongoing", pct: "", max: "", from: "", note: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-5">
        <Sel label="Funding stream" value={f.stream} onChange={(v) => setF((o) => ({ ...o, stream: v }))} options={[["all", "All streams"], ["ongoing", "Support at Home quarterly"], ["at_hm", "AT-HM"], ["restorative", "Restorative Care"], ["end_of_life", "End-of-Life"], ["hcp_unspent", "Unspent HCP funds"], ["ndis_plan", "NDIS"], ["private", "Private"]]} />
        <label className={field}>Markup %<input value={f.pct} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, pct: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Most per charge (optional)<input value={f.max} inputMode="decimal" onChange={(e) => setF((o) => ({ ...o, max: e.target.value }))} className={inputClass} /></label>
        <label className={field}>From<DateInput value={f.from} onChange={(e) => setF((o) => ({ ...o, from: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Note<input value={f.note} maxLength={500} onChange={(e) => setF((o) => ({ ...o, note: e.target.value }))} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => addMarkupRule(f))}>Add markup rule</Button></div>
      <Msg state={state} />
    </div>
  );
}

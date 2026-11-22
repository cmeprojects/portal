// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import {
  addFeeReduction, addPayer, approveClaim, approveInvoice, cancelClaim, cancelInvoice, endRecord, issueInvoice, issueStatement, linkPayer, makeClaimFile, markInvoiceSent,
  prepareClaim, prepareInvoices, recordAcknowledgement, recordSubmission, removeClaimItem, removeInvoiceItem, setPlanDetails, setZone,
} from "./claim-actions";

// cmeprojects (update 163): forms for claims, invoices, statements and client
// billing details. The database enforces every rule; these only collect input.
const field = "flex flex-col gap-1 text-xs font-medium";
const linkBtn = "text-xs font-semibold text-brand underline disabled:opacity-50";
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
type Opt = [string, string];
function Select({ value, onChange, options, label, blank }: { value: string; onChange: (v: string) => void; options: Opt[]; label: string; blank?: string }) {
  return (
    <label className={field}>{label}
      <select value={value} onChange={(e) => onChange(e.target.value)} className={inputClass}>
        {blank !== undefined ? <option value="">{blank}</option> : null}
        {options.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
      </select>
    </label>
  );
}

export function PrepareClaimForm({ from, to, programs }: { from: string; to: string; programs: Opt[] }) {
  const router = useRouter();
  const [f, setF] = useState({ program: programs[0]?.[0] ?? "support_at_home", from, to });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-end gap-2">
        <Select label="Program" value={f.program} onChange={(v) => setF((o) => ({ ...o, program: v }))} options={programs} />
        <label className={field}>From<DateInput value={f.from} onChange={(e) => setF((o) => ({ ...o, from: e.target.value }))} className={inputClass} /></label>
        <label className={field}>To<DateInput value={f.to} onChange={(e) => setF((o) => ({ ...o, to: e.target.value }))} className={inputClass} /></label>
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => prepareClaim(f.program, f.from, f.to), (r) => { const id = (r as { id?: string })?.id; if (id) router.push(`/billing/claims/${id}`); })}>
          {pending ? "Preparing…" : "Prepare claim"}
        </Button>
      </div>
      <p className="text-xs text-muted">Approved billing lines in the period not yet claimed. Support at Home also includes each approved quarter&apos;s care management when the quarter ends in the period. NDIS: agency-managed plans only (plan- and self-managed are invoiced). Lines that can&apos;t be claimed are listed with the reason.</p>
      <Msg state={state} />
    </div>
  );
}

export function ClaimActions({ id, status, hasFile, canApprove, canCancel, canSubmit, mine, channel }: { id: string; status: string; hasFile: boolean; canApprove: boolean; canCancel: boolean; canSubmit: boolean; mine: boolean; channel: string }) {
  const { pending, state, run } = useRun();
  const [reason, setReason] = useState("");
  const [sub, setSub] = useState({ submitted_at: "", channel, reference: "", notes: "" });
  const [ack, setAck] = useState("");
  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        {status === "draft" && canApprove ? (
          mine ? <span className="text-xs text-muted">You prepared this claim, so someone else approves it.</span>
            : <Button type="button" size="sm" disabled={pending} onClick={() => run(() => approveClaim(id))}>Approve claim</Button>
        ) : null}
        {status === "approved" && !hasFile && (canApprove || canSubmit) ? <Button type="button" size="sm" disabled={pending} onClick={() => run(() => makeClaimFile(id))}>Make claim file</Button> : null}
        {hasFile ? <a href={`/billing/claims/${id}/file`} className="text-sm font-semibold text-brand underline">Download claim file</a> : null}
      </div>
      {status === "approved" && hasFile && canSubmit ? (
        <div className="flex flex-col gap-2 rounded-md border border-line p-3">
          <p className="text-sm font-semibold">Record the submission</p>
          <p className="text-xs text-muted">Only after you&apos;ve uploaded the file yourself in the government portal. This is what marks the claim Submitted.</p>
          <div className="grid gap-2 sm:grid-cols-2">
            <label className={field}>Uploaded on (Sydney time)<input type="datetime-local" value={sub.submitted_at} onChange={(e) => setSub((o) => ({ ...o, submitted_at: e.target.value }))} className={inputClass} /></label>
            <Select label="Where" value={sub.channel} onChange={(v) => setSub((o) => ({ ...o, channel: v }))} options={[["aged_care_provider_portal", "Aged Care Provider Portal (Services Australia)"], ["ndis_provider_portal", "my NDIS provider portal"], ["other", "Other"]]} />
            <label className={field}>Reference the portal gave<input value={sub.reference} maxLength={120} onChange={(e) => setSub((o) => ({ ...o, reference: e.target.value }))} className={inputClass} /></label>
            <label className={field}>Notes<input value={sub.notes} maxLength={1000} onChange={(e) => setSub((o) => ({ ...o, notes: e.target.value }))} className={inputClass} /></label>
          </div>
          <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => recordSubmission(id, sub))}>Record submission</Button></div>
        </div>
      ) : null}
      {status === "submitted" && canSubmit ? (
        <div className="flex flex-wrap items-end gap-2">
          <label className={`${field} min-w-64 flex-1`}>Acknowledgement or result from the portal<input value={ack} maxLength={1000} onChange={(e) => setAck(e.target.value)} className={inputClass} /></label>
          <Button type="button" size="sm" disabled={pending} onClick={() => run(() => recordAcknowledgement(id, ack))}>Record acknowledgement</Button>
        </div>
      ) : null}
      {(status === "draft" || status === "approved") && canCancel ? (
        <details>
          <summary className={`${linkBtn} cursor-pointer`}>Cancel this claim</summary>
          <div className="mt-2 flex flex-wrap items-end gap-2">
            <label className={`${field} min-w-64 flex-1`}>Why<input value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} className={inputClass} /></label>
            <Button type="button" size="sm" variant="danger" disabled={pending}
              onClick={async () => { if (await askConfirm("Cancel this claim? It's kept, and its lines can be claimed again.", { action: "Cancel claim", danger: true })) run(() => cancelClaim(id, reason)); }}>Cancel claim</Button>
          </div>
        </details>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

export function RemoveItem({ id, parent, kind }: { id: string; parent: string; kind: "claim" | "invoice" }) {
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-col">
      <button type="button" className={linkBtn} disabled={pending}
        onClick={async () => { if (await askConfirm("Remove this line from the draft? It can go in a later one.", { action: "Remove line" })) run(() => (kind === "claim" ? removeClaimItem(id, parent) : removeInvoiceItem(id, parent))); }}>Remove</button>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

export function PrepareInvoicesForm({ from, to }: { from: string; to: string }) {
  const [f, setF] = useState({ kind: "sah_contribution", from, to });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-end gap-2">
        <Select label="Kind" value={f.kind} onChange={(v) => setF((o) => ({ ...o, kind: v }))}
          options={[["sah_contribution", "Support at Home contributions"], ["private", "Private clients"], ["ndis_plan_managed", "NDIS plan-managed (to the plan manager)"], ["ndis_self_managed", "NDIS self-managed (to the participant)"]]} />
        <label className={field}>From<DateInput value={f.from} onChange={(e) => setF((o) => ({ ...o, from: e.target.value }))} className={inputClass} /></label>
        <label className={field}>To<DateInput value={f.to} onChange={(e) => setF((o) => ({ ...o, to: e.target.value }))} className={inputClass} /></label>
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => prepareInvoices(f.kind, f.from, f.to))}>{pending ? "Preparing…" : "Prepare invoices"}</Button>
      </div>
      <p className="text-xs text-muted">One draft per client and payer, from approved lines not yet invoiced. Support at Home contributions skip dates covered by a full fee reduction supplement. Numbers are given only when an invoice is issued.</p>
      <Msg state={state} />
    </div>
  );
}

export function InvoiceActions({ id, status, canApprove, canIssue, canCancel, mine, hasPdf }: { id: string; status: string; canApprove: boolean; canIssue: boolean; canCancel: boolean; mine: boolean; hasPdf: boolean }) {
  const { pending, state, run } = useRun();
  const [reason, setReason] = useState("");
  const [note, setNote] = useState("");
  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        {status === "draft" && canApprove ? (mine ? <span className="text-xs text-muted">You prepared this invoice, so someone else approves it.</span>
          : <Button type="button" size="sm" disabled={pending} onClick={() => run(() => approveInvoice(id))}>Approve invoice</Button>) : null}
        {status === "approved" && canIssue ? (
          <Button type="button" size="sm" disabled={pending}
            onClick={async () => { if (await askConfirm("Issue this invoice? It gets the next number and never changes after this.", { action: "Issue invoice" })) run(() => issueInvoice(id)); }}>Issue invoice</Button>
        ) : null}
        {hasPdf ? <a href={`/billing/invoices/${id}/pdf`} className="text-sm font-semibold text-brand underline">Download PDF</a> : null}
      </div>
      {status === "issued" && canIssue ? (
        <div className="flex flex-wrap items-end gap-2">
          <label className={`${field} min-w-64 flex-1`}>How it was sent (optional)<input value={note} maxLength={500} onChange={(e) => setNote(e.target.value)} className={inputClass} placeholder="For example, emailed to the billing contact" /></label>
          <Button type="button" size="sm" disabled={pending} onClick={() => run(() => markInvoiceSent(id, note))}>Mark sent</Button>
        </div>
      ) : null}
      {(status === "draft" || status === "approved") && canCancel ? (
        <details>
          <summary className={`${linkBtn} cursor-pointer`}>Cancel this invoice</summary>
          <div className="mt-2 flex flex-wrap items-end gap-2">
            <label className={`${field} min-w-64 flex-1`}>Why<input value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} className={inputClass} /></label>
            <Button type="button" size="sm" variant="danger" disabled={pending}
              onClick={async () => { if (await askConfirm("Cancel this invoice? It's kept, never numbered, and its lines can be invoiced again.", { action: "Cancel invoice", danger: true })) run(() => cancelInvoice(id, reason)); }}>Cancel invoice</Button>
          </div>
        </details>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

export function StatementForm({ clients }: { clients: { id: string; name: string; enrolment: string }[] }) {
  const [f, setF] = useState({ client: clients[0]?.id ?? "", month: "" });
  const { pending, state, run } = useRun();
  const c = clients.find((x) => x.id === f.client);
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-end gap-2">
        <Select label="Client (Support at Home)" value={f.client} onChange={(v) => setF((o) => ({ ...o, client: v }))} options={clients.map((x) => [x.id, x.name])} />
        <label className={field}>Month<input type="month" value={f.month} onChange={(e) => setF((o) => ({ ...o, month: e.target.value }))} className={inputClass} /></label>
        <Button type="button" size="sm" disabled={pending || !c} onClick={() => c && run(() => issueStatement(c.id, c.enrolment, f.month))}>Issue statement</Button>
      </div>
      <Msg state={state} />
    </div>
  );
}

export function PayerForm({ clients }: { clients: Opt[] }) {
  const blank = { kind: "plan_manager", client_id: "", person_id: "", name: "", abn: "", email: "", phone: "", address: "", reference: "" };
  const [f, setF] = useState(blank);
  const { pending, state, run } = useRun();
  const set = (k: keyof typeof blank) => (e: React.ChangeEvent<HTMLInputElement>) => setF((o) => ({ ...o, [k]: e.target.value }));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <Select label="Kind" value={f.kind} onChange={(v) => setF((o) => ({ ...o, kind: v }))} options={[["plan_manager", "NDIS plan manager"], ["participant", "NDIS participant (self-managed)"], ["client", "Client billing contact"], ["other", "Other"]]} />
        {f.kind === "participant" || f.kind === "client" ? <Select label="Client" value={f.client_id} onChange={(v) => setF((o) => ({ ...o, client_id: v }))} options={clients} blank="Choose" /> : null}
        <label className={field}>Name<input value={f.name} maxLength={200} onChange={set("name")} className={inputClass} /></label>
        <label className={field}>ABN (optional)<input value={f.abn} maxLength={14} inputMode="numeric" onChange={set("abn")} className={inputClass} /></label>
        <label className={field}>Email<input type="email" value={f.email} maxLength={200} onChange={set("email")} className={inputClass} /></label>
        <label className={field}>Phone<input type="tel" value={f.phone} maxLength={30} onChange={set("phone")} className={inputClass} /></label>
        <label className={`${field} sm:col-span-2`}>Postal address<input value={f.address} maxLength={400} onChange={set("address")} className={inputClass} /></label>
        <label className={field}>Their reference (optional)<input value={f.reference} maxLength={100} onChange={set("reference")} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => addPayer(f), () => setF(blank))}>Add payer</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function LinkPayerForm({ clients, payers, plans }: { clients: Opt[]; payers: { id: string; label: string; client_id: string | null }[]; plans: { id: string; label: string; client_id: string }[] }) {
  const [f, setF] = useState({ client_id: "", role: "client", funding_id: "", payer_id: "", starts_on: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <Select label="Client" value={f.client_id} onChange={(v) => setF((o) => ({ ...o, client_id: v, funding_id: "", payer_id: "" }))} options={clients} blank="Choose" />
        <Select label="Pays for" value={f.role} onChange={(v) => setF((o) => ({ ...o, role: v }))} options={[["client", "The client's share (contributions, private)"], ["funding", "An NDIS plan (plan- or self-managed)"]]} />
        {f.role === "funding" ? <Select label="NDIS plan" value={f.funding_id} onChange={(v) => setF((o) => ({ ...o, funding_id: v }))} options={plans.filter((p) => p.client_id === f.client_id).map((p) => [p.id, p.label])} blank="Choose" /> : null}
        <Select label="Payer" value={f.payer_id} onChange={(v) => setF((o) => ({ ...o, payer_id: v }))} options={payers.filter((p) => !p.client_id || p.client_id === f.client_id).map((p) => [p.id, p.label])} blank="Choose" />
        <label className={field}>From<DateInput value={f.starts_on} onChange={(e) => setF((o) => ({ ...o, starts_on: e.target.value }))} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => linkPayer(f))}>Link payer</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function EndForm({ table, id }: { table: "client_payer_links" | "client_fee_reductions"; id: string }) {
  const [d, setD] = useState("");
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex flex-wrap items-end gap-1">
      <DateInput value={d} onChange={(e) => setD(e.target.value)} className={`${inputClass} w-36`} aria-label="End date" />
      <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => endRecord(table, id, d))}>Set end date</button>
      {state?.error ? <span className="text-xs text-danger">{state.error}</span> : null}
    </span>
  );
}

export function FeeReductionForm({ clients }: { clients: { id: string; name: string; enrolment: string }[] }) {
  const [f, setF] = useState({ client: "", starts_on: "", ends_on: "", source: "" });
  const { pending, state, run } = useRun();
  const c = clients.find((x) => x.id === f.client);
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <Select label="Client (Support at Home)" value={f.client} onChange={(v) => setF((o) => ({ ...o, client: v }))} options={clients.map((x) => [x.id, x.name])} blank="Choose" />
        <label className={field}>From<DateInput value={f.starts_on} onChange={(e) => setF((o) => ({ ...o, starts_on: e.target.value }))} className={inputClass} /></label>
        <label className={field}>To (optional)<DateInput value={f.ends_on} onChange={(e) => setF((o) => ({ ...o, ends_on: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Source<input value={f.source} maxLength={300} onChange={(e) => setF((o) => ({ ...o, source: e.target.value }))} className={inputClass} placeholder="Services Australia notice, date" /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending || !c} onClick={() => c && run(() => addFeeReduction({ client_id: c.id, enrolment_id: c.enrolment, starts_on: f.starts_on, ends_on: f.ends_on, source: f.source }))}>Record fee reduction</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function ZoneForm({ locations }: { locations: Opt[] }) {
  const [f, setF] = useState({ location_id: "", zone: "national", mmm: "", source: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <Select label="Service delivery location" value={f.location_id} onChange={(v) => setF((o) => ({ ...o, location_id: v }))} options={locations} blank="Choose" />
        <Select label="NDIS pricing zone" value={f.zone} onChange={(v) => setF((o) => ({ ...o, zone: v }))} options={[["national", "National (MM 1-5)"], ["remote", "Remote (MM 6)"], ["very_remote", "Very remote (MM 7)"]]} />
        <label className={field}>Modified Monash category<input value={f.mmm} maxLength={10} onChange={(e) => setF((o) => ({ ...o, mmm: e.target.value }))} className={inputClass} placeholder="MM6" /></label>
        <label className={field}>How it was worked out<input value={f.source} maxLength={300} onChange={(e) => setF((o) => ({ ...o, source: e.target.value }))} className={inputClass} placeholder="Health Workforce Locator, date" /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => setZone(f))}>Save zone</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function PlanDetailsForm({ plans }: { plans: Opt[] }) {
  const [f, setF] = useState({ funding_id: "", my_provider: true, recorded_on: "", note: "" });
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <Select label="Agency-managed NDIS plan" value={f.funding_id} onChange={(v) => setF((o) => ({ ...o, funding_id: v }))} options={plans} blank="Choose" />
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={f.my_provider} onChange={(e) => setF((o) => ({ ...o, my_provider: e.target.checked }))} /> We&apos;re recorded as &quot;my provider&quot;</label>
        <label className={field}>Checked on<DateInput value={f.recorded_on} onChange={(e) => setF((o) => ({ ...o, recorded_on: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Note<input value={f.note} maxLength={300} onChange={(e) => setF((o) => ({ ...o, note: e.target.value }))} className={inputClass} /></label>
      </div>
      <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => setPlanDetails(f))}>Save plan details</Button></div>
      <Msg state={state} />
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { addContributionRate, endContributionRate, removeDraftTerms, saveCancellation, saveServiceTerms, serviceTermsStep } from "./billing-actions";

// cmeprojects (update 161): billing terms for an approved service, contribution
// rates and cancellation details. Approval here is the Billing part's own,
// separate from care plans and funding. The database enforces every rule.
const field = "flex flex-col gap-1 text-xs font-medium";
const linkBtn = "text-xs font-semibold text-brand underline disabled:opacity-50";
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

const STATUS: Record<string, [string, string]> = {
  draft: ["Draft", "bg-warn-soft"], pending_review: ["Pending review", "bg-brand-soft"], changes_required: ["Changes required", "bg-danger-soft"],
  approved: ["Approved", "bg-good-soft"], superseded: ["Superseded", "bg-line"],
};
const FREQ: [string, string][] = [["week", "a week"], ["fortnight", "a fortnight"], ["month", "a month"], ["quarter", "a quarter"], ["plan", "over the plan"], ["once", "once"], ["as_needed", "as needed"]];
const UNIT: [string, string][] = [["hour", "hours"], ["visit", "visits"], ["each", "each"], ["km", "km"], ["day", "days"]];
const STREAM: [string, string][] = [["ongoing", "Ongoing budget"], ["at_hm", "AT-HM"], ["restorative", "Restorative Care Pathway"], ["end_of_life", "End-of-Life Pathway"], ["hcp_unspent", "Unspent HCP funds"], ["ndis_plan", "NDIS plan budget"], ["grant", "Grant (CHSP)"], ["private", "Private"], ["other", "Other"]];
const CAT: [string, string][] = [["clinical", "Clinical"], ["independence", "Independence"], ["everyday_living", "Everyday living"]];
const lbl = (l: [string, string][], k: string | null) => l.find(([x]) => x === k)?.[1] ?? k ?? "";

export type Terms = {
  id: string; version: number; status: string; effective_from: string; effective_to: string | null; enrolment_id: string; funding_id: string | null; agreement_id: string | null;
  price_list_id: string | null; quantity: number | null; unit: string; frequency: string; sah_category: string | null; personal_care: boolean; funding_stream: string;
  source_support_line_id: string | null; notes: string; review_note: string; trail: string; mine: boolean;
};
type Opt = [string, string];

export function ServiceTermsPanel({ clientId, serviceId, scheme, terms, enrolments, funding, agreements, priceLists, supportLines, canPrepare, canApprove, today }: {
  clientId: string; serviceId: string; scheme: string; terms: Terms[]; enrolments: Opt[]; funding: Opt[]; agreements: Opt[]; priceLists: Opt[]; supportLines: Opt[]; canPrepare: boolean; canApprove: boolean; today: string;
}) {
  const current = terms.find((t) => t.status === "approved");
  const open = terms.find((t) => ["draft", "pending_review", "changes_required"].includes(t.status));
  return (
    <details className="mt-2 rounded-lg border border-line px-3 py-2">
      <summary className="flex cursor-pointer list-none flex-wrap items-center gap-2 text-sm [&::-webkit-details-marker]:hidden">
        <span className="font-semibold">Billing terms</span>
        {current ? <span className="text-xs text-muted">v{current.version}: {current.quantity ?? "–"} {lbl(UNIT, current.unit)} {lbl(FREQ, current.frequency)} from {current.effective_from.split("-").reverse().join("/")}</span> : <span className="text-xs font-semibold text-warn">No approved terms yet: this service can&apos;t be billed</span>}
        {open ? <span className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${STATUS[open.status][1]}`}>v{open.version} {STATUS[open.status][0]}</span> : null}
      </summary>
      <div className="mt-2 flex flex-col gap-2">
        <p className="text-xs text-muted">What the provider is authorised to deliver and bill for this service, linked to its program, funding record and agreement. Changes are new versions; approved ones never change. Approval is separate from care plans and funding.</p>
        {terms.map((t) => (
          <TermsRow key={t.id} t={t} clientId={clientId} serviceId={serviceId} scheme={scheme} enrolments={enrolments} funding={funding} agreements={agreements} priceLists={priceLists} supportLines={supportLines} canPrepare={canPrepare} canApprove={canApprove} />
        ))}
        {canPrepare && !open ? (
          <details className="rounded-md border border-dashed border-line px-3 py-2">
            <summary className="cursor-pointer text-xs font-semibold text-brand">{current ? "Start new terms (a new version)" : "Add billing terms"}</summary>
            <div className="mt-2">
              <TermsForm clientId={clientId} serviceId={serviceId} scheme={scheme} enrolments={enrolments} funding={funding} agreements={agreements} priceLists={priceLists} supportLines={supportLines}
                init={current ? { ...current, effective_from: today } : undefined} />
            </div>
          </details>
        ) : null}
      </div>
    </details>
  );
}

export function TermsRow({ t, clientId, serviceId, scheme, enrolments, funding, agreements, priceLists, supportLines, canPrepare, canApprove }: {
  t: Terms; clientId: string; serviceId: string; scheme: string; enrolments: Opt[]; funding: Opt[]; agreements: Opt[]; priceLists: Opt[]; supportLines: Opt[]; canPrepare: boolean; canApprove: boolean;
}) {
  const { pending, state, run } = useRun();
  const [note, setNote] = useState("");
  const [asking, setAsking] = useState(false);
  const editable = t.status === "draft" || t.status === "changes_required";
  return (
    <div className={`rounded-md border px-3 py-2 text-sm ${t.status === "superseded" ? "border-line text-muted" : "border-line"}`}>
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-semibold">Version {t.version}</span>
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${STATUS[t.status][1]}`}>{STATUS[t.status][0]}</span>
        <span className="text-xs">{t.effective_from.split("-").reverse().join("/")}{t.effective_to ? ` to ${t.effective_to.split("-").reverse().join("/")}` : " onwards"}</span>
      </div>
      <p className="text-xs">
        {t.quantity ?? "No quantity"} {lbl(UNIT, t.unit)} {lbl(FREQ, t.frequency)} · {lbl(STREAM, t.funding_stream)}
        {t.sah_category ? ` · ${lbl(CAT, t.sah_category)}${t.personal_care ? " (personal care)" : ""}` : ""}
      </p>
      <p className="text-xs text-muted">
        Program: {lbl(enrolments, t.enrolment_id) || "–"} · Funding: {lbl(funding, t.funding_id) || "not linked"} · Agreement: {lbl(agreements, t.agreement_id) || "not linked"} · Prices: {lbl(priceLists, t.price_list_id) || "not chosen"}
        {t.source_support_line_id ? ` · From support plan: ${lbl(supportLines, t.source_support_line_id)}` : ""}
      </p>
      {t.notes ? <p className="text-xs">{t.notes}</p> : null}
      <p className="text-xs text-muted">{t.trail}</p>
      {t.status === "changes_required" && t.review_note ? <p className="rounded bg-danger-soft px-2 py-1 text-xs"><span className="font-semibold">What needs changing:</span> {t.review_note}</p> : null}
      {editable && canPrepare ? (
        <details className="mt-1">
          <summary className="cursor-pointer text-xs font-semibold text-brand">Edit this draft</summary>
          <div className="mt-2"><TermsForm clientId={clientId} serviceId={serviceId} scheme={scheme} enrolments={enrolments} funding={funding} agreements={agreements} priceLists={priceLists} supportLines={supportLines} init={t} termsId={t.id} /></div>
        </details>
      ) : null}
      <div className="mt-1 flex flex-wrap items-center gap-3">
        {editable && canPrepare ? <Button type="button" size="sm" disabled={pending} onClick={() => run(() => serviceTermsStep(t.id, "submit"))}>Send for review</Button> : null}
        {editable && canPrepare && t.status === "draft" ? <button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Remove this unsent draft?", { action: "Remove" })) run(() => removeDraftTerms(t.id, clientId)); }}>Remove draft</button> : null}
        {t.status === "pending_review" && canApprove && !t.mine ? (
          <>
            <Button type="button" size="sm" disabled={pending} onClick={async () => { if (await askConfirm("Approve these billing terms? They never change after this, and earlier terms end the day before.", { action: "Approve" })) run(() => serviceTermsStep(t.id, "approve")); }}>Approve</Button>
            <button type="button" className={linkBtn} disabled={pending} onClick={() => setAsking((x) => !x)}>Changes required</button>
          </>
        ) : null}
        {t.status === "pending_review" && canApprove && t.mine ? <span className="text-xs text-muted">You made or sent these, so someone else with the Billing approve right reviews them.</span> : null}
        {t.status === "pending_review" && canPrepare ? <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => serviceTermsStep(t.id, "take_back"))}>Take back to draft</button> : null}
      </div>
      {asking ? (
        <div className="mt-2 flex flex-col gap-2">
          <label className={field}>What needs changing<textarea value={note} onChange={(e) => setNote(e.target.value)} rows={2} maxLength={1000} className={inputClass} /></label>
          <div><Button type="button" size="sm" variant="secondary" disabled={pending || !note.trim()} onClick={() => run(() => serviceTermsStep(t.id, "changes", note), () => setAsking(false))}>Send back</Button></div>
        </div>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

function TermsForm({ clientId, serviceId, scheme, enrolments, funding, agreements, priceLists, supportLines, init, termsId }: {
  clientId: string; serviceId: string; scheme: string; enrolments: Opt[]; funding: Opt[]; agreements: Opt[]; priceLists: Opt[]; supportLines: Opt[]; init?: Partial<Terms>; termsId?: string;
}) {
  const start = {
    effective_from: init?.effective_from ?? "", enrolment_id: init?.enrolment_id ?? enrolments[0]?.[0] ?? "", funding_id: init?.funding_id ?? "", agreement_id: init?.agreement_id ?? "",
    price_list_id: init?.price_list_id ?? priceLists[0]?.[0] ?? "", quantity: init?.quantity != null ? String(init.quantity) : "", unit: init?.unit ?? "hour", frequency: init?.frequency ?? "week",
    sah_category: init?.sah_category ?? "", personal_care: String(init?.personal_care ?? false), funding_stream: init?.funding_stream ?? (scheme === "support_at_home" ? "ongoing" : scheme === "ndis" ? "ndis_plan" : scheme === "chsp" ? "grant" : scheme === "private" ? "private" : "other"),
    source_support_line_id: init?.source_support_line_id ?? "", notes: init?.notes ?? "",
  };
  const [f, setF] = useState(start);
  const set = (k: keyof typeof start, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  const sel = (k: keyof typeof start, opts: Opt[], blank?: string) => (
    <select value={f[k]} onChange={(e) => set(k, e.target.value)} className={inputClass}>
      {blank !== undefined ? <option value="">{blank}</option> : null}
      {opts.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
    </select>
  );
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>Starts on<DateInput value={f.effective_from} onChange={(e) => set("effective_from", e.target.value)} className={inputClass} /></label>
        <label className={field}>Program enrolment{sel("enrolment_id", enrolments)}</label>
        <label className={field}>Funding record{sel("funding_id", funding, "Not linked")}</label>
        <label className={field}>Approved quantity<input value={f.quantity} onChange={(e) => set("quantity", e.target.value)} inputMode="decimal" className={inputClass} /></label>
        <label className={field}>Unit{sel("unit", UNIT)}</label>
        <label className={field}>How often{sel("frequency", FREQ)}</label>
        <label className={field}>Funding stream{sel("funding_stream", STREAM)}</label>
        <label className={field}>Price list{sel("price_list_id", priceLists, "Not chosen yet")}</label>
        <label className={field}>Service agreement{sel("agreement_id", agreements, "Not linked")}</label>
        {scheme === "support_at_home" ? (
          <>
            <label className={field}>Category (decides the contribution){sel("sah_category", CAT, "Choose…")}</label>
            <label className="flex items-center gap-2 self-end text-xs font-medium"><input type="checkbox" checked={f.personal_care === "true"} onChange={(e) => set("personal_care", String(e.target.checked))} /> Personal care</label>
          </>
        ) : null}
        {supportLines.length ? <label className={`${field} sm:col-span-2`}>From the support plan (optional){sel("source_support_line_id", supportLines, "Not linked")}</label> : null}
      </div>
      <label className={field}>Notes (optional)<textarea value={f.notes} onChange={(e) => set("notes", e.target.value)} rows={2} maxLength={2000} className={inputClass} /></label>
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => saveServiceTerms(clientId, serviceId, f, termsId))}>{termsId ? "Save draft" : "Add draft terms"}</Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

// ---- Contribution rates ----
export type Rate = { id: string; category: string; rate_pct: number; contribution_group: string; effective_from: string; effective_to: string | null; source: string; enrolment: string };
export function ContributionRates({ clientId, rates, enrolments, documents, canPrepare }: { clientId: string; rates: Rate[]; enrolments: Opt[]; documents: Opt[]; canPrepare: boolean }) {
  const blank = { enrolment_id: enrolments[0]?.[0] ?? "", category: "everyday_living", rate_pct: "", contribution_group: "standard", effective_from: "", source: "", document_id: "" };
  const [f, setF] = useState(blank);
  const set = (k: keyof typeof blank, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      {rates.length ? (
        <ul className="divide-y divide-line rounded-md border border-line text-sm">
          {rates.map((r) => <RateRow key={r.id} r={r} clientId={clientId} canPrepare={canPrepare} />)}
        </ul>
      ) : <p className="text-sm text-muted">No contribution rates recorded.</p>}
      {canPrepare && enrolments.length ? (
        <details className="rounded-md border border-dashed border-line px-3 py-2">
          <summary className="cursor-pointer text-xs font-semibold text-brand">Record a contribution rate</summary>
          <div className="mt-2 flex flex-col gap-2">
            <div className="grid gap-2 sm:grid-cols-3">
              <label className={field}>Program<select value={f.enrolment_id} onChange={(e) => set("enrolment_id", e.target.value)} className={inputClass}>{enrolments.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select></label>
              <label className={field}>Category<select value={f.category} onChange={(e) => set("category", e.target.value)} className={inputClass}>{CAT.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select></label>
              <label className={field}>Rate (%)<input value={f.rate_pct} onChange={(e) => set("rate_pct", e.target.value)} inputMode="decimal" className={inputClass} /></label>
              <label className={field}>Contribution group<select value={f.contribution_group} onChange={(e) => set("contribution_group", e.target.value)} className={inputClass}><option value="standard">Standard</option><option value="no_worse_off">No worse off</option><option value="">Not stated</option></select></label>
              <label className={field}>Applies from<DateInput value={f.effective_from} onChange={(e) => set("effective_from", e.target.value)} className={inputClass} /></label>
              {documents.length ? <label className={field}>Letter (optional)<select value={f.document_id} onChange={(e) => set("document_id", e.target.value)} className={inputClass}><option value="">None</option>{documents.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select></label> : null}
            </div>
            <label className={field}>Source<input value={f.source} onChange={(e) => set("source", e.target.value)} maxLength={300} placeholder="e.g. Services Australia letter, 3 Oct 2026" className={inputClass} /></label>
            <p className="text-xs text-muted">From the client&apos;s Services Australia letter. A recorded rate isn&apos;t changed: end it and record the new one.</p>
            <div className="flex flex-wrap items-center gap-3">
              <Button type="button" size="sm" disabled={pending} onClick={() => run(() => addContributionRate(clientId, f), () => setF(blank))}>Record rate</Button>
              <Msg state={state} />
            </div>
          </div>
        </details>
      ) : null}
    </div>
  );
}
function RateRow({ r, clientId, canPrepare }: { r: Rate; clientId: string; canPrepare: boolean }) {
  const [endOn, setEndOn] = useState("");
  const { pending, state, run } = useRun();
  return (
    <li className={`px-3 py-1.5 ${r.effective_to ? "text-muted" : ""}`}>
      <div className="flex flex-wrap items-center gap-2">
        <span className="min-w-32 flex-1 font-semibold">{lbl(CAT, r.category)}: {Number(r.rate_pct)}%</span>
        <span className="text-xs">{r.effective_from.split("-").reverse().join("/")}{r.effective_to ? ` to ${r.effective_to.split("-").reverse().join("/")}` : " onwards"} · {r.enrolment}{r.contribution_group ? ` · ${r.contribution_group === "no_worse_off" ? "no worse off" : "standard"}` : ""}</span>
      </div>
      <p className="text-xs text-muted">{r.source}</p>
      {canPrepare && !r.effective_to ? (
        <div className="mt-1 flex flex-wrap items-end gap-2">
          <label className={field}>Last day it applies<DateInput value={endOn} onChange={(e) => setEndOn(e.target.value)} className={inputClass} /></label>
          <Button type="button" size="sm" variant="outline" disabled={pending || !endOn} onClick={() => run(() => endContributionRate(r.id, clientId, endOn))}>End rate</Button>
        </div>
      ) : null}
      <Msg state={state} />
    </li>
  );
}

// ---- Cancellation details ----
export type Cancellation = { notified_at: string; cancelled_by: string; reason: string; reasonable_grounds: boolean | null; charge: string; charge_note: string; decided: string };
const toLocal = (iso: string) => {
  const d = new Date(iso);
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`;
};
export function CancellationForm({ shiftId, c, canDecide }: { shiftId: string; c: Cancellation | null; canDecide: boolean }) {
  const start = {
    notified_at: c ? toLocal(c.notified_at) : "", cancelled_by: c?.cancelled_by ?? "client", reason: c?.reason ?? "",
    reasonable_grounds: c?.reasonable_grounds === true ? "yes" : c?.reasonable_grounds === false ? "no" : "", charge: c?.charge ?? "undecided", charge_note: c?.charge_note ?? "",
  };
  const [f, setF] = useState(start);
  const set = (k: keyof typeof start, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>When they told us<input type="datetime-local" value={f.notified_at} onChange={(e) => set("notified_at", e.target.value)} className={inputClass} /></label>
        <label className={field}>Who cancelled<select value={f.cancelled_by} onChange={(e) => set("cancelled_by", e.target.value)} className={inputClass}><option value="client">Client</option><option value="representative">Representative</option><option value="provider">Us (provider)</option><option value="worker">Worker</option><option value="other">Other</option></select></label>
        <label className={field}>Reasonable grounds?<select value={f.reasonable_grounds} onChange={(e) => set("reasonable_grounds", e.target.value)} className={inputClass}><option value="">Not decided</option><option value="yes">Yes (e.g. sudden hospital admission)</option><option value="no">No</option></select></label>
      </div>
      <label className={field}>Reason<input value={f.reason} onChange={(e) => set("reason", e.target.value)} maxLength={1000} className={inputClass} /></label>
      {canDecide ? (
        <div className="grid gap-2 sm:grid-cols-[14rem_1fr]">
          <label className={field}>Charge the client?<select value={f.charge} onChange={(e) => set("charge", e.target.value)} className={inputClass}><option value="undecided">Not decided</option><option value="no_charge">No charge</option><option value="charge">Charge (late cancellation)</option></select></label>
          <label className={field}>Why<input value={f.charge_note} onChange={(e) => set("charge_note", e.target.value)} maxLength={1000} className={inputClass} /></label>
        </div>
      ) : <p className="text-xs text-muted">{c && c.charge !== "undecided" ? `Charge decision: ${c.charge === "charge" ? "charge" : "no charge"} (${c.charge_note}) · ${c.decided}` : "Whether it's charged is decided by someone with the Billing approve right."}</p>}
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => saveCancellation(shiftId, { ...f, notified_at: f.notified_at ? new Date(f.notified_at).toISOString() : "" }, !!c))}>{c ? "Save changes" : "Save details"}</Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { abnValid } from "@/lib/abn";
import { CLAIM_FIELDS, csvRows, guessField, headerRow } from "@/lib/claim-fields";
import { addTemplate, importCatalogue, removeDraft, saveBusiness, saveReview, verifyCatalogue, verifyTemplate } from "./compliance-actions";
import type { Business } from "@/lib/business";

// cmeprojects (update 163): business details, compliance register fields, official
// claim templates and NDIS catalogue imports. The database enforces every rule.
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
async function sha256(text: string) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
const STATES = ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"];


export function BusinessForm({ initial, canEdit, compact }: { initial: Business; canEdit: boolean; compact?: boolean }) {
  const [b, setB] = useState<Business>(initial);
  const { pending, state, run } = useRun();
  const set = (k: keyof Business) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => setB((o) => ({ ...o, [k]: e.target.value }));
  const tick = (k: "gst_registered" | "prices_include_gst") => (e: React.ChangeEvent<HTMLInputElement>) => setB((o) => ({ ...o, [k]: e.target.checked }));
  const abn = b.abn.replace(/\s/g, "");
  const inp = (k: keyof Business, label: string, extra: React.InputHTMLAttributes<HTMLInputElement> = {}) => (
    <label className={field}>{label}<input value={String(b[k])} onChange={set(k)} disabled={!canEdit} className={inputClass} {...extra} /></label>
  );
  return (
    <div className="flex flex-col gap-3">
      <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
        {inp("legal_name", "Legal name", { maxLength: 200 })}
        {inp("trading_name", "Trading name (if different)", { maxLength: 200 })}
        <label className={field}>ABN<input value={b.abn} onChange={set("abn")} disabled={!canEdit} inputMode="numeric" maxLength={14} className={inputClass} aria-invalid={abn.length === 11 && !abnValid(abn)} />
          {abn.length === 11 && !abnValid(abn) ? <span className="text-danger">That ABN isn&apos;t valid.</span> : null}</label>
        {inp("address", "Street address", { maxLength: 300 })}
        {inp("suburb", "Suburb", { maxLength: 100 })}
        <div className="grid grid-cols-2 gap-2">
          <label className={field}>State<select value={b.state} onChange={set("state")} disabled={!canEdit} className={inputClass}>{STATES.map((s) => <option key={s}>{s}</option>)}</select></label>
          {inp("postcode", "Postcode", { maxLength: 4, inputMode: "numeric" })}
        </div>
        {inp("phone", "Phone", { type: "tel", maxLength: 30 })}
        {inp("email", "Accounts email", { type: "email", maxLength: 200 })}
      </div>
      {!compact ? (
        <>
          <fieldset className="flex flex-col gap-2 rounded-md border border-line p-3">
            <legend className="px-1 text-xs font-semibold">GST (verified by your accountant)</legend>
            <div className="flex flex-wrap gap-4 text-sm">
              <label className="flex items-center gap-2"><input type="checkbox" checked={b.gst_registered} onChange={tick("gst_registered")} disabled={!canEdit} /> Registered for GST</label>
              <label className="flex items-center gap-2"><input type="checkbox" checked={b.prices_include_gst} onChange={tick("prices_include_gst")} disabled={!canEdit} /> Prices include GST (for taxable items)</label>
            </div>
            <div className="grid gap-2 sm:grid-cols-3">
              {inp("gst_verified_by_name", "Verified by (accountant's name)", { maxLength: 120 })}
              <label className={field}>Verified on<DateInput value={b.gst_verified_on} onChange={(e) => setB((o) => ({ ...o, gst_verified_on: e.target.value }))} disabled={!canEdit} className={inputClass} /></label>
              {inp("gst_evidence", "Evidence (for example, letter on file)", { maxLength: 500 })}
            </div>
            <p className="text-xs text-muted">Invoices can&apos;t be issued until this is recorded. Most care services are GST-free; each price item has its own GST code.</p>
          </fieldset>
          <div className="grid gap-2 sm:grid-cols-3">
            {inp("ndis_registration_number", "NDIS registration number", { maxLength: 40 })}
            {inp("sah_provider_id", "Support at Home provider ID", { maxLength: 60 })}
            {inp("sah_service_branch", "Support at Home service or branch", { maxLength: 120 })}
          </div>
          <fieldset className="flex flex-col gap-2 rounded-md border border-line p-3">
            <legend className="px-1 text-xs font-semibold">How clients pay (shown on invoices)</legend>
            <div className="grid gap-2 sm:grid-cols-4">
              {inp("payment_account_name", "Account name", { maxLength: 120 })}
              {inp("payment_bsb", "BSB", { maxLength: 7, inputMode: "numeric" })}
              {inp("payment_account_number", "Account number", { maxLength: 10, inputMode: "numeric" })}
              {inp("payment_terms_days", "Payment terms (days)", { type: "number", min: 0, max: 120 })}
            </div>
            <label className={field}>Other ways to pay<textarea value={b.payment_other} onChange={set("payment_other")} disabled={!canEdit} maxLength={500} rows={2} className={inputClass} /></label>
          </fieldset>
        </>
      ) : null}
      {canEdit ? <div><Button type="button" size="sm" disabled={pending} onClick={() => run(() => saveBusiness(b))}>{pending ? "Saving…" : "Save business details"}</Button></div>
        : <p className="text-xs text-muted">Only the System Administrator or someone with the Billing approve right changes business details.</p>}
      <Msg state={state} />
    </div>
  );
}

export function ReviewRow({ kind, r, canEdit }: { kind: "check" | "figure"; r: { id: string; label: string; status: string; official_url: string; document_version: string; effective_from: string | null; review_by: string | null }; canEdit: boolean }) {
  const [f, setF] = useState({ url: r.official_url, version: r.document_version, effective_from: r.effective_from ?? "", review_by: r.review_by ?? "" });
  const { pending, state, run } = useRun();
  const locked = r.status === "verified";
  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
  const lapsed = r.review_by && r.review_by < today;
  const complete = r.official_url && r.document_version && r.review_by;
  return (
    <li className="flex flex-col gap-1 px-3 py-2 text-sm">
      <p className="font-semibold">{r.label} <span className={`text-xs font-normal ${lapsed ? "text-danger" : complete ? "text-muted" : "text-warn"}`}>
        {r.status === "verified" ? "verified" : "not verified"} · {lapsed ? `past its review date (${r.review_by?.split("-").reverse().join("/")})` : complete ? `review by ${r.review_by?.split("-").reverse().join("/")}` : "link, version or review date missing"}</span></p>
      {canEdit ? (
        <div className="grid gap-2 sm:grid-cols-[1fr_9rem_9rem_9rem_auto] sm:items-end">
          <label className={field}>Official link<input value={f.url} onChange={(e) => setF((o) => ({ ...o, url: e.target.value }))} disabled={locked && !!r.official_url} maxLength={500} placeholder="https://" className={inputClass} /></label>
          <label className={field}>Document version<input value={f.version} onChange={(e) => setF((o) => ({ ...o, version: e.target.value }))} disabled={locked && !!r.document_version} maxLength={100} className={inputClass} /></label>
          {kind === "check" ? <label className={field}>Effective from<DateInput value={f.effective_from} onChange={(e) => setF((o) => ({ ...o, effective_from: e.target.value }))} className={inputClass} /></label> : <span />}
          <label className={field}>Review by<DateInput value={f.review_by} onChange={(e) => setF((o) => ({ ...o, review_by: e.target.value }))} className={inputClass} /></label>
          <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => saveReview(kind, r.id, f))}>Save</Button>
        </div>
      ) : r.official_url ? <a href={r.official_url} target="_blank" rel="noreferrer" className="text-xs text-brand underline">{r.document_version || "Official source"}</a> : null}
      <Msg state={state} />
    </li>
  );
}

export function TemplateUpload() {
  const [t, setT] = useState({ program: "support_at_home", name: "", date_format: "YYYY-MM-DD", file_name_max: "", file_name: "", checksum: "" });
  const [headers, setHeaders] = useState<string[]>([]);
  const [mapping, setMapping] = useState<Record<string, string>>({});
  const { pending, state, run } = useRun();
  const onFile = async (file: File | undefined) => {
    if (!file) return;
    const text = await file.text();
    const h = headerRow(text);
    setHeaders(h);
    setMapping(Object.fromEntries(h.map((x) => [x, guessField(x)])));
    setT((o) => ({ ...o, file_name: file.name, checksum: "", name: o.name || file.name.replace(/\.csv$/i, "") }));
    const sum = await sha256(text);
    setT((o) => ({ ...o, checksum: sum }));
  };
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <label className={field}>Program<select value={t.program} onChange={(e) => setT((o) => ({ ...o, program: e.target.value }))} className={inputClass}><option value="support_at_home">Support at Home (Services Australia)</option><option value="ndis">NDIS (bulk upload)</option></select></label>
        <label className={field}>Official file (CSV)<input type="file" accept=".csv,text/csv" onChange={(e) => onFile(e.target.files?.[0])} className="text-sm" /></label>
        <label className={field}>Name<input value={t.name} onChange={(e) => setT((o) => ({ ...o, name: e.target.value }))} maxLength={200} className={inputClass} /></label>
        <div className="grid grid-cols-2 gap-2">
          <label className={field}>Date format<select value={t.date_format} onChange={(e) => setT((o) => ({ ...o, date_format: e.target.value }))} className={inputClass}><option>YYYY-MM-DD</option><option>YYYY/MM/DD</option><option>DD/MM/YYYY</option></select></label>
          <label className={field}>File name limit<input type="number" min={5} max={200} value={t.file_name_max} onChange={(e) => setT((o) => ({ ...o, file_name_max: e.target.value }))} className={inputClass} /></label>
        </div>
      </div>
      {headers.length ? (
        <div className="flex flex-col gap-1">
          <p className="text-xs text-muted">{headers.length} columns, kept exactly and in this order. Choose what goes in each (first guesses shown; check every one). Fixed text: choose &quot;Fixed text&quot; and type it.</p>
          <ul className="divide-y divide-line rounded-md border border-line">
            {headers.map((h) => {
              const v = mapping[h] ?? "";
              const fixed = v.startsWith("=");
              return (
                <li key={h} className="grid gap-2 px-3 py-1.5 sm:grid-cols-[14rem_1fr_12rem] sm:items-center">
                  <code className="text-xs">{h}</code>
                  <select value={fixed ? "=" : v} onChange={(e) => setMapping((m) => ({ ...m, [h]: e.target.value === "=" ? "=" : e.target.value }))} className={inputClass} aria-label={`What goes in ${h}`}>
                    {CLAIM_FIELDS.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
                    <option value="=">Fixed text…</option>
                  </select>
                  {fixed ? <input value={v.slice(1)} onChange={(e) => setMapping((m) => ({ ...m, [h]: `=${e.target.value}` }))} maxLength={100} className={inputClass} aria-label={`Fixed text for ${h}`} /> : <span />}
                </li>
              );
            })}
          </ul>
        </div>
      ) : null}
      <div><Button type="button" size="sm" disabled={pending || !headers.length || !t.checksum} onClick={() => run(() => addTemplate({ ...t, headers, mapping }), () => setHeaders([]))}>Save template as draft</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function TemplateRow({ t, canPrices, canApprove }: { t: { id: string; program: string; name: string; version: number; status: string; headers: string[]; mapping: Record<string, string>; date_format: string; file_name_max: number | null; official_url: string; document_version: string; review_by: string | null; verified: string }; canPrices: boolean; canApprove: boolean }) {
  const [f, setF] = useState({ url: t.official_url, version: t.document_version, review_by: t.review_by ?? "" });
  const { pending, state, run } = useRun();
  const label = (k: string) => (k.startsWith("=") ? `"${k.slice(1)}"` : CLAIM_FIELDS.find(([x]) => x === k)?.[1] ?? "blank");
  return (
    <li className={`flex flex-col gap-2 px-3 py-2 text-sm ${t.status === "retired" ? "text-muted" : ""}`}>
      <p className="font-semibold">{t.program === "ndis" ? "NDIS" : "Support at Home"}: {t.name} <span className="text-xs font-normal text-muted">v{t.version} · {t.status === "verified" ? `verified ${t.verified}` : t.status === "retired" ? "retired" : "draft"} · dates {t.date_format}{t.file_name_max ? ` · file name up to ${t.file_name_max}` : ""}{t.review_by ? ` · review by ${t.review_by.split("-").reverse().join("/")}` : ""}</span></p>
      <details><summary className={`${linkBtn} cursor-pointer`}>{t.headers.length} columns</summary>
        <ol className="mt-1 list-decimal pl-6 text-xs">{t.headers.map((h) => <li key={h}><code>{h}</code> ← {label(t.mapping[h] ?? "")}</li>)}</ol>
      </details>
      {t.status === "draft" && canApprove ? (
        <div className="grid gap-2 sm:grid-cols-[1fr_9rem_9rem_auto_auto] sm:items-end">
          <label className={field}>Official link<input value={f.url} onChange={(e) => setF((o) => ({ ...o, url: e.target.value }))} maxLength={500} placeholder="https://" className={inputClass} /></label>
          <label className={field}>Document version<input value={f.version} onChange={(e) => setF((o) => ({ ...o, version: e.target.value }))} maxLength={100} className={inputClass} /></label>
          <label className={field}>Review by<DateInput value={f.review_by} onChange={(e) => setF((o) => ({ ...o, review_by: e.target.value }))} className={inputClass} /></label>
          <Button type="button" size="sm" disabled={pending} onClick={async () => { if (await askConfirm("Verify this template? You've checked every column against the official guide. It never changes after this.", { action: "Verify" })) run(() => verifyTemplate(t.id, f)); }}>Verify</Button>
        </div>
      ) : null}
      {t.status === "draft" && canPrices ? <div><button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Remove this draft template?", { action: "Remove", danger: true })) run(() => removeDraft("template", t.id)); }}>Remove draft</button></div> : null}
      {t.official_url && t.status !== "draft" ? <a href={t.official_url} target="_blank" rel="noreferrer" className="text-xs text-brand underline">Official source ({t.document_version})</a> : null}
      <Msg state={state} />
    </li>
  );
}

// NDIS Support Catalogue: columns found by name. National = the NSW column (or a "National" column).
function findCol(head: string[], ...names: RegExp[]) {
  const h = head.map((x) => x.toLowerCase().replace(/[^a-z]/g, ""));
  for (const re of names) { const i = h.findIndex((x) => re.test(x)); if (i >= 0) return i; }
  return -1;
}
export function CatalogueImport() {
  const [c, setC] = useState({ name: "", effective_from: "", effective_to: "", url: "", version: "", review_by: "", file_name: "", checksum: "" });
  const [items, setItems] = useState<Parameters<typeof importCatalogue>[0]["items"]>([]);
  const [found, setFound] = useState("");
  const { pending, state, run } = useRun();
  const onFile = async (file: File | undefined) => {
    if (!file) return;
    const text = await file.text();
    const rows = csvRows(text);
    const head = rows[0] ?? [];
    const col = {
      num: findCol(head, /^supportitemnumber$/, /itemnumber/), name: findCol(head, /^supportitemname$/, /itemname/), cat: findCol(head, /^supportcategoryname$/, /categoryname/),
      reg: findCol(head, /^registrationgroupname$/, /registrationgroup/), unit: findCol(head, /^unit$/, /unitofmeasure/), quote: findCol(head, /^quote$/, /quotable/),
      nat: findCol(head, /^national$/, /^nationalnonremote$/, /^nsw$/), rem: findCol(head, /^remote$/), vrem: findCol(head, /^veryremote$/),
    };
    const num = (s: string | undefined) => { const v = String(s ?? "").replace(/[$,\s]/g, ""); return v && Number.isFinite(Number(v)) ? Number(v) : null; };
    const list = col.num < 0 ? [] : rows.slice(1).map((r) => ({
      item_number: (r[col.num] ?? "").trim(), item_name: col.name >= 0 ? r[col.name] ?? "" : "", category: col.cat >= 0 ? r[col.cat] ?? "" : "", registration_group: col.reg >= 0 ? r[col.reg] ?? "" : "",
      unit: col.unit >= 0 ? r[col.unit] ?? "" : "", limit_national: col.nat >= 0 ? num(r[col.nat]) : null, limit_remote: col.rem >= 0 ? num(r[col.rem]) : null, limit_very_remote: col.vrem >= 0 ? num(r[col.vrem]) : null,
      quotable: col.quote >= 0 ? /^(y|yes|true)$/i.test((r[col.quote] ?? "").trim()) : false,
    })).filter((i) => i.item_number);
    setItems(list);
    setFound(col.num < 0 ? "No \"Support Item Number\" column found." : `${list.length} items. Columns used: national limit from "${head[col.nat] ?? "none"}", remote from "${head[col.rem] ?? "none"}", very remote from "${head[col.vrem] ?? "none"}".`);
    setC((o) => ({ ...o, file_name: file.name, name: o.name || file.name.replace(/\.csv$/i, ""), checksum: "" }));
    const sum = await sha256(text);
    setC((o) => ({ ...o, checksum: sum }));
  };
  const set = (k: keyof typeof c) => (e: React.ChangeEvent<HTMLInputElement>) => setC((o) => ({ ...o, [k]: e.target.value }));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>Support Catalogue (CSV, saved from the official file)<input type="file" accept=".csv,text/csv" onChange={(e) => onFile(e.target.files?.[0])} className="text-sm" /></label>
        <label className={field}>Name<input value={c.name} onChange={set("name")} maxLength={200} className={inputClass} /></label>
        <label className={field}>Pricing Arrangements version<input value={c.version} onChange={set("version")} maxLength={100} className={inputClass} placeholder="2025-26 v1.1" /></label>
        <label className={field}>In force from<DateInput value={c.effective_from} onChange={(e) => setC((o) => ({ ...o, effective_from: e.target.value }))} className={inputClass} /></label>
        <label className={field}>In force to (optional)<DateInput value={c.effective_to} onChange={(e) => setC((o) => ({ ...o, effective_to: e.target.value }))} className={inputClass} /></label>
        <label className={field}>Review by<DateInput value={c.review_by} onChange={(e) => setC((o) => ({ ...o, review_by: e.target.value }))} className={inputClass} /></label>
        <label className={`${field} sm:col-span-3`}>Official link<input value={c.url} onChange={set("url")} maxLength={500} placeholder="https://www.ndis.gov.au/providers/pricing-arrangements" className={inputClass} /></label>
      </div>
      {found ? <p className="text-xs text-muted">{found}</p> : null}
      <div><Button type="button" size="sm" disabled={pending || !items.length || !c.checksum} onClick={() => run(() => importCatalogue({ ...c, items }), () => setItems([]))}>{pending ? "Importing…" : "Import as draft"}</Button></div>
      <Msg state={state} />
    </div>
  );
}

export function CatalogueRow({ v, canPrices, canApprove }: { v: { id: string; name: string; document_version: string; effective_from: string; effective_to: string | null; review_by: string | null; item_count: number; status: string; official_url: string; verified: string }; canPrices: boolean; canApprove: boolean }) {
  const { pending, state, run } = useRun();
  const dmy = (d: string | null) => (d ? d.split("-").reverse().join("/") : "");
  return (
    <li className="flex flex-col gap-1 px-3 py-2 text-sm">
      <p className="font-semibold">{v.name} <span className="text-xs font-normal text-muted">{v.document_version} · in force from {dmy(v.effective_from)}{v.effective_to ? ` to ${dmy(v.effective_to)}` : ""} · {v.item_count} items · {v.status === "verified" ? `verified ${v.verified}` : "draft"}{v.review_by ? ` · review by ${dmy(v.review_by)}` : ""}</span></p>
      <div className="flex flex-wrap gap-3">
        {v.status === "draft" && canApprove ? <Button type="button" size="sm" disabled={pending} onClick={async () => { if (await askConfirm("Verify this catalogue? You've checked it against the official file. It never changes after this.", { action: "Verify" })) run(() => verifyCatalogue(v.id)); }}>Verify</Button> : null}
        {v.status === "draft" && canPrices ? <button type="button" className={linkBtn} disabled={pending} onClick={async () => { if (await askConfirm("Remove this draft catalogue and its items?", { action: "Remove", danger: true })) run(() => removeDraft("catalogue", v.id)); }}>Remove draft</button> : null}
        {v.official_url ? <a href={v.official_url} target="_blank" rel="noreferrer" className="text-xs text-brand underline">Official source</a> : null}
      </div>
      <Msg state={state} />
    </li>
  );
}

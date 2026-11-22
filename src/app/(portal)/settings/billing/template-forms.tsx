// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import type { FormState } from "@/lib/form";
import { saveTemplate } from "./template-actions";

// cmeprojects (update 168): document template settings for one kind of document.
const field = "flex flex-col gap-1 text-xs font-medium";
export const TEMPLATE_SECTIONS: Record<string, [string, string][]> = {
  statement: [["carried_in", "Funds carried into the quarter"], ["quarter_months", "Quarter month by month"], ["charge_detail", "AT-HM and other charges table"], ["care_management", "Care management table"], ["away_note", "\"Tell us if you'll be away\" note"]],
  invoice: [["client_address", "Client's address"], ["service_codes", "Service codes on each line"], ["payment_details", "How to pay (bank details and payment note)"]],
  receipt: [],
  credit_note: [],
};
export type TemplateSettings = { layout: string; logo_position: string; colour_source: string; primary: string; accent: string; sections: Record<string, boolean>; header_note: string; footer_text: string; payment_note: string };
export function TemplateForm({ kind, initial, version, theme, canEdit }: { kind: string; initial: TemplateSettings; version: number; theme: { primary: string; accent: string }; canEdit: boolean }) {
  const router = useRouter();
  const [f, setF] = useState<TemplateSettings>(initial);
  const [note, setNote] = useState("");
  const [pending, start] = useTransition();
  const [state, setState] = useState<FormState>(null);
  const set = (k: keyof TemplateSettings, v: string) => setF((o) => ({ ...o, [k]: v }));
  const secs = TEMPLATE_SECTIONS[kind] ?? [];
  const isOn = (k: string) => (k in f.sections ? f.sections[k] : f.layout === "compact" ? !["carried_in", "quarter_months"].includes(k) : true);
  return (
    <div className="flex flex-col gap-3">
      <div className="grid gap-2 sm:grid-cols-4">
        <label className={field}>Layout
          <select value={f.layout} disabled={!canEdit} onChange={(e) => set("layout", e.target.value)} className={inputClass}>
            <option value="full">Full{kind === "statement" ? " (summary, then detail pages)" : ""}</option><option value="compact">Compact{kind === "statement" ? " (fewer sections, one flow)" : ""}</option>
          </select>
        </label>
        <label className={field}>Logo
          <select value={f.logo_position} disabled={!canEdit} onChange={(e) => set("logo_position", e.target.value)} className={inputClass}>
            <option value="left">Left</option><option value="centre">Centre</option><option value="right">Right</option><option value="none">No logo</option>
          </select>
        </label>
        <label className={field}>Colours
          <select value={f.colour_source} disabled={!canEdit} onChange={(e) => set("colour_source", e.target.value)} className={inputClass}>
            <option value="theme">The portal&apos;s theme</option><option value="custom">Custom</option>
          </select>
        </label>
        {f.colour_source === "custom" ? (
          <div className="flex items-end gap-2">
            <label className={field}>Main<input type="color" value={f.primary || theme.primary} disabled={!canEdit} onChange={(e) => set("primary", e.target.value)} className="h-10 w-14 rounded border border-field" /></label>
            <label className={field}>Accent<input type="color" value={f.accent || theme.accent} disabled={!canEdit} onChange={(e) => set("accent", e.target.value)} className="h-10 w-14 rounded border border-field" /></label>
          </div>
        ) : <p className="self-end text-xs text-muted">Theme: <span className="inline-block size-3 rounded-full align-middle" style={{ background: theme.primary }} /> {theme.primary}</p>}
      </div>
      {secs.length ? (
        <fieldset className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
          <legend className="text-xs font-medium">Sections</legend>
          {secs.map(([k, l]) => (
            <label key={k} className="inline-flex items-center gap-2"><input type="checkbox" checked={isOn(k)} disabled={!canEdit} onChange={(e) => setF((o) => ({ ...o, sections: { ...o.sections, [k]: e.target.checked } }))} /> {l}</label>
          ))}
        </fieldset>
      ) : null}
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>Header note (optional)<textarea value={f.header_note} disabled={!canEdit} onChange={(e) => set("header_note", e.target.value)} maxLength={300} rows={2} className={`${inputClass} h-auto py-2`} /></label>
        <label className={field}>Footer text (optional)<textarea value={f.footer_text} disabled={!canEdit} onChange={(e) => set("footer_text", e.target.value)} maxLength={300} rows={2} className={`${inputClass} h-auto py-2`} /></label>
        {kind === "invoice" ? <label className={`${field} sm:col-span-2`}>Payment note (optional, under the bank details)<textarea value={f.payment_note} disabled={!canEdit} onChange={(e) => set("payment_note", e.target.value)} maxLength={500} rows={2} className={`${inputClass} h-auto py-2`} /></label> : null}
      </div>
      <p className="text-xs text-muted">Always printed whatever the settings: business name, ABN and address{kind === "invoice" ? ", \"Tax invoice\" when it is one, and GST" : ""}. Version {version} in use.</p>
      <div className="flex flex-wrap items-end gap-3">
        {canEdit ? (
          <>
            <label className={field}>What changed (optional)<input value={note} onChange={(e) => setNote(e.target.value)} maxLength={300} className={`${inputClass} w-64`} /></label>
            <Button type="button" size="sm" disabled={pending} onClick={() => start(async () => { const r = await saveTemplate(kind, { ...f, note }); setState(r); if (!r?.error) router.refresh(); })}>{pending ? "Saving…" : "Save as new version"}</Button>
          </>
        ) : null}
        <a href={`/settings/billing/templates/preview?kind=${kind}`} target="_blank" rel="noreferrer" className="text-sm font-semibold text-brand underline">Preview PDF (saved version)</a>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

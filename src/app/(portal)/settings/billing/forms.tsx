// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { CheckCircle2, CircleAlert, Trash2 } from "lucide-react";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { addHoliday, addPriceList, newVersion, publishVersion, removePart, saveBand, saveItem, saveRuleCheck, saveSchemeRules, saveVersion, setHolidayActive } from "./actions";

// cmeprojects (update 161): billing set-up forms. The database enforces every rule.
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

// ---- Scheme rules and the verification register ----
export type RuleCheck = { id: string; item: string; value: string; source: string; as_at: string | null; status: string; checked: string };
export type SchemeRule = { scheme: string; label: string; status: string; rules_summary: string; source: string; as_at: string | null; confirmed: string; checks: RuleCheck[] };

export function SchemeRuleCard({ rule, canApprove }: { rule: SchemeRule; canApprove: boolean }) {
  const [summary, setSummary] = useState(rule.rules_summary);
  const [source, setSource] = useState(rule.source);
  const [asAt, setAsAt] = useState(rule.as_at ?? "");
  const { pending, state, run } = useRun();
  const confirmed = rule.status === "confirmed";
  const open = rule.checks.filter((c) => c.status !== "verified").length;
  return (
    <details className="rounded-md border border-line px-3 py-2">
      <summary className="flex cursor-pointer list-none flex-wrap items-center gap-2 [&::-webkit-details-marker]:hidden">
        <span className="min-w-32 flex-1 font-semibold">{rule.label}</span>
        {confirmed ? (
          <span className="inline-flex items-center gap-1 rounded-full bg-good-soft px-2 py-0.5 text-xs font-semibold"><CheckCircle2 aria-hidden="true" className="size-3.5" /> Rules confirmed</span>
        ) : (
          <span className="inline-flex items-center gap-1 rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold"><CircleAlert aria-hidden="true" className="size-3.5" /> Not confirmed: billing stays off</span>
        )}
        {rule.checks.length ? <span className="text-xs text-muted">{rule.checks.length - open} of {rule.checks.length} figures verified</span> : null}
      </summary>
      <div className="mt-3 flex flex-col gap-3">
        {confirmed ? <p className="text-xs text-muted">{rule.confirmed}</p> : null}
        <label className={field}>
          This scheme&apos;s billing rules (in plain words)
          <textarea value={summary} onChange={(e) => setSummary(e.target.value)} disabled={!canApprove || confirmed} rows={3} maxLength={4000} className={inputClass} />
        </label>
        <div className="grid gap-2 sm:grid-cols-[1fr_12rem]">
          <label className={field}>
            Source
            <input value={source} onChange={(e) => setSource(e.target.value)} disabled={!canApprove || confirmed} maxLength={1000} placeholder="e.g. Owner decision, or the official document" className={inputClass} />
          </label>
          <label className={field}>
            As at
            <DateInput value={asAt} onChange={(e) => setAsAt(e.target.value)} disabled={!canApprove || confirmed} className={inputClass} />
          </label>
        </div>
        {canApprove ? (
          <div className="flex flex-wrap items-center gap-3">
            {confirmed ? (
              <Button type="button" size="sm" variant="outline" disabled={pending} onClick={async () => { if (await askConfirm("Mark this scheme's rules not confirmed? Billing for it stays off until confirmed again.", { action: "Mark not confirmed" })) run(() => saveSchemeRules(rule.scheme, { confirmed: false, summary, source, asAt })); }}>
                Mark not confirmed
              </Button>
            ) : (
              <>
                <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => saveSchemeRules(rule.scheme, { confirmed: false, summary, source, asAt }))}>Save draft</Button>
                <Button type="button" size="sm" disabled={pending} onClick={async () => { if (await askConfirm(`Confirm ${rule.label}'s billing rules? Billing for it can then be used (Phase 4B).`, { action: "Confirm rules" })) run(() => saveSchemeRules(rule.scheme, { confirmed: true, summary, source, asAt })); }}>
                  Confirm rules
                </Button>
              </>
            )}
            <Msg state={state} />
          </div>
        ) : null}
        {rule.checks.length ? (
          <div className="flex flex-col gap-2">
            <h3 className="text-xs font-semibold uppercase text-muted">Figures to verify (official source and &quot;as at&quot; date)</h3>
            {rule.checks.map((c) => <CheckRow key={c.id} check={c} canApprove={canApprove && !confirmed} />)}
          </div>
        ) : null}
      </div>
    </details>
  );
}

function CheckRow({ check, canApprove }: { check: RuleCheck; canApprove: boolean }) {
  const [value, setValue] = useState(check.value);
  const [source, setSource] = useState(check.source);
  const [asAt, setAsAt] = useState(check.as_at ?? "");
  const { pending, state, run } = useRun();
  const ok = check.status === "verified";
  return (
    <div className={`rounded-md border px-2 py-2 text-sm ${ok ? "border-good/40" : "border-warn/40"}`}>
      <p className="font-semibold">
        {ok ? <CheckCircle2 aria-hidden="true" className="mr-1 inline size-4 text-good" /> : <CircleAlert aria-hidden="true" className="mr-1 inline size-4 text-warn" />}
        {check.item}
      </p>
      {ok ? <p className="text-xs text-muted">{check.value} · {check.source} · as at {check.as_at?.split("-").reverse().join("/")} · {check.checked}</p> : null}
      {canApprove ? (
        <div className="mt-2 grid gap-2 sm:grid-cols-[1fr_1fr_10rem_auto] sm:items-end">
          <label className={field}>Figure or rule<input value={value} onChange={(e) => setValue(e.target.value)} maxLength={1000} className={inputClass} /></label>
          <label className={field}>Official source<input value={source} onChange={(e) => setSource(e.target.value)} maxLength={1000} className={inputClass} /></label>
          <label className={field}>As at<DateInput value={asAt} onChange={(e) => setAsAt(e.target.value)} className={inputClass} /></label>
          <div className="flex gap-2">
            <Button type="button" size="sm" disabled={pending} onClick={() => run(() => saveRuleCheck(check.id, { verified: true, value, source, asAt }))}>{ok ? "Update" : "Mark verified"}</Button>
            {ok ? <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => saveRuleCheck(check.id, { verified: false, value, source, asAt }))}>Unverify</button> : null}
          </div>
        </div>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

// ---- Price lists ----
export function NewPriceListForm({ schemes }: { schemes: [string, string][] }) {
  const [state, action, pending] = useActionState(addPriceList, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Scheme
          <select name="scheme" required className={inputClass}>
            {schemes.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
          </select>
        </label>
        <label className={`${field} sm:col-span-2`}>Name<input name="name" required maxLength={120} placeholder="e.g. Standard prices" className={inputClass} /></label>
      </div>
      <label className={field}>Description (optional)<input name="description" maxLength={1000} className={inputClass} /></label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>{pending ? "Saving…" : "Add price list"}</Button>
        <Msg state={state} />
      </div>
    </form>
  );
}

export type Version = { id: string; version: number; status: string; effective_from: string | null; unit_minutes: number; rounding: string; minimum_minutes: number; crossing: string; notes: string };

export function VersionSettings({ v, listId, editable }: { v: Version; listId: string; editable: boolean }) {
  const init = { effective_from: v.effective_from ?? "", unit_minutes: String(v.unit_minutes), rounding: v.rounding, minimum_minutes: String(v.minimum_minutes), crossing: v.crossing, notes: v.notes };
  const [f, setF] = useState(init);
  const set = (k: keyof typeof init, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>Takes effect from<DateInput value={f.effective_from} onChange={(e) => set("effective_from", e.target.value)} disabled={!editable} className={inputClass} /></label>
        <label className={field}>
          Billing unit (minutes)
          <input value={f.unit_minutes} onChange={(e) => set("unit_minutes", e.target.value)} disabled={!editable} inputMode="numeric" className={inputClass} />
        </label>
        <label className={field}>
          Rounding to the unit
          <select value={f.rounding} onChange={(e) => set("rounding", e.target.value)} disabled={!editable} className={inputClass}>
            <option value="nearest">Nearest unit</option>
            <option value="up">Always up</option>
            <option value="down">Always down</option>
          </select>
        </label>
        <label className={field}>
          Minimum charge (minutes, 0 for none)
          <input value={f.minimum_minutes} onChange={(e) => set("minimum_minutes", e.target.value)} disabled={!editable} inputMode="numeric" className={inputClass} />
        </label>
        <label className={`${field} sm:col-span-2`}>
          Shifts that cross from one band to another
          <select value={f.crossing} onChange={(e) => set("crossing", e.target.value)} disabled={!editable} className={inputClass}>
            <option value="split">Split the time across each band (one billing line per band)</option>
            <option value="whole_highest">Charge the whole shift at the highest band it touches</option>
          </select>
        </label>
      </div>
      <label className={field}>Notes (optional)<textarea value={f.notes} onChange={(e) => set("notes", e.target.value)} disabled={!editable} rows={2} maxLength={2000} className={inputClass} /></label>
      {editable ? (
        <div className="flex flex-wrap items-center gap-3">
          <Button type="button" size="sm" disabled={pending || JSON.stringify(f) === JSON.stringify(init)} onClick={() => run(() => saveVersion(v.id, listId, f))}>Save</Button>
          <Msg state={state} />
        </div>
      ) : null}
    </div>
  );
}

export function BandForm({ versionId, listId }: { versionId: string; listId: string }) {
  const [f, setF] = useState({ key: "", label: "", day_kind: "weekday", starts_at: "06:00", ends_at: "20:00" });
  const set = (k: keyof typeof f, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-5">
        <label className={field}>Code<input value={f.key} onChange={(e) => set("key", e.target.value)} maxLength={40} placeholder="weekday_day" className={inputClass} /></label>
        <label className={field}>Name<input value={f.label} onChange={(e) => set("label", e.target.value)} maxLength={80} placeholder="Weekday day" className={inputClass} /></label>
        <label className={field}>
          Day
          <select value={f.day_kind} onChange={(e) => set("day_kind", e.target.value)} className={inputClass}>
            <option value="weekday">Weekday</option>
            <option value="saturday">Saturday</option>
            <option value="sunday">Sunday</option>
            <option value="public_holiday">Public holiday</option>
          </select>
        </label>
        {f.day_kind === "weekday" ? (
          <>
            <label className={field}>From<input type="time" value={f.starts_at} onChange={(e) => set("starts_at", e.target.value)} className={inputClass} /></label>
            <label className={field}>To (00:00 = midnight)<input type="time" value={f.ends_at} onChange={(e) => set("ends_at", e.target.value)} className={inputClass} /></label>
          </>
        ) : <p className="self-end text-xs text-muted sm:col-span-2">All day</p>}
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => saveBand(versionId, listId, f), () => setF((o) => ({ ...o, key: "", label: "" })))}>Add band</Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

export function ItemForm({ versionId, listId, bands, catalogue, scheme }: { versionId: string; listId: string; bands: [string, string][]; catalogue: [string, string][]; scheme: string }) {
  const blank = { label: "", catalogue_id: "", unit: "hour", band_key: bands[0]?.[0] ?? "", price: "", gst_code: "gst_free", sah_category: "", personal_care: "false", ndis_item: "" };
  const [f, setF] = useState(blank);
  const set = (k: keyof typeof blank, x: string) => setF((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-4">
        <label className={field}>
          Service (from the catalogue)
          <select value={f.catalogue_id} onChange={(e) => { set("catalogue_id", e.target.value); if (!f.label) set("label", catalogue.find(([k]) => k === e.target.value)?.[1] ?? ""); }} className={inputClass}>
            <option value="">Not linked</option>
            {catalogue.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
          </select>
        </label>
        <label className={field}>Name on the price list<input value={f.label} onChange={(e) => set("label", e.target.value)} maxLength={160} className={inputClass} /></label>
        <label className={field}>
          Band
          <select value={f.band_key} onChange={(e) => set("band_key", e.target.value)} className={inputClass}>
            <option value="">Any time (not by band)</option>
            {bands.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
          </select>
        </label>
        <label className={field}>Price (AUD)<input value={f.price} onChange={(e) => set("price", e.target.value)} inputMode="decimal" className={inputClass} /></label>
        <label className={field}>
          Per
          <select value={f.unit} onChange={(e) => set("unit", e.target.value)} className={inputClass}>
            <option value="hour">Hour</option><option value="visit">Visit</option><option value="each">Each</option><option value="km">Kilometre</option><option value="day">Day</option>
          </select>
        </label>
        <label className={field}>
          GST
          <select value={f.gst_code} onChange={(e) => set("gst_code", e.target.value)} className={inputClass}>
            <option value="gst_free">GST-free</option><option value="taxable">Taxable</option><option value="input_taxed">Input-taxed</option>
          </select>
        </label>
        {scheme === "support_at_home" ? (
          <>
            <label className={field}>
              Category (decides the contribution)
              <select value={f.sah_category} onChange={(e) => set("sah_category", e.target.value)} className={inputClass}>
                <option value="">Choose…</option><option value="clinical">Clinical</option><option value="independence">Independence</option><option value="everyday_living">Everyday living</option>
              </select>
            </label>
            <label className="flex items-center gap-2 self-end text-xs font-medium">
              <input type="checkbox" checked={f.personal_care === "true"} onChange={(e) => set("personal_care", String(e.target.checked))} /> Personal care
            </label>
          </>
        ) : null}
        {scheme === "ndis" ? <label className={field}>NDIS support item number<input value={f.ndis_item} onChange={(e) => set("ndis_item", e.target.value)} maxLength={40} className={inputClass} /></label> : null}
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => saveItem(versionId, listId, f), () => setF(blank))}>Add price</Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

export function RemovePart({ kind, id, listId, label }: { kind: "band" | "item"; id: string; listId: string; label: string }) {
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex items-center gap-2">
      <button type="button" className={linkBtn} aria-label={`Remove ${label}`} disabled={pending} onClick={async () => { if (await askConfirm(`Remove ${label} from this draft?`, { action: "Remove" })) run(() => removePart(kind, id, listId)); }}>
        <Trash2 aria-hidden="true" className="size-3.5" />
      </button>
      {state?.error ? <Msg state={state} /> : null}
    </span>
  );
}

export function VersionButtons({ listId, draftId, canNew }: { listId: string; draftId: string | null; canNew: boolean }) {
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-wrap items-center gap-3">
      {draftId ? (
        <Button type="button" size="sm" disabled={pending} onClick={async () => { if (await askConfirm("Publish this version? It never changes after this; the current version is retired and kept.", { action: "Publish" })) run(() => publishVersion(draftId, listId)); }}>
          Publish draft
        </Button>
      ) : null}
      {canNew ? <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => newVersion(listId))}>Start a new version</Button> : null}
      <Msg state={state} />
    </div>
  );
}

// ---- Public holidays ----
const STATES = ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"];
export function HolidayForm() {
  const [state, action, pending] = useActionState(addHoliday, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-[8rem_12rem_1fr]">
        <label className={field}>State<select name="state" required className={inputClass}>{STATES.map((s) => <option key={s} value={s}>{s}</option>)}</select></label>
        <label className={field}>Date<DateInput name="on_date" required className={inputClass} /></label>
        <label className={field}>Name<input name="name" required maxLength={120} placeholder="e.g. Christmas Day" className={inputClass} /></label>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>{pending ? "Saving…" : "Add holiday"}</Button>
        <Msg state={state} />
      </div>
    </form>
  );
}

export function HolidayToggle({ id, active }: { id: string; active: boolean }) {
  const { pending, state, run } = useRun();
  return (
    <span className="inline-flex items-center gap-2">
      <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => setHolidayActive(id, !active))}>{active ? "Switch off" : "Switch on"}</button>
      {state?.error ? <Msg state={state} /> : null}
    </span>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, useTransition, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { CheckCircle2, ClipboardList, FileCheck2, Link2, Pencil, Trash2 } from "lucide-react";
import { Button, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import type { FormState } from "@/lib/form";
import { addToWorkerInstructions, generateCareDocuments, recordAgreement, removeDocLine, saveDocHeader, saveDocLine, setDocStep, startDoc, type DocKind } from "./care-doc-actions";

// cmeprojects (update 160): care plans, support plans and proposed budgets.
// Each goes Draft -> Pending review -> Changes required / Approved -> Superseded.
// The database enforces every step; these pieces show what each person can do.
const field = "flex flex-col gap-1 text-xs font-medium";
const linkBtn = "text-xs font-semibold text-brand underline disabled:opacity-50";

export const CARE_SECTIONS: [string, string][] = [
  ["need", "Needs"],
  ["risk", "Risks and safety"],
  ["requirement", "Care requirements"],
  ["intervention", "Interventions"],
  ["instruction", "Support instructions"],
  ["monitoring", "Monitoring"],
  ["preference", "Preferences"],
];

const STATUS: Record<string, [string, string]> = {
  draft: ["Draft", "bg-warn-soft"],
  pending_review: ["Pending review", "bg-brand-soft"],
  changes_required: ["Changes required", "bg-danger-soft"],
  current: ["Approved", "bg-good-soft"],
  approved: ["Approved", "bg-good-soft"],
  archived: ["Superseded", "bg-line"],
  superseded: ["Superseded", "bg-line"],
};

export function DocStatus({ status, withdrawn = false }: { status: string; withdrawn?: boolean }) {
  const [text, tone] = withdrawn ? ["Withdrawn", "bg-line"] : (STATUS[status] ?? [status, "bg-line"]);
  return <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tone}`}>{text}</span>;
}

export type Trail = {
  source?: string | null;
  program?: string | null;
  made?: string | null;
  submitted?: string | null;
  reviewed?: string | null;
  approved?: string | null;
  reviewNote?: string;
  status: string;
};

// Where it came from, and who did each step.
export function DocTrail({ t }: { t: Trail }) {
  const bits = [t.made, t.submitted, t.approved ?? (t.status === "changes_required" ? t.reviewed : null)].filter(Boolean);
  return (
    <div className="flex flex-col gap-1 text-xs text-muted">
      {t.source || t.program ? (
        <p className="flex flex-wrap items-center gap-1">
          <Link2 aria-hidden="true" className="size-3.5" />
          {t.source ? <span>From {t.source}</span> : <span>Made by hand</span>}
          {t.program ? <span>· program: {t.program}</span> : null}
        </p>
      ) : null}
      {bits.length ? <p>{bits.join(" · ")}</p> : null}
      {t.reviewNote && t.status === "changes_required" ? (
        <p className="rounded-md bg-danger-soft px-2 py-1 text-ink">
          <span className="font-semibold">What needs changing:</span> {t.reviewNote}
        </p>
      ) : null}
    </div>
  );
}

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
  return { pending, state, run, setState };
}

function Msg({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

// The review steps. "mine" = this person made or submitted it, so they can't approve it.
export function DocSteps({ kind, id, status, canEdit, canApprove, mine }: { kind: DocKind; id: string; status: string; canEdit: boolean; canApprove: boolean; mine: boolean }) {
  const { pending, state, run } = useRun();
  const [note, setNote] = useState("");
  const [asking, setAsking] = useState(false);
  const what = kind === "budget" ? "proposed budget" : kind === "support" ? "support plan" : "care plan";
  const editable = status === "draft" || status === "changes_required";
  const reviewing = status === "pending_review";
  if (!editable && !reviewing) return null;
  return (
    <div className="flex flex-col gap-2 rounded-md border border-line bg-page px-3 py-2">
      <div className="flex flex-wrap items-center gap-3">
        {editable && canEdit ? (
          <Button type="button" size="sm" disabled={pending} onClick={() => run(() => setDocStep(kind, id, "submit"))}>
            Send for review
          </Button>
        ) : null}
        {reviewing && canApprove && !mine ? (
          <>
            <Button
              size="sm"
              disabled={pending}
              onClick={async () => {
                if (await askConfirm(`Approve this ${what}? Its wording is then fixed, and any earlier approved one is superseded (kept).`, { action: "Approve" })) run(() => setDocStep(kind, id, "approve"));
              }}
            >
              Approve
            </Button>
            <button type="button" className={linkBtn} disabled={pending} onClick={() => setAsking((v) => !v)}>
              Changes required
            </button>
          </>
        ) : null}
        {reviewing && canEdit ? (
          <button type="button" className={linkBtn} disabled={pending} onClick={() => run(() => setDocStep(kind, id, "take_back"))}>
            Take back to draft
          </button>
        ) : null}
        {kind === "care" && editable && canEdit ? (
          <button
            type="button"
            className={linkBtn}
            disabled={pending}
            onClick={async () => {
              if (await askConfirm("Withdraw this draft? It's kept with the client's records but can't be used again.", { action: "Withdraw" })) run(() => setDocStep(kind, id, "withdraw"));
            }}
          >
            Withdraw draft
          </button>
        ) : null}
      </div>
      {reviewing && canApprove && mine ? <p className="text-xs text-muted">You made or sent this one, so someone else with the right to approve reviews it.</p> : null}
      {reviewing && !canApprove ? <p className="text-xs text-muted">Waiting for someone with the right to approve {what}s.</p> : null}
      {asking ? (
        <div className="flex flex-col gap-2">
          <label className={field}>
            What needs changing
            <textarea value={note} onChange={(e) => setNote(e.target.value)} maxLength={1000} rows={2} className={inputClass} />
          </label>
          <div>
            <Button type="button" size="sm" variant="secondary" disabled={pending || !note.trim()} onClick={() => run(() => setDocStep(kind, id, "changes", note), () => setAsking(false))}>
              Send back
            </Button>
          </div>
        </div>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

function SourceTag({ from, edited }: { from?: string | null; edited?: boolean }) {
  if (!from) return null;
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-page px-2 py-0.5 text-[11px] text-muted ring-1 ring-line" title={from}>
      <ClipboardList aria-hidden="true" className="size-3" />
      From assessment{edited ? " · edited" : ""}
    </span>
  );
}

// ---- Care plan items ----
export type CareItem = { id: string; section: string; text: string; detail: string; edited: boolean; source?: string | null; instructionAdded?: boolean };

export function CareItems({ planId, clientId, items, editable, approved, canEdit }: { planId: string; clientId: string; items: CareItem[]; editable: boolean; approved: boolean; canEdit: boolean }) {
  return (
    <div className="flex flex-col gap-3">
      {CARE_SECTIONS.map(([key, title]) => {
        const rows = items.filter((i) => i.section === key);
        if (!rows.length && !(editable && canEdit)) return null;
        return (
          <section key={key} aria-label={title} className="flex flex-col gap-1">
            <h3 className="text-xs font-semibold uppercase text-muted">{title}</h3>
            {rows.length ? (
              <ul className="flex flex-col gap-1">
                {rows.map((i) => (
                  <CareItemRow key={i.id} item={i} clientId={clientId} planId={planId} editable={editable && canEdit} canInstruct={approved && canEdit && key === "instruction"} />
                ))}
              </ul>
            ) : (
              <p className="text-xs text-muted">None yet.</p>
            )}
          </section>
        );
      })}
      {editable && canEdit ? <AddCareItem planId={planId} clientId={clientId} /> : null}
    </div>
  );
}

function CareItemRow({ item, clientId, planId, editable, canInstruct }: { item: CareItem; clientId: string; planId: string; editable: boolean; canInstruct: boolean }) {
  const [editing, setEditing] = useState(false);
  const [text, setText] = useState(item.text);
  const [detail, setDetail] = useState(item.detail);
  const [heading, setHeading] = useState(item.text.slice(0, 60));
  const [instructing, setInstructing] = useState(false);
  const { pending, state, run } = useRun();
  return (
    <li className="rounded-md border border-line px-2 py-1.5">
      {editing ? (
        <div className="flex flex-col gap-2">
          <input aria-label="Item" value={text} onChange={(e) => setText(e.target.value)} maxLength={1000} className={inputClass} />
          <textarea aria-label="More detail (optional)" value={detail} onChange={(e) => setDetail(e.target.value)} maxLength={2000} rows={2} className={inputClass} />
          <div className="flex gap-3">
            <Button type="button" size="sm" disabled={pending || !text.trim()} onClick={() => run(() => saveDocLine("care", planId, clientId, { section: item.section, text, detail }, item.id), () => setEditing(false))}>
              Save
            </Button>
            <button type="button" className={linkBtn} onClick={() => setEditing(false)}>
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <div className="flex flex-wrap items-start gap-2">
          <span className="min-w-40 flex-1">
            {item.text}
            {item.detail ? <span className="block whitespace-pre-line text-xs text-muted">{item.detail}</span> : null}
          </span>
          <SourceTag from={item.source} edited={item.edited} />
          {editable ? (
            <span className="flex gap-2">
              <button type="button" className={linkBtn} onClick={() => setEditing(true)} aria-label={`Change: ${item.text}`}>
                <Pencil aria-hidden="true" className="size-3.5" />
              </button>
              <button
                type="button"
                className={linkBtn}
                aria-label={`Remove: ${item.text}`}
                onClick={async () => {
                  if (await askConfirm("Remove this item from the draft?", { action: "Remove" })) run(() => removeDocLine("care", item.id, clientId));
                }}
              >
                <Trash2 aria-hidden="true" className="size-3.5" />
              </button>
            </span>
          ) : null}
          {item.instructionAdded ? (
            <span className="inline-flex items-center gap-1 text-xs text-good">
              <FileCheck2 aria-hidden="true" className="size-3.5" /> In worker instructions
            </span>
          ) : canInstruct ? (
            <button type="button" className={linkBtn} onClick={() => setInstructing((v) => !v)}>
              Add to worker instructions
            </button>
          ) : null}
        </div>
      )}
      {instructing && !item.instructionAdded ? (
        <div className="mt-2 flex flex-wrap items-end gap-2">
          <label className={field}>
            Heading staff see
            <input value={heading} onChange={(e) => setHeading(e.target.value)} maxLength={120} className={inputClass} />
          </label>
          <Button type="button" size="sm" disabled={pending || !heading.trim()} onClick={() => run(() => addToWorkerInstructions(item.id, clientId, heading), () => setInstructing(false))}>
            Add
          </Button>
        </div>
      ) : null}
      <Msg state={state} />
    </li>
  );
}

function AddCareItem({ planId, clientId }: { planId: string; clientId: string }) {
  const [section, setSection] = useState("need");
  const [text, setText] = useState("");
  const [detail, setDetail] = useState("");
  const { pending, state, run } = useRun();
  return (
    <details className="rounded-md border border-dashed border-line px-3 py-2">
      <summary className="cursor-pointer text-xs font-semibold text-brand">Add an item</summary>
      <div className="mt-2 flex flex-col gap-2">
        <div className="grid gap-2 sm:grid-cols-[12rem_1fr]">
          <label className={field}>
            Section
            <select value={section} onChange={(e) => setSection(e.target.value)} className={inputClass}>
              {CARE_SECTIONS.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className={field}>
            Item
            <input value={text} onChange={(e) => setText(e.target.value)} maxLength={1000} className={inputClass} />
          </label>
        </div>
        <label className={field}>
          More detail (optional)
          <textarea value={detail} onChange={(e) => setDetail(e.target.value)} maxLength={2000} rows={2} className={inputClass} />
        </label>
        <div>
          <Button type="button" size="sm" disabled={pending || !text.trim()} onClick={() => run(() => saveDocLine("care", planId, clientId, { section, text, detail }), () => { setText(""); setDetail(""); })}>
            Add item
          </Button>
        </div>
        <Msg state={state} />
      </div>
    </details>
  );
}

// ---- Support plan and budget lines ----
type Svc = [string, string];
export type SupportLine = { id: string; support: string; frequency: string; hours_per_week: number | null; delivery: string; responsibilities: string; instructions: string; service_id: string | null; edited: boolean; source?: string | null };
export type BudgetLine = { id: string; description: string; hours_per_week: number | null; weeks: number | null; estimated_rate: number | null; estimated_cost: number; service_id: string | null; fromSupport: boolean };

const aud = (n: number) => Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" });
const s = (v: number | null) => (v === null || v === undefined ? "" : String(v));

function LineEditor({ fields, initial, services, onSave, onCancel, pending, saveLabel }: { fields: [string, string, "text" | "long" | "number"][]; initial: Record<string, string>; services: Svc[]; onSave: (v: Record<string, string>) => void; onCancel?: () => void; pending: boolean; saveLabel: string }) {
  const [v, setV] = useState(initial);
  const set = (k: string, x: string) => setV((o) => ({ ...o, [k]: x }));
  return (
    <div className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-2">
        {fields.map(([k, l, t]) => (
          <label key={k} className={`${field} ${t === "long" ? "sm:col-span-2" : ""}`}>
            {l}
            {t === "long" ? (
              <textarea value={v[k] ?? ""} onChange={(e) => set(k, e.target.value)} rows={2} maxLength={2000} className={inputClass} />
            ) : (
              <input value={v[k] ?? ""} onChange={(e) => set(k, e.target.value)} inputMode={t === "number" ? "decimal" : undefined} maxLength={500} className={inputClass} />
            )}
          </label>
        ))}
        <label className={field}>
          Approved service (optional)
          <select value={v.service_id ?? ""} onChange={(e) => set("service_id", e.target.value)} className={inputClass}>
            <option value="">Not linked yet</option>
            {services.map(([id, l]) => (
              <option key={id} value={id}>
                {l}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div className="flex gap-3">
        <Button type="button" size="sm" disabled={pending} onClick={() => onSave(v)}>
          {saveLabel}
        </Button>
        {onCancel ? (
          <button type="button" className={linkBtn} onClick={onCancel}>
            Cancel
          </button>
        ) : null}
      </div>
    </div>
  );
}

const SUPPORT_FIELDS: [string, string, "text" | "long" | "number"][] = [
  ["support", "Support", "text"],
  ["frequency", "How often", "text"],
  ["hours_per_week", "Hours a week", "number"],
  ["delivery", "How it's delivered", "long"],
  ["responsibilities", "Who does what", "long"],
  ["instructions", "Instructions and preferences", "long"],
];
const BUDGET_FIELDS: [string, string, "text" | "long" | "number"][] = [
  ["description", "Description", "text"],
  ["hours_per_week", "Hours a week", "number"],
  ["weeks", "Weeks", "number"],
  ["estimated_rate", "Estimated rate (AUD an hour)", "number"],
];

export function SupportLines({ planId, clientId, lines, services, editable }: { planId: string; clientId: string; lines: SupportLine[]; services: Svc[]; editable: boolean }) {
  const { pending, state, run } = useRun();
  const [editing, setEditing] = useState<string | null>(null);
  const svcName = new Map(services);
  return (
    <div className="flex flex-col gap-2">
      {lines.length ? (
        <ul className="flex flex-col gap-1">
          {lines.map((l) => (
            <li key={l.id} className="rounded-md border border-line px-2 py-1.5 text-sm">
              {editing === l.id ? (
                <LineEditor
                  fields={SUPPORT_FIELDS}
                  services={services}
                  initial={{ support: l.support, frequency: l.frequency, hours_per_week: s(l.hours_per_week), delivery: l.delivery, responsibilities: l.responsibilities, instructions: l.instructions, service_id: l.service_id ?? "" }}
                  pending={pending}
                  saveLabel="Save"
                  onCancel={() => setEditing(null)}
                  onSave={(v) => run(() => saveDocLine("support", planId, clientId, v, l.id), () => setEditing(null))}
                />
              ) : (
                <div className="flex flex-wrap items-start gap-2">
                  <span className="min-w-40 flex-1">
                    <span className="font-semibold">{l.support}</span>
                    <span className="block text-xs text-muted">
                      {[l.frequency, l.hours_per_week !== null ? `${l.hours_per_week} h a week` : "", l.service_id ? svcName.get(l.service_id) ?? "service" : "no service linked"].filter(Boolean).join(" · ")}
                    </span>
                    {l.delivery ? <span className="block text-xs">How: {l.delivery}</span> : null}
                    {l.responsibilities ? <span className="block text-xs">Who: {l.responsibilities}</span> : null}
                    {l.instructions ? <span className="block whitespace-pre-line text-xs">{l.instructions}</span> : null}
                  </span>
                  <SourceTag from={l.source} edited={l.edited} />
                  {editable ? (
                    <span className="flex gap-2">
                      <button type="button" className={linkBtn} onClick={() => setEditing(l.id)} aria-label={`Change: ${l.support}`}>
                        <Pencil aria-hidden="true" className="size-3.5" />
                      </button>
                      <button
                        type="button"
                        className={linkBtn}
                        aria-label={`Remove: ${l.support}`}
                        onClick={async () => {
                          if (await askConfirm("Remove this line from the draft?", { action: "Remove" })) run(() => removeDocLine("support", l.id, clientId));
                        }}
                      >
                        <Trash2 aria-hidden="true" className="size-3.5" />
                      </button>
                    </span>
                  ) : null}
                </div>
              )}
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-xs text-muted">No supports yet.</p>
      )}
      {editable ? (
        <details className="rounded-md border border-dashed border-line px-3 py-2">
          <summary className="cursor-pointer text-xs font-semibold text-brand">Add a support</summary>
          <div className="mt-2">
            <LineEditor key={lines.length} fields={SUPPORT_FIELDS} services={services} initial={{}} pending={pending} saveLabel="Add support" onSave={(v) => run(() => saveDocLine("support", planId, clientId, v))} />
          </div>
        </details>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

export type FundingFit = { service_id: string | null; service_label: string | null; estimated_cost: number; funding_id: string | null; funding_start: string | null; funding_end: string | null; total: number | null; used: number | null; remaining: number | null; fit: "covers" | "partial" | "none" };

export function BudgetLines({ proposalId, clientId, lines, services, editable, fits, day }: { proposalId: string; clientId: string; lines: BudgetLine[]; services: Svc[]; editable: boolean; fits: FundingFit[]; day: Record<string, string> }) {
  const { pending, state, run } = useRun();
  const [editing, setEditing] = useState<string | null>(null);
  const svcName = new Map(services);
  const total = lines.reduce((t, l) => t + Number(l.estimated_cost), 0);
  // Per service: estimated cost, and only funding whose period fits inside the budget period counts.
  const byService = new Map<string, FundingFit[]>();
  for (const f of fits) byService.set(f.service_id ?? "", [...(byService.get(f.service_id ?? "") ?? []), f]);
  return (
    <div className="flex flex-col gap-2">
      <p className="rounded-md bg-warn-soft px-2 py-1 text-xs">Estimates only. A proposed budget isn&apos;t funding, a price list or an invoice, and never changes funding records.</p>
      {lines.length ? (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[34rem] text-left text-sm">
            <thead className="text-xs text-muted">
              <tr>
                <th className="py-1 pr-2 font-semibold">Line</th>
                <th className="py-1 pr-2 font-semibold">Service</th>
                <th className="py-1 pr-2 text-right font-semibold">Hours/wk</th>
                <th className="py-1 pr-2 text-right font-semibold">Weeks</th>
                <th className="py-1 pr-2 text-right font-semibold">Rate</th>
                <th className="py-1 pr-2 text-right font-semibold">Estimate</th>
                {editable ? <th className="py-1"><span className="sr-only">Actions</span></th> : null}
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {lines.map((l) =>
                editing === l.id ? (
                  <tr key={l.id}>
                    <td colSpan={7} className="py-2">
                      <LineEditor
                        fields={BUDGET_FIELDS}
                        services={services}
                        initial={{ description: l.description, hours_per_week: s(l.hours_per_week), weeks: s(l.weeks), estimated_rate: s(l.estimated_rate), service_id: l.service_id ?? "" }}
                        pending={pending}
                        saveLabel="Save"
                        onCancel={() => setEditing(null)}
                        onSave={(v) => run(() => saveDocLine("budget", proposalId, clientId, v, l.id), () => setEditing(null))}
                      />
                    </td>
                  </tr>
                ) : (
                  <tr key={l.id}>
                    <td className="py-1 pr-2">
                      {l.description}
                      {l.fromSupport ? <span className="block text-[11px] text-muted">From the support plan</span> : null}
                    </td>
                    <td className="py-1 pr-2 text-xs">{l.service_id ? svcName.get(l.service_id) ?? "Service" : <span className="text-muted">Not linked</span>}</td>
                    <td className="py-1 pr-2 text-right">{s(l.hours_per_week) || "–"}</td>
                    <td className="py-1 pr-2 text-right">{s(l.weeks) || "–"}</td>
                    <td className="py-1 pr-2 text-right">{l.estimated_rate !== null ? aud(l.estimated_rate) : "–"}</td>
                    <td className="py-1 pr-2 text-right font-semibold">{aud(l.estimated_cost)}</td>
                    {editable ? (
                      <td className="py-1 text-right">
                        <span className="inline-flex gap-2">
                          <button type="button" className={linkBtn} onClick={() => setEditing(l.id)} aria-label={`Change: ${l.description}`}>
                            <Pencil aria-hidden="true" className="size-3.5" />
                          </button>
                          <button
                            type="button"
                            className={linkBtn}
                            aria-label={`Remove: ${l.description}`}
                            onClick={async () => {
                              if (await askConfirm("Remove this line from the draft?", { action: "Remove" })) run(() => removeDocLine("budget", l.id, clientId));
                            }}
                          >
                            <Trash2 aria-hidden="true" className="size-3.5" />
                          </button>
                        </span>
                      </td>
                    ) : null}
                  </tr>
                ),
              )}
            </tbody>
            <tfoot>
              <tr>
                <td colSpan={5} className="py-1 pr-2 text-right text-xs font-semibold">Estimated total</td>
                <td className="py-1 pr-2 text-right font-semibold">{aud(total)}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      ) : (
        <p className="text-xs text-muted">No lines yet.</p>
      )}
      {editable ? (
        <details className="rounded-md border border-dashed border-line px-3 py-2">
          <summary className="cursor-pointer text-xs font-semibold text-brand">Add a line</summary>
          <div className="mt-2">
            <LineEditor key={lines.length} fields={BUDGET_FIELDS} services={services} initial={{}} pending={pending} saveLabel="Add line" onSave={(v) => run(() => saveDocLine("budget", proposalId, clientId, v))} />
          </div>
        </details>
      ) : null}
      {lines.length ? (
        <section aria-label="Compared with funding" className="flex flex-col gap-1">
          <h3 className="text-xs font-semibold uppercase text-muted">Compared with recorded funding</h3>
          <ul className="flex flex-col gap-1 text-xs">
            {[...byService.entries()].map(([svc, rows]) => {
              const cost = Number(rows[0]?.estimated_cost ?? 0);
              const covers = rows.filter((r) => r.fit === "covers");
              const partial = rows.filter((r) => r.fit === "partial");
              const period = (r: FundingFit) => `${day[r.funding_start ?? ""] ?? r.funding_start} to ${day[r.funding_end ?? ""] ?? r.funding_end}`;
              const name = svc ? svcName.get(svc) ?? rows[0]?.service_label ?? "Service" : "Lines not linked to a service";
              return (
                <li key={svc || "none"} className="rounded-md border border-line px-2 py-1">
                  <span className="font-semibold">{name}</span>: estimate {aud(cost)}
                  {!svc ? (
                    <span className="block text-muted">Link these lines to a service to compare them with funding.</span>
                  ) : covers.length === 0 && partial.length === 0 ? (
                    <span className="block font-semibold text-warn">No verified funding recorded for this period.</span>
                  ) : (
                    <>
                      {covers.length === 0 ? <span className="block font-semibold text-warn">No funding record covers the whole budget period.</span> : null}
                      {covers.map((r) => (
                        <span key={r.funding_id} className="block">
                          <span className="font-semibold">Covers the whole budget period:</span> funding {period(r)}, {aud(Number(r.remaining ?? 0))} left of {aud(Number(r.total ?? 0))} for that whole funding period (not prorated to this budget period).
                          {cost > Number(r.remaining ?? 0) ? <span className="block font-semibold text-danger">The estimate is more than what&apos;s left in this funding record.</span> : null}
                        </span>
                      ))}
                      {partial.map((r) => (
                        <span key={r.funding_id} className="block text-muted">
                          <span className="font-semibold">Partly overlaps, not counted:</span> funding {period(r)}, {aud(Number(r.remaining ?? 0))} left of {aud(Number(r.total ?? 0))} for that funding period.
                        </span>
                      ))}
                    </>
                  )}
                </li>
              );
            })}
          </ul>
        </section>
      ) : null}
      <Msg state={state} />
    </div>
  );
}

// Support plan or budget heading, while it can change.
export function DocHeader({ kind, id, clientId, values }: { kind: "support" | "budget"; id: string; clientId: string; values: Record<string, string> }) {
  const [v, setV] = useState(values);
  const set = (k: string, x: string) => setV((o) => ({ ...o, [k]: x }));
  const { pending, state, run } = useRun();
  const changed = JSON.stringify(v) !== JSON.stringify(values);
  return (
    <div className="flex flex-col gap-2">
      <label className={field}>
        Title
        <input value={v.title ?? ""} onChange={(e) => set("title", e.target.value)} maxLength={120} className={inputClass} />
      </label>
      {kind === "support" ? (
        <>
          <div className="grid gap-2 sm:grid-cols-2">
            <label className={field}>
              Starts on
              <DateInput value={v.starts_on ?? ""} onChange={(e) => set("starts_on", e.target.value)} className={inputClass} />
            </label>
            <label className={field}>
              Review by
              <DateInput value={v.review_by ?? ""} onChange={(e) => set("review_by", e.target.value)} className={inputClass} />
            </label>
          </div>
          <label className={field}>
            Summary
            <textarea value={v.summary ?? ""} onChange={(e) => set("summary", e.target.value)} maxLength={4000} rows={3} className={inputClass} />
          </label>
        </>
      ) : (
        <>
          <div className="grid gap-2 sm:grid-cols-2">
            <label className={field}>
              Period starts
              <DateInput value={v.period_start ?? ""} onChange={(e) => set("period_start", e.target.value)} className={inputClass} />
            </label>
            <label className={field}>
              Period ends
              <DateInput value={v.period_end ?? ""} onChange={(e) => set("period_end", e.target.value)} className={inputClass} />
            </label>
          </div>
          <label className={field}>
            Notes
            <textarea value={v.notes ?? ""} onChange={(e) => set("notes", e.target.value)} maxLength={2000} rows={2} className={inputClass} />
          </label>
        </>
      )}
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size="sm" disabled={pending || !changed} onClick={() => run(() => saveDocHeader(kind, id, clientId, v))}>
          Save
        </Button>
        <Msg state={state} />
      </div>
    </div>
  );
}

// ---- Agreement ----
export type Agreement = { agreed_name: string; agreed_by: string; capacity: string; authority: string; method: string; agreed_on: string; recorded: string; notes: string; document?: string | null };
const METHODS: [string, string][] = [
  ["signed", "Signed"],
  ["written", "In writing (email or letter)"],
  ["verbal", "Verbally"],
];

export function AgreementBox({ kind, planId, clientId, agreement, people, documents, canEdit, dayText }: { kind: "care" | "support"; planId: string; clientId: string; agreement: Agreement | null; people: [string, string][]; documents: [string, string][]; canEdit: boolean; dayText: string }) {
  const [state, action, pending] = useActionState(recordAgreement, null);
  if (agreement) {
    return (
      <p className="flex flex-wrap items-center gap-1 rounded-md bg-good-soft px-2 py-1 text-xs">
        <CheckCircle2 aria-hidden="true" className="size-3.5" />
        Agreed by {agreement.agreed_name}
        {agreement.agreed_by === "client" ? " (the client, personally)" : ` on the client's behalf, as ${agreement.capacity || "a contact"}`}
        {agreement.authority ? ` · authority: ${agreement.authority}` : ""} · {METHODS.find(([k]) => k === agreement.method)?.[1].toLowerCase()} on {agreement.agreed_on} · recorded {agreement.recorded}
        {agreement.document ? ` · document: ${agreement.document}` : ""}
        {agreement.notes ? ` · ${agreement.notes}` : ""}
      </p>
    );
  }
  if (!canEdit) return <p className="text-xs font-semibold text-warn">Client or representative agreement not recorded yet.</p>;
  return (
    <details className="rounded-md border border-warn/50 px-3 py-2">
      <summary className="cursor-pointer text-xs font-semibold text-warn">Record the client&apos;s or representative&apos;s agreement</summary>
      <form action={action} className="mt-2 flex flex-col gap-2">
        <input type="hidden" name="client_id" value={clientId} />
        <input type="hidden" name="plan_id" value={planId} />
        <input type="hidden" name="kind" value={kind} />
        <div className="grid gap-2 sm:grid-cols-3">
          <label className={field}>
            Who agreed
            <select name="who" required defaultValue="client" className={inputClass}>
              <option value="client">The client</option>
              {people.map(([id, l]) => (
                <option key={id} value={id}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className={field}>
            How
            <select name="method" required defaultValue="signed" className={inputClass}>
              {METHODS.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className={field}>
            Date
            <DateInput name="agreed_on" required defaultValue={dayText} max={dayText} className={inputClass} />
          </label>
        </div>
        {documents.length ? (
          <label className={field}>
            Signed copy or record (optional)
            <select name="document_id" defaultValue="" className={inputClass}>
              <option value="">None</option>
              {documents.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
        ) : null}
        <label className={field}>
          Notes (optional)
          <input name="notes" maxLength={1000} className={inputClass} />
        </label>
        <p className="text-xs text-muted">A recorded agreement can&apos;t be changed later.</p>
        <div className="flex flex-wrap items-center gap-3">
          <Button size="sm" disabled={pending}>
            {pending ? "Saving…" : "Record agreement"}
          </Button>
          <Msg state={state} />
        </div>
      </form>
    </details>
  );
}

// ---- Start a support plan or budget by hand ----
export function StartDocForm({ kind, clientId, enrolments, supportPlans, today }: { kind: "support" | "budget"; clientId: string; enrolments: [string, string][]; supportPlans: [string, string][]; today: string }) {
  const [state, action, pending] = useActionState(startDoc, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="kind" value={kind} />
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Title
          <input name="title" required maxLength={120} placeholder={kind === "support" ? "e.g. Support plan 2027" : "e.g. Proposed budget, first quarter"} className={inputClass} />
        </label>
        <label className={field}>
          Program
          <select name="enrolment_id" defaultValue={enrolments[0]?.[0] ?? ""} className={inputClass}>
            <option value="">Not linked</option>
            {enrolments.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        {kind === "budget" ? (
          <>
            <label className={field}>
              Period starts
              <DateInput name="period_start" required defaultValue={today} className={inputClass} />
            </label>
            <label className={field}>
              Period ends
              <DateInput name="period_end" required className={inputClass} />
            </label>
            {supportPlans.length ? (
              <label className={field}>
                Support plan (optional)
                <select name="support_plan_id" defaultValue="" className={inputClass}>
                  <option value="">None</option>
                  {supportPlans.map(([v, l]) => (
                    <option key={v} value={v}>
                      {l}
                    </option>
                  ))}
                </select>
              </label>
            ) : null}
          </>
        ) : null}
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Add draft"}
        </Button>
        <Msg state={state} />
      </div>
    </form>
  );
}

// ---- From a completed assessment ----
export function GenerateDrafts({ assessmentId, existing }: { assessmentId: string; existing: ReactNode }) {
  const { pending, state, run } = useRun();
  return (
    <div className="flex flex-col gap-2">
      <div>
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => generateCareDocuments(assessmentId))}>
          {pending ? "Making drafts…" : "Create draft care plan, support plan and budget"}
        </Button>
      </div>
      <p className="text-xs text-muted">Uses this assessment&apos;s active findings. Each draft keeps its source; nothing is approved until someone reviews it. Running it again makes only what&apos;s missing and never changes an existing draft.</p>
      {existing}
      <Msg state={state} />
    </div>
  );
}

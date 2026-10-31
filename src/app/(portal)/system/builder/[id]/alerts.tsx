// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Badge, Button, Field, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import type { Feature, FeatureField, Option } from "@/lib/feature-types";
import { deleteAlert, saveAlert, type AlertDraft } from "../actions";

const WHEN: Record<AlertDraft["when_kind"], string> = {
  any: "Every new entry",
  choice: "An answer is…",
  above: "A number is above…",
  below: "A number is below…",
  total_over: "A client's daily total goes over their target",
  total_met: "A client's daily total reaches their target",
  total_under_by: "At a set time: a client's daily total is still under their target",
  no_entry_by: "At a set time: nothing has been entered today",
};
const TIMED = (k: AlertDraft["when_kind"]) => k === "total_under_by" || k === "no_entry_by";
const hourLabel = (h: number) => (h === 0 ? "12 am" : h < 12 ? `${h} am` : h === 12 ? "12 pm" : `${h - 12} pm`);
const ROLES: Role[] = ["manager", "staff_admin", "team_leader"];
const tick = "h-5 w-5 shrink-0 accent-[var(--brand-primary)]";

const blank = (): AlertDraft => ({
  id: `new-${Math.random().toString(36).slice(2, 10)}`,
  name: "",
  when_kind: "any",
  at_hour: null,
  field_id: null,
  match_text: "",
  limit_value: null,
  notify_roles: ["manager"],
  notify_leader: false,
  notify_people: [],
  by_bell: true,
  by_email: false,
  on_fix: false,
  message: "",
  active: true,
});

// cmeprojects: the builder's Alerts tab. Each alert says when it goes off,
// who's told and how (bell, email or both). Managers by default.
export function Alerts({ feature, fields, staff, alerts, dirty }: { feature: Feature; fields: FeatureField[]; staff: Option[]; alerts: AlertDraft[]; dirty: boolean }) {
  const [editing, setEditing] = useState<AlertDraft | null>(null);
  const live = fields.filter((f) => !f.archived && !f.id.startsWith("new-"));

  const summary = (a: AlertDraft) => {
    const field = live.find((f) => f.id === a.field_id);
    const when =
      a.when_kind === "choice"
        ? `${field?.label ?? "An answer"} is ${a.match_text}`
        : a.when_kind === "above" || a.when_kind === "below"
          ? `${field?.label ?? "A number"} is ${a.when_kind} ${a.limit_value ?? "?"}${field?.unit ? ` ${field.unit}` : ""}`
          : TIMED(a.when_kind)
            ? `${a.when_kind === "no_entry_by" ? "Nothing entered" : "A client under target"} by ${hourLabel(a.at_hour ?? 18)}, checked daily`
            : WHEN[a.when_kind];
    const who = [
      ...a.notify_roles.map((r) => (r in ROLE_LABELS ? ROLE_LABELS[r as Role] + "s" : r)),
      a.notify_leader ? "their team leader" : "",
      ...a.notify_people.map((p) => staff.find((s) => s.id === p)?.name ?? ""),
    ].filter(Boolean);
    const how = a.by_bell && a.by_email ? "bell and email" : a.by_email ? "email" : "bell";
    return { when, who: who.join(", "), how };
  };

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-line bg-surface p-5">
      <p className="text-sm text-muted">
        Tell people the moment an entry is saved that needs attention, by the bell, email or both. The person who made the entry isn&apos;t told.
      </p>
      {dirty ? <p className="text-sm text-warn">Save your changes to the form first, so alerts can use the new questions.</p> : null}
      {alerts.length === 0 && !editing ? <p className="text-sm text-muted">No alerts yet.</p> : null}
      <ul className="flex flex-col gap-2">
        {alerts.map((a) => {
          const s = summary(a);
          return editing?.id === a.id ? (
            <li key={a.id}>
              <AlertEditor draft={editing} feature={feature} fields={live} staff={staff} onClose={() => setEditing(null)} />
            </li>
          ) : (
            <li key={a.id} className="flex flex-wrap items-center gap-3 rounded-md border border-line px-4 py-3">
              <span className="min-w-48 flex-1 text-sm">
                <span className="flex flex-wrap items-center gap-2 font-semibold">
                  {a.name || s.when}
                  {a.active ? null : <Badge tone="grey">{TIMED(a.when_kind) ? "Off" : "Paused"}</Badge>}
                  {TIMED(a.when_kind) ? <Badge tone="soft">Daily at {hourLabel(a.at_hour ?? 18)}</Badge> : null}
                </span>
                <span className="block text-muted">
                  {a.name ? `${s.when} → ` : "→ "}
                  {s.who || "nobody"} · {s.how}
                  {a.on_fix ? " · also when fixed" : ""}
                </span>
              </span>
              <button type="button" className="text-sm font-semibold text-brand underline" onClick={() => setEditing(a)}>
                Edit
              </button>
            </li>
          );
        })}
        {editing && editing.id.startsWith("new-") ? (
          <li>
            <AlertEditor draft={editing} feature={feature} fields={live} staff={staff} onClose={() => setEditing(null)} />
          </li>
        ) : null}
      </ul>
      {!editing ? (
        <Button type="button" variant="outline" className="self-start" disabled={dirty} onClick={() => setEditing(blank())}>
          + Add an alert
        </Button>
      ) : null}
    </div>
  );
}

function AlertEditor({ draft, feature, fields, staff, onClose }: { draft: AlertDraft; feature: Feature; fields: FeatureField[]; staff: Option[]; onClose: () => void }) {
  const router = useRouter();
  const [a, setA] = useState(draft);
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const set = <K extends keyof AlertDraft>(k: K, v: AlertDraft[K]) => setA((x) => ({ ...x, [k]: v }));
  const listFields = fields.filter((f) => f.type === "choice" || f.type === "multi" || f.type === "yesno");
  const numberFields = fields.filter((f) => f.type === "number");
  const field = fields.find((f) => f.id === a.field_id);
  const totals = Boolean(feature.total_field && feature.group_field);
  const toggle = (list: string[], v: string, on: boolean) => (on ? [...new Set([...list, v])] : list.filter((x) => x !== v));
  const run = (task: () => Promise<{ error?: string; message?: string }>) =>
    start(async () => {
      const r = await task();
      setResult(r);
      if (!r.error) {
        router.refresh();
        onClose();
      }
    });

  return (
    <div className="flex flex-col gap-4 rounded-md border border-brand/40 bg-brand-soft/30 p-4">
      <Field label="When" htmlFor="al-when">
        <select
          id="al-when"
          value={a.when_kind}
          onChange={(e) => {
            const k = e.target.value as AlertDraft["when_kind"];
            // Time-based alerts start switched off until the conditions are right.
            setA((x) => ({ ...x, when_kind: k, field_id: null, match_text: "", limit_value: null, at_hour: TIMED(k) ? x.at_hour ?? 18 : null, active: TIMED(k) && x.id.startsWith("new-") ? false : x.active }));
          }}
          className={inputClass}
        >
          {(Object.keys(WHEN) as AlertDraft["when_kind"][]).map((k) => (
            <option key={k} value={k} disabled={(k === "total_over" || k === "total_met" || k === "total_under_by") && !totals}>
              {WHEN[k]}
              {(k === "total_over" || k === "total_met" || k === "total_under_by") && !totals ? " (set up daily totals first)" : ""}
            </option>
          ))}
        </select>
      </Field>

      {a.when_kind === "choice" ? (
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="Question" htmlFor="al-field">
            <select id="al-field" value={a.field_id ?? ""} onChange={(e) => setA((x) => ({ ...x, field_id: e.target.value || null, match_text: "" }))} className={inputClass}>
              <option value="">Choose</option>
              {listFields.map((f) => (
                <option key={f.id} value={f.id}>
                  {f.label}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Answer" htmlFor="al-match">
            <select id="al-match" value={a.match_text} onChange={(e) => set("match_text", e.target.value)} className={inputClass} disabled={!field}>
              <option value="">Choose</option>
              {(field?.type === "yesno" ? ["Yes", "No"] : (field?.options ?? [])).map((o) => (
                <option key={o}>{o}</option>
              ))}
            </select>
          </Field>
        </div>
      ) : null}

      {a.when_kind === "above" || a.when_kind === "below" ? (
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="Number" htmlFor="al-num">
            <select id="al-num" value={a.field_id ?? ""} onChange={(e) => set("field_id", e.target.value || null)} className={inputClass}>
              <option value="">Choose</option>
              {numberFields.map((f) => (
                <option key={f.id} value={f.id}>
                  {f.label}
                  {f.unit ? ` (${f.unit})` : ""}
                </option>
              ))}
            </select>
          </Field>
          <Field label={`${a.when_kind === "above" ? "Above" : "Below"}${field?.unit ? ` (${field.unit})` : ""}`} htmlFor="al-limit">
            <input
              id="al-limit"
              inputMode="decimal"
              value={a.limit_value ?? ""}
              onChange={(e) => set("limit_value", e.target.value.trim() === "" || Number.isNaN(Number(e.target.value)) ? null : Number(e.target.value))}
              className={inputClass}
            />
          </Field>
        </div>
      ) : null}
      {TIMED(a.when_kind) ? (
        <div className="flex flex-col gap-2">
          <Field label="Check at" htmlFor="al-hour" hint="Checked once a day, at the start of that hour (company time).">
            <select id="al-hour" value={a.at_hour ?? 18} onChange={(e) => set("at_hour", Number(e.target.value))} className={`${inputClass} max-w-40`}>
              {Array.from({ length: 24 }, (_, h) => (
                <option key={h} value={h}>
                  {hourLabel(h)}
                </option>
              ))}
            </select>
          </Field>
          <p className="rounded-md bg-warn-soft px-3 py-2 text-xs text-warn">
            {a.when_kind === "no_entry_by"
              ? "Sends one note if no one has filled it in by then."
              : "Sends one note listing every client still under their target by then."}{" "}
            Time-based alerts start switched off. Tick On below when the conditions are right.
          </p>
        </div>
      ) : null}

      {a.when_kind === "total_over" || a.when_kind === "total_met" ? (
        <p className="text-xs text-muted">Once a day per client, the moment their total crosses the target set on the Daily totals and targets tab.</p>
      ) : null}

      <fieldset>
        <legend className="text-sm font-semibold">Who&apos;s told</legend>
        <div className="mt-1 grid grid-cols-2 gap-x-4 gap-y-1 sm:grid-cols-4">
          {ROLES.map((r) => (
            <label key={r} className="flex min-h-10 items-center gap-2 text-sm">
              <input type="checkbox" checked={a.notify_roles.includes(r)} onChange={(e) => set("notify_roles", toggle(a.notify_roles, r, e.target.checked))} className={tick} />
              {ROLE_LABELS[r]}s
            </label>
          ))}
          <label className={`col-span-2 flex min-h-10 items-center gap-2 text-sm ${TIMED(a.when_kind) ? "hidden" : ""}`}>
            <input type="checkbox" checked={a.notify_leader} onChange={(e) => set("notify_leader", e.target.checked)} className={tick} />
            The team leader of whoever made the entry
          </label>
        </div>
        <details className="mt-1">
          <summary className="cursor-pointer text-sm font-semibold text-brand">Named people{a.notify_people.length ? ` (${a.notify_people.length})` : ""}</summary>
          <div className="mt-2 grid max-h-56 grid-cols-1 gap-x-4 overflow-y-auto sm:grid-cols-2">
            {staff.map((p) => (
              <label key={p.id} className="flex min-h-10 items-center gap-2 text-sm">
                <input type="checkbox" checked={a.notify_people.includes(p.id)} onChange={(e) => set("notify_people", toggle(a.notify_people, p.id, e.target.checked))} className={tick} />
                {p.name}
              </label>
            ))}
          </div>
        </details>
      </fieldset>

      <fieldset>
        <legend className="text-sm font-semibold">How</legend>
        <div className="mt-1 flex flex-wrap gap-x-6">
          <label className="flex min-h-10 items-center gap-2 text-sm">
            <input type="checkbox" checked={a.by_bell} onChange={(e) => set("by_bell", e.target.checked)} className={tick} />
            Bell in the portal
          </label>
          <label className="flex min-h-10 items-center gap-2 text-sm">
            <input type="checkbox" checked={a.by_email} onChange={(e) => set("by_email", e.target.checked)} className={tick} />
            Email
          </label>
        </div>
      </fieldset>

      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Name (optional)" htmlFor="al-name" hint="Shown in this list, e.g. Refused drinks.">
          <input id="al-name" value={a.name} maxLength={80} onChange={(e) => set("name", e.target.value)} className={inputClass} />
        </Field>
        <Field label="Message (optional)" htmlFor="al-msg" hint="Leave blank for one that says what happened. You can use {client}, {staff} and {feature}.">
          <input id="al-msg" value={a.message} maxLength={200} placeholder="e.g. {client} refused a drink" onChange={(e) => set("message", e.target.value)} className={inputClass} />
        </Field>
      </div>

      <div className="flex flex-wrap gap-x-6">
        <label className={`flex min-h-10 items-center gap-2 text-sm ${TIMED(a.when_kind) ? "hidden" : ""}`}>
          <input type="checkbox" checked={a.on_fix} onChange={(e) => set("on_fix", e.target.checked)} className={tick} />
          Also when a manager fixes an entry
        </label>
        <label className="flex min-h-10 items-center gap-2 text-sm">
          <input type="checkbox" checked={a.active} onChange={(e) => set("active", e.target.checked)} className={tick} />
          On
        </label>
      </div>

      {result?.error ? <Notice tone="error">{result.error}</Notice> : null}
      <div className="flex flex-wrap gap-2">
        <Button type="button" disabled={pending} onClick={() => run(async () => saveAlert(feature.id, a))}>
          {pending ? "Saving…" : "Save alert"}
        </Button>
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
        {a.id.startsWith("new-") ? null : (
          <Button type="button" variant="danger" disabled={pending} className="ml-auto" onClick={() => confirm("Delete this alert?") && run(() => deleteAlert(a.id))}>
            Delete
          </Button>
        )}
      </div>
    </div>
  );
}

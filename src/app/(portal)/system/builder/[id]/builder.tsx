// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Badge, Button, Field, Notice, inputClass } from "@/components/ui";
import { FeatureForm } from "@/components/feature-form";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { FIELD_TYPES, blankField, quickValues, type Feature, type FeatureField, type FieldType, type Option } from "@/lib/feature-types";
import { TargetsEditor } from "@/components/feature-targets";
import { deleteDraft, publishFeature, saveFeature, setFeatureIncluded } from "../actions";

type Ctx = { clients: Option[]; staff: Option[]; targets: Record<string, number>; me: { id: string; name: string; teams: string }; timeZone: string };

const FILL_ROLES: Role[] = ["support_worker", "team_leader", "staff_admin", "manager"];
const SEE_ROLES: Role[] = ["team_leader", "staff_admin", "manager"];
const numOrNull = (v: string) => (v.trim() === "" || Number.isNaN(Number(v)) ? null : Number(v));

// cmeprojects: the Feature builder. Changes show straight away in the phone
// preview; Save keeps them, Publish lets staff use the feature.
export function Builder({
  feature: initialFeature,
  fields: initialFields,
  ctx,
  typed,
  entryCount,
}: {
  feature: Feature;
  fields: FeatureField[];
  ctx: Ctx;
  typed: Record<string, [string, number][]>;
  entryCount: number;
}) {
  const router = useRouter();
  const [feature, setFeature] = useState(initialFeature);
  const [fields, setFields] = useState(initialFields);
  // What was last saved, to show "Unsaved changes".
  const [baseline, setBaseline] = useState(() => JSON.stringify({ feature: initialFeature, fields: initialFields }));
  const [tab, setTab] = useState<"details" | "fields" | "totals">("fields");
  const [previewTab, setPreviewTab] = useState<"phone" | "report">("phone");
  const [showPreview, setShowPreview] = useState(false);
  const [editing, setEditing] = useState<string | null>(null);
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const dirty = useMemo(() => JSON.stringify({ feature, fields }) !== baseline, [feature, fields, baseline]);
  const set = <K extends keyof Feature>(k: K, v: Feature[K]) => setFeature((f) => ({ ...f, [k]: v }));
  const setField = (id: string, patch: Partial<FeatureField>) => setFields((list) => list.map((f) => (f.id === id ? { ...f, ...patch } : f)));
  const move = (i: number, by: number) =>
    setFields((list) => {
      const next = [...list];
      [next[i], next[i + by]] = [next[i + by], next[i]];
      return next.map((f, n) => ({ ...f, sort_order: n + 1 }));
    });

  const save = (then?: () => Promise<{ error?: string; message?: string }>) =>
    start(async () => {
      const { id: _id, slug: _slug, status: _status, enabled: _enabled, ...rest } = feature;
      void _id;
      void _slug;
      void _status;
      void _enabled;
      const r = await saveFeature(feature.id, { feature: rest, fields });
      if (r.error) {
        setResult(r);
        return;
      }
      // New fields now have their real ids; keep working where you are.
      const ids = r.ids ?? {};
      const savedFields = fields.map((f, n) => ({ ...f, id: ids[f.id] ?? f.id, sort_order: n + 1 }));
      const map = (id: string | null) => (id ? ids[id] ?? id : null);
      const savedFeature = { ...feature, total_field: map(feature.total_field), group_field: map(feature.group_field) };
      setFields(savedFields);
      setFeature(savedFeature);
      setBaseline(JSON.stringify({ feature: savedFeature, fields: savedFields }));
      setEditing((e) => (e ? ids[e] ?? e : e));
      if (then) {
        const t = await then();
        setResult(t);
        if (!t.error && feature.status === "draft") setFeature((f) => ({ ...f, status: "published" }));
      } else setResult(r);
      router.refresh();
    });

  const tabBtn = (k: typeof tab, label: string) => (
    <button
      type="button"
      onClick={() => setTab(k)}
      aria-current={tab === k ? "page" : undefined}
      className={`-mb-px min-h-11 border-b-2 px-3 text-sm font-semibold ${tab === k ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"}`}
    >
      {label}
    </button>
  );

  return (
    <div className="flex flex-col gap-4">
      {/* Top bar: name, status, save and publish. */}
      <div className="sticky top-0 z-20 -mx-4 flex flex-wrap items-center gap-3 border-b border-line bg-page/95 px-4 py-3 backdrop-blur md:-mx-8 md:px-8">
        <div className="min-w-0 flex-1">
          <p className="text-xs text-muted">
            <Link href="/system/builder" className="underline">
              Feature builder
            </Link>{" "}
            › {feature.name || "New feature"}
          </p>
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="heading-sm">{feature.name || "New feature"}</h1>
            <Badge tone="soft">Premium</Badge>
            {feature.status === "published" ? <Badge tone="good">Live</Badge> : <Badge tone="grey">Draft</Badge>}
            {dirty ? <Badge tone="warn">Unsaved changes</Badge> : null}
          </div>
        </div>
        <Button variant="outline" className="lg:hidden" onClick={() => setShowPreview((s) => !s)} type="button">
          {showPreview ? "Back to builder" : "Preview"}
        </Button>
        <Button variant="outline" disabled={pending || !dirty} onClick={() => save()} type="button">
          {pending ? "Saving…" : "Save"}
        </Button>
        {feature.status === "draft" ? (
          <Button disabled={pending} onClick={() => save(() => publishFeature(feature.id))} type="button">
            Save and publish
          </Button>
        ) : (
          <Link href={`/f/${feature.slug}`} className="text-sm font-semibold text-brand underline">
            Open as staff
          </Link>
        )}
      </div>
      {result?.error ? <Notice tone="error">{result.error}</Notice> : result?.message ? <Notice tone="success">{result.message}</Notice> : null}

      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_400px]">
        {/* The builder */}
        <div className={`flex min-w-0 flex-col gap-4 ${showPreview ? "max-lg:hidden" : ""}`}>
          <nav aria-label="Builder" className="flex gap-1 overflow-x-auto border-b border-line">
            {tabBtn("fields", "Fields")}
            {tabBtn("details", "Details and who")}
            {tabBtn("totals", "Daily totals and targets")}
          </nav>

          {tab === "details" ? (
            <div className="flex flex-col gap-4 rounded-lg border border-line bg-surface p-5">
              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Name" htmlFor="b-name">
                  <input id="b-name" value={feature.name} maxLength={60} onChange={(e) => set("name", e.target.value)} className={inputClass} />
                </Field>
                <Field label="Menu label" htmlFor="b-menu" hint="Short: it's what staff see in the menu.">
                  <input id="b-menu" value={feature.menu_label} maxLength={30} onChange={(e) => set("menu_label", e.target.value)} className={inputClass} />
                </Field>
              </div>
              <Field label="Description" htmlFor="b-desc" hint="Shown at the top of the form.">
                <input id="b-desc" value={feature.description} maxLength={300} onChange={(e) => set("description", e.target.value)} className={inputClass} />
              </Field>
              <RoleBoxes label="Who can fill it in" roles={FILL_ROLES} value={feature.fill_roles} onChange={(v) => set("fill_roles", v)} />
              <RoleBoxes
                label="Who sees every entry (and the report)"
                hint="Team leaders see their own team's entries. Everyone sees the entries they made."
                roles={SEE_ROLES}
                value={feature.see_roles}
                onChange={(v) => set("see_roles", v)}
              />
              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Time to undo an entry (minutes)" htmlFor="b-undo" hint="After this, only a manager can fix it (if you allow it below).">
                  <input id="b-undo" inputMode="numeric" value={String(feature.undo_minutes)} onChange={(e) => set("undo_minutes", Number(e.target.value.replace(/\D/g, "")) || 0)} className={inputClass} />
                </Field>
                <label className="flex items-center gap-3 self-end pb-2 text-sm">
                  <input type="checkbox" checked={feature.record_team} onChange={(e) => set("record_team", e.target.checked)} className="h-5 w-5 accent-[var(--brand-primary)]" />
                  Also record their team
                </label>
              </div>
              <p className="text-xs text-muted">The date, time and the signed-in staff member&apos;s name are always recorded.</p>
              <fieldset className="border-t border-line pt-4">
                <legend className="text-sm font-semibold">Managers can also</legend>
                <p className="text-xs text-muted">You can always do these. Managers find them under Manage on the feature&apos;s page.</p>
                {(
                  [
                    ["managers_fix", "Fix entries", "Change the answers after the undo time, with a reason. The change log keeps what it was."],
                    ["managers_targets", "Set client targets", "The daily target for everyone and each client's own."],
                    ["managers_options", "Change drop-down options", "Add or remove options. Not the rest of the form."],
                  ] as const
                ).map(([k, label, hint]) => (
                  <label key={k} className="mt-2 flex items-start gap-3 text-sm">
                    <input type="checkbox" checked={feature[k]} onChange={(e) => set(k, e.target.checked)} className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand-primary)]" />
                    <span>
                      <span className="block font-medium">{label}</span>
                      <span className="block text-xs text-muted">{hint}</span>
                    </span>
                  </label>
                ))}
              </fieldset>
              {feature.status === "published" ? (
                <div className="flex flex-wrap items-center justify-between gap-3 border-t border-line pt-4">
                  <span>
                    <span className="block font-semibold">In this company&apos;s package</span>
                    <span className="block text-sm text-muted">Off hides it everywhere; entries are kept.</span>
                  </span>
                  <form action={setFeatureIncluded}>
                    <input type="hidden" name="id" value={feature.id} />
                    <input type="hidden" name="enabled" value={feature.enabled ? "false" : "true"} />
                    <Button variant={feature.enabled ? "primary" : "outline"}>{feature.enabled ? "In package: on" : "Off"}</Button>
                  </form>
                </div>
              ) : entryCount === 0 ? (
                <form action={deleteDraft} className="border-t border-line pt-4">
                  <input type="hidden" name="id" value={feature.id} />
                  <Button variant="danger">Delete this draft</Button>
                </form>
              ) : null}
            </div>
          ) : null}

          {tab === "fields" ? (
            <div className="flex flex-col gap-4">
              <ul className="overflow-hidden rounded-lg border border-line bg-surface">
                {fields.map((f, i) => (
                  <li key={f.id} className="border-t border-line first:border-t-0">
                    <div className="flex items-center gap-2 px-3 py-2.5">
                      <div className="flex gap-1">
                        <ArrowButton dir="up" disabled={i === 0} onClick={() => move(i, -1)} />
                        <ArrowButton dir="down" disabled={i === fields.length - 1} onClick={() => move(i, 1)} />
                      </div>
                      <button type="button" onClick={() => setEditing(editing === f.id ? null : f.id)} className="min-w-0 flex-1 pl-1 text-left">
                        <span className="block font-semibold">
                          {f.label || "(no question)"} {f.required ? <Badge tone="warn">Required</Badge> : null}
                        </span>
                        <span className="block text-xs text-muted">
                          {FIELD_TYPES[f.type].label}
                          {f.unit ? ` · ${f.unit}` : ""}
                          {f.type === "choice" || f.type === "multi" ? ` · ${f.options.length} options` : ""}
                          {f.allow_other ? (f.add_typed ? " · typed answers join the list" : " · staff can type their own") : ""}
                        </span>
                      </button>
                      <button type="button" className="text-sm font-semibold text-brand underline" onClick={() => setEditing(editing === f.id ? null : f.id)}>
                        {editing === f.id ? "Done" : "Edit"}
                      </button>
                    </div>
                    {editing === f.id ? (
                      <FieldEditor
                        f={f}
                        typed={typed[f.id] ?? []}
                        onChange={(patch) => setField(f.id, patch)}
                        onRemove={() => {
                          setFields((list) => list.filter((x) => x.id !== f.id));
                          setEditing(null);
                        }}
                      />
                    ) : null}
                  </li>
                ))}
                {fields.length === 0 ? <li className="px-4 py-4 text-sm text-muted">No fields yet. Add the first one below.</li> : null}
              </ul>
              <div>
                <p className="mb-2 text-sm font-semibold">Add a field</p>
                <div className="flex flex-wrap gap-2">
                  {(Object.keys(FIELD_TYPES) as FieldType[]).map((t) => (
                    <button
                      key={t}
                      type="button"
                      title={FIELD_TYPES[t].hint}
                      onClick={() => {
                        const f = blankField(t, fields.length + 1);
                        setFields((list) => [...list, f]);
                        setEditing(f.id);
                      }}
                      className="min-h-10 rounded-full border border-line bg-surface px-3.5 text-sm font-semibold text-ink hover:border-muted"
                    >
                      + {FIELD_TYPES[t].label}
                    </button>
                  ))}
                </div>
              </div>
              {entryCount ? (
                <p className="text-xs text-muted">
                  {entryCount.toLocaleString("en-AU")} entries so far. Removing a field hides it from the form; answers already given are kept.
                </p>
              ) : null}
            </div>
          ) : null}

          {tab === "totals" ? <Totals feature={feature} fields={fields} ctx={ctx} set={set} dirty={dirty} /> : null}
        </div>

        {/* The live preview */}
        <aside className={`flex min-w-0 flex-col gap-3 lg:sticky lg:top-24 ${showPreview ? "" : "max-lg:hidden"}`}>
          <div className="flex gap-1.5">
            {(["phone", "report"] as const).map((k) => (
              <button
                key={k}
                type="button"
                onClick={() => setPreviewTab(k)}
                aria-current={previewTab === k ? "page" : undefined}
                className={`min-h-9 rounded-full border px-4 text-sm font-semibold ${previewTab === k ? "border-brand bg-brand text-brand-fg" : "border-line bg-surface text-muted"}`}
              >
                {k === "phone" ? "Phone preview" : "Report preview"}
              </button>
            ))}
          </div>
          {previewTab === "phone" ? (
            <div className="mx-auto w-full max-w-[380px] rounded-[2.4rem] bg-[#0d1b30] p-2.5 shadow-xl">
              <div className="flex h-[720px] flex-col overflow-hidden rounded-[1.9rem] bg-page">
                <div className="bg-[var(--side-bg)] px-5 py-3 text-side-fg">
                  <p className="font-display text-xs font-semibold tracking-widest uppercase">{feature.menu_label || "New feature"}</p>
                  <p className="text-[11px] text-side-muted">As {ctx.me.name || "staff"} would see it</p>
                </div>
                <div className="flex-1 overflow-y-auto p-4">
                  <FeatureForm feature={feature} fields={fields} clients={ctx.clients} staff={ctx.staff} me={ctx.me} targets={ctx.targets} timeZone={ctx.timeZone} mode="preview" />
                </div>
              </div>
            </div>
          ) : (
            <ReportPreview feature={feature} fields={fields} ctx={ctx} />
          )}
        </aside>
      </div>
    </div>
  );
}

function RoleBoxes({ label, hint, roles, value, onChange }: { label: string; hint?: string; roles: Role[]; value: Role[]; onChange: (v: Role[]) => void }) {
  return (
    <fieldset>
      <legend className="text-sm font-semibold">{label}</legend>
      <div className="flex flex-wrap gap-x-5">
        {roles.map((r) => (
          <label key={r} className="flex min-h-10 items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={value.includes(r)}
              onChange={(e) => onChange(e.target.checked ? [...value, r] : value.filter((x) => x !== r))}
              className="h-5 w-5 accent-[var(--brand-primary)]"
            />
            {ROLE_LABELS[r]}
          </label>
        ))}
      </div>
      {hint ? <p className="text-xs text-muted">{hint}</p> : null}
    </fieldset>
  );
}

function ArrowButton({ dir, disabled, onClick }: { dir: "up" | "down"; disabled: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={dir === "up" ? "Move up" : "Move down"}
      className="flex size-9 items-center justify-center rounded-md border border-field bg-surface text-muted hover:text-ink disabled:opacity-30"
    >
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden="true">
        <path d={dir === "up" ? "M6 15l6-6 6 6" : "M6 9l6 6 6-6"} />
      </svg>
    </button>
  );
}

function FieldEditor({ f, typed, onChange, onRemove }: { f: FeatureField; typed: [string, number][]; onChange: (p: Partial<FeatureField>) => void; onRemove: () => void }) {
  const [newOption, setNewOption] = useState("");
  const list = f.type === "choice" || f.type === "multi";
  const addOption = (v: string) => {
    const o = v.trim();
    if (o && !f.options.includes(o)) onChange({ options: [...f.options, o] });
    setNewOption("");
  };
  return (
    <div className="flex flex-col gap-3 border-t border-brand/30 bg-brand-soft/30 px-4 py-4">
      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Question" htmlFor={`q-${f.id}`}>
          <input id={`q-${f.id}`} value={f.label} maxLength={80} onChange={(e) => onChange({ label: e.target.value })} className={inputClass} />
        </Field>
        <Field label="Type" htmlFor={`t-${f.id}`}>
          <select
            id={`t-${f.id}`}
            value={f.type}
            onChange={(e) => {
              const type = e.target.value as FieldType;
              onChange({ type, options: (type === "choice" || type === "multi") && f.options.length === 0 ? ["Option 1", "Option 2"] : f.options });
            }}
            className={inputClass}
          >
            {(Object.keys(FIELD_TYPES) as FieldType[]).map((t) => (
              <option key={t} value={t}>
                {FIELD_TYPES[t].label}
              </option>
            ))}
          </select>
        </Field>
      </div>
      {f.type === "number" ? (
        <div className="grid gap-3 sm:grid-cols-4">
          <Field label="Unit" htmlFor={`u-${f.id}`}>
            <input id={`u-${f.id}`} value={f.unit} maxLength={12} placeholder="e.g. ml, °C, $" onChange={(e) => onChange({ unit: e.target.value })} className={inputClass} />
          </Field>
          <Field label="Smallest" htmlFor={`mn-${f.id}`}>
            <input id={`mn-${f.id}`} inputMode="decimal" value={f.min_value ?? ""} onChange={(e) => onChange({ min_value: numOrNull(e.target.value) })} className={inputClass} />
          </Field>
          <Field label="Largest" htmlFor={`mx-${f.id}`}>
            <input id={`mx-${f.id}`} inputMode="decimal" value={f.max_value ?? ""} onChange={(e) => onChange({ max_value: numOrNull(e.target.value) })} className={inputClass} />
          </Field>
          <Field label="Quick buttons" htmlFor={`qk-${f.id}`} hint={f.quick.length ? undefined : quickValues(f).length ? `Using ${quickValues(f).join(", ")}` : "e.g. 50, 100, 200"}>
            <input
              id={`qk-${f.id}`}
              defaultValue={f.quick.join(", ")}
              onBlur={(e) =>
                onChange({
                  quick: e.target.value
                    .split(/[,\s]+/)
                    .map(Number)
                    .filter((n) => Number.isFinite(n) && n > 0),
                })
              }
              className={inputClass}
            />
          </Field>
        </div>
      ) : null}
      {list ? (
        <div className="flex flex-col gap-2">
          <p className="text-sm font-semibold">Options</p>
          <div className="flex flex-wrap gap-2">
            {f.options.map((o, i) => (
              <span key={o + i} className="inline-flex items-center gap-1 rounded-full border border-line bg-surface py-1 pr-1 pl-3 text-sm">
                {o}
                <button type="button" aria-label={`Remove ${o}`} onClick={() => onChange({ options: f.options.filter((_, n) => n !== i) })} className="size-7 rounded-full text-muted hover:bg-page">
                  ×
                </button>
              </span>
            ))}
          </div>
          <div className="flex gap-2">
            <label htmlFor={`no-${f.id}`} className="sr-only">
              Add an option
            </label>
            <input
              id={`no-${f.id}`}
              value={newOption}
              placeholder="Add an option"
              onChange={(e) => setNewOption(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  addOption(newOption);
                }
              }}
              className={`${inputClass} min-w-0 flex-1`}
            />
            <Button type="button" variant="outline" onClick={() => addOption(newOption)}>
              Add
            </Button>
          </div>
          {f.type === "choice" ? (
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={f.allow_other} onChange={(e) => onChange({ allow_other: e.target.checked })} className="h-5 w-5 accent-[var(--brand-primary)]" />
              Staff can type their own answer if it&apos;s not in the list
            </label>
          ) : null}
          {f.allow_other ? (
            <label className="flex items-center gap-2 pl-7 text-sm">
              <input type="checkbox" checked={f.add_typed} onChange={(e) => onChange({ add_typed: e.target.checked })} className="h-5 w-5 accent-[var(--brand-primary)]" />
              Add their answer to the list for everyone next time
            </label>
          ) : null}
          {f.allow_other && typed.length ? (
            <div className="rounded-md border border-line bg-surface p-3 text-sm">
              <p className="mb-2">
                <strong>Typed by staff so far</strong> <span className="text-muted">(add common ones to the list so they&apos;re one tap next time)</span>
              </p>
              <div className="flex flex-wrap gap-2">
                {typed
                  .filter(([v]) => !f.options.includes(v))
                  .map(([v, n]) => (
                    <span key={v} className="inline-flex items-center gap-1 rounded-full border border-line bg-page py-1 pr-1 pl-3">
                      {v} · {n}
                      <button type="button" onClick={() => addOption(v)} className="rounded-full px-2 font-semibold text-brand hover:bg-brand-soft">
                        + Add
                      </button>
                    </span>
                  ))}
              </div>
            </div>
          ) : null}
        </div>
      ) : null}
      <Field label="Help text (optional)" htmlFor={`h-${f.id}`} hint="A short tip under the question.">
        <input id={`h-${f.id}`} value={f.help} maxLength={200} onChange={(e) => onChange({ help: e.target.value })} className={inputClass} />
      </Field>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={f.required} onChange={(e) => onChange({ required: e.target.checked })} className="h-5 w-5 accent-[var(--brand-primary)]" />
          Required
        </label>
        <Button type="button" variant="danger" onClick={onRemove}>
          Remove field
        </Button>
      </div>
    </div>
  );
}

function Totals({
  feature,
  fields,
  ctx,
  set,
  dirty,
}: {
  feature: Feature;
  fields: FeatureField[];
  ctx: Ctx;
  set: <K extends keyof Feature>(k: K, v: Feature[K]) => void;
  dirty: boolean;
}) {
  const numbers = fields.filter((f) => f.type === "number");
  const groups = fields.filter((f) => f.type === "client");
  const total = numbers.find((f) => f.id === feature.total_field);

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-line bg-surface p-5">
      <p className="text-sm text-muted">Add up a number each day for each client (for example millilitres of fluid), with a target per client. Staff see the client&apos;s total after saving.</p>
      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Add up this number" htmlFor="tt-field">
          <select id="tt-field" value={feature.total_field ?? ""} onChange={(e) => set("total_field", e.target.value || null)} className={inputClass}>
            <option value="">Don&apos;t add up</option>
            {numbers.map((f) => (
              <option key={f.id} value={f.id}>
                {f.label}
                {f.unit ? ` (${f.unit})` : ""}
              </option>
            ))}
          </select>
        </Field>
        <Field label="For each" htmlFor="tt-group">
          <select id="tt-group" value={feature.group_field ?? ""} onChange={(e) => set("group_field", e.target.value || null)} className={inputClass}>
            <option value="">Choose a client field</option>
            {groups.map((f) => (
              <option key={f.id} value={f.id}>
                {f.label}
              </option>
            ))}
          </select>
        </Field>
      </div>
      {numbers.length === 0 || groups.length === 0 ? <p className="text-sm text-warn">Add a Number field and a Client field first.</p> : null}
      {feature.total_field && feature.group_field ? (
        dirty ? (
          <p className="text-sm text-warn">Save your changes first, then set the targets.</p>
        ) : (
          <div className="border-t border-line pt-4">
            <TargetsEditor featureId={feature.id} unit={total?.unit ?? ""} clients={ctx.clients} targets={ctx.targets} defaultTarget={feature.default_target} />
          </div>
        )
      ) : null}
    </div>
  );
}

// What the report will look like, with made-up sample entries.
function ReportPreview({ feature, fields, ctx }: { feature: Feature; fields: FeatureField[]; ctx: Ctx }) {
  const clients = ctx.clients.length ? ctx.clients : [{ id: "a", name: "Client A" }, { id: "b", name: "Client B" }];
  const staff = ["Sam", "Lee", "Taylor"];
  const total = fields.find((f) => f.id === feature.total_field);
  const sample = (f: FeatureField, i: number): string => {
    switch (f.type) {
      case "client":
        return clients[i % clients.length].name;
      case "staff":
        return staff[i % staff.length];
      case "choice":
      case "multi":
        return f.options.length ? f.options[i % f.options.length] : "";
      case "number": {
        const q = quickValues(f);
        return String(q.length ? q[(i * 2 + 1) % q.length] : Math.round(((f.min_value ?? 0) + (f.max_value ?? 100)) / 2));
      }
      case "yesno":
        return i % 3 === 0 ? "Yes" : "No";
      case "date":
        return "Today";
      case "time":
        return `${9 + i}:00`;
      case "photo":
        return "Photo";
      default:
        return i % 2 ? "—" : "Sample";
    }
  };
  const rows = Array.from({ length: 6 }, (_, i) => fields.map((f) => sample(f, i)));
  const byClient = clients.slice(0, 4).map((c, ci) => {
    const sum = total ? rows.filter((r, i) => clients[i % clients.length].id === c.id).reduce((s, r) => s + (Number(r[fields.indexOf(total)]) || 0), 0) + ci * 400 : 0;
    const target = ctx.targets[c.id] ?? feature.default_target ?? 0;
    return { c, sum, target };
  });
  return (
    <div className="flex flex-col gap-3 rounded-lg border border-line bg-surface p-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="heading-sm">{feature.name} report</h2>
        <Badge tone="grey">Sample data</Badge>
      </div>
      {total && feature.group_field ? (
        <div className="flex flex-col gap-2">
          <p className="text-xs font-semibold tracking-wider text-muted uppercase">Daily totals</p>
          {byClient.map(({ c, sum, target }) => {
            const pct = target ? Math.min(100, Math.round((sum / target) * 100)) : 0;
            return (
              <div key={c.id} className="flex items-center gap-2 text-sm">
                <span className="w-24 truncate">{c.name}</span>
                <span className="h-2.5 flex-1 overflow-hidden rounded-full bg-page">
                  <span className={`block h-full ${pct >= 100 ? "bg-good" : pct >= 60 ? "bg-warn" : "bg-danger"}`} style={{ width: `${target ? pct : 0}%` }} />
                </span>
                <span className="w-28 text-right text-xs tabular-nums text-muted">
                  {sum.toLocaleString("en-AU")}
                  {target ? ` / ${target.toLocaleString("en-AU")}` : ""} {total.unit}
                </span>
              </div>
            );
          })}
        </div>
      ) : null}
      <p className="text-xs font-semibold tracking-wider text-muted uppercase">Every entry</p>
      <div className="overflow-x-auto rounded-md border border-line">
        <table className="w-full border-collapse text-xs">
          <thead>
            <tr className="text-left text-muted">
              <th className="px-2 py-1.5 whitespace-nowrap">Time</th>
              {fields.map((f) => (
                <th key={f.id} className="px-2 py-1.5 whitespace-nowrap">
                  {f.label}
                  {f.unit ? ` (${f.unit})` : ""}
                </th>
              ))}
              <th className="px-2 py-1.5 whitespace-nowrap">Staff</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i} className="border-t border-line">
                <td className="px-2 py-1.5 whitespace-nowrap">{8 + i * 2}:15 am</td>
                {r.map((v, j) => (
                  <td key={j} className="px-2 py-1.5 whitespace-nowrap">
                    {v}
                  </td>
                ))}
                <td className="px-2 py-1.5 whitespace-nowrap">{staff[i % staff.length]}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-muted">The real report (with filters, Excel and print) comes in the next step.</p>
    </div>
  );
}

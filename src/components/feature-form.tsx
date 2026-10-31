// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState, useTransition } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { quickValues, type Answers, type Feature, type FeatureField, type Option } from "@/lib/feature-types";
import { submitEntry, undoEntry, type SaveResult, type TodayRow } from "@/app/(portal)/f/actions";

type FormFeature = Pick<Feature, "id" | "name" | "description" | "undo_minutes" | "record_team" | "total_field" | "group_field" | "default_target">;

export type FeatureFormProps = {
  feature: FormFeature;
  fields: FeatureField[];
  clients: Option[];
  staff: Option[];
  me: { id: string; name: string; teams: string };
  targets: Record<string, number>;
  // "preview": the builder's live preview; nothing is saved.
  mode: "live" | "preview";
  timeZone: string;
  // Answers filled in already (e.g. the client, from a QR sticker on their door).
  preset?: Answers;
};

const OTHER = "\u0000other";
// An id and time for an entry saved in the builder's preview (never stored).
const previewStamp = () => ({ id: Date.now(), at: new Date().toISOString() });
const fmt = (n: number) => n.toLocaleString("en-AU");
// Times in the company's time zone, so every phone shows the same.
const timeOf = (iso: string, timeZone: string) =>
  new Intl.DateTimeFormat("en-AU", { hour: "numeric", minute: "2-digit", timeZone }).format(new Date(iso)).toLowerCase();

// A short line for an entry, e.g. "250 ml · Water".
function summarise(data: Record<string, unknown>, fields: FeatureField[], totalField: string | null): string {
  const total = fields.find((f) => f.id === totalField);
  const choice = fields.find((f) => f.type === "choice");
  return [
    total && data[total.id] != null ? `${fmt(Number(data[total.id]))}${total.unit ? ` ${total.unit}` : ""}` : "",
    choice && data[choice.id] ? String(data[choice.id]) : "",
  ]
    .filter(Boolean)
    .join(" · ");
}

export function FeatureForm(props: FeatureFormProps) {
  const { feature, fields, clients, staff, me, targets, mode } = props;
  const live = fields.filter((f) => !f.archived).sort((a, b) => a.sort_order - b.sort_order);
  const [answers, setAnswers] = useState<Answers>(props.preset ?? {});
  const [typed, setTyped] = useState<Record<string, string>>({});
  const [error, setError] = useState("");
  const [saved, setSaved] = useState<SaveResult | null>(null);
  const [pending, start] = useTransition();
  // The builder's preview keeps its "saved" entries here (nothing reaches the database).
  const [previewRows, setPreviewRows] = useState<(TodayRow & { client: string })[]>([]);

  const set = (id: string, v: string | string[]) => setAnswers((a) => ({ ...a, [id]: v }));
  const valueFor = (f: FeatureField): string | string[] => {
    const v = answers[f.id];
    if (f.type === "choice" && v === OTHER) return (typed[f.id] ?? "").trim();
    return v ?? (f.type === "multi" ? [] : "");
  };

  function save() {
    setError("");
    const data: Answers = {};
    for (const f of live) {
      const v = valueFor(f);
      if (f.required && (Array.isArray(v) ? v.length === 0 : !String(v).trim())) {
        setError(`${f.label}: this is needed.`);
        return;
      }
      if (f.type === "number" && v !== "" && Number.isNaN(Number(v))) {
        setError(`${f.label}: enter a number.`);
        return;
      }
      if (Array.isArray(v) ? v.length : String(v).trim()) data[f.id] = v;
    }
    if (mode === "preview") {
      const group = live.find((f) => f.id === feature.group_field && f.type === "client");
      const clientId = group ? String(data[group.id] ?? "") : "";
      const stamp = previewStamp();
      const row = { id: stamp.id, created_at: stamp.at, data, by_name: me.name.split(" ")[0], mine: true, client: clientId };
      const rows = [row, ...previewRows];
      setPreviewRows(rows);
      setSaved({ ok: true, entryId: row.id, clientId, today: rows.filter((r) => r.client === clientId), savedAt: row.created_at, data });
      setAnswers(props.preset ?? {});
      setTyped({});
      return;
    }
    start(async () => {
      const result = await submitEntry(feature.id, data);
      if (!result.ok) setError(result.error);
      else {
        setSaved(result);
        setAnswers(props.preset ?? {});
        setTyped({});
      }
    });
  }

  if (saved?.ok) {
    return (
      <Saved
        result={saved}
        props={props}
        live={live}
        onAnother={() => setSaved(null)}
        onUndo={async () => {
          if (mode === "preview") {
            setPreviewRows((r) => r.filter((x) => x.id !== saved.entryId));
            setSaved(null);
            return;
          }
          const r = await undoEntry(saved.entryId);
          if (r.error) setError(r.error);
          setSaved(null);
        }}
        clients={clients}
        targets={targets}
      />
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h2 className="heading-sm">{feature.name}</h2>
        {feature.description ? <p className="mt-1 text-sm text-muted">{feature.description}</p> : null}
      </div>
      <div className="flex flex-wrap gap-1.5 text-xs">
        <span className="rounded-full border border-line bg-surface px-2.5 py-0.5 text-muted">Date and time recorded when you save</span>
        <span className="rounded-full border border-line bg-surface px-2.5 py-0.5 text-muted">{me.name}</span>
        {feature.record_team && me.teams ? <span className="rounded-full border border-line bg-surface px-2.5 py-0.5 text-muted">{me.teams}</span> : null}
      </div>
      {error ? <Notice tone="error">{error}</Notice> : null}
      {live.length === 0 ? <p className="text-sm text-muted">No fields yet. Add some in the builder.</p> : null}
      {live.map((f) => (
        <FieldInput
          key={f.id}
          f={f}
          value={answers[f.id]}
          typed={typed[f.id] ?? ""}
          onChange={(v) => set(f.id, v)}
          onTyped={(v) => setTyped((t) => ({ ...t, [f.id]: v }))}
          clients={clients}
          staff={staff}
          userId={me.id}
          preview={mode === "preview"}
        />
      ))}
      {live.length ? (
        <Button className="min-h-14 w-full text-lg" disabled={pending} onClick={save} type="button">
          {pending ? "Saving…" : "Save"}
        </Button>
      ) : null}
      {mode === "preview" ? <p className="text-center text-xs text-muted">Preview: nothing is saved.</p> : null}
    </div>
  );
}

function Label({ f }: { f: FeatureField }) {
  return (
    <span className="text-sm font-semibold">
      {f.label}
      {f.unit && f.type === "number" ? ` (${f.unit})` : ""}
      {f.required ? "" : <span className="font-normal text-muted"> (optional)</span>}
    </span>
  );
}

const chip = (on: boolean) =>
  `min-h-10 rounded-full border-2 px-3.5 text-sm font-semibold ${on ? "border-brand bg-brand-soft text-brand" : "border-line bg-surface text-ink"}`;

function FieldInput({
  f,
  value,
  typed,
  onChange,
  onTyped,
  clients,
  staff,
  userId,
  preview,
}: {
  f: FeatureField;
  value: string | string[] | undefined;
  typed: string;
  onChange: (v: string | string[]) => void;
  onTyped: (v: string) => void;
  clients: Option[];
  staff: Option[];
  userId: string;
  preview: boolean;
}) {
  const id = `ff-${f.id}`;
  const help = f.help ? <span className="text-xs text-muted">{f.help}</span> : null;
  switch (f.type) {
    case "client":
    case "staff": {
      const list = f.type === "client" ? clients : staff;
      return (
        <label className="flex flex-col gap-1.5" htmlFor={id}>
          <Label f={f} />
          <select id={id} value={String(value ?? "")} onChange={(e) => onChange(e.target.value)} className={`${inputClass} h-12`}>
            <option value="">Choose…</option>
            {list.map((o) => (
              <option key={o.id} value={o.id}>
                {o.name}
              </option>
            ))}
          </select>
          {f.type === "client" && list.length === 0 ? <span className="text-xs text-warn">No clients yet. Add them under People → Clients.</span> : null}
          {help}
        </label>
      );
    }
    case "choice":
      return (
        <div className="flex flex-col gap-1.5">
          <Label f={f} />
          <div className="flex flex-wrap gap-2">
            {f.options.map((o) => (
              <button key={o} type="button" aria-pressed={value === o} className={chip(value === o)} onClick={() => onChange(o)}>
                {o}
              </button>
            ))}
            {f.allow_other ? (
              <button type="button" aria-pressed={value === OTHER} className={chip(value === OTHER)} onClick={() => onChange(OTHER)}>
                + Something else
              </button>
            ) : null}
          </div>
          {value === OTHER ? (
            <input aria-label={`${f.label}: type it`} autoFocus value={typed} onChange={(e) => onTyped(e.target.value)} placeholder="Type it here" className={`${inputClass} h-12`} />
          ) : null}
          {help}
        </div>
      );
    case "multi": {
      const list = Array.isArray(value) ? value : [];
      return (
        <fieldset className="flex flex-col gap-1">
          <legend className="mb-1">
            <Label f={f} />
          </legend>
          {f.options.map((o) => (
            <label key={o} className="flex min-h-10 items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={list.includes(o)}
                onChange={(e) => onChange(e.target.checked ? [...list, o] : list.filter((x) => x !== o))}
                className="h-5 w-5 accent-[var(--brand-primary)]"
              />
              {o}
            </label>
          ))}
          {help}
        </fieldset>
      );
    }
    case "number": {
      const quick = quickValues(f);
      return (
        <div className="flex flex-col gap-1.5">
          <label htmlFor={id}>
            <Label f={f} />
          </label>
          {quick.length ? (
            <div className="flex flex-wrap gap-2">
              {quick.map((q) => (
                <button key={q} type="button" className={chip(String(value) === String(q))} onClick={() => onChange(String(q))}>
                  {fmt(q)}
                </button>
              ))}
            </div>
          ) : null}
          <input id={id} inputMode="decimal" value={String(value ?? "")} onChange={(e) => onChange(e.target.value)} className={`${inputClass} h-14 text-xl tabular-nums`} />
          {f.min_value != null || f.max_value != null ? (
            <span className="text-xs text-muted">
              {f.min_value != null && f.max_value != null ? `Between ${fmt(f.min_value)} and ${fmt(f.max_value)}` : f.min_value != null ? `At least ${fmt(f.min_value)}` : `Up to ${fmt(f.max_value!)}`}
              {f.unit ? ` ${f.unit}` : ""}
            </span>
          ) : null}
          {help}
        </div>
      );
    }
    case "yesno":
      return (
        <div className="flex flex-wrap items-center justify-between gap-2">
          <Label f={f} />
          <div className="flex gap-2">
            {["Yes", "No"].map((o) => (
              <button key={o} type="button" aria-pressed={value === o} className={chip(value === o)} onClick={() => onChange(o)}>
                {o}
              </button>
            ))}
          </div>
          {help}
        </div>
      );
    case "long":
      return (
        <label className="flex flex-col gap-1.5" htmlFor={id}>
          <Label f={f} />
          <textarea id={id} rows={3} maxLength={2000} value={String(value ?? "")} onChange={(e) => onChange(e.target.value)} className={`${inputClass} h-auto py-2`} />
          {help}
        </label>
      );
    case "date":
    case "time":
      return (
        <label className="flex flex-col gap-1.5" htmlFor={id}>
          <Label f={f} />
          <input id={id} type={f.type} value={String(value ?? "")} onChange={(e) => onChange(e.target.value)} className={`${inputClass} h-12`} />
          {help}
        </label>
      );
    case "photo":
      return (
        <div className="flex flex-col gap-1.5">
          <Label f={f} />
          {preview ? (
            <div className="rounded-md border-2 border-dashed border-line p-4 text-center text-sm text-muted">Take or choose a photo</div>
          ) : (
            <PhotoField id={id} userId={userId} onChange={onChange} />
          )}
          {help}
        </div>
      );
    default:
      return (
        <label className="flex flex-col gap-1.5" htmlFor={id}>
          <Label f={f} />
          <input id={id} maxLength={200} value={String(value ?? "")} onChange={(e) => onChange(e.target.value)} className={`${inputClass} h-12`} />
          {help}
        </label>
      );
  }
}

function PhotoField({ id, userId, onChange }: { id: string; userId: string; onChange: (v: string) => void }) {
  return (
    <FileUpload
      id={id}
      bucket="feature-files"
      folder={userId}
      name={id}
      accept="image/*,application/pdf"
      onReady={(ready) => {
        if (!ready) onChange("");
      }}
      onUploaded={(path) => onChange(path)}
    />
  );
}

function Saved({
  result,
  props,
  live,
  onAnother,
  onUndo,
  clients,
  targets,
}: {
  result: Extract<SaveResult, { ok: true }>;
  props: FeatureFormProps;
  live: FeatureField[];
  onAnother: () => void;
  onUndo: () => Promise<void>;
  clients: Option[];
  targets: Record<string, number>;
}) {
  const { feature, mode } = props;
  const total = live.find((f) => f.id === feature.total_field);
  const client = clients.find((c) => c.id === result.clientId);
  const target = result.clientId ? targets[result.clientId] ?? feature.default_target : feature.default_target;
  const sum = total ? result.today.reduce((s, r) => s + (Number(r.data[total.id]) || 0), 0) : 0;
  const pct = target ? Math.min(100, Math.round((sum / target) * 100)) : 0;
  const [left, setLeft] = useState(feature.undo_minutes * 60);
  const [undoing, setUndoing] = useState(false);
  useEffect(() => {
    const t = window.setInterval(() => setLeft((s) => Math.max(0, s - 1)), 1000);
    return () => window.clearInterval(t);
  }, []);
  const summary = summarise(result.data, live, feature.total_field);

  return (
    <div className="flex flex-col gap-4">
      <p className="rounded-lg bg-good-soft px-4 py-3 text-sm font-semibold text-good">
        Saved at {timeOf(result.savedAt, props.timeZone)}
        {summary ? `: ${summary}` : ""}
        {client ? ` for ${client.name}` : ""}
        {(client?.name ?? summary).endsWith(".") ? "" : "."}
      </p>
      {client && total ? (
        <div className="flex flex-col gap-2 rounded-xl border border-line bg-surface p-4">
          <div className="flex justify-between gap-2 text-sm font-semibold">
            <span>{client.name} today</span>
            <span className="tabular-nums">
              {fmt(sum)}
              {target ? ` / ${fmt(target)}` : ""} {total.unit}
            </span>
          </div>
          {target ? (
            <>
              <div className="h-3.5 overflow-hidden rounded-full border border-line bg-page">
                <div className={`h-full ${pct >= 100 ? "bg-good" : pct >= 60 ? "bg-warn" : "bg-danger"}`} style={{ width: `${pct}%` }} />
              </div>
              <span className="text-xs text-muted">{pct >= 100 ? "Target reached." : `${fmt(target - sum)} ${total.unit} to go today.`}</span>
            </>
          ) : null}
        </div>
      ) : null}
      {left > 0 ? (
        <div className="flex items-center justify-between gap-3 rounded-lg bg-warn-soft px-4 py-3 text-sm font-semibold text-warn">
          <span>
            Wrong client or amount? {Math.floor(left / 60)}:{String(left % 60).padStart(2, "0")} left to undo.
          </span>
          <Button
            variant="outline"
            disabled={undoing}
            onClick={async () => {
              setUndoing(true);
              await onUndo();
            }}
          >
            Undo
          </Button>
        </div>
      ) : null}
      <Button className="min-h-14 w-full text-lg" onClick={onAnother}>
        Add another
      </Button>
      {client && result.today.length ? (
        <div className="flex flex-col gap-2">
          <h3 className="text-sm font-semibold">{client.name} today</h3>
          <ul className="divide-y divide-line rounded-lg border border-line bg-surface text-sm">
            {result.today.map((r) => (
              <li key={r.id} className="flex justify-between gap-3 px-3 py-2">
                <span className="text-muted tabular-nums">{timeOf(r.created_at, props.timeZone)}</span>
                <span className="flex-1">{summarise(r.data, live, feature.total_field)}</span>
                <span className="text-muted">{r.mine ? "You" : r.by_name}</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
      {mode === "preview" ? <p className="text-center text-xs text-muted">Preview: nothing is saved.</p> : null}
    </div>
  );
}

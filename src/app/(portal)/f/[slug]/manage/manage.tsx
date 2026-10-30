// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Badge, Button, Field, Notice, inputClass } from "@/components/ui";
import { TargetsEditor } from "@/components/feature-targets";
import type { Answers, Feature, FeatureField, Option } from "@/lib/feature-types";
import { fixEntry, saveOptions } from "../../actions";

export type ManageEntry = {
  id: number;
  created_at: string;
  by: string;
  client_name: string;
  data: Record<string, unknown>;
  corrected_at: string | null;
  correction_reason: string;
};
type Ctx = { clients: Option[]; staff: Option[]; targets: Record<string, number>; timeZone: string };
type Tab = "fix" | "targets" | "options";

const fmt = (n: number) => n.toLocaleString("en-AU");

// cmeprojects: fix entries, client targets and drop-down options, each only
// when the system admin allowed it for this feature.
export function Manage({ feature, fields, ctx, entries, can }: { feature: Feature; fields: FeatureField[]; ctx: Ctx; entries: ManageEntry[]; can: Record<Tab, boolean> }) {
  const tabs = (["fix", "targets", "options"] as const).filter((t) => can[t]);
  const [tab, setTab] = useState<Tab>(tabs[0]);
  const label: Record<Tab, string> = { fix: "Fix entries", targets: "Client targets", options: "Drop-down options" };
  const total = fields.find((f) => f.id === feature.total_field);

  return (
    <div className="flex flex-col gap-4">
      {tabs.length > 1 ? (
        <nav aria-label="Manage" className="flex gap-1 overflow-x-auto border-b border-line">
          {tabs.map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              aria-current={tab === t ? "page" : undefined}
              className={`-mb-px min-h-11 border-b-2 px-3 text-sm font-semibold whitespace-nowrap ${tab === t ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"}`}
            >
              {label[t]}
            </button>
          ))}
        </nav>
      ) : null}
      {tab === "fix" ? <FixEntries fields={fields} ctx={ctx} entries={entries} totalField={feature.total_field} /> : null}
      {tab === "targets" ? (
        <div className="rounded-lg border border-line bg-surface p-5">
          <TargetsEditor featureId={feature.id} unit={total?.unit ?? ""} clients={ctx.clients} targets={ctx.targets} defaultTarget={feature.default_target} />
        </div>
      ) : null}
      {tab === "options" ? <Options fields={fields.filter((f) => f.type === "choice" || f.type === "multi")} /> : null}
    </div>
  );
}

// What an answer looks like in a list.
function show(f: FeatureField, v: unknown, ctx: Ctx): string {
  if (v == null || v === "") return "";
  if (Array.isArray(v)) return v.join(", ");
  if (f.type === "client") return ctx.clients.find((c) => c.id === v)?.name ?? "(client no longer listed)";
  if (f.type === "staff") return ctx.staff.find((s) => s.id === v)?.name ?? "";
  if (f.type === "number") return `${fmt(Number(v))}${f.unit ? ` ${f.unit}` : ""}`;
  if (f.type === "photo") return "Photo";
  return String(v);
}

function FixEntries({ fields, ctx, entries, totalField }: { fields: FeatureField[]; ctx: Ctx; entries: ManageEntry[]; totalField: string | null }) {
  const [client, setClient] = useState("");
  const [open, setOpen] = useState<number | null>(null);
  const when = useMemo(
    () => new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone: ctx.timeZone }),
    [ctx.timeZone],
  );
  const names = [...new Set(entries.map((e) => e.client_name).filter(Boolean))].sort();
  const list = entries.filter((e) => !client || e.client_name === client);
  const total = fields.find((f) => f.id === totalField);
  const choice = fields.find((f) => f.type === "choice");

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <p className="text-sm text-muted">The last 31 days. Staff can undo their own entries for a few minutes; after that, fix them here.</p>
        {names.length > 1 ? (
          <Field label="Client" htmlFor="fx-client">
            <select id="fx-client" value={client} onChange={(e) => setClient(e.target.value)} className={inputClass}>
              <option value="">Everyone</option>
              {names.map((n) => (
                <option key={n}>{n}</option>
              ))}
            </select>
          </Field>
        ) : null}
      </div>
      {list.length === 0 ? <p className="rounded-lg border border-line bg-surface px-4 py-4 text-sm text-muted">No entries yet.</p> : null}
      <ul className="divide-y divide-line overflow-hidden rounded-lg border border-line bg-surface text-sm">
        {list.map((e) => (
          <li key={e.id}>
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 px-4 py-2.5">
              <span className="min-w-0 flex-1">
                <span className="block font-semibold">
                  {e.client_name || "—"} {e.corrected_at ? <Badge tone="grey">Fixed</Badge> : null}
                </span>
                <span className="block text-xs text-muted">
                  {when.format(new Date(e.created_at))} · {e.by}
                </span>
              </span>
              <span className="text-right">
                {total ? show(total, e.data[total.id], ctx) : ""}
                {choice && e.data[choice.id] ? <span className="block text-xs text-muted">{String(e.data[choice.id])}</span> : null}
              </span>
              <button type="button" className="min-h-10 px-2 font-semibold text-brand underline" onClick={() => setOpen(open === e.id ? null : e.id)}>
                {open === e.id ? "Close" : "Fix"}
              </button>
            </div>
            {open === e.id ? <EntryEditor key={e.id} entry={e} fields={fields} ctx={ctx} onDone={() => setOpen(null)} /> : null}
          </li>
        ))}
      </ul>
    </div>
  );
}

function EntryEditor({ entry, fields, ctx, onDone }: { entry: ManageEntry; fields: FeatureField[]; ctx: Ctx; onDone: () => void }) {
  const router = useRouter();
  const start0 = (): Answers =>
    Object.fromEntries(
      fields.map((f) => {
        const v = entry.data[f.id];
        return [f.id, Array.isArray(v) ? v.map(String) : v == null ? "" : String(v)];
      }),
    );
  const [answers, setAnswers] = useState<Answers>(start0);
  const [reason, setReason] = useState("");
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const set = (id: string, v: string | string[]) => setAnswers((a) => ({ ...a, [id]: v }));

  return (
    <div className="flex flex-col gap-3 border-t border-brand/30 bg-brand-soft/30 px-4 py-4">
      {entry.corrected_at ? <p className="text-xs text-muted">Fixed before: {entry.correction_reason}</p> : null}
      {fields.map((f) => (
        <Field key={f.id} label={`${f.label}${f.unit ? ` (${f.unit})` : ""}`} htmlFor={`fx-${entry.id}-${f.id}`}>
          <Input f={f} id={`fx-${entry.id}-${f.id}`} value={answers[f.id] ?? ""} onChange={(v) => set(f.id, v)} ctx={ctx} />
        </Field>
      ))}
      <Field label="Why is it being changed?" htmlFor={`fx-${entry.id}-why`} hint="Kept in the change log with what it was.">
        <input id={`fx-${entry.id}-why`} value={reason} maxLength={300} placeholder="e.g. Wrong client chosen" onChange={(e) => setReason(e.target.value)} className={inputClass} />
      </Field>
      {result?.error ? <Notice tone="error">{result.error}</Notice> : null}
      <div className="flex gap-2">
        <Button
          type="button"
          disabled={pending}
          onClick={() =>
            start(async () => {
              const r = await fixEntry(entry.id, answers, reason);
              setResult(r);
              if (!r.error) {
                router.refresh();
                onDone();
              }
            })
          }
        >
          {pending ? "Saving…" : "Save fix"}
        </Button>
        <Button type="button" variant="outline" onClick={onDone}>
          Cancel
        </Button>
      </div>
    </div>
  );
}

function Input({ f, id, value, onChange, ctx }: { f: FeatureField; id: string; value: string | string[]; onChange: (v: string | string[]) => void; ctx: Ctx }) {
  const v = Array.isArray(value) ? "" : value;
  const pick = (list: Option[]) => (
    <select id={id} value={v} onChange={(e) => onChange(e.target.value)} className={inputClass}>
      <option value="">—</option>
      {list.map((o) => (
        <option key={o.id} value={o.id}>
          {o.name}
        </option>
      ))}
    </select>
  );
  switch (f.type) {
    case "client":
      return pick(ctx.clients);
    case "staff":
      return pick(ctx.staff);
    case "yesno":
      return pick([
        { id: "Yes", name: "Yes" },
        { id: "No", name: "No" },
      ]);
    case "choice":
      if (f.allow_other)
        return (
          <>
            <input id={id} list={`${id}-list`} value={v} onChange={(e) => onChange(e.target.value)} className={inputClass} />
            <datalist id={`${id}-list`}>
              {f.options.map((o) => (
                <option key={o} value={o} />
              ))}
            </datalist>
          </>
        );
      return pick([...new Set([...f.options, ...(v ? [v] : [])])].map((o) => ({ id: o, name: o })));
    case "multi": {
      const chosen = Array.isArray(value) ? value : [];
      return (
        <div id={id} className="flex flex-wrap gap-x-4">
          {[...new Set([...f.options, ...chosen])].map((o) => (
            <label key={o} className="flex min-h-10 items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={chosen.includes(o)}
                onChange={(e) => onChange(e.target.checked ? [...chosen, o] : chosen.filter((x) => x !== o))}
                className="h-5 w-5 accent-[var(--brand-primary)]"
              />
              {o}
            </label>
          ))}
        </div>
      );
    }
    case "long":
      return <textarea id={id} rows={3} value={v} maxLength={2000} onChange={(e) => onChange(e.target.value)} className={inputClass} />;
    case "photo":
      return <p className="text-sm text-muted">{v ? "Photo kept as it is." : "No photo."}</p>;
    default:
      return (
        <input
          id={id}
          type={f.type === "date" ? "date" : f.type === "time" ? "time" : "text"}
          inputMode={f.type === "number" ? "decimal" : undefined}
          value={v}
          maxLength={200}
          onChange={(e) => onChange(e.target.value)}
          className={inputClass}
        />
      );
  }
}

function Options({ fields }: { fields: FeatureField[] }) {
  if (fields.length === 0) return <p className="rounded-lg border border-line bg-surface px-4 py-4 text-sm text-muted">This feature has no drop-downs.</p>;
  return (
    <div className="flex flex-col gap-4">
      {fields.map((f) => (
        <OptionList key={f.id} f={f} />
      ))}
    </div>
  );
}

function OptionList({ f }: { f: FeatureField }) {
  const router = useRouter();
  const [options, setOptions] = useState(f.options);
  const [add, setAdd] = useState("");
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const dirty = JSON.stringify(options) !== JSON.stringify(f.options);
  const addOne = () => {
    const o = add.trim();
    if (o && !options.some((x) => x.toLowerCase() === o.toLowerCase())) setOptions([...options, o]);
    setAdd("");
  };

  return (
    <section className="flex flex-col gap-2 rounded-lg border border-line bg-surface p-5">
      <h2 className="font-semibold">{f.label}</h2>
      {f.add_typed ? <p className="text-xs text-muted">Answers staff type themselves are added here automatically.</p> : null}
      <div className="flex flex-wrap gap-2">
        {options.map((o, i) => (
          <span key={o + i} className="inline-flex items-center gap-1 rounded-full border border-line bg-page py-1 pr-1 pl-3 text-sm">
            {o}
            <button type="button" aria-label={`Remove ${o}`} onClick={() => setOptions(options.filter((_, n) => n !== i))} className="size-7 rounded-full text-muted hover:bg-surface">
              ×
            </button>
          </span>
        ))}
      </div>
      <div className="flex gap-2">
        <label htmlFor={`op-${f.id}`} className="sr-only">
          Add an option
        </label>
        <input
          id={`op-${f.id}`}
          value={add}
          maxLength={80}
          placeholder="Add an option"
          onChange={(e) => setAdd(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              addOne();
            }
          }}
          className={`${inputClass} min-w-0 flex-1`}
        />
        <Button type="button" variant="outline" onClick={addOne}>
          Add
        </Button>
      </div>
      {result?.error ? <Notice tone="error">{result.error}</Notice> : result?.message && !dirty ? <Notice tone="success">{result.message}</Notice> : null}
      <Button
        type="button"
        className="self-start"
        disabled={pending || !dirty}
        onClick={() =>
          start(async () => {
            const r = await saveOptions(f.id, options);
            setResult(r);
            if (!r.error) router.refresh();
          })
        }
      >
        {pending ? "Saving…" : "Save list"}
      </Button>
    </section>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";

// cmeprojects (update 159): one set of answer inputs for staff Forms and
// client assessments (short and long text, pick one, tick boxes, yes/no,
// date, number). Forms adds its own file and signature inputs.
export type QuestionInputType = "text" | "long" | "choice" | "multi" | "yesno" | "date" | "number";

export function QuestionInput({ id, type, options, value, set, disabled = false }: { id: string; type: QuestionInputType; options: string[]; value: string | string[] | undefined; set: (v: string | string[]) => void; disabled?: boolean }) {
  const v = typeof value === "string" ? value : "";
  const chip = (on: boolean) =>
    `min-h-11 rounded-full border px-4 text-sm font-medium disabled:opacity-60 ${on ? "border-brand bg-brand text-brand-fg" : "border-line bg-surface text-ink hover:border-muted"}`;
  switch (type) {
    case "long":
      return <textarea id={id} rows={4} maxLength={5000} value={v} disabled={disabled} onChange={(e) => set(e.target.value)} className={`${inputClass} min-h-28 py-3`} />;
    case "choice":
      return (
        <div className="flex flex-wrap gap-2" role="radiogroup" aria-labelledby={id}>
          {options.map((o, n) => (
            <button key={o} id={n === 0 ? id : undefined} type="button" role="radio" aria-checked={v === o} disabled={disabled} onClick={() => set(v === o ? "" : o)} className={chip(v === o)}>
              {o}
            </button>
          ))}
        </div>
      );
    case "multi": {
      const list = Array.isArray(value) ? value : [];
      return (
        <div className="flex flex-col gap-1">
          {options.map((o, n) => (
            <label key={o} className="flex min-h-10 items-center gap-2 text-sm">
              <input
                id={n === 0 ? id : undefined}
                type="checkbox"
                checked={list.includes(o)}
                disabled={disabled}
                onChange={(e) => set(e.target.checked ? [...list, o] : list.filter((x) => x !== o))}
                className="h-5 w-5 accent-[var(--brand-primary)]"
              />
              {o}
            </label>
          ))}
        </div>
      );
    }
    case "yesno":
      return (
        <div className="flex gap-2">
          {["Yes", "No"].map((o, n) => (
            <button key={o} id={n === 0 ? id : undefined} type="button" aria-pressed={v === o} disabled={disabled} onClick={() => set(v === o ? "" : o)} className={chip(v === o)}>
              {o}
            </button>
          ))}
        </div>
      );
    case "date":
      return <DateInput id={id} value={v} disabled={disabled} onChange={(e) => set(e.target.value)} className={`${inputClass} max-w-56`} />;
    case "number":
      return <input id={id} inputMode="decimal" value={v} disabled={disabled} onChange={(e) => set(e.target.value.replace(/[^\d.-]/g, ""))} className={`${inputClass} max-w-56`} />;
    default:
      return <input id={id} value={v} maxLength={300} disabled={disabled} onChange={(e) => set(e.target.value)} className={inputClass} />;
  }
}

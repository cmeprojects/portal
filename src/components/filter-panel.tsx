// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { SlidersHorizontal, X } from "lucide-react";

// cmeprojects (owner, 20 Nov 2026): a Filters button that opens a floating panel,
// like the side menu: nothing on the page moves. The button shows how many
// filters are on; the panel counts the results as you choose. Closes on Done, a
// click outside or Esc. Used by the client and staff lists.
export function FilterPanel({ count, results, resultWord = "results", onClear, children }: { count: number; results: number; resultWord?: string; onClear: () => void; children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const away = (e: MouseEvent) => {
      if (box.current && !box.current.contains(e.target as Node)) setOpen(false);
    };
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", away);
    document.addEventListener("keydown", esc);
    return () => {
      document.removeEventListener("mousedown", away);
      document.removeEventListener("keydown", esc);
    };
  }, [open]);
  return (
    <div ref={box} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className={`inline-flex h-10 items-center gap-1.5 rounded-lg border px-3 text-sm font-semibold transition-colors ${open || count ? "border-brand bg-brand-soft text-ink" : "border-field bg-surface text-muted hover:text-ink"}`}
      >
        <SlidersHorizontal aria-hidden="true" className="size-4" /> Filters
        {count ? <span className="rounded-full bg-brand px-1.5 text-xs leading-5 font-bold text-brand-fg">{count}</span> : null}
      </button>
      {open ? (
        <div role="dialog" aria-label="Filters" className="absolute top-full left-0 z-40 mt-2 w-80 overflow-hidden rounded-2xl border border-line bg-surface shadow-2xl ring-1 ring-black/5">
          <div className="flex items-center gap-2 border-b border-line bg-page/50 px-4 py-3">
            <SlidersHorizontal aria-hidden="true" className="size-4 text-brand" />
            <p className="flex-1 text-sm font-semibold text-ink">
              Filters {count ? <span className="ml-1 rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">{count} on</span> : null}
            </p>
            <button type="button" onClick={() => setOpen(false)} aria-label="Close filters" className="rounded-md p-1 text-muted hover:bg-surface hover:text-ink">
              <X aria-hidden="true" className="size-4" />
            </button>
          </div>
          <div className="thin-scroll flex max-h-[60vh] flex-col gap-3 overflow-y-auto px-4 py-3">{children}</div>
          <div className="flex items-center justify-between gap-2 border-t border-line px-4 py-3">
            <button type="button" onClick={onClear} disabled={!count} className="rounded-lg px-2 py-1.5 text-sm font-semibold text-muted hover:bg-page hover:text-ink disabled:opacity-40">
              Clear all
            </button>
            <button type="button" onClick={() => setOpen(false)} className="rounded-lg bg-brand px-4 py-1.5 text-sm font-semibold text-brand-fg shadow-sm hover:opacity-90">
              Show {results} {results === 1 ? resultWord.replace(/s$/, "") : resultWord}
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

// One filter in the panel: its name above, and it stands out once something is chosen.
export function FilterSelect({ label, value, onChange, options }: { label: string; value: string; onChange: (v: string) => void; options: [string, string][] }) {
  return (
    <label className="flex flex-col gap-1">
      <span className="flex items-center justify-between text-xs font-semibold text-muted">
        {label}
        {value ? (
          <button type="button" onClick={() => onChange("")} className="font-semibold text-brand hover:underline">
            Clear
          </button>
        ) : null}
      </span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        aria-label={label}
        className={`h-10 w-full rounded-lg border px-2.5 text-sm ${value ? "border-brand bg-brand-soft font-semibold text-ink" : "border-field bg-surface text-ink"}`}
      >
        <option value="">Any</option>
        {options.map(([k, l]) => (
          <option key={k} value={k}>
            {l}
          </option>
        ))}
      </select>
    </label>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState } from "react";
import { buttonClass, inputClass } from "@/components/ui";

type Range = { from: string; to: string };

const iso = (d: Date) => d.toISOString().slice(0, 10);
const utc = (y: number, m: number, d: number) => new Date(Date.UTC(y, m, d));

// Quick date ranges, worked out from today's date in the company's time zone.
// The Australian financial year runs 1 July to 30 June.
function presets(today: string): { key: string; label: string; range: Range }[] {
  const [y, m] = today.split("-").map(Number);
  const mi = m - 1;
  const q = Math.floor(mi / 3) * 3;
  const fyStart = mi >= 6 ? y : y - 1;
  return [
    { key: "month", label: "This month", range: { from: iso(utc(y, mi, 1)), to: iso(utc(y, mi + 1, 0)) } },
    { key: "last", label: "Last month", range: { from: iso(utc(y, mi - 1, 1)), to: iso(utc(y, mi, 0)) } },
    { key: "quarter", label: "This quarter", range: { from: iso(utc(y, q, 1)), to: iso(utc(y, q + 3, 0)) } },
    { key: "fy", label: "This financial year", range: { from: `${fyStart}-07-01`, to: `${fyStart + 1}-06-30` } },
    { key: "all", label: "All dates", range: { from: "", to: "" } },
  ];
}

// "Download for Excel": choose the dates (and which entries) first.
export function ExportPanel({
  registerId,
  today,
  records,
  status,
  q,
}: {
  registerId: string;
  today: string;
  records: boolean;
  status: string;
  q: string;
}) {
  const [open, setOpen] = useState(false);
  const [range, setRange] = useState<Range>({ from: "", to: "" });
  const [which, setWhich] = useState(status);
  const box = useRef<HTMLDivElement>(null);
  const list = presets(today);
  const picked = list.find((p) => p.range.from === range.from && p.range.to === range.to)?.key;

  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent | KeyboardEvent) => {
      if (e instanceof KeyboardEvent ? e.key === "Escape" : !box.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", close);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", close);
    };
  }, [open]);

  const badRange = Boolean(range.from && range.to && range.from > range.to);

  return (
    <div ref={box} className="relative">
      <button type="button" aria-expanded={open} onClick={() => setOpen(!open)} className={buttonClass("outline")}>
        Download for Excel
      </button>
      {open ? (
        <form
          method="get"
          action={`/registers/${registerId}/export`}
          onSubmit={() => setTimeout(() => setOpen(false), 300)}
          className="absolute top-full right-0 z-40 mt-2 flex w-[min(24rem,calc(100vw-2rem))] flex-col gap-4 rounded-lg border border-line bg-surface p-4 text-ink shadow-lg"
        >
          <p className="heading-sm">Download for Excel</p>

          <fieldset className="flex flex-col gap-2">
            <legend className="mb-1 text-sm font-medium">{records ? "Date added" : "Date reported"}</legend>
            <div className="flex flex-wrap gap-1.5">
              {list.map((p) => (
                <button
                  key={p.key}
                  type="button"
                  aria-pressed={picked === p.key}
                  onClick={() => setRange(p.range)}
                  className={`min-h-9 rounded-md border px-2.5 text-xs font-semibold ${
                    picked === p.key ? "border-brand bg-brand text-brand-fg" : "border-field bg-surface text-ink hover:border-muted"
                  }`}
                >
                  {p.label}
                </button>
              ))}
            </div>
            <div className="grid grid-cols-2 gap-2">
              <label className="flex flex-col gap-1 text-xs font-medium">
                From
                <input type="date" name="from" value={range.from} onChange={(e) => setRange({ ...range, from: e.target.value })} className={inputClass} />
              </label>
              <label className="flex flex-col gap-1 text-xs font-medium">
                To
                <input type="date" name="to" value={range.to} onChange={(e) => setRange({ ...range, to: e.target.value })} className={inputClass} />
              </label>
            </div>
            {badRange ? <p className="text-xs font-semibold text-danger">The From date is after the To date.</p> : null}
          </fieldset>

          <label className="flex flex-col gap-1 text-sm font-medium">
            Include
            <select name="status" value={which} onChange={(e) => setWhich(e.target.value)} className={inputClass}>
              {records ? (
                <>
                  <option value="open">Items in the list</option>
                  <option value="done">Archived items</option>
                  <option value="all">Everything</option>
                </>
              ) : (
                <>
                  <option value="open">Open tasks</option>
                  <option value="done">Completed tasks</option>
                  <option value="all">All tasks</option>
                </>
              )}
            </select>
          </label>
          {q ? <input type="hidden" name="q" value={q} /> : null}

          <p className="text-xs text-muted">
            The file has the company logo and a heading, and is set up to print on A4 landscape.
          </p>
          <button className={buttonClass("primary")} disabled={badRange}>
            Download
          </button>
        </form>
      ) : null}
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useId, useRef, useState } from "react";
import { Clock } from "lucide-react";
import { inputClass } from "@/components/ui";

// "09:30" -> "9:30 am"
export function niceTime(t: string): string {
  if (!/^\d{2}:\d{2}$/.test(t)) return "";
  const h = Number(t.slice(0, 2));
  return `${((h + 11) % 12) + 1}:${t.slice(3, 5)} ${h < 12 ? "am" : "pm"}`;
}

// What people type -> "HH:MM": "9", "930", "9:30", "9.30pm", "21:30", "noon", "midnight".
export function parseTime(raw: string): string | null {
  const s = raw.trim().toLowerCase().replace(/\s+/g, "");
  if (!s) return null;
  if (s === "noon" || s === "midday") return "12:00";
  if (s === "midnight") return "00:00";
  const m = s.match(/^(\d{1,2})(?:[:.]?(\d{2}))?(am|pm|a|p)?$/);
  if (!m) return null;
  let h = Number(m[1]);
  const min = Number(m[2] ?? 0);
  const ap = m[3]?.[0];
  if (min > 59 || h > 23 || (ap && (h < 1 || h > 12))) return null;
  if (ap === "p" && h < 12) h += 12;
  if (ap === "a" && h === 12) h = 0;
  return `${String(h).padStart(2, "0")}:${String(min).padStart(2, "0")}`;
}

const SLOTS = Array.from({ length: 96 }, (_, i) => `${String(Math.floor(i / 4)).padStart(2, "0")}:${String((i % 4) * 15).padStart(2, "0")}`);

// cmeprojects: a time box you can type into ("930", "9:30pm") or pick from a
// 15-minute list. Keyboard: arrows move, Enter picks, Esc closes. The form
// gets HH:MM in a hidden field, as before.
export function TimeField({ name, label, value, onChange, invalid }: { name: string; label: string; value: string; onChange: (v: string) => void; invalid?: boolean }) {
  const id = useId();
  // While typing, show what's typed; otherwise the chosen time.
  const [draft, setDraft] = useState<string | null>(null);
  const text = draft ?? niceTime(value);
  const setText = (v: string | null) => setDraft(v);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const listRef = useRef<HTMLUListElement>(null);
  const boxRef = useRef<HTMLDivElement>(null);
  // Open on the chosen time (or the nearest quarter hour).
  const openList = () => {
    if (open) return;
    setActive(Math.max(0, SLOTS.findIndex((t) => t >= (value || "09:00"))));
    setOpen(true);
  };
  useEffect(() => {
    if (open && active >= 0) (listRef.current?.children[active] as HTMLElement | undefined)?.scrollIntoView({ block: "nearest" });
  }, [open, active]);
  useEffect(() => {
    if (!open) return;
    const away = (e: MouseEvent) => {
      if (!boxRef.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", away);
    return () => document.removeEventListener("mousedown", away);
  }, [open]);
  const commit = (raw: string) => {
    const t = parseTime(raw);
    if (t) onChange(t);
    setText(null);
  };
  const pick = (t: string) => {
    onChange(t);
    setText(null);
    setOpen(false);
  };
  return (
    <div ref={boxRef} className="relative flex flex-col gap-1">
      <label htmlFor={id} className="text-xs font-semibold text-ink">
        {label}
      </label>
      <input type="hidden" name={name} value={value} />
      <div className="relative">
        <Clock aria-hidden="true" className="pointer-events-none absolute top-3.5 left-3 size-4 text-muted" />
        <input
          id={id}
          role="combobox"
          aria-expanded={open}
          aria-controls={`${id}-list`}
          aria-invalid={invalid || undefined}
          autoComplete="off"
          inputMode="text"
          value={text}
          placeholder="9:00 am"
          onFocus={openList}
          onClick={openList}
          onChange={(e) => {
            setText(e.target.value);
            const t = parseTime(e.target.value);
            if (t) setActive(Math.max(0, SLOTS.findIndex((s) => s >= t)));
          }}
          onBlur={() => commit(text)}
          onKeyDown={(e) => {
            if (e.key === "ArrowDown" || e.key === "ArrowUp") {
              e.preventDefault();
              if (!open) return openList();
              setText(null);
              setActive(Math.min(SLOTS.length - 1, Math.max(0, active + (e.key === "ArrowDown" ? 1 : -1))));
            } else if (e.key === "Enter") {
              e.preventDefault();
              // Something typed wins; otherwise the highlighted time in the list.
              const typed = draft !== null ? parseTime(draft) : null;
              if (typed) pick(typed);
              else if (open && active >= 0) pick(SLOTS[active]);
              else commit(text);
            } else if (e.key === "Escape") {
              setOpen(false);
            }
          }}
          className={`${inputClass} pl-9 tabular-nums`}
        />
      </div>
      {open ? (
        <ul id={`${id}-list`} ref={listRef} role="listbox" className="thin-scroll absolute top-full left-0 z-30 mt-1 max-h-60 w-full overflow-y-auto rounded-lg border border-line bg-surface py-1 shadow-lg">
          {SLOTS.map((t, i) => (
            <li
              key={t}
              role="option"
              aria-selected={t === value}
              onMouseDown={(e) => {
                e.preventDefault();
                pick(t);
              }}
              onMouseEnter={() => setActive(i)}
              className={`cursor-pointer px-3 py-1.5 text-sm tabular-nums ${i === active ? "bg-brand-soft text-brand" : ""} ${t === value ? "font-semibold" : ""}`}
            >
              {niceTime(t)}
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useId, useMemo, useRef, useState, type ComponentProps } from "react";
import { CalendarDays, ChevronLeft, ChevronRight } from "lucide-react";
import { inputClass } from "@/components/ui";

// cmeprojects (owner, 20 Nov 2026): one date picker for the whole portal, in
// place of the browser's own. Type the date as dd/mm/yyyy (the slashes come by
// themselves) or pick it: month and year lists jump straight to, say, 1974, and
// choosing a day closes the calendar. Forms still receive YYYY-MM-DD, so nothing
// changes on the server. Earliest and latest dates (min, max) are kept.

type Props = Omit<ComponentProps<"input">, "type" | "value" | "defaultValue" | "onChange"> & {
  value?: string;
  defaultValue?: string;
  onChange?: (e: { target: { value: string; name: string } }) => void;
};

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const DAYS = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
const pad = (n: number) => String(n).padStart(2, "0");
const toIso = (y: number, m: number, d: number) => `${y}-${pad(m + 1)}-${pad(d)}`;
const isIso = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T00:00:00Z`));
const show = (iso: string) => (isIso(iso) ? `${iso.slice(8, 10)}/${iso.slice(5, 7)}/${iso.slice(0, 4)}` : "");
const todayIso = () => new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });

// "31121974", "31/12/1974" or "31-12-74" -> "1974-12-31" (blank when it isn't a real date).
function parseTyped(raw: string): string {
  const m = raw.trim().match(/^(\d{1,2})[/.\- ]?(\d{1,2})[/.\- ]?(\d{2}|\d{4})$/);
  if (!m) return "";
  const d = Number(m[1]);
  const mo = Number(m[2]);
  let y = Number(m[3]);
  if (m[3].length === 2) y += y > Number(todayIso().slice(2, 4)) + 10 ? 1900 : 2000;
  const iso = toIso(y, mo - 1, d);
  const back = new Date(`${iso}T00:00:00Z`);
  return isIso(iso) && back.getUTCDate() === d && back.getUTCMonth() === mo - 1 ? iso : "";
}

// Typing: digits only, with the slashes added (dd/mm/yyyy).
function maskTyped(raw: string): string {
  const digits = raw.replace(/\D/g, "").slice(0, 8);
  if (digits.length <= 2) return digits;
  if (digits.length <= 4) return `${digits.slice(0, 2)}/${digits.slice(2)}`;
  return `${digits.slice(0, 2)}/${digits.slice(2, 4)}/${digits.slice(4)}`;
}

export function DateInput({ value, defaultValue = "", onChange, name = "", min, max, required, disabled, id, className = "", placeholder, ...rest }: Props) {
  const controlled = value !== undefined;
  const [own, setOwn] = useState(defaultValue ?? "");
  const iso = controlled ? (value ?? "") : own;
  const [typed, setTyped] = useState<string | null>(null);
  const [open, setOpen] = useState(false);
  const autoId = useId();
  const boxId = id ?? `date-${autoId}`;
  const hidden = useRef<HTMLInputElement>(null);
  const visible = useRef<HTMLInputElement>(null);
  const wrap = useRef<HTMLDivElement>(null);
  const minS = typeof min === "string" ? min : min !== undefined ? String(min) : "";
  const maxS = typeof max === "string" ? max : max !== undefined ? String(max) : "";

  // The calendar shows the chosen month, or today's (kept within min and max).
  const start = isIso(iso) ? iso : maxS && todayIso() > maxS ? maxS : minS && todayIso() < minS ? minS : todayIso();
  const [view, setView] = useState({ y: Number(start.slice(0, 4)), m: Number(start.slice(5, 7)) - 1 });

  const outOfRange = (v: string) => (minS && v < minS) || (maxS && v > maxS);
  const message = (v: string) =>
    !v && required ? "Choose a date." : v && minS && v < minS ? `Choose ${show(minS)} or later.` : v && maxS && v > maxS ? `Choose ${show(maxS)} or earlier.` : "";

  // Tell the form (its "unsaved changes" check and its own validation) and the caller.
  const commit = (next: string) => {
    if (!controlled) setOwn(next);
    setTyped(null);
    if (hidden.current) {
      hidden.current.value = next;
      hidden.current.dispatchEvent(new Event("input", { bubbles: true }));
      hidden.current.dispatchEvent(new Event("change", { bubbles: true }));
    }
    visible.current?.setCustomValidity(message(next));
    onChange?.({ target: { value: next, name } });
  };

  // A date set by the page itself (controlled) reaches the form too.
  useEffect(() => {
    if (hidden.current && hidden.current.value !== iso) hidden.current.value = iso;
  }, [iso]);

  // Keep the browser's "this field needs filling in" check in step.
  useEffect(() => {
    visible.current?.setCustomValidity(typed !== null && typed !== "" && !parseTyped(typed) ? "Enter the date as dd/mm/yyyy." : message(iso));
  });

  useEffect(() => {
    if (!open) return;
    const away = (e: MouseEvent) => {
      if (wrap.current && !wrap.current.contains(e.target as Node)) setOpen(false);
    };
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", away);
    document.addEventListener("keydown", esc);
    return () => {
      document.removeEventListener("mousedown", away);
      document.removeEventListener("keydown", esc);
    };
  }, [open]);

  const years = useMemo(() => {
    const now = Number(todayIso().slice(0, 4));
    const from = minS ? Number(minS.slice(0, 4)) : now - 110;
    const to = maxS ? Number(maxS.slice(0, 4)) : now + 15;
    const list: number[] = [];
    for (let y = to; y >= from; y--) list.push(y);
    return list;
  }, [minS, maxS]);

  const cells = useMemo(() => {
    const first = new Date(Date.UTC(view.y, view.m, 1));
    const lead = (first.getUTCDay() + 6) % 7; // Monday first
    const days = new Date(Date.UTC(view.y, view.m + 1, 0)).getUTCDate();
    const out: (number | null)[] = Array.from({ length: lead }, () => null);
    for (let d = 1; d <= days; d++) out.push(d);
    return out;
  }, [view]);

  const move = (by: number) => setView((v) => ({ y: v.y + Math.floor((v.m + by) / 12), m: (((v.m + by) % 12) + 12) % 12 }));
  const openCalendar = () => {
    if (disabled) return;
    setView({ y: Number(start.slice(0, 4)), m: Number(start.slice(5, 7)) - 1 });
    setOpen(true);
  };

  return (
    <div ref={wrap} className="relative">
      <input ref={hidden} type="hidden" name={name || undefined} defaultValue={iso} disabled={disabled} />
      <input
        {...rest}
        ref={visible}
        id={boxId}
        type="text"
        inputMode="numeric"
        autoComplete="off"
        disabled={disabled}
        required={required}
        placeholder={placeholder ?? "dd/mm/yyyy"}
        value={typed ?? show(iso)}
        onChange={(e) => {
          const t = maskTyped(e.target.value);
          // While typing, only a full dd/mm/yyyy counts (so "05/03/19" isn't taken as 2019 too soon).
          const p = t.length === 10 ? parseTyped(t) : "";
          if (p || t === "") commit(p);
          else setTyped(t);
        }}
        onBlur={() => {
          // Leaving the box: a short year (05/03/80) is filled in; anything else stays to be fixed.
          if (typed === null) return;
          const p = parseTyped(typed);
          if (p) commit(p);
        }}
        onKeyDown={(e) => {
          if (e.key === "ArrowDown" && e.altKey) openCalendar();
        }}
        className={`${className || inputClass} pr-10`}
      />
      <button
        type="button"
        onClick={() => (open ? setOpen(false) : openCalendar())}
        disabled={disabled}
        aria-label="Choose a date"
        aria-expanded={open}
        className="absolute top-1/2 right-1.5 -translate-y-1/2 rounded-md p-1.5 text-muted hover:bg-page hover:text-ink disabled:opacity-40"
      >
        <CalendarDays aria-hidden="true" className="size-4" />
      </button>
      {open ? (
        <div role="dialog" aria-label="Choose a date" className="absolute top-full left-0 z-50 mt-1 w-72 rounded-xl border border-line bg-surface p-3 shadow-2xl">
          <div className="mb-2 flex items-center gap-1">
            <button type="button" onClick={() => move(-1)} aria-label="Previous month" className="rounded-md p-1.5 hover:bg-page">
              <ChevronLeft aria-hidden="true" className="size-4" />
            </button>
            <select aria-label="Month" value={view.m} onChange={(e) => setView((v) => ({ ...v, m: Number(e.target.value) }))} className="min-w-0 flex-1 rounded-md border border-line bg-surface px-1.5 py-1 text-sm font-semibold">
              {MONTHS.map((mn, i) => (
                <option key={mn} value={i}>
                  {mn}
                </option>
              ))}
            </select>
            <select aria-label="Year" value={view.y} onChange={(e) => setView((v) => ({ ...v, y: Number(e.target.value) }))} className="w-20 rounded-md border border-line bg-surface px-1.5 py-1 text-sm font-semibold">
              {(years.includes(view.y) ? years : [view.y, ...years]).map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
            <button type="button" onClick={() => move(1)} aria-label="Next month" className="rounded-md p-1.5 hover:bg-page">
              <ChevronRight aria-hidden="true" className="size-4" />
            </button>
          </div>
          <div className="grid grid-cols-7 gap-0.5 text-center text-xs">
            {DAYS.map((d) => (
              <span key={d} className="py-1 font-semibold text-muted">
                {d}
              </span>
            ))}
            {cells.map((d, i) => {
              if (d === null) return <span key={`b${i}`} />;
              const v = toIso(view.y, view.m, d);
              const off = Boolean(outOfRange(v));
              const chosen = v === iso;
              const today = v === todayIso();
              return (
                <button
                  key={v}
                  type="button"
                  disabled={off}
                  onClick={() => {
                    commit(v);
                    setOpen(false);
                    visible.current?.focus();
                  }}
                  aria-pressed={chosen}
                  className={`rounded-md py-1.5 text-sm ${chosen ? "bg-brand font-semibold text-brand-fg" : today ? "font-semibold text-brand ring-1 ring-brand/40" : "text-ink hover:bg-page"} disabled:cursor-not-allowed disabled:text-muted/40`}
                >
                  {d}
                </button>
              );
            })}
          </div>
          <div className="mt-2 flex items-center justify-between border-t border-line pt-2 text-sm">
            <button
              type="button"
              onClick={() => {
                commit("");
                setOpen(false);
              }}
              className="rounded-md px-2 py-1 font-semibold text-muted hover:bg-page"
            >
              Clear
            </button>
            <button
              type="button"
              disabled={Boolean(outOfRange(todayIso()))}
              onClick={() => {
                commit(todayIso());
                setOpen(false);
              }}
              className="rounded-md px-2 py-1 font-semibold text-brand hover:bg-page disabled:text-muted/40"
            >
              Today
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

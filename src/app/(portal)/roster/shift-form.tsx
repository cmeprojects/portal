// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { REPEAT_MAX_DAYS, SHIFT_ALLOWANCES, repeatDates, repeatSummary, type RepeatFreq, type RepeatRule } from "@/lib/roster";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useActionState, useMemo, useRef, useState, type ReactNode } from "react";
import { AlertTriangle, Check, XCircle, Briefcase, CalendarClock, ChevronDown, FileText, Loader2, MapPin, PenLine, Save, Settings2, Sparkles, UserRound, X } from "lucide-react";
import { Button, Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { TimeField, niceTime } from "./time-field";
import { bulkShifts, copyLastWeek, copyToNextWeek, saveShift } from "./actions";

export type ShiftDraft = {
  id?: string;
  date: string;
  start: string;
  end: string;
  nextDay: boolean;
  break_minutes: number;
  worker_id: string;
  client_id: string;
  location_id: string;
  service_id: string;
  notes: string;
  extra_notes: string;
  status: string;
  series: boolean;
  shift_type: string;
  shift_type_other?: string;
  vehicle_id: string;
  pay_group: string;
  pay_class: string;
  allowances: string[];
  signatures_needed: string[];
  notify_worker: boolean;
  // update 146: other residents on a house (SIL) shift; undefined before it runs.
  residents?: string[];
  // update 150: the SIL house the shift is at; undefined while SIL houses is off.
  house_id?: string;
};
export type HouseOpt = { id: string; name: string; residents: string[] };
type Opt = { id: string; name: string };
export type LocationOpt = Opt & { client_id: string; address: string; suburb: string; state: string; postcode: string; access_notes: string };
export type ShiftTypeOpt = { key: string; label: string; active: boolean; used_for?: string; needs?: { id: string; title: string }[] };
// A client's approved service (update 143): its shift types, or null when it doesn't restrict them (older entries).
export type ServiceOpt = Opt & { client_id: string; status: string; start_date: string; end_date: string | null; program: string; types: string[] | null };
export type TemplateOpt = { id: string; name: string; start: string; end: string };
// What the Suggest button weighs, per worker (only what this person may see).
export type WorkerFit = {
  id: string;
  name: string;
  role: string;
  hours: number;
  leave: string[];
  busy: { date: string; start: string; end: string }[];
  expiredBeforeWork: string;
  expiredOther: string;
  avail: Record<string, string[]> | null;
  // Why they already know a client, by client id.
  knows: Record<string, string[]>;
  // update 145: what they hold, by item (expiry date, or null when it doesn't expire).
  holds?: Record<string, string | null>;
};
const label = "text-xs font-semibold text-ink";
const field = "flex flex-col gap-1";
const hint = "text-xs text-muted";
const fieldError = "text-xs font-medium text-danger";
const check = "inline-flex min-h-9 items-center gap-2 text-sm";
const box = "size-4 accent-[var(--brand-primary)]";
// The shared input style, without its full width and height (for small inline fields).
const inlineInput = inputClass.replace("w-full", "").replace("h-11", "");
const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const AVAIL_DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
const SIGNATURES: [string, string][] = [
  ["worker_in", "Worker signature at clock in"],
  ["worker_out", "Worker signature at clock out"],
  ["client_out", "Client signature at clock out"],
  ["representative_out", "Authorised representative signature at clock out"],
];
const BREAKS = [15, 30, 45, 60, 90, 120];
const mins = (t: string) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
const slot = (t: string) => {
  const h = Number(t.slice(0, 2));
  return h >= 6 && h < 12 ? "am" : h >= 12 && h < 18 ? "pm" : "night";
};
const dowOf = (d: string) => (new Date(`${d}T12:00:00Z`).getUTCDay() + 6) % 7;
const nextDate = (d: string) => new Date(Date.parse(`${d}T12:00:00Z`) + 86_400_000).toISOString().slice(0, 10);
const longDay = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });
const hm = (m: number) => `${Math.floor(m / 60)}h${m % 60 ? ` ${m % 60}m` : ""}`;

// One section of the panel: an icon, a heading and its fields.
function Section({ icon: Icon, title, children, aside }: { icon: typeof MapPin; title: string; children: ReactNode; aside?: ReactNode }) {
  return (
    <section className="flex flex-col gap-3 border-b border-line px-5 py-4 last:border-b-0">
      <div className="flex items-center justify-between gap-2">
        <h3 className="flex items-center gap-2 text-sm font-semibold text-ink">
          <Icon aria-hidden="true" className="size-4 text-brand" />
          {title}
        </h3>
        {aside}
      </div>
      {children}
    </section>
  );
}

// cmeprojects (owner's redesign, update 141): add or change a shift in one
// side panel: Save and Close at the top, six sections, fields shown only when
// they apply. New shifts are saved as drafts; publishing stays on the roster.
// The database still decides (leave, clashes, expired checks, client rules).
export function ShiftForm({
  shift,
  workers,
  clients,
  locations,
  services,
  shiftTypes,
  templates = [],
  templateHref,
  cars = [],
  closeHref,
  backHref,
  houses,
}: {
  shift: ShiftDraft;
  workers: WorkerFit[];
  clients: (Opt & { disabled?: boolean })[];
  locations: LocationOpt[];
  services: ServiceOpt[];
  shiftTypes: ShiftTypeOpt[];
  templates?: TemplateOpt[];
  // Address that reopens the panel with a template applied (…&tpl=).
  templateHref?: string;
  cars?: Opt[];
  closeHref: string;
  backHref?: string;
  houses?: HouseOpt[];
}) {
  const [state, action, pending] = useActionState(saveShift, null);
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  // Ctrl+S (or Cmd+S) saves, like a desktop app.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "s") {
        e.preventDefault();
        formRef.current?.requestSubmit();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  // A successful save closes the panel and shows what happened above the roster.
  useEffect(() => {
    if (state?.message)
      router.push(`${closeHref}${closeHref.includes("?") ? "&" : "?"}saved=${encodeURIComponent(state.message)}${state.spotlight ? `&spot=${state.spotlight}&spotlabel=${shift.id ? "changed" : "added"}` : ""}`, { scroll: false });
  }, [state, closeHref, router, shift.id]);

  const [client, setClient] = useState(shift.client_id);
  const [location, setLocation] = useState(shift.location_id);
  const [worker, setWorker] = useState(shift.worker_id);
  const [shiftType, setShiftType] = useState(shift.shift_type || "standard");
  const [date, setDate] = useState(shift.date);
  const [start, setStart] = useState(shift.start);
  const [end, setEnd] = useState(shift.end);
  const [nextDay, setNextDay] = useState(shift.nextDay);
  // Set the start and finish together; a finish at or before the start is the next day.
  const setTimes = (a: string, z: string) => {
    setStart(a);
    setEnd(z);
    setNextDay(mins(z) <= mins(a));
  };
  const setLength = (h: number) => {
    const total = mins(start) + h * 60;
    const z = `${String(Math.floor(total / 60) % 24).padStart(2, "0")}:${String(total % 60).padStart(2, "0")}`;
    setEnd(z);
    setNextDay(total >= 1440);
  };
  const [hasBreak, setHasBreak] = useState(shift.break_minutes > 0);
  const [breakMins, setBreakMins] = useState(shift.break_minutes || 30);
  const [repeat, setRepeat] = useState(false);
  const [freq, setFreq] = useState<RepeatFreq>("weekly");
  const [every, setEvery] = useState(1);
  const [days, setDays] = useState<number[]>([dowOf(shift.date)]);
  const [byCount, setByCount] = useState(false);
  const [until, setUntil] = useState("");
  const [count, setCount] = useState(5);
  const [suggesting, setSuggesting] = useState(false);
  const [asTemplate, setAsTemplate] = useState(false);
  const [more, setMore] = useState(false);

  // Times: the finish is on the next day only when ticked (so 9pm–7am needs the tick).
  const span = mins(end) - mins(start) + (nextDay ? 1440 : 0);
  const timeError = !start || !end ? "Choose the start and finish." : span <= 0 ? "The finish is at or before the start. Tick “Finishes the next day” for an overnight shift." : span > 16 * 60 ? "A shift can be 16 hours at most." : "";
  const breakError = hasBreak && span > 0 && breakMins >= span ? "The break is as long as the shift." : "";
  const paid = Math.max(0, span - (hasBreak ? breakMins : 0));
  const sleepoverShown = shiftType === "sleepover" || nextDay;

  const rule: RepeatRule = { freq, every, days, until, count, byCount };
  const dates = useMemo(() => (repeat ? repeatDates(date, rule) : [date]), [repeat, date, freq, every, days, until, count, byCount]); // eslint-disable-line react-hooks/exhaustive-deps
  const repeatError = repeat && !shift.id ? (!byCount && !until ? "Choose the end date." : dates.length < 1 ? "No dates match: check the days and the end date." : "") : "";

  const clientLocations = locations.filter((l) => l.client_id === client);
  const clientServices = services.filter((v) => v.client_id === client);
  // Services that can be rostered on the chosen date (pending or active, within their dates).
  const usable = (v: ServiceOpt, d: string) => ["planned", "active"].includes(v.status) && v.start_date <= d && (!v.end_date || v.end_date >= d);
  const rosterable = clientServices.filter((v) => usable(v, date));
  // Services that list the type win; older entries with no types set are only used when none does.
  // Other residents at the same address (SIL houses): each needs a current service covering the type.
  const norm = (a: string) => a.toLowerCase().replace(/\s+/g, " ").trim();
  const [residents, setResidents] = useState<string[]>(shift.residents ?? []);
  const residentCover = (c: string, k: string) => {
    const mine = services.filter((v) => v.client_id === c && usable(v, date));
    const listed = mine.filter((v) => v.types?.includes(k));
    return listed.length ? listed : mine.filter((v) => !v.types);
  };
  const coveredBy = (k: string) => {
    const listed = rosterable.filter((v) => v.types?.includes(k));
    return listed.length ? listed : rosterable.filter((v) => !v.types);
  };
  const place = clientLocations.find((l) => l.id === location) ?? null;
  // update 150: the house's current residents count as housemates too.
  const [house, setHouse] = useState(shift.house_id ?? "");
  const houseResidents = houses?.find((h) => h.id === house)?.residents ?? [];
  const housemates = clients.filter(
    (c) => c.id !== client && (houseResidents.includes(c.id) || (place ? locations.some((l) => l.client_id === c.id && norm(l.address) === norm(place.address)) : false)),
  );
  const fits = (t: ShiftTypeOpt, c: string) => !t.used_for || t.used_for === "both" || t.used_for === (c ? "client" : "internal");
  // A new client: its only location and service are chosen for you.
  const pickClient = (c: string) => {
    setClient(c);
    // Keep the shift type if it still fits; otherwise the first that does (Office work for internal work).
    const current = shiftTypes.find((t) => t.key === shiftType);
    const cover = (k: string) => !c || services.some((v) => v.client_id === c && usable(v, date) && (!v.types || v.types.includes(k)));
    if (!current || !fits(current, c) || !cover(current.key)) {
      const ok = shiftTypes.filter((t) => t.active && fits(t, c) && cover(t.key));
      setShiftType((!c && ok.find((t) => t.key === "admin")?.key) || ok.find((t) => t.used_for !== "both")?.key || ok[0]?.key || "standard");
    }
    const ls = locations.filter((l) => l.client_id === c);
    setLocation(ls.length === 1 ? ls[0].id : "");
  };

  const hours = paid / 60;
  const fit = (w: WorkerFit) => {
    const refuse: string[] = [];
    const warn: string[] = [];
    if (w.expiredBeforeWork) refuse.push(`expired: ${w.expiredBeforeWork}`);
    // Qualifications the shift type needs (update 145).
    const missing = (shiftTypes.find((t) => t.key === shiftType)?.needs ?? []).filter((n) => {
      const h = w.holds?.[n.id];
      return h === undefined || (h !== null && h < date);
    });
    if (missing.length) refuse.push(`doesn't hold: ${missing.map((n) => n.title).join(", ")}`);
    if (w.leave.includes(date)) refuse.push("on leave");
    if (w.busy.some((b) => b.date === date && mins(b.start) < mins(start) + span && mins(start) < mins(b.end))) refuse.push("already busy then");
    const total = w.hours + (worker === w.id && shift.id ? 0 : hours);
    if (total > 38) warn.push(`${total.toFixed(1)} h this week`);
    if (w.avail && Object.values(w.avail).some((v) => v?.length) && !(w.avail[AVAIL_DAYS[dowOf(date)]] ?? []).includes(slot(start))) warn.push("outside their availability");
    if (w.expiredOther) warn.push(`expired: ${w.expiredOther}`);
    const known = client ? (w.knows[client] ?? []) : [];
    // The same checks, one line each, for the chosen worker (ok, warning or refused).
    const needs = shiftTypes.find((t) => t.key === shiftType)?.needs ?? [];
    const hasAvail = Boolean(w.avail && Object.values(w.avail).some((v) => v?.length));
    const inAvail = hasAvail && (w.avail![AVAIL_DAYS[dowOf(date)]] ?? []).includes(slot(start));
    const checks: { state: "ok" | "warn" | "no"; text: string }[] = [
      w.leave.includes(date) ? { state: "no", text: "On leave that day" } : { state: "ok", text: "Not on leave" },
      refuse.includes("already busy then") ? { state: "no", text: "Already has a shift then" } : { state: "ok", text: "No clash with other shifts" },
      !hasAvail ? { state: "warn", text: "No availability given" } : inAvail ? { state: "ok", text: "Available then" } : { state: "warn", text: "Outside their availability" },
      w.expiredBeforeWork ? { state: "no", text: `Expired before-work check: ${w.expiredBeforeWork}` } : w.expiredOther ? { state: "warn", text: `Expired: ${w.expiredOther}` } : { state: "ok", text: "Checks current" },
      ...(needs.length ? [missing.length ? { state: "no" as const, text: `Doesn't hold: ${missing.map((n) => n.title).join(", ")}` } : { state: "ok" as const, text: `Holds: ${needs.map((n) => n.title).join(", ")}` }] : []),
      ...(client ? [known.length ? { state: "ok" as const, text: `Knows the client: ${known.join(", ")}` } : { state: "warn" as const, text: "Hasn't worked with this client lately" }] : []),
      total > 38 ? { state: "warn", text: `${total.toFixed(1)} of 38 hours this week` } : { state: "ok", text: `${total.toFixed(1)} of 38 hours this week` },
    ];
    return { refuse, warn, total, known, checks };
  };
  const chosen = workers.find((w) => w.id === worker);
  const chosenFit = chosen ? fit(chosen) : null;
  const ranked = useMemo(
    () =>
      workers
        .map((w) => ({ w, f: fit(w) }))
        .sort((a, b) => a.f.refuse.length - b.f.refuse.length || Number(b.f.known.length > 0) - Number(a.f.known.length > 0) || a.f.warn.length - b.f.warn.length || b.f.known.length - a.f.known.length || a.w.hours - b.w.hours)
        .slice(0, 8),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [workers, date, start, end, nextDay, worker, client, shiftType],
  );
  // Only the types that fit: client shifts, or internal work when there's no client (update 142).
  // Client shifts: only the types the client's approved services cover.
  const types = shiftTypes.filter((t) => (t.active && fits(t, client) && (!client || coveredBy(t.key).length > 0)) || (shift.id && t.key === shift.shift_type));
  const candidates = client ? coveredBy(shiftType) : [];
  const [serviceChoice, setServiceChoice] = useState(shift.service_id);
  const serviceId = candidates.length === 1 ? candidates[0].id : candidates.some((v) => v.id === serviceChoice) ? serviceChoice : "";
  const blocked = Boolean(timeError || breakError || repeatError || (client && !candidates.length));

  return (
    <form
      ref={formRef}
      action={action}
      onSubmit={(e) => {
        // One save at a time, and only when the times make sense.
        if (pending || blocked) e.preventDefault();
      }}
      className="flex min-h-full flex-col"
      aria-busy={pending || undefined}
    >
      {shift.id ? <input type="hidden" name="id" value={shift.id} /> : null}
      {/* Update 142 has run (shift types say what they're used for): the "Other" description can be saved. */}
      {shiftTypes.some((t) => t.used_for !== undefined) ? <input type="hidden" name="type_other_ready" value="1" /> : null}
      <header className="sticky top-0 z-20 flex items-center gap-2 border-b border-line bg-surface/95 px-5 py-3 backdrop-blur">
        <div className="min-w-0 flex-1">
          <h2 className="heading-sm">Shift</h2>
          <p className="truncate text-xs text-muted">{shift.id ? `Changing ${shift.status === "published" ? "a published shift" : "a draft"}` : "New shifts are saved as drafts. Publish them from the roster."}</p>
        </div>
        {backHref ? (
          <Link href={backHref} scroll={false} className="rounded-lg px-2 py-1.5 text-sm font-semibold text-muted hover:bg-page hover:text-ink">
            Back
          </Link>
        ) : null}
        <Button size="sm" disabled={pending || blocked} icon={pending ? Loader2 : Save} title="Save (Ctrl+S)">
          {pending ? "Saving…" : "Save"}
        </Button>
        <Link href={closeHref} scroll={false} title="Close" className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-line px-3 text-sm font-semibold text-ink hover:bg-page">
          <X aria-hidden="true" className="size-4" />
          Close
        </Link>
      </header>
      {state?.error ? (
        <div className="px-5 pt-3" role="alert">
          <Notice tone="error">{state.error}</Notice>
        </div>
      ) : null}

      <Section icon={MapPin} title="Client and location">
        <div className="grid gap-3 sm:grid-cols-2">
          {houses && shift.house_id !== undefined ? (
            <label className={`${field} sm:col-span-2`}>
              <input type="hidden" name="house_ready" value="1" />
              <span className={label}>House (SIL)</span>
              <select
                name="house_id"
                value={house}
                onChange={(e) => {
                  const h = houses.find((x) => x.id === e.target.value);
                  setHouse(e.target.value);
                  if (!h) return;
                  // The first resident who can be rostered becomes the main client; the others are offered below.
                  const open = h.residents.filter((r) => clients.some((c) => c.id === r && !c.disabled));
                  const main = client && h.residents.includes(client) ? client : (open[0] ?? client);
                  if (main && main !== client) pickClient(main);
                  setResidents(open.filter((r) => r !== main));
                }}
                className={inputClass}
              >
                <option value="">Not at a house</option>
                {houses.map((h) => (
                  <option key={h.id} value={h.id}>
                    {h.name} ({h.residents.length} resident{h.residents.length === 1 ? "" : "s"})
                  </option>
                ))}
              </select>
            </label>
          ) : null}
          <label className={`${field} sm:col-span-2`}>
            <span className={label}>Client</span>
            <select name="client_id" value={client} onChange={(e) => pickClient(e.target.value)} className={inputClass}>
              <option value="">No client: office, training or internal work</option>
              {clients.map((c) => (
                <option key={c.id} value={c.id} disabled={c.disabled}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          {client ? (
            <>
              {/* What the client is approved for: a quick snapshot (update 143). */}
              <div className="rounded-lg border border-line bg-page px-3 py-2 sm:col-span-2">
                <p className="text-xs font-semibold text-muted">Approved for</p>
                {clientServices.length ? (
                  <ul className="mt-1 flex flex-wrap gap-1.5">
                    {clientServices.map((v) => {
                      const ok = usable(v, date);
                      const tone = !ok ? "bg-line text-muted" : v.status === "active" ? "bg-good-soft text-ink" : "bg-warn-soft text-ink";
                      const why = v.status === "on_hold" ? "suspended" : v.status === "planned" ? "pending" : v.end_date && v.end_date < date ? "ended" : v.start_date > date ? `from ${longDay(v.start_date)}` : "";
                      return (
                        <li key={v.id} className={`rounded-full px-2.5 py-1 text-xs font-medium ${tone}`} title={v.types ? `Covers: ${v.types.map((k) => shiftTypes.find((t) => t.key === k)?.label ?? k).join(", ")}` : "Covers any client shift type (not set yet)"}>
                          {v.name} · {v.program}
                          {why ? ` · ${why}` : ""}
                          {v.end_date && ok ? ` · until ${longDay(v.end_date)}` : ""}
                        </li>
                      );
                    })}
                  </ul>
                ) : (
                  <p className={fieldError}>No approved services. Add one on the client&apos;s page before rostering.</p>
                )}
              </div>
              <label className={field}>
                <span className={label}>Service location</span>
                <select name="location_id" required value={location} onChange={(e) => setLocation(e.target.value)} className={inputClass}>
                  <option value="" disabled>
                    Choose an approved location
                  </option>
                  {clientLocations.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.name}
                    </option>
                  ))}
                </select>
              </label>
              {!clientLocations.length ? <p className={`${fieldError} sm:col-span-2`}>This client needs an approved location before they can be rostered. Add it on the client&apos;s page.</p> : null}
              {place ? (
                <div className="rounded-lg border border-line bg-page px-3 py-2 text-sm sm:col-span-2">
                  <p className="font-medium">{place.address}</p>
                  <p className={hint}>{[place.suburb, place.state, place.postcode].filter(Boolean).join(" ")}</p>
                  {place.access_notes ? <p className="mt-1 text-xs">Access: {place.access_notes}</p> : null}
                  <p className={`${hint} mt-1`}>Unit or apartment numbers are part of the approved address. Change it on the client&apos;s page.</p>
                </div>
              ) : null}
              {shift.residents !== undefined && housemates.length ? (
                <fieldset className="flex flex-col gap-1 rounded-lg border border-line p-3 sm:col-span-2">
                  <input type="hidden" name="residents_ready" value="1" />
                  <legend className={`${label} px-1`}>Other residents at this address (shared support)</legend>
                  {housemates.map((c) => {
                    const ok = residentCover(c.id, shiftType).length > 0;
                    return (
                      <label key={c.id} className={`${check} ${ok ? "" : "text-muted"}`}>
                        <input
                          type="checkbox"
                          name="residents"
                          value={c.id}
                          disabled={!ok}
                          checked={ok && residents.includes(c.id)}
                          onChange={(e) => setResidents((v) => (e.target.checked ? [...v, c.id] : v.filter((x) => x !== c.id)))}
                          className={box}
                        />
                        {c.name}
                        {ok ? null : <span className={hint}>(no current approved service for this shift type)</span>}
                      </label>
                    );
                  })}
                  {residents.length ? <p className={hint}>One worker for {residents.filter((r) => residentCover(r, shiftType).length).length + 1} people. Each resident&apos;s approved service is attached for them.</p> : null}
                </fieldset>
              ) : null}
            </>
          ) : (
            <p className={`${hint} sm:col-span-2`}>A shift with no client is internal work (office, training, meetings). Workers see the instructions only.</p>
          )}
        </div>
      </Section>

      <Section icon={CalendarClock} title="Time and service">
        <div className="grid gap-3 sm:grid-cols-2">
          <label className={`${field} sm:col-span-2`}>
            <span className={label}>Shift type</span>
            <select name="shift_type" value={shiftType} onChange={(e) => setShiftType(e.target.value)} className={inputClass}>
              {types.map((t) => (
                <option key={t.key} value={t.key}>
                  {t.label}
                  {t.active ? "" : " (switched off)"}
                </option>
              ))}
            </select>
            {(shiftTypes.find((t) => t.key === shiftType)?.needs ?? []).length ? (
              <span className={hint}>Needs: {shiftTypes.find((t) => t.key === shiftType)!.needs!.map((n) => n.title).join(", ")}. Only workers who hold it can be given this shift.</span>
            ) : null}
            {shiftType === "other" && shiftTypes.some((t) => t.used_for !== undefined) ? (
              <input name="shift_type_other" required maxLength={60} defaultValue={shift.shift_type_other ?? ""} placeholder="What kind of shift is it?" aria-label="Other shift type" className={`${inputClass} mt-1`} />
            ) : null}
            {client ? (
              candidates.length > 1 ? (
                <label className={`${field} mt-1`}>
                  <span className={label}>Under which approved service?</span>
                  <select name="service_id" required value={serviceId} onChange={(e) => setServiceChoice(e.target.value)} className={inputClass}>
                    <option value="" disabled>
                      Choose the service
                    </option>
                    {candidates.map((v) => (
                      <option key={v.id} value={v.id}>
                        {v.name} ({v.program})
                      </option>
                    ))}
                  </select>
                </label>
              ) : candidates.length === 1 ? (
                <>
                  <input type="hidden" name="service_id" value={candidates[0].id} />
                  <span className={hint}>
                    Under the approved service: {candidates[0].name} ({candidates[0].program}){candidates[0].status === "planned" ? ", still pending" : ""}.
                  </span>
                </>
              ) : (
                <span className={fieldError}>{rosterable.length ? "None of the client's approved services covers this shift type." : "The client has no approved service current on this date."}</span>
              )
            ) : (
              <span className={hint}>Internal work types only (no client).</span>
            )}
          </label>
          <label className={field}>
            <span className={label}>Date</span>
            <input type="date" name="date" required value={date} onChange={(e) => setDate(e.target.value)} className={inputClass} />
          </label>
          <div className="grid grid-cols-2 gap-2">
            <TimeField name="start" label="Start" value={start} onChange={setStart} invalid={Boolean(timeError)} />
            <TimeField name="end" label="Finish" value={end} onChange={setEnd} invalid={Boolean(timeError)} />
          </div>
        </div>
        {/* Quick picks: a usual period, or a length from the start (crossing midnight ticks "Finishes the next day"). */}
        <div className="flex flex-wrap items-center gap-1.5">
          {(
            [
              ["Morning", "07:00", "11:00"],
              ["Afternoon", "13:00", "17:00"],
              ["Evening", "17:00", "21:00"],
              ["Overnight", "22:00", "07:00"],
            ] as const
          ).map(([l, a, z]) => (
            <button key={l} type="button" onClick={() => setTimes(a, z)} className={`rounded-full border px-2.5 py-1 text-xs font-medium ${start === a && end === z ? "border-brand bg-brand-soft text-brand" : "border-line text-muted hover:bg-page hover:text-ink"}`}>
              {l}
            </button>
          ))}
          <span className="mx-1 h-4 w-px bg-line" aria-hidden="true" />
          {[2, 3, 4, 6, 8, 10, 12].map((h) => (
            <button key={h} type="button" onClick={() => setLength(h)} aria-label={`${h} hours from the start`} className={`rounded-full border px-2.5 py-1 text-xs font-medium tabular-nums ${span === h * 60 ? "border-brand bg-brand-soft text-brand" : "border-line text-muted hover:bg-page hover:text-ink"}`}>
              {h}h
            </button>
          ))}
        </div>
        <div className="flex flex-wrap gap-x-5">
          <label className={check}>
            <input type="checkbox" name="next_day" checked={nextDay} onChange={(e) => setNextDay(e.target.checked)} className={box} /> Finishes the next day
          </label>
          <label className={check}>
            <input type="checkbox" checked={hasBreak} onChange={(e) => setHasBreak(e.target.checked)} className={box} /> Unpaid break
          </label>
          {hasBreak ? (
            <select name="break_minutes" value={breakMins} onChange={(e) => setBreakMins(Number(e.target.value))} aria-label="Break length" className={`${inlineInput} h-9 w-36`}>
              {BREAKS.map((b) => (
                <option key={b} value={b}>
                  {b} minutes
                </option>
              ))}
            </select>
          ) : (
            <input type="hidden" name="break_minutes" value="0" />
          )}
        </div>
        {timeError || breakError ? (
          <p className={fieldError} role="alert">
            {timeError || breakError}
          </p>
        ) : (
          <p className={hint}>
            {longDay(date)} {niceTime(start)} to {nextDay ? `${longDay(nextDate(date))} ` : ""}
            {niceTime(end)} · {hm(span)}
            {hasBreak ? `, ${hm(paid)} paid after the break` : ""}
          </p>
        )}
        {sleepoverShown ? (
          <label className={check}>
            <input type="checkbox" name="allowances" value="Sleepover" defaultChecked={shift.allowances.includes("Sleepover") || (!shift.id && shiftType === "sleepover")} className={box} /> Sleepover rate applies
            <span className={hint}>(an overnight shift isn&apos;t a sleepover unless ticked)</span>
          </label>
        ) : null}
        {shift.id ? (
          shift.series ? (
            <label className={field}>
              <span className={label}>This is a repeating shift. Apply changes to</span>
              <select name="scope" className={inputClass}>
                <option value="one">Just this shift</option>
                <option value="future">This and the later shifts in the series</option>
              </select>
              <span className={hint}>Earlier shifts in the series are never changed.</span>
            </label>
          ) : null
        ) : (
          <div className="flex flex-col gap-3 rounded-lg border border-line p-3">
            <label className={check}>
              <input type="checkbox" checked={repeat} onChange={(e) => setRepeat(e.target.checked)} className={box} /> Repeat
            </label>
            {repeat ? (
              <>
                <input type="hidden" name="repeat" value={freq} />
                <input type="hidden" name="repeat_every" value={every} />
                <input type="hidden" name="repeat_end" value={byCount ? "count" : "date"} />
                <div className="grid gap-3 sm:grid-cols-2">
                  <label className={field}>
                    <span className={label}>Repeats</span>
                    <select value={freq} onChange={(e) => setFreq(e.target.value as RepeatFreq)} className={inputClass}>
                      <option value="daily">Daily</option>
                      <option value="weekly">Weekly</option>
                      <option value="fortnightly">Fortnightly</option>
                      <option value="monthly">Monthly (same date)</option>
                    </select>
                  </label>
                  <label className={field}>
                    <span className={label}>Every</span>
                    <span className="flex items-center gap-2">
                      <input type="number" min={1} max={12} value={every} onChange={(e) => setEvery(Math.max(1, Math.min(12, Number(e.target.value) || 1)))} className={`${inlineInput} h-11 w-20`} />
                      <span className="text-sm text-muted">{freq === "daily" ? "day(s)" : freq === "monthly" ? "month(s)" : freq === "fortnightly" ? "fortnight(s)" : "week(s)"}</span>
                    </span>
                  </label>
                </div>
                {freq === "weekly" || freq === "fortnightly" ? (
                  <fieldset className="flex flex-col gap-1">
                    <legend className={label}>On</legend>
                    <div className="flex flex-wrap gap-1.5">
                      {DAYS.map((d, i) => (
                        <label key={d} className={`inline-flex h-9 min-w-12 cursor-pointer items-center justify-center rounded-lg border px-2 text-sm font-medium has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-brand ${days.includes(i) ? "border-brand bg-brand-soft text-brand" : "border-line text-muted hover:bg-page"}`}>
                          <input type="checkbox" name="repeat_days" value={i} checked={days.includes(i)} onChange={(e) => setDays((v) => (e.target.checked ? [...v, i] : v.filter((x) => x !== i)))} className="sr-only" />
                          {d}
                        </label>
                      ))}
                    </div>
                  </fieldset>
                ) : null}
                <div className="grid gap-3 sm:grid-cols-2">
                  <fieldset className="flex flex-col gap-1">
                    <legend className={label}>Ends</legend>
                    <span className="flex gap-4">
                      <label className={check}>
                        <input type="radio" checked={!byCount} onChange={() => setByCount(false)} className={box} /> On a date
                      </label>
                      <label className={check}>
                        <input type="radio" checked={byCount} onChange={() => setByCount(true)} className={box} /> After
                      </label>
                    </span>
                  </fieldset>
                  {byCount ? (
                    <label className={field}>
                      <span className={label}>Number of shifts</span>
                      <input type="number" name="repeat_count" min={1} max={100} value={count} onChange={(e) => setCount(Math.max(1, Math.min(100, Number(e.target.value) || 1)))} className={inputClass} />
                    </label>
                  ) : (
                    <label className={field}>
                      <span className={label}>End date</span>
                      <input type="date" name="repeat_until" min={date} value={until} onChange={(e) => setUntil(e.target.value)} className={inputClass} />
                    </label>
                  )}
                </div>
                <p className={repeatError ? fieldError : "rounded-lg bg-brand-soft px-3 py-2 text-sm font-medium text-brand"} role="status">
                  {repeatError || repeatSummary(date, rule, dates)}
                </p>
                <p className={hint}>Up to {REPEAT_MAX_DAYS} days ahead. Each shift is checked on its own (leave, clashes, checks); any refused are skipped and listed.</p>
              </>
            ) : null}
          </div>
        )}
      </Section>

      <Section
        icon={UserRound}
        title="Worker"
        aside={
          <span className="flex items-center gap-1">
            <Button type="button" size="sm" variant="outline" icon={Sparkles} onClick={() => setSuggesting((v) => !v)} aria-expanded={suggesting}>
              Smart suggest
            </Button>
            <span title="Coming later: post the shift for staff to apply" className="rounded-full border border-dashed border-line px-2 py-1 text-xs text-muted">
              Job board: coming later
            </span>
          </span>
        }
      >
        <label className={field}>
          <span className={label}>Support worker</span>
          <select name="worker_id" value={worker} onChange={(e) => setWorker(e.target.value)} className={inputClass}>
            <option value="">Open shift (staff put their hand up)</option>
            {workers.map((w) => (
              <option key={w.id} value={w.id}>
                {w.name}
                {w.role ? ` (${w.role})` : ""} · {w.hours.toFixed(0)}/38 h{w.expiredBeforeWork ? " · check expired" : ""}
              </option>
            ))}
          </select>
        </label>
        {suggesting ? (
          <ul className="flex flex-col gap-1" aria-label="Suggested workers">
            {ranked.map(({ w, f }) => (
              <li key={w.id}>
                <button
                  type="button"
                  onClick={() => {
                    setWorker(w.id);
                    setSuggesting(false);
                  }}
                  className={`flex w-full flex-wrap items-center justify-between gap-2 rounded-lg border border-line px-3 py-2 text-left text-sm hover:bg-page ${f.refuse.length ? "opacity-50" : ""}`}
                >
                  <span>
                    <b>{w.name}</b> {w.role ? <span className="text-xs text-muted">{w.role} · </span> : null}
                    <span className="text-xs text-muted">{w.hours.toFixed(0)}/38 h</span>
                    {f.known.length ? <span className="block text-xs text-good">Knows the client: {f.known.join(", ")}</span> : null}
                  </span>
                  <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${f.refuse.length ? "bg-danger-soft text-danger" : f.warn.length ? "bg-warn-soft" : "bg-good-soft"}`}>
                    {f.refuse.length ? f.refuse.join(", ") : f.warn.length ? f.warn.join(", ") : "Good match"}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        ) : null}
        {chosenFit ? (
          <div className={`rounded-lg border px-3 py-2 ${chosenFit.refuse.length ? "border-danger/40 bg-danger-soft/40" : chosenFit.warn.length ? "border-warn/40" : "border-good/40"}`}>
            <p className={`text-xs font-semibold ${chosenFit.refuse.length ? "text-danger" : "text-ink"}`}>
              {chosenFit.refuse.length ? `${chosen!.name} can't be given this shift` : chosenFit.warn.length ? `${chosen!.name} can work it, with warnings` : `${chosen!.name} is a good fit`}
            </p>
            <ul className="mt-1 grid gap-x-4 gap-y-0.5 sm:grid-cols-2">
              {chosenFit.checks.map((c) => (
                <li key={c.text} className={`flex items-start gap-1.5 text-xs ${c.state === "no" ? "font-medium text-danger" : c.state === "warn" ? "text-warn" : "text-muted"}`}>
                  {c.state === "ok" ? <Check aria-hidden="true" className="mt-0.5 size-3.5 shrink-0 text-good" /> : c.state === "warn" ? <AlertTriangle aria-hidden="true" className="mt-0.5 size-3.5 shrink-0" /> : <XCircle aria-hidden="true" className="mt-0.5 size-3.5 shrink-0" />}
                  {c.text}
                </li>
              ))}
            </ul>
          </div>
        ) : null}
        <div className="grid gap-3 sm:grid-cols-2">
          <label className={field}>
            <span className={label}>Pay classification</span>
            <select name="pay_class" defaultValue={shift.pay_class} className={inputClass}>
              <option value="">Not set</option>
              <option value="regular">Regular</option>
              <option value="casual">Casual</option>
            </select>
            <span className={hint}>Rates come from pay settings later; nothing is worked out here.</span>
          </label>
          <label className={`${check} self-center`}>
            <input type="checkbox" name="notify_worker" defaultChecked={shift.notify_worker} className={box} /> Notify the worker
            <span className={hint}>(when it&apos;s published)</span>
          </label>
        </div>
      </Section>

      <Section icon={FileText} title="Instructions and notes">
        <label className={field}>
          <span className={label}>Shift instructions</span>
          <textarea name="notes" maxLength={500} rows={2} defaultValue={shift.notes} placeholder="What to do on this shift. The worker sees this." className={`${inputClass} h-auto py-2`} />
        </label>
        <label className={field}>
          <span className={label}>Additional shift notes</span>
          <textarea name="extra_notes" maxLength={1000} rows={2} defaultValue={shift.extra_notes} placeholder="Anything else the worker should know (parking, keys, who to call)." className={`${inputClass} h-auto py-2`} />
        </label>
        <label className={field}>
          <span className={label}>Internal note</span>
          <textarea name="internal_note" maxLength={2000} rows={2} placeholder="For people who roster only. Never shown to the worker." className={`${inputClass} h-auto py-2`} />
          <span className={hint}>Kept with the shift&apos;s internal notes (dated, can&apos;t be changed later).</span>
        </label>
      </Section>

      <Section icon={PenLine} title="Signatures">
        <div className="grid gap-x-4 sm:grid-cols-2">
          {SIGNATURES.map(([k, l]) => (
            <label key={k} className={check}>
              <input type="checkbox" name="signatures_needed" value={k} defaultChecked={shift.signatures_needed.includes(k)} className={box} /> {l}
            </label>
          ))}
        </div>
        <p className={hint}>Collected on the worker&apos;s phone at clock in and clock out. Nobody can mark a signature as collected here.</p>
      </Section>

      <section className="px-5 py-4">
        <button type="button" onClick={() => setMore((v) => !v)} aria-expanded={more} className="flex w-full items-center justify-between gap-2 text-sm font-semibold text-ink">
          <span className="flex items-center gap-2">
            <Settings2 aria-hidden="true" className="size-4 text-brand" /> More options
          </span>
          <ChevronDown aria-hidden="true" className={`size-4 transition ${more ? "rotate-180" : ""}`} />
        </button>
        <div className={`mt-3 flex flex-col gap-4 ${more ? "" : "hidden"}`}>
          {!shift.id && templates.length && templateHref ? (
            <label className={field}>
              <span className={label}>Start from a template</span>
              <select
                defaultValue=""
                onChange={(e) => {
                  if (e.target.value) router.push(`${templateHref}&tpl=${e.target.value}`, { scroll: false });
                }}
                className={inputClass}
              >
                <option value="">Choose a template</option>
                {templates.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name} ({t.start}–{t.end})
                  </option>
                ))}
              </select>
              <span className={hint}>Fills in the type, times, instructions and signatures. You still choose the client, date and worker. A template never makes repeating shifts.</span>
            </label>
          ) : null}
          <div className="flex flex-col gap-2">
            <label className={check}>
              <input type="checkbox" checked={asTemplate} onChange={(e) => setAsTemplate(e.target.checked)} className={box} /> Save as a template
            </label>
            {asTemplate ? (
              <label className={field}>
                <span className={label}>Template name</span>
                <input name="save_template" required maxLength={80} placeholder="e.g. Morning personal care" className={inputClass} />
              </label>
            ) : null}
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className={field}>
              <span className={label}>Company car</span>
              <select name="vehicle_id" defaultValue={shift.vehicle_id} className={inputClass}>
                <option value="">No company car</option>
                {cars.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </label>
            <label className={field}>
              <span className={label}>Pay group (optional)</span>
              <input name="pay_group" maxLength={60} defaultValue={shift.pay_group} placeholder="e.g. SCHADS level 2" className={inputClass} />
            </label>
          </div>
          <fieldset className="flex flex-col gap-1">
            <legend className={label}>Allowances</legend>
            <div className="flex flex-wrap gap-x-4">
              {SHIFT_ALLOWANCES.filter((a) => a !== "Sleepover" || !sleepoverShown).map((a) => (
                <label key={a} className={check}>
                  <input type="checkbox" name="allowances" value={a} defaultChecked={shift.allowances.includes(a)} className={box} /> {a}
                </label>
              ))}
            </div>
          </fieldset>
          <ul className="flex flex-col gap-1 text-xs text-muted">
            <li className="flex items-center gap-2">
              <Briefcase aria-hidden="true" className="size-3.5" /> Link a form (checklist or service form): coming later.
            </li>
            <li className="flex items-center gap-2">
              <Briefcase aria-hidden="true" className="size-3.5" /> Tasks for this shift: coming later (tasks can&apos;t be linked to shifts yet).
            </li>
          </ul>
        </div>
      </section>
    </form>
  );
}

export function CopyWeekForm({ from, to }: { from: string; to: string }) {
  const [lastState, lastAction, lastPending] = useActionState(copyLastWeek, null);
  const [nextState, nextAction, nextPending] = useActionState(copyToNextWeek, null);
  const state = nextState ?? lastState;
  return (
    <div className="flex flex-col gap-1">
      <form action={nextAction}>
        <input type="hidden" name="from" value={from} />
        <input type="hidden" name="to" value={to} />
        <button disabled={nextPending} className="w-full px-3 py-2 text-left text-sm font-semibold hover:bg-page">
          {nextPending ? "Copying…" : "Copy this week to next week"}
        </button>
      </form>
      <form action={lastAction}>
        <input type="hidden" name="from" value={from} />
        <button disabled={lastPending} className="w-full px-3 py-2 text-left text-sm font-semibold hover:bg-page">
          {lastPending ? "Copying…" : "Copy last week into this week"}
        </button>
      </form>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

// The bar under the roster while selecting shifts.
export function BulkBar({ formId }: { formId: string; workers?: Opt[] }) {
  const [state, action, pending] = useActionState(bulkShifts, null);
  // How many shifts are ticked (the tick boxes sit in the calendar).
  const [count, setCount] = useState(0);
  const router = useRouter();
  // Done: the floating message, as for a saved shift (errors stay in the bar).
  useEffect(() => {
    if (!state?.message) return;
    const url = new URL(window.location.href);
    url.searchParams.set("saved", state.message);
    router.push(`${url.pathname}?${url.searchParams.toString()}`, { scroll: false });
  }, [state, router]);
  useEffect(() => {
    const recount = () => setCount(document.querySelectorAll(`input[form="${formId}"][name="ids"]:checked`).length);
    recount();
    document.addEventListener("change", recount);
    return () => document.removeEventListener("change", recount);
  }, [formId]);
  return (
    <div
      className={`fixed bottom-6 left-1/2 z-40 flex -translate-x-1/2 flex-wrap items-center gap-2 rounded-xl bg-ink px-4 py-2.5 text-sm text-surface shadow-2xl transition ${count ? "translate-y-0 opacity-100" : "pointer-events-none translate-y-4 opacity-0"}`}
      role="region"
      aria-label="Selected shifts"
    >
      <b>
        {count} shift{count === 1 ? "" : "s"} selected
      </b>
      {(
        [
          ["copy", "Copy to next week"],
          ["publish", "Publish"],
          ["cancel", "Cancel shifts"],
        ] as const
      ).map(([k, l]) => (
        <button
          key={k}
          form={formId}
          formAction={action}
          name="bulk"
          value={k}
          disabled={pending || !count}
          onClick={(e) => {
            // Publishing and cancelling ask first.
            const b = e.currentTarget;
            if (k === "copy" || b.dataset.confirmed === "1") {
              delete b.dataset.confirmed;
              return;
            }
            e.preventDefault();
            const question =
              k === "publish"
                ? [`Publish ${count} shift${count === 1 ? "" : "s"}? Drafts among them are published and their workers are told (unless "Notify the worker" was unticked).`, "Publish shifts"]
                : [`Cancel ${count} shift${count === 1 ? "" : "s"}? Workers already told will be told again. They stay in the log.`, "Cancel shifts"];
            void askConfirm(question[0], { action: question[1] }).then((ok) => {
              if (!ok) return;
              b.dataset.confirmed = "1";
              b.click();
            });
          }}
          className="rounded-md border border-surface/30 px-2 py-1 font-semibold hover:bg-surface/10 disabled:opacity-50">
          {l}
        </button>
      ))}
      <button
        type="button"
        onClick={() => {
          document.querySelectorAll<HTMLInputElement>(`input[form="${formId}"][name="ids"]:checked`).forEach((c) => (c.checked = false));
          setCount(0);
        }}
        className="rounded-md px-2 py-1 font-semibold underline"
      >
        Clear
      </button>
      {state?.error ? <span className="rounded-md bg-danger-soft px-2 py-1 text-danger">{state.error}</span> : null}
    </div>
  );
}

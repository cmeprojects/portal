// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { SHIFT_ALLOWANCES, SHIFT_TYPES } from "@/lib/roster";
import { useRouter } from "next/navigation";
import { useEffect, useActionState, useMemo, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
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
  status: string;
  series: boolean;
  shift_type: string;
  vehicle_id: string;
  pay_group: string;
  allowances: string[];
  needs_worker_signature: boolean;
  needs_client_signature: boolean;
};
type Opt = { id: string; name: string };
// What the Suggest button weighs, per worker (only what this person may see).
export type WorkerFit = {
  id: string;
  name: string;
  hours: number;
  leave: string[];
  busy: { date: string; start: string; end: string }[];
  expiredBeforeWork: string;
  expiredOther: string;
  avail: Record<string, string[]> | null;
};
const field = "flex flex-col gap-1 text-xs font-medium";
const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const AVAIL_DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
const mins = (t: string) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
const slot = (t: string) => {
  const h = Number(t.slice(0, 2));
  return h >= 6 && h < 12 ? "am" : h >= 12 && h < 18 ? "pm" : "night";
};
const dowOf = (d: string) => (new Date(`${d}T12:00:00Z`).getUTCDay() + 6) % 7;

// cmeprojects (rostering round 2): add or change a shift. Refusals (leave,
// clash, expired "before work" check) come from the database; warnings show here.
export function ShiftForm({
  shift,
  workers,
  clients,
  locations,
  services,
  cars = [],
  closeHref,
}: {
  shift: ShiftDraft;
  workers: WorkerFit[];
  clients: Opt[];
  locations: (Opt & { client_id: string })[];
  services: (Opt & { client_id: string })[];
  cars?: Opt[];
  closeHref?: string;
}) {
  const [state, action, pending] = useActionState(saveShift, null);
  const router = useRouter();
  // cmeprojects: a successful save closes the panel and shows what happened above the roster.
  useEffect(() => {
    if (state?.message && closeHref)
      router.push(`${closeHref}${closeHref.includes("?") ? "&" : "?"}saved=${encodeURIComponent(state.message)}${state.spotlight ? `&spot=${state.spotlight}&spotlabel=${shift.id ? "changed" : "added"}` : ""}`, { scroll: false });
  }, [state, closeHref, router, shift.id]);
  const [client, setClient] = useState(shift.client_id);
  const [worker, setWorker] = useState(shift.worker_id);
  const [date, setDate] = useState(shift.date);
  const [start, setStart] = useState(shift.start);
  const [end, setEnd] = useState(shift.end);
  const [repeat, setRepeat] = useState("none");
  const [endBy, setEndBy] = useState("date");
  const [suggesting, setSuggesting] = useState(false);
  const hours = Math.max(0, ((mins(end) - mins(start) + (mins(end) <= mins(start) ? 1440 : 0)) / 60));
  const fit = (w: WorkerFit) => {
    const refuse: string[] = [];
    const warn: string[] = [];
    if (w.expiredBeforeWork) refuse.push(`expired: ${w.expiredBeforeWork}`);
    if (w.leave.includes(date)) refuse.push("on leave");
    if (w.busy.some((b) => b.date === date && mins(b.start) < mins(end) + (mins(end) <= mins(start) ? 1440 : 0) && mins(start) < mins(b.end))) refuse.push("already busy then");
    const total = w.hours + (worker === w.id && shift.id ? 0 : hours);
    if (total > 38) warn.push(`${total.toFixed(1)} h this week`);
    if (w.avail && Object.values(w.avail).some((v) => v?.length) && !(w.avail[AVAIL_DAYS[dowOf(date)]] ?? []).includes(slot(start))) warn.push("outside their availability");
    if (w.expiredOther) warn.push(`expired: ${w.expiredOther}`);
    return { refuse, warn, total };
  };
  const chosen = workers.find((w) => w.id === worker);
  const chosenFit = chosen ? fit(chosen) : null;
  const ranked = useMemo(
    () =>
      workers
        .map((w) => ({ w, f: fit(w) }))
        .sort((a, b) => a.f.refuse.length - b.f.refuse.length || a.f.warn.length - b.f.warn.length || a.w.hours - b.w.hours)
        .slice(0, 8),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [workers, date, start, end, worker],
  );
  return (
    <form action={action} className="flex flex-col gap-3">
      {shift.id ? <input type="hidden" name="id" value={shift.id} /> : null}
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Client</legend>
        <div className="grid gap-2 sm:grid-cols-3">
          <label className={field}>
            Client
            <select name="client_id" value={client} onChange={(e) => setClient(e.target.value)} className={inputClass}>
              <option value="">No client (e.g. training, office)</option>
              {clients.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          {client ? (
            <>
              <label className={field}>
                Service
                <select name="service_id" required defaultValue={shift.service_id} className={inputClass}>
                  <option value="" disabled>
                    Choose the service
                  </option>
                  {services.filter((v) => v.client_id === client).map((v) => (
                    <option key={v.id} value={v.id}>
                      {v.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className={field}>
                Location
                <select name="location_id" required defaultValue={shift.location_id} className={inputClass}>
                  <option value="" disabled>
                    Choose the location
                  </option>
                  {locations.filter((l) => l.client_id === client).map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.name}
                    </option>
                  ))}
                </select>
              </label>
              {!services.some((v) => v.client_id === client) || !locations.some((l) => l.client_id === client) ? (
                <p className="text-xs text-danger sm:col-span-2">
                  This client needs {!services.some((v) => v.client_id === client) ? "an active service" : ""}
                  {!services.some((v) => v.client_id === client) && !locations.some((l) => l.client_id === client) ? " and " : ""}
                  {!locations.some((l) => l.client_id === client) ? "an approved location" : ""} before they can be rostered. Add it on the client&apos;s page.
                </p>
              ) : null}
            </>
          ) : null}
        </div>
      </fieldset>
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Time</legend>
        <label className={`${field} sm:max-w-64`}>
          Shift type
          <select name="shift_type" defaultValue={shift.shift_type || "standard"} className={inputClass}>
            {SHIFT_TYPES.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <div className="grid gap-2 sm:grid-cols-4">
          <label className={field}>
            Date
            <input type="date" name="date" required value={date} onChange={(e) => setDate(e.target.value)} className={inputClass} />
          </label>
          <label className={field}>
            Start
            <input type="time" name="start" required value={start} onChange={(e) => setStart(e.target.value)} className={inputClass} />
          </label>
          <label className={field}>
            Finish
            <input type="time" name="end" required value={end} onChange={(e) => setEnd(e.target.value)} className={inputClass} />
          </label>
          <label className={field}>
            Unpaid break
            <select name="break_minutes" defaultValue={String(shift.break_minutes)} className={inputClass}>
              {[0, 15, 30, 45, 60].map((b) => (
                <option key={b} value={b}>
                  {b ? `${b} minutes` : "None"}
                </option>
              ))}
            </select>
          </label>
        </div>
        <p className="text-xs text-muted">
          {hours.toFixed(2)} hours{mins(end) <= mins(start) ? " (finishes the next day)" : ""}.
        </p>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="next_day" defaultChecked={shift.nextDay} className="size-4" /> Finishes the next day
        </label>
        {shift.id ? (
          shift.series ? (
            <label className={field}>
              This is a repeating shift. Apply changes to
              <select name="scope" className={inputClass}>
                <option value="one">Just this shift</option>
                <option value="future">This and the later shifts in the series</option>
              </select>
            </label>
          ) : null
        ) : (
          <div className="grid gap-2 sm:grid-cols-3">
            <label className={field}>
              Repeat
              <select name="repeat" value={repeat} onChange={(e) => setRepeat(e.target.value)} className={inputClass}>
                <option value="none">Doesn&apos;t repeat</option>
                <option value="daily">Every day</option>
                <option value="weekly">Every week on…</option>
                <option value="fortnightly">Every fortnight on…</option>
              </select>
            </label>
            {repeat !== "none" ? (
              <>
                <label className={field}>
                  Ends
                  <select name="repeat_end" value={endBy} onChange={(e) => setEndBy(e.target.value)} className={inputClass}>
                    <option value="date">On a date</option>
                    <option value="count">After a number of shifts</option>
                  </select>
                </label>
                {endBy === "date" ? (
                  <label className={field}>
                    Last date (12 weeks at most)
                    <input type="date" name="repeat_until" className={inputClass} />
                  </label>
                ) : (
                  <label className={field}>
                    How many shifts
                    <input type="number" name="repeat_count" min={1} max={100} defaultValue={10} className={inputClass} />
                  </label>
                )}
                {repeat !== "daily" ? (
                  <div className="flex flex-wrap gap-1 sm:col-span-3">
                    {DAYS.map((d, i) => (
                      <label key={d} className="inline-flex items-center gap-1 rounded-md border border-line px-2 py-1 text-xs">
                        <input type="checkbox" name="repeat_days" value={i} defaultChecked={i === dowOf(date)} /> {d}
                      </label>
                    ))}
                  </div>
                ) : null}
                <p className="text-xs text-muted sm:col-span-3">Each shift is checked on its own (leave, clashes, checks); any refused are skipped and listed.</p>
              </>
            ) : null}
          </div>
        )}
      </fieldset>
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Worker</legend>
        <div className="flex flex-wrap items-end gap-2">
          <label className={`${field} min-w-56 flex-1`}>
            Worker
            <select name="worker_id" value={worker} onChange={(e) => setWorker(e.target.value)} className={inputClass}>
              <option value="">Open shift (staff put their hand up)</option>
              {workers.map((w) => (
                <option key={w.id} value={w.id}>
                  {w.name} · {w.hours.toFixed(0)}/38 h{w.expiredBeforeWork ? " · check expired" : ""}
                </option>
              ))}
            </select>
          </label>
          <Button type="button" size="sm" variant="outline" onClick={() => setSuggesting((v) => !v)}>
            Suggest worker
          </Button>
        </div>
        {suggesting ? (
          <ul className="flex flex-col gap-1">
            {ranked.map(({ w, f }) => (
              <li key={w.id}>
                <button
                  type="button"
                  onClick={() => {
                    setWorker(w.id);
                    setSuggesting(false);
                  }}
                  className={`flex w-full flex-wrap items-center justify-between gap-2 rounded-md border border-line px-2 py-1.5 text-left text-sm hover:bg-page ${f.refuse.length ? "opacity-50" : ""}`}
                >
                  <span>
                    <b>{w.name}</b> <span className="text-xs text-muted">{w.hours.toFixed(0)}/38 h</span>
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
          chosenFit.refuse.length ? (
            <Notice tone="error">Can&apos;t assign {chosen!.name}: {chosenFit.refuse.join(", ")}.</Notice>
          ) : chosenFit.warn.length ? (
            <Notice tone="info">Warning: {chosenFit.warn.join(", ")}.</Notice>
          ) : (
            <p className="text-xs text-good">Available, checks current, {chosenFit.total.toFixed(1)} of 38 hours this week.</p>
          )
        ) : null}
      </fieldset>
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Car and pay</legend>
        <div className="grid gap-2 sm:grid-cols-2">
          <label className={field}>
            Company car
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
            Pay group (optional)
            <input name="pay_group" maxLength={60} defaultValue={shift.pay_group} placeholder="e.g. SCHADS level 2" className={inputClass} />
          </label>
        </div>
        <fieldset className="flex flex-wrap gap-2">
          <legend className="mb-1 text-xs font-medium">Allowances</legend>
          {SHIFT_ALLOWANCES.map((a) => (
            <label key={a} className="inline-flex items-center gap-1 rounded-md border border-line px-2 py-1 text-xs">
              <input type="checkbox" name="allowances" value={a} defaultChecked={shift.allowances.includes(a)} /> {a}
            </label>
          ))}
        </fieldset>
        <p className="text-xs text-muted">Pay amounts aren&apos;t worked out here; payroll uses the approved timesheet.</p>
      </fieldset>
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Instructions</legend>
        <label className={field}>
          For the worker (shows on their shift)
          <textarea name="notes" maxLength={500} rows={2} defaultValue={shift.notes} placeholder="What to do on this shift. The client's support instructions show to them anyway." className={inputClass} />
        </label>
        <label className={field}>
          Internal note (people who roster only; never shown to the worker)
          <textarea name="internal_note" maxLength={2000} rows={2} placeholder="Added to the shift's notes when you save." className={inputClass} />
        </label>
      </fieldset>
      <fieldset className="flex flex-col gap-1 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Signatures</legend>
        <label className="inline-flex items-center gap-2 text-sm">
          <input type="checkbox" name="needs_worker_signature" defaultChecked={shift.needs_worker_signature} /> Worker signs at clock in and clock out
        </label>
        <label className="inline-flex items-center gap-2 text-sm">
          <input type="checkbox" name="needs_client_signature" defaultChecked={shift.needs_client_signature} /> Client (or representative) signs at clock out
        </label>
      </fieldset>
      <label className={`${field} sm:max-w-80`}>
        Also save as a template (optional)
        <input name="save_template" maxLength={80} placeholder="Template name, e.g. Morning personal care" className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <select name="status" defaultValue={shift.status === "published" ? "published" : "draft"} aria-label="Save as" className={`${inputClass.replace("w-full", "")} w-auto`}>
          <option value="draft">Save as draft</option>
          <option value="published">Publish (the worker is told)</option>
        </select>
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : shift.id ? "Save shift" : "Add shift"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
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
            // Cancelling asks first.
            const b = e.currentTarget;
            if (k !== "cancel" || b.dataset.confirmed === "1") {
              delete b.dataset.confirmed;
              return;
            }
            e.preventDefault();
            void askConfirm(`Cancel ${count} shift${count === 1 ? "" : "s"}? Workers already told will be told again. They stay in the log.`, { action: "Cancel shifts" }).then((ok) => {
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
      {state?.message ? <span className="rounded-md bg-good-soft px-2 py-1 text-ink">{state.message}</span> : null}
    </div>
  );
}

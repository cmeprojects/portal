// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { endShift } from "./actions";

const field = "flex flex-col gap-1 text-xs font-medium";
const ALLOWANCES = ["Sleepover", "Broken shift", "First aid", "Higher duties"];

// cmeprojects: finishing a shift in one go: times, shift notes (what was
// done, how the client was), any incident or issue (managers are told), and
// mileage in the worker's own car. Saves the timesheet and the service record.
export function EndShiftForm(p: {
  shiftId: string;
  date: string;
  start: string;
  end: string;
  breakMinutes: number;
  km?: number;
  expense?: number;
  allowances?: string[];
  delivered?: string;
  wellbeing?: string;
  concern?: boolean;
  concernNote?: string;
}) {
  const [state, action, pending] = useActionState(endShift, null);
  const [issue, setIssue] = useState(!!p.concern);
  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="shift_id" value={p.shiftId} />
      <input type="hidden" name="date" value={p.date} />
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Your times</legend>
        <div className="grid gap-2 sm:grid-cols-3">
          <label className={field}>
            Clock in
            <input type="time" name="start" required defaultValue={p.start} className={inputClass} />
          </label>
          <label className={field}>
            Clock out
            <input type="time" name="end" required defaultValue={p.end} className={inputClass} />
          </label>
          <label className={field}>
            Unpaid break (minutes)
            <input type="number" name="break_minutes" min={0} max={240} step={5} defaultValue={p.breakMinutes} className={inputClass} />
          </label>
        </div>
      </fieldset>
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Shift notes</legend>
        <label className={field}>
          What you did on this shift
          <textarea name="delivered" required maxLength={4000} rows={3} defaultValue={p.delivered ?? ""} placeholder="e.g. Shower and dressing, breakfast, short walk to the shops." className={inputClass} />
        </label>
        <label className={`${field} sm:max-w-64`}>
          How the client was
          <select name="client_wellbeing" defaultValue={p.wellbeing ?? "settled"} className={inputClass}>
            <option value="settled">Settled, as usual</option>
            <option value="some_concerns">Some concerns</option>
            <option value="unwell_or_distressed">Unwell or distressed</option>
          </select>
        </label>
        <label className="inline-flex items-center gap-2 text-sm font-semibold">
          <input type="checkbox" name="concern" checked={issue} onChange={(e) => setIssue(e.target.checked)} /> There was an incident or issue
        </label>
        {issue ? (
          <label className={field}>
            What happened (the managers and the case manager are told straight away)
            <textarea name="concern_note" required maxLength={2000} rows={3} defaultValue={p.concernNote ?? ""} className={inputClass} />
          </label>
        ) : null}
      </fieldset>
      <fieldset className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <legend className="px-1 text-xs font-semibold text-muted">Mileage and extras</legend>
        <div className="grid gap-2 sm:grid-cols-2">
          <label className={field}>
            Mileage in your own car (km)
            <input type="number" name="km" min={0} step={0.1} defaultValue={p.km || ""} placeholder="0" className={inputClass} />
          </label>
          <label className={field}>
            Expenses ($)
            <input type="number" name="expense" min={0} step={0.01} defaultValue={p.expense || ""} placeholder="0.00" className={inputClass} />
          </label>
        </div>
        <div className="flex flex-wrap gap-2">
          {ALLOWANCES.map((a) => (
            <label key={a} className="inline-flex items-center gap-1 rounded-md border border-line px-2 py-1 text-xs">
              <input type="checkbox" name="allowances" value={a} defaultChecked={(p.allowances ?? []).includes(a)} /> {a}
            </label>
          ))}
        </div>
        <p className="text-xs text-muted">Company car trips are recorded in the Cars app instead.</p>
      </fieldset>
      <div className="flex flex-wrap items-center gap-3">
        <Button disabled={pending}>{pending ? "Saving…" : "Finish shift"}</Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

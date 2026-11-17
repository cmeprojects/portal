// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveTimesheet } from "../actions";

const field = "flex flex-col gap-1 text-xs font-medium";
const ALLOWANCES = ["Sleepover", "Broken shift", "First aid", "Higher duties"];

// cmeprojects (rostering round 2): the worker's clock in and out (and extras),
// sent by the worker or corrected by people who roster (with a reason).
export function TimesheetForm({
  shiftId,
  date,
  start,
  end,
  breakMinutes,
  km = 0,
  expense = 0,
  allowances = [],
  note = "",
  needsReason = false,
}: {
  shiftId: string;
  date: string;
  start: string;
  end: string;
  breakMinutes: number;
  km?: number;
  expense?: number;
  allowances?: string[];
  note?: string;
  needsReason?: boolean;
}) {
  const [state, action, pending] = useActionState(saveTimesheet, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="shift_id" value={shiftId} />
      <input type="hidden" name="date" value={date} />
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Clock in
          <input type="time" name="start" required defaultValue={start} className={inputClass} />
        </label>
        <label className={field}>
          Clock out
          <input type="time" name="end" required defaultValue={end} className={inputClass} />
        </label>
        <label className={field}>
          Unpaid break (minutes)
          <input type="number" name="break_minutes" min={0} max={240} step={5} defaultValue={breakMinutes} className={inputClass} />
        </label>
      </div>
      <fieldset className="flex flex-wrap gap-2">
        <legend className="mb-1 text-xs font-medium">Allowances</legend>
        {ALLOWANCES.map((a) => (
          <label key={a} className="inline-flex items-center gap-1 rounded-md border border-line px-2 py-1 text-xs">
            <input type="checkbox" name="allowances" value={a} defaultChecked={allowances.includes(a)} /> {a}
          </label>
        ))}
      </fieldset>
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Mileage (km)
          <input type="number" name="km" min={0} step={0.1} defaultValue={km || ""} className={inputClass} />
        </label>
        <label className={field}>
          Expense ($)
          <input type="number" name="expense" min={0} step={0.01} defaultValue={expense || ""} className={inputClass} />
        </label>
      </div>
      <label className={field}>
        Note
        <input name="note" maxLength={500} defaultValue={note} className={inputClass} />
      </label>
      {needsReason ? (
        <label className={field}>
          Why the times changed (needed if you change them; it goes in the shift log)
          <input name="change_reason" maxLength={500} className={inputClass} />
        </label>
      ) : null}
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : needsReason ? "Save" : "Send my times"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

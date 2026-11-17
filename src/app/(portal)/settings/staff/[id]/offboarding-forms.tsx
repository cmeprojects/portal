// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { addOffboardingStep, saveOffboarding, startOffboarding } from "./offboarding-actions";
import { LEAVING_REASONS } from "@/lib/hr-lists";

const field = "flex flex-col gap-1 text-xs font-medium";

function Result({ state }: { state: { error?: string; message?: string } | null }) {
  return state?.error ? <Notice tone="error">{state.error}</Notice> : state?.message ? <Notice tone="success">{state.message}</Notice> : null;
}

export function StartOffboardingForm({ userId, name }: { userId: string; name: string }) {
  const [state, action, pending] = useActionState(startOffboarding, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="user_id" value={userId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Why is {name} leaving?
          <select name="reason" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose…
            </option>
            {LEAVING_REASONS.map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className={field}>
          Last day
          <input type="date" name="last_day" required className={inputClass} />
        </label>
      </div>
      <label className={field}>
        Note (optional)
        <textarea name="note" maxLength={1000} rows={2} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Starting…" : "Start offboarding"}
        </Button>
        <Result state={state} />
      </div>
    </form>
  );
}

export function OffboardingForm({ id, userId, lastDay, exitNotes, allDone }: { id: string; userId: string; lastDay: string; exitNotes: string; allDone: boolean }) {
  const [state, action, pending] = useActionState(saveOffboarding, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="user_id" value={userId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Last day
          <input type="date" name="last_day" defaultValue={lastDay} className={inputClass} />
        </label>
        <label className={field}>
          Status
          <select name="status" defaultValue="open" className={inputClass}>
            <option value="open">In progress</option>
            <option value="completed" disabled={!allDone}>
              Completed{allDone ? "" : " (finish the checklist first)"}
            </option>
            <option value="cancelled">Cancelled (they&apos;re staying)</option>
          </select>
        </label>
      </div>
      <label className={field}>
        Exit interview notes (only people who manage offboarding see these)
        <textarea name="exit_notes" maxLength={3000} rows={3} defaultValue={exitNotes} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Save"}
        </Button>
        <Result state={state} />
      </div>
    </form>
  );
}

export function AddStepForm({ offboardingId, userId }: { offboardingId: string; userId: string }) {
  const [state, action, pending] = useActionState(addOffboardingStep, null);
  return (
    <form action={action} className="flex flex-wrap items-end gap-2">
      <input type="hidden" name="offboarding_id" value={offboardingId} />
      <input type="hidden" name="user_id" value={userId} />
      <label className={`${field} min-w-48 flex-1`}>
        Another step
        <input name="title" required maxLength={120} placeholder="e.g. Return the medication training kit" className={inputClass} />
      </label>
      <Button size="sm" variant="outline" disabled={pending}>
        Add
      </Button>
      <Result state={state} />
    </form>
  );
}

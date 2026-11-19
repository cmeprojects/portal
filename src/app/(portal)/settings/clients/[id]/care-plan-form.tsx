// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveCareGoal, saveCarePlan, saveWorkerInstruction } from "./actions";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";

export type CarePlan = { id: string; title: string; status: string; assessed_on: string | null; starts_on: string | null; review_by: string | null; summary: string; document_id: string | null };

const field = "flex flex-col gap-1 text-xs font-medium";

function Footer({ pending, state, submit, unchanged = false }: { pending: boolean; state: { error?: string; message?: string } | null; submit: string; unchanged?: boolean }) {
  return (
    <div className="flex flex-wrap items-center gap-3">
      <Button size="sm" disabled={pending || unchanged}>
        {pending ? "Saving…" : submit}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

// cmeprojects (Care block C4): a care plan draft (new, or changing a draft).
export function CarePlanForm({ clientId, plan, documents }: { clientId: string; plan?: CarePlan; documents: [string, string][] }) {
  const [state, action, pending] = useActionState(saveCarePlan, null);
  // Changing a draft: Save stays greyed out until something changes.
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form ref={ref} action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      {plan ? <input type="hidden" name="id" value={plan.id} /> : null}
      <label className={field}>
        Title
        <input name="title" required maxLength={120} defaultValue={plan?.title ?? ""} placeholder="e.g. Care plan 2026" className={inputClass} />
      </label>
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Assessed on
          <input type="date" name="assessed_on" defaultValue={plan?.assessed_on ?? ""} className={inputClass} />
        </label>
        <label className={field}>
          Starts on
          <input type="date" name="starts_on" defaultValue={plan?.starts_on ?? ""} className={inputClass} />
        </label>
        <label className={field}>
          Review by
          <input type="date" name="review_by" defaultValue={plan?.review_by ?? ""} className={inputClass} />
        </label>
      </div>
      <label className={field}>
        Summary of needs and supports
        <textarea name="summary" maxLength={5000} rows={4} defaultValue={plan?.summary ?? ""} className={inputClass} />
      </label>
      {documents.length ? (
        <label className={field}>
          Assessment or plan document (optional)
          <select name="document_id" defaultValue={plan?.document_id ?? ""} className={inputClass}>
            <option value="">None</option>
            {documents.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
      ) : null}
      <Footer pending={pending} state={state} submit={plan ? "Save draft" : "Add draft"} unchanged={Boolean(plan) && !dirty} />
    </form>
  );
}

export function CareGoalForm({ clientId, planId }: { clientId: string; planId: string }) {
  const [state, action, pending] = useActionState(saveCareGoal, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="plan_id" value={planId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Goal
          <input name="goal" required maxLength={500} className={inputClass} />
        </label>
        <label className={field}>
          How we&apos;ll know (optional)
          <input name="measure" maxLength={500} className={inputClass} />
        </label>
      </div>
      <Footer pending={pending} state={state} submit="Add goal" />
    </form>
  );
}

export function WorkerInstructionForm({ clientId }: { clientId: string }) {
  const [state, action, pending] = useActionState(saveWorkerInstruction, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <label className={field}>
        Heading
        <input name="title" required maxLength={120} placeholder="e.g. Meals, Personal care" className={inputClass} />
      </label>
      <label className={field}>
        What staff do
        <textarea name="instructions" required maxLength={2000} rows={3} className={inputClass} />
      </label>
      <Footer pending={pending} state={state} submit="Add instruction" />
    </form>
  );
}

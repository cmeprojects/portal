// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { closeReview, planReview } from "./review-actions";
import { REVIEW_KINDS, REVIEW_OUTCOMES } from "@/lib/hr-lists";
import { DateInput } from "@/components/date-input";

const field = "flex flex-col gap-1 text-xs font-medium";
function Result({ state }: { state: { error?: string; message?: string } | null }) {
  return state?.error ? <Notice tone="error">{state.error}</Notice> : state?.message ? <Notice tone="success">{state.message}</Notice> : null;
}

export function PlanReviewForm({ userId, reviewers, me }: { userId: string; reviewers: { id: string; name: string }[]; me: string }) {
  const [state, action, pending] = useActionState(planReview, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="user_id" value={userId} />
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Kind
          <select name="kind" className={inputClass}>
            {REVIEW_KINDS.map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className={field}>
          Due on
          <DateInput name="due_on" required className={inputClass} />
        </label>
        <label className={field}>
          Reviewer
          <select name="reviewer_id" defaultValue={me} className={inputClass}>
            {reviewers.map((r) => (
              <option key={r.id} value={r.id}>
                {r.name}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Plan review"}
        </Button>
        <Result state={state} />
      </div>
    </form>
  );
}

export function HoldReviewForm({ id, userId, kind, today }: { id: string; userId: string; kind: string; today: string }) {
  const [state, action, pending] = useActionState(closeReview, null);
  const [status, setStatus] = useState("held");
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="user_id" value={userId} />
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Record as
          <select name="status" value={status} onChange={(e) => setStatus(e.target.value)} className={inputClass}>
            <option value="held">Held</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </label>
        {status === "held" ? (
          <>
            <label className={field}>
              Held on
              <DateInput name="held_on" required defaultValue={today} max={today} className={inputClass} />
            </label>
            <label className={field}>
              Outcome
              <select name="outcome" defaultValue={kind === "probation" ? "passed" : "on_track"} className={inputClass}>
                {REVIEW_OUTCOMES.filter(([k]) => (kind === "probation" ? ["passed", "extended", "not_passed"] : ["", "on_track", "needs_support"]).includes(k)).map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </label>
          </>
        ) : null}
      </div>
      {status === "held" ? (
        <>
          <label className={field}>
            Summary (they&apos;ll see this)
            <textarea name="summary" required maxLength={5000} rows={3} className={inputClass} />
          </label>
          <div className="grid gap-2 sm:grid-cols-2">
            <label className={field}>
              Goals
              <textarea name="goals" maxLength={3000} rows={3} className={inputClass} />
            </label>
            <label className={field}>
              Training and development
              <textarea name="development" maxLength={3000} rows={3} className={inputClass} />
            </label>
          </div>
        </>
      ) : null}
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : status === "held" ? "Record review" : "Cancel review"}
        </Button>
        <Result state={state} />
      </div>
    </form>
  );
}

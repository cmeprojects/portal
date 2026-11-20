// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { setLeaveBalance } from "./leave-actions";
import { DateInput } from "@/components/date-input";

const field = "flex flex-col gap-1 text-xs font-medium";

// cmeprojects (update 120): opening balance, yearly accrual and "as at".
export function LeaveBalanceForm({ userId, today }: { userId: string; today: string }) {
  const [state, action, pending] = useActionState(setLeaveBalance, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="user_id" value={userId} />
      <div className="grid gap-2 sm:grid-cols-4">
        <label className={field}>
          Leave type
          <select name="leave_type" className={inputClass}>
            <option value="annual">Annual leave</option>
            <option value="personal">Personal/carer&apos;s leave</option>
            <option value="long_service">Long service leave</option>
          </select>
        </label>
        <label className={field}>
          Balance (days)
          <input name="opening_days" inputMode="decimal" required placeholder="e.g. 7.5" className={inputClass} />
        </label>
        <label className={field}>
          Builds up per year (days)
          <input name="accrual_days_per_year" inputMode="decimal" placeholder="e.g. 20 (full time)" className={inputClass} />
        </label>
        <label className={field}>
          Correct as at
          <DateInput name="as_at" required defaultValue={today} className={inputClass} />
        </label>
      </div>
      <p className="text-xs text-muted">Full-time: 20 days annual and 10 days personal a year (part-time pro rata; casuals none). Approved leave since the date is taken off automatically.</p>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Save balance"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

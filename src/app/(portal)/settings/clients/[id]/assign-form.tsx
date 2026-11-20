// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { assignStaff } from "./actions";
import { ASSIGNED_AS } from "@/lib/client-sections";
import { DateInput } from "@/components/date-input";

// cmeprojects (Stage 5): assign a staff member to this client, with dates.
export function AssignForm({ clientId, staff }: { clientId: string; staff: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(assignStaff, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className="flex flex-col gap-1 text-xs font-medium">
          Staff member
          <select name="user_id" required className={inputClass} defaultValue="">
            <option value="" disabled>
              Choose…
            </option>
            {staff.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Assigned as
          <select name="assigned_as" className={inputClass} defaultValue="case_manager">
            {ASSIGNED_AS.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          From
          <DateInput name="starts_on" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Until (optional)
          <DateInput name="ends_on" className={inputClass} />
        </label>
      </div>
      <label className="flex flex-col gap-1 text-xs font-medium">
        Note (optional)
        <input name="note" maxLength={300} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Assigning…" : "Assign"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { askChange } from "../roster/actions";

// cmeprojects (rostering round 2): ask to swap a shift, or say you can't work it.
export function ChangeRequestForm({ shiftId, people }: { shiftId: string; people: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(askChange, null);
  const [kind, setKind] = useState("swap");
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="shift_id" value={shiftId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className="flex flex-col gap-1 text-xs font-medium">
          What you need
          <select name="kind" value={kind} onChange={(e) => setKind(e.target.value)} className={inputClass}>
            <option value="swap">Swap with someone</option>
            <option value="cannot_work">I can&apos;t work it</option>
          </select>
        </label>
        {kind === "swap" ? (
          <label className="flex flex-col gap-1 text-xs font-medium">
            Swap with
            <select name="swap_with" required className={inputClass} defaultValue="">
              <option value="" disabled>
                Choose…
              </option>
              {people.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          </label>
        ) : null}
      </div>
      <label className="flex flex-col gap-1 text-xs font-medium">
        Reason
        <input name="reason" required maxLength={500} placeholder="e.g. Uni exam" className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Sending…" : "Send to the roster team"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

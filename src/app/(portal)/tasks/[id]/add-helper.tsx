// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { addHelper } from "../actions";

export function AddHelperForm({ taskId, people }: { taskId: string; people: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(addHelper, null);
  if (people.length === 0) return null;
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="task_id" value={taskId} />
      <label htmlFor="helper" className="text-sm font-semibold">
        Tag someone to help out
      </label>
      <div className="flex flex-wrap gap-2">
        <select id="helper" name="user_id" defaultValue="" className={`${inputClass} min-w-0 flex-1`}>
          <option value="" disabled>
            Choose a person
          </option>
          {people.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </select>
        <Button variant="outline" className="h-12" disabled={pending}>
          {pending ? "Adding…" : "Add helper"}
        </Button>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

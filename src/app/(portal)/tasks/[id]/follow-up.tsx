// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import type { Option } from "@/components/field-input";
import { addFollowUpAction } from "../actions";

export function FollowUpForm({ parentId, people, today }: { parentId: string; people: Option[]; today: string }) {
  const [state, action, pending] = useActionState(addFollowUpAction, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="parent_id" value={parentId} />
      <Field label="What needs doing?" htmlFor="a-title">
        <input id="a-title" name="title" required maxLength={200} className={inputClass} />
      </Field>
      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Who will do it?" htmlFor="a-who">
          <select id="a-who" name="assigned_to" defaultValue="" required className={inputClass}>
            <option value="" disabled>
              Choose a person
            </option>
            {people.map((p) => (
              <option key={p.id} value={p.id}>
                {p.label}
              </option>
            ))}
          </select>
        </Field>
        <Field label="By when? (optional)" htmlFor="a-due">
          <input id="a-due" name="due_date" type="date" min={today} className={inputClass} />
        </Field>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending}>
        {pending ? "Adding…" : "Add action"}
      </Button>
    </form>
  );
}

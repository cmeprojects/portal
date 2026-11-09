// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";
import { saveRequestType } from "../../requests/actions";
import { APPROVER_ROLES } from "@/lib/requests-shared";

type T = { key: string; label: string; first_approvers: string[]; second_approvers: string[]; notify: string[]; escalate_days: number; escalate_to: string[] };

// cmeprojects: who approves one request type, who's told, and escalation.
export function RequestTypeForm({ type, people }: { type: T; people: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(saveRequestType, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  const pick = (name: string, label: string, chosen: string[], hint?: string) => (
    <fieldset className="flex flex-col gap-1.5">
      <legend className="text-sm font-medium">{label}</legend>
      {hint ? <p className="text-xs text-muted">{hint}</p> : null}
      <div className="flex flex-wrap gap-x-4 gap-y-1">
        {APPROVER_ROLES.map(([v, l]) => (
          <label key={v} className="flex min-h-9 items-center gap-2 text-sm">
            <input type="checkbox" name={`${name}_roles`} value={v} defaultChecked={chosen.includes(v)} className="h-4 w-4 accent-[var(--brand-primary)]" />
            {l}
          </label>
        ))}
      </div>
      <select name={`${name}_people`} multiple defaultValue={chosen.filter((c) => c.startsWith("user:")).map((c) => c.slice(5))} aria-label={`${label}: chosen people`} className={`${inputClass} h-24 py-1`}>
        {people.map((p) => (
          <option key={p.id} value={p.id}>
            {p.name}
          </option>
        ))}
      </select>
    </fieldset>
  );
  return (
    <form ref={ref} action={action} className="flex flex-col gap-4">
      <input type="hidden" name="key" value={type.key} />
      <div className="grid gap-4 md:grid-cols-2">
        {pick("first", "First approver", type.first_approvers, "Their team leader falls back to the managers if the person has none.")}
        {pick("second", "Second approver (optional)", type.second_approvers, "Leave empty for one-step approval. Must be a different person.")}
        {pick("notify", "Also tell (optional)", type.notify, "Told when a request is sent; they can't approve.")}
        <div className="flex flex-col gap-3">
          <Field label="Escalate if nobody acts within (days)" htmlFor={`esc-${type.key}`} hint="0 turns escalation off.">
            <input id={`esc-${type.key}`} name="escalate_days" type="number" min={0} max={60} defaultValue={type.escalate_days} className={`${inputClass} max-w-28`} />
          </Field>
          {pick("escalate", "Escalate to", type.escalate_to)}
        </div>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button className="self-start" disabled={pending || !dirty}>
        {pending ? "Saving…" : "Save"}
      </Button>
    </form>
  );
}

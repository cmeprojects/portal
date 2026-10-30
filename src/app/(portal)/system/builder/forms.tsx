// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { createFeature, setFeatureIncluded } from "./actions";

export function NewFeatureForm() {
  const [state, action, pending] = useActionState(createFeature, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="grid gap-3 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
        <Field label="Name" htmlFor="nf-name">
          <input id="nf-name" name="name" required maxLength={60} placeholder="e.g. Fluid intake, Fridge temperatures" className={inputClass} />
        </Field>
        <Field label="Start from" htmlFor="nf-template">
          <select id="nf-template" name="template" className={inputClass}>
            <option value="">A blank form</option>
            <option value="fluid">The Fluid intake example</option>
          </select>
        </Field>
        <Button disabled={pending}>{pending ? "Creating…" : "Create draft"}</Button>
      </div>
      <p className="text-xs text-muted">It starts as a draft: staff don&apos;t see it until you publish it.</p>
    </form>
  );
}

// In this company's package (premium add-on): on shows it to staff, off hides it and keeps its entries.
export function IncludedSwitch({ id, enabled }: { id: string; enabled: boolean }) {
  return (
    <form action={setFeatureIncluded}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="enabled" value={enabled ? "false" : "true"} />
      <button
        role="switch"
        aria-checked={enabled}
        aria-label={`In the package: ${enabled ? "on" : "off"}`}
        className={`flex h-9 min-w-24 items-center justify-center gap-2 rounded-md px-3 text-sm font-semibold ${
          enabled ? "bg-brand text-brand-fg" : "border border-field bg-surface text-muted"
        }`}
      >
        <span aria-hidden="true" className={`h-2.5 w-2.5 rounded-full ${enabled ? "bg-brand-fg" : "bg-muted"}`} />
        {enabled ? "In package" : "Off"}
      </button>
    </form>
  );
}

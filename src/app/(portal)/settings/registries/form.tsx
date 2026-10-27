// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { saveRegistry } from "./actions";

type Person = { id: string; full_name: string; email: string };
export type Registry = { id: string; name: string; description: string; requires_approval: boolean; active: boolean };

const check = "h-5 w-5 accent-[var(--brand-primary)]";

export function RegistryForm({
  registry,
  managerIds = [],
  candidates,
}: {
  registry?: Registry;
  managerIds?: string[];
  candidates: Person[];
}) {
  const [state, action, pending] = useActionState(saveRegistry, null);
  const key = registry?.id ?? "new";

  return (
    <form action={action} className="flex flex-col gap-4">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <input type="hidden" name="id" value={registry?.id ?? ""} />
      <Field label="Name" htmlFor={`name-${key}`}>
        <input id={`name-${key}`} name="name" defaultValue={registry?.name} required className={inputClass} />
      </Field>
      <Field label="What it's for (optional)" htmlFor={`desc-${key}`}>
        <input id={`desc-${key}`} name="description" defaultValue={registry?.description} className={inputClass} />
      </Field>
      <fieldset className="flex flex-col gap-1">
        <legend className="mb-1 text-[15px] font-semibold">Managers</legend>
        {candidates.length === 0 ? (
          <p className="text-sm text-muted">Give someone the Manager role on the Staff &amp; roles page first.</p>
        ) : (
          candidates.map((c) => (
            <label key={c.id} className="flex min-h-11 items-center gap-3 text-[15px]">
              <input type="checkbox" name="managers" value={c.id} defaultChecked={managerIds.includes(c.id)} className={check} />
              {c.full_name || c.email}
            </label>
          ))
        )}
      </fieldset>
      <label className="flex min-h-11 items-center gap-3 text-[15px]">
        <input type="checkbox" name="requires_approval" defaultChecked={registry?.requires_approval} className={check} />
        Manager approval needed to close tasks
      </label>
      {registry ? (
        <label className="flex min-h-11 items-center gap-3 text-[15px]">
          <input type="checkbox" name="active" defaultChecked={registry.active} className={check} />
          Registry is in use
        </label>
      ) : null}
      <Button className="self-start" disabled={pending}>
        {pending ? "Saving…" : registry ? "Save registry" : "Add registry"}
      </Button>
    </form>
  );
}

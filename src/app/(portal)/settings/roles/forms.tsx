// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, ROLES, type JobTitle } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { addJobTitle, saveJobTitle } from "./actions";

const LEVELS = ROLES.filter((r) => r !== "system_admin");

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

function TitleFields({ title, idPrefix, inUse }: { title?: JobTitle; idPrefix: string; inUse?: number }) {
  return (
    <div className="grid gap-4 md:grid-cols-[2fr_1.4fr_3fr_0.7fr] md:items-end">
      <Field label="Role name" htmlFor={`${idPrefix}-name`}>
        <input id={`${idPrefix}-name`} name="name" required defaultValue={title?.name} placeholder="e.g. Nurse" className={inputClass} />
      </Field>
      <Field label="Access level" htmlFor={`${idPrefix}-level`}>
        <select
          id={`${idPrefix}-level`}
          name="access_level"
          defaultValue={title?.access_level ?? "support_worker"}
          disabled={!!inUse}
          className={inputClass}
        >
          {LEVELS.map((r) => (
            <option key={r} value={r}>
              {ROLE_LABELS[r]}
            </option>
          ))}
        </select>
        {inUse ? <input type="hidden" name="access_level" value={title?.access_level} /> : null}
      </Field>
      <Field label="Description (optional)" htmlFor={`${idPrefix}-desc`}>
        <input id={`${idPrefix}-desc`} name="description" defaultValue={title?.description} className={inputClass} />
      </Field>
      <Field label="Order" htmlFor={`${idPrefix}-sort`}>
        <input id={`${idPrefix}-sort`} name="sort_order" type="number" defaultValue={title?.sort_order ?? 0} className={inputClass} />
      </Field>
    </div>
  );
}

export function NewJobTitleForm() {
  const [state, action, pending] = useActionState(addJobTitle, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      <TitleFields idPrefix="new-title" />
      <Button className="self-start" disabled={pending}>{pending ? "Adding…" : "Add role"}</Button>
    </form>
  );
}

export function JobTitleForm({ title, inUse }: { title: JobTitle; inUse: number }) {
  const [state, action, pending] = useActionState(saveJobTitle, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      <input type="hidden" name="id" value={title.id} />
      <TitleFields title={title} idPrefix={`title-${title.id}`} inUse={inUse} />
      {inUse ? (
        <p className="text-sm text-muted">
          {inUse} {inUse === 1 ? "person has" : "people have"} this role, so its access level is locked. Give them another role first.
        </p>
      ) : null}
      <div className="flex flex-wrap items-center gap-4">
        <label className="flex min-h-11 items-center gap-3 text-sm">
          <input type="checkbox" name="active" defaultChecked={title.active} className="h-5 w-5 accent-[var(--brand-primary)]" />
          Role is in use
        </label>
        <Button disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
      </div>
    </form>
  );
}

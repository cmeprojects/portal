// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, type FormEvent } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, ROLES, type JobTitle } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { addJobTitle, saveJobTitle } from "./actions";

const LEVELS = ROLES.filter((r) => r !== "system_admin" && r !== "new_starter");

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export type GroupChoice = { id: string; name: string; active: boolean };

// A role needs at least one group: checked before sending, so nothing typed is lost.
function useGroupCheck() {
  const [missing, setMissing] = useState(false);
  const onSubmit = (e: FormEvent<HTMLFormElement>) => {
    const f = e.currentTarget;
    const none = Boolean(f.querySelector("input[name=fg_shown]")) && !f.querySelector("input[name=function_groups]:checked");
    setMissing(none);
    if (none) e.preventDefault();
  };
  return { missing, onSubmit };
}

// cmeprojects (Stage 2): the function groups a role belongs to (at least one).
function GroupChoices({ groups, chosen, idPrefix }: { groups: GroupChoice[]; chosen: string[]; idPrefix: string }) {
  const shown = groups.filter((g) => g.active || chosen.includes(g.id));
  return (
    <fieldset className="flex flex-col gap-1">
      <legend className="mb-1 text-sm font-medium">Function groups (at least one)</legend>
      <input type="hidden" name="fg_shown" value="1" />
      <div className="flex flex-wrap gap-x-5 gap-y-1">
        {shown.map((g) => (
          <label key={g.id} htmlFor={`${idPrefix}-fg-${g.id}`} className="flex min-h-9 items-center gap-2 text-sm">
            <input id={`${idPrefix}-fg-${g.id}`} type="checkbox" name="function_groups" value={g.id} defaultChecked={chosen.includes(g.id)} disabled={!g.active && !chosen.includes(g.id)} className="h-4 w-4 accent-[var(--brand-primary)]" />
            {g.name}
            {!g.active ? <span className="text-xs text-muted">(not in use)</span> : null}
          </label>
        ))}
      </div>
    </fieldset>
  );
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

export function NewJobTitleForm({ groups }: { groups?: GroupChoice[] | null }) {
  const [state, action, pending] = useActionState(addJobTitle, null);
  const check = useGroupCheck();
  return (
    <form action={action} onSubmit={check.onSubmit} className="flex flex-col gap-4">
      <Result state={state} />
      {check.missing ? <Notice tone="error">Choose at least one function group.</Notice> : null}
      <TitleFields idPrefix="new-title" />
      {groups ? <GroupChoices groups={groups} chosen={[]} idPrefix="new-title" /> : null}
      <Button className="self-start" disabled={pending}>{pending ? "Adding…" : "Add role"}</Button>
    </form>
  );
}

export function JobTitleForm({ title, inUse, groups, chosen = [] }: { title: JobTitle; inUse: number; groups?: GroupChoice[] | null; chosen?: string[] }) {
  const [state, action, pending] = useActionState(saveJobTitle, null);
  const check = useGroupCheck();
  return (
    <form action={action} onSubmit={check.onSubmit} className="flex flex-col gap-4">
      <Result state={state} />
      {check.missing ? <Notice tone="error">Choose at least one function group.</Notice> : null}
      <input type="hidden" name="id" value={title.id} />
      <TitleFields title={title} idPrefix={`title-${title.id}`} inUse={inUse} />
      {groups ? <GroupChoices groups={groups} chosen={chosen} idPrefix={`title-${title.id}`} /> : null}
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

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { PeopleChecklist, type Person } from "@/components/people-picker";
import { FieldInput, type Option } from "@/components/field-input";
import { PRIORITIES, PRIORITY_LABELS } from "@/lib/tasks";
import type { Registry, RegistryField } from "@/lib/registers";
import { createTask } from "../actions";

export function PriorityPicker({ value = "medium" }: { value?: string }) {
  return (
    <fieldset>
      <legend className="mb-1.5 text-sm font-semibold">Priority</legend>
      <div className="flex flex-wrap gap-2">
        {PRIORITIES.map((p) => (
          <label key={p} className="cursor-pointer">
            <input type="radio" name="priority" value={p} defaultChecked={p === value} className="peer sr-only" />
            <span className="inline-flex min-h-11 items-center rounded-md border border-field bg-surface px-4 text-sm font-semibold peer-checked:border-brand peer-checked:bg-brand peer-checked:text-brand-fg peer-focus-visible:outline peer-focus-visible:outline-3 peer-focus-visible:outline-brand-accent">
              {PRIORITY_LABELS[p]}
            </span>
          </label>
        ))}
      </div>
    </fieldset>
  );
}

export function NewTaskForm({
  registries,
  fields,
  people,
  assets,
  meId,
  today,
  initialRegistryId,
}: {
  registries: Registry[];
  fields: RegistryField[];
  people: Person[];
  assets: Option[];
  meId: string;
  today: string;
  initialRegistryId?: string;
}) {
  const [state, action, pending] = useActionState(createTask, null);
  // System admins can't take tasks, so they start with the first person in the list.
  const [assignee, setAssignee] = useState(people.some((p) => p.id === meId) ? meId : (people[0]?.id ?? ""));
  const [registryId, setRegistryId] = useState(
    registries.find((r) => r.id === initialRegistryId)?.id ?? registries.find((r) => r.is_default)?.id ?? registries[0]?.id ?? "",
  );
  const registry = registries.find((r) => r.id === registryId);
  const custom = fields.filter((f) => f.registry_id === registryId && f.active);
  const personOptions = people.map((p) => ({ id: p.id, label: p.name }));

  return (
    <form action={action} className="flex flex-col gap-5">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}

      <Field
        label="Register"
        htmlFor="registry_id"
        hint={registry?.requires_approval ? "A manager needs to approve before tasks in this register can close." : registry?.description}
      >
        <select id="registry_id" name="registry_id" value={registryId} onChange={(e) => setRegistryId(e.target.value)} className={inputClass}>
          {registries.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
      </Field>

      <Field label={registry?.title_label ?? "Title"} htmlFor="title" hint="A short summary people will recognise in a list.">
        <input id="title" name="title" required maxLength={200} className={inputClass} />
      </Field>

      <Field label={`${registry?.description_label ?? "Description"} (optional)`} htmlFor="description">
        <textarea id="description" name="description" rows={5} className={`${inputClass} h-auto py-3`} />
      </Field>

      <div className="grid gap-5 md:grid-cols-3">
        <Field label="Date reported" htmlFor="date_reported">
          <input id="date_reported" name="date_reported" type="date" defaultValue={today} max={today} className={inputClass} />
        </Field>
        {registry?.show_due_date !== false ? (
          <Field label="Due date (optional)" htmlFor="due_date">
            <input id="due_date" name="due_date" type="date" min={today} className={inputClass} />
          </Field>
        ) : null}
        {registry?.show_review_date ? (
          <Field label={`${registry.review_label} (optional)`} htmlFor="review_date">
            <input id="review_date" name="review_date" type="date" className={inputClass} />
          </Field>
        ) : null}
      </div>

      <PriorityPicker />

      {custom.length ? (
        // key resets the inputs when the register changes.
        <fieldset key={registryId} className="flex flex-col gap-5 rounded-lg border border-line bg-page/60 p-4 sm:p-5">
          <legend className="px-1 text-sm font-semibold text-brand">{registry?.name} details</legend>
          {custom.map((f) => (
            <FieldInput key={f.id} field={f} people={personOptions} assets={assets} />
          ))}
        </fieldset>
      ) : null}

      <div className="grid gap-5 md:grid-cols-2">
        <Field label="Who will look after it?" htmlFor="assigned_to">
          <select id="assigned_to" name="assigned_to" value={assignee} onChange={(e) => setAssignee(e.target.value)} className={inputClass}>
            {people.map((p) => (
              <option key={p.id} value={p.id}>
                {p.id === meId ? `${p.name} (me)` : p.name} · {p.detail}
              </option>
            ))}
          </select>
        </Field>
        <PeopleChecklist name="helpers" label="Helpers (optional)" people={people} exclude={[assignee]} />
      </div>

      <p className="text-sm text-muted">
        We&apos;ll email the person looking after it and copy in the helpers. Photos and files can be added once the
        task is created.
      </p>
      <Button className="min-h-12 self-start px-8 text-base" disabled={pending}>
        {pending ? "Creating…" : "Create task"}
      </Button>
    </form>
  );
}

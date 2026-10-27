// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { PeopleChecklist, type Person } from "@/components/people-picker";
import { PRIORITIES, PRIORITY_LABELS } from "@/lib/tasks";
import { createTask } from "../actions";

type Registry = { id: string; name: string; requires_approval: boolean };

export function NewTaskForm({
  registries,
  people,
  meId,
  today,
}: {
  registries: Registry[];
  people: Person[];
  meId: string;
  today: string;
}) {
  const [state, action, pending] = useActionState(createTask, null);
  const [assignee, setAssignee] = useState(meId);
  const [registryId, setRegistryId] = useState(registries[0]?.id ?? "");
  const registry = registries.find((r) => r.id === registryId);

  return (
    <form action={action} className="flex flex-col gap-5">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}

      <Field label="Title" htmlFor="title" hint="A short summary, for example “Replace smoke alarm battery in bedroom 2”.">
        <input id="title" name="title" required maxLength={200} className={inputClass} />
      </Field>

      <div className="grid gap-5 md:grid-cols-2">
        <Field
          label="Registry"
          htmlFor="registry_id"
          hint={registry?.requires_approval ? "A manager needs to approve before this task can close." : undefined}
        >
          <select id="registry_id" name="registry_id" value={registryId} onChange={(e) => setRegistryId(e.target.value)} className={inputClass}>
            {registries.map((r) => (
              <option key={r.id} value={r.id}>
                {r.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Due date (optional)" htmlFor="due_date">
          <input id="due_date" name="due_date" type="date" min={today} className={inputClass} />
        </Field>
      </div>

      <fieldset>
        <legend className="mb-1.5 text-[15px] font-semibold">Priority</legend>
        <div className="flex flex-wrap gap-2">
          {PRIORITIES.map((p) => (
            <label key={p} className="cursor-pointer">
              <input type="radio" name="priority" value={p} defaultChecked={p === "medium"} className="peer sr-only" />
              <span className="inline-flex min-h-11 items-center rounded-full border border-field bg-white px-5 text-[15px] font-semibold peer-checked:border-brand peer-checked:bg-brand peer-checked:text-white peer-focus-visible:outline peer-focus-visible:outline-3 peer-focus-visible:outline-brand-accent">
                {PRIORITY_LABELS[p]}
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      <Field label="Description (optional)" htmlFor="description" hint="What needs doing, where, and anything the person should know.">
        <textarea id="description" name="description" rows={5} className={`${inputClass} h-auto py-3`} />
      </Field>

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
      <Button className="h-[52px] self-start px-8 text-[17px]" disabled={pending}>
        {pending ? "Creating…" : "Create task"}
      </Button>
    </form>
  );
}

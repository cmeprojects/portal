// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useDirty } from "@/components/use-dirty";
import { useActionState, useRef } from "react";
import { closeParentDetails, useAfterSuccess } from "@/components/use-after-success";
import { toast } from "@/components/toast";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FieldInput, type Option } from "@/components/field-input";
import type { Details, Registry, RegistryField } from "@/lib/registers";
import { PriorityPicker } from "../new/form";
import { updateTaskDetails } from "../actions";

export type EditableTask = {
  id: string;
  title: string;
  description: string;
  priority: string;
  due_date: string | null;
  date_reported: string;
  review_date: string | null;
  outcome: string;
  details: Details;
  isAction: boolean;
};

export function EditDetailsForm({
  task,
  registry,
  fields,
  people,
  assets,
  clients = [],
  clientId = "",
}: {
  task: EditableTask;
  registry: Registry;
  fields: RegistryField[];
  people: Option[];
  assets: Option[];
  // cmeprojects: who the task is about (names only).
  clients?: { id: string; name: string }[];
  clientId?: string;
}) {
  const [state, action, pending] = useActionState(updateTaskDetails, null);
  const { ref: dirtyRef, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  const form = useRef<HTMLFormElement>(null);
  // cmeprojects: once saved, fold the section away; the page shows the change.
  useAfterSuccess(state, (message) => { form.current?.reset(); closeParentDetails(form.current); toast(message); });
  return (
    <form ref={(el) => { form.current = el; dirtyRef.current = el; }} action={action} className="flex flex-col gap-5">
      <input type="hidden" name="task_id" value={task.id} />
      <Field label={registry.title_label} htmlFor="e-title">
        <input id="e-title" name="title" defaultValue={task.title} required maxLength={200} className={inputClass} />
      </Field>
      <Field label={registry.description_label} htmlFor="e-description">
        <textarea id="e-description" name="description" rows={5} defaultValue={task.description} className={`${inputClass} h-auto py-3`} />
      </Field>
      <div className="grid gap-5 md:grid-cols-3">
        <Field label="Date reported" htmlFor="e-reported">
          <input id="e-reported" name="date_reported" type="date" defaultValue={task.date_reported} className={inputClass} />
        </Field>
        <Field label="Due date" htmlFor="e-due">
          <input id="e-due" name="due_date" type="date" defaultValue={task.due_date ?? ""} className={inputClass} />
        </Field>
        {registry.show_review_date && !task.isAction ? (
          <Field label={registry.review_label} htmlFor="e-review">
            <input id="e-review" name="review_date" type="date" defaultValue={task.review_date ?? ""} className={inputClass} />
          </Field>
        ) : (
          <input type="hidden" name="review_date" value={task.review_date ?? ""} />
        )}
      </div>
      {clients.length ? (
        <Field label="Client (optional)" htmlFor="e-client">
          <select id="e-client" name="client_id" defaultValue={clientId} className={`${inputClass} md:max-w-md`}>
            <option value="">No client</option>
            {clients.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </Field>
      ) : null}
      <PriorityPicker value={task.priority} />
      {!task.isAction
        ? fields.map((f) => <FieldInput key={f.id} field={f} value={task.details[f.key]} people={people} assets={assets} />)
        : null}
      {registry.show_outcome && !task.isAction ? (
        <Field
          label={registry.outcome_required ? `${registry.outcome_label} (needed before completing)` : registry.outcome_label}
          htmlFor="e-outcome"
          hint="What was done about it. You can fill this in as you go."
        >
          <textarea id="e-outcome" name="outcome" rows={4} defaultValue={task.outcome} className={`${inputClass} h-auto py-3`} />
        </Field>
      ) : (
        <input type="hidden" name="outcome" value={task.outcome} />
      )}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button className="self-start" disabled={pending || !dirty}>
        {pending ? "Saving…" : "Save changes"}
      </Button>
    </form>
  );
}

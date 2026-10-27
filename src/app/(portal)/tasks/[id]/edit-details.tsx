// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
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
}: {
  task: EditableTask;
  registry: Registry;
  fields: RegistryField[];
  people: Option[];
  assets: Option[];
}) {
  const [state, action, pending] = useActionState(updateTaskDetails, null);
  return (
    <form action={action} className="flex flex-col gap-5">
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
      <PriorityPicker value={task.priority} />
      {!task.isAction
        ? fields.map((f) => <FieldInput key={f.id} field={f} value={task.details[f.key]} people={people} assets={assets} />)
        : null}
      {registry.show_outcome && !task.isAction ? (
        <Field label={registry.outcome_label} htmlFor="e-outcome" hint="What was done about it. You can fill this in as you go.">
          <textarea id="e-outcome" name="outcome" rows={4} defaultValue={task.outcome} className={`${inputClass} h-auto py-3`} />
        </Field>
      ) : (
        <input type="hidden" name="outcome" value={task.outcome} />
      )}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button className="self-start" disabled={pending}>
        {pending ? "Saving…" : "Save changes"}
      </Button>
    </form>
  );
}

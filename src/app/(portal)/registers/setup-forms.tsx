// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FIELD_TYPE_LABELS, FIELD_TYPES, type FieldType, type Registry, type RegistryField } from "@/lib/registers";
import type { FormState } from "@/lib/form";
import { addField, createRegistry, saveManagers, saveRegistrySettings, updateField } from "./setup-actions";

const check = "h-5 w-5 accent-[var(--brand-primary)]";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

function Toggle({ name, label, defaultChecked }: { name: string; label: string; defaultChecked: boolean }) {
  return (
    <label className="flex min-h-11 items-center gap-3 text-sm">
      <input type="checkbox" name={name} defaultChecked={defaultChecked} className={check} />
      {label}
    </label>
  );
}

export function CreateRegistryForm() {
  const [state, action, pending] = useActionState(createRegistry, null);
  const [kind, setKind] = useState("tasks");
  return (
    <form action={action} className="flex flex-col gap-5">
      <Result state={state} />
      <Field label="Name" htmlFor="name" hint="For example “Incident Register”.">
        <input id="name" name="name" required maxLength={80} className={inputClass} />
      </Field>
      <Field label="What it's for (optional)" htmlFor="description">
        <input id="description" name="description" className={inputClass} />
      </Field>
      <fieldset>
        <legend className="mb-2 text-sm font-semibold">What kind of register?</legend>
        <div className="grid gap-3 md:grid-cols-2">
          {[
            ["tasks", "Tasks", "Things that need doing, with someone looking after each one, a status and due dates."],
            ["records", "A list of things", "Like an asset register: items with details, but no one assigned and no workflow."],
          ].map(([value, title, help]) => (
            <label key={value} className={`flex cursor-pointer gap-3 rounded-lg border p-4 ${kind === value ? "border-brand bg-brand-soft" : "border-line"}`}>
              <input type="radio" name="kind" value={value} checked={kind === value} onChange={() => setKind(value)} className={`${check} mt-0.5`} />
              <span>
                <span className="block font-semibold">{title}</span>
                <span className="block text-sm text-muted">{help}</span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <Field label="Reference prefix (optional)" htmlFor="prefix" hint="2–6 letters, like INC. Leave blank to make one from the name.">
        <input id="prefix" name="prefix" maxLength={6} className={`${inputClass} max-w-40 uppercase`} />
      </Field>
      {kind === "tasks" ? <Toggle name="requires_approval" label="Manager approval needed to close tasks" defaultChecked={false} /> : null}
      <p className="text-sm text-muted">Next you&apos;ll add its fields and choose its managers.</p>
      <Button className="self-start" disabled={pending}>
        {pending ? "Creating…" : "Create register"}
      </Button>
    </form>
  );
}

export function RegistrySettingsForm({ registry }: { registry: Registry }) {
  const [state, action, pending] = useActionState(saveRegistrySettings, null);
  const tasks = registry.kind === "tasks";
  return (
    <form action={action} className="flex flex-col gap-5">
      <input type="hidden" name="id" value={registry.id} />
      <div className="grid gap-5 md:grid-cols-[1fr_160px]">
        <Field label="Name" htmlFor="s-name">
          <input id="s-name" name="name" defaultValue={registry.name} required maxLength={80} className={inputClass} />
        </Field>
        <Field label="Prefix" htmlFor="s-prefix" hint="Used in reference numbers.">
          <input id="s-prefix" name="prefix" defaultValue={registry.prefix} required maxLength={6} className={`${inputClass} uppercase`} />
        </Field>
      </div>
      <Field label="What it's for" htmlFor="s-desc">
        <input id="s-desc" name="description" defaultValue={registry.description} className={inputClass} />
      </Field>
      <div className="grid gap-5 md:grid-cols-2">
        <Field label={tasks ? "Label for the title" : "Label for the name"} htmlFor="s-title">
          <input id="s-title" name="title_label" defaultValue={registry.title_label} className={inputClass} />
        </Field>
        {tasks ? (
          <Field label="Label for the description box" htmlFor="s-dlabel" hint="For example “Risk description”.">
            <input id="s-dlabel" name="description_label" defaultValue={registry.description_label} className={inputClass} />
          </Field>
        ) : (
          <input type="hidden" name="description_label" value={registry.description_label} />
        )}
      </div>
      {tasks ? (
        <div className="flex flex-col gap-1 rounded-lg border border-line p-4">
          <Toggle name="requires_approval" label="Manager approval needed to close tasks" defaultChecked={registry.requires_approval} />
          <Toggle name="show_due_date" label="Ask for a due date" defaultChecked={registry.show_due_date} />
          <Toggle name="show_review_date" label="Show a review date" defaultChecked={registry.show_review_date} />
          <div className="pl-8">
            <Field label="Review date label" htmlFor="s-review">
              <input id="s-review" name="review_label" defaultValue={registry.review_label} className={`${inputClass} max-w-sm`} />
            </Field>
          </div>
          <Toggle name="show_outcome" label="Show an outcome / actions taken box" defaultChecked={registry.show_outcome} />
          <div className="pl-8">
            <Field label="Outcome label" htmlFor="s-outcome">
              <input id="s-outcome" name="outcome_label" defaultValue={registry.outcome_label} className={`${inputClass} max-w-sm`} />
            </Field>
          </div>
        </div>
      ) : (
        <>
          <input type="hidden" name="review_label" value={registry.review_label} />
          <input type="hidden" name="outcome_label" value={registry.outcome_label} />
        </>
      )}
      {registry.is_default ? (
        <input type="hidden" name="active" value="on" />
      ) : (
        <Toggle name="active" label="Register is in use (untick to retire it; everything in it is kept)" defaultChecked={registry.active} />
      )}
      <Result state={state} />
      <Button className="self-start" disabled={pending}>
        {pending ? "Saving…" : "Save settings"}
      </Button>
    </form>
  );
}

export function ManagersForm({
  registryId,
  managerIds,
  candidates,
}: {
  registryId: string;
  managerIds: string[];
  candidates: { id: string; label: string }[];
}) {
  const [state, action, pending] = useActionState(saveManagers, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={registryId} />
      {candidates.length === 0 ? (
        <p className="text-sm text-muted">Give someone the Manager role on the Staff &amp; roles page first.</p>
      ) : (
        candidates.map((c) => (
          <label key={c.id} className="flex min-h-11 items-center gap-3 text-sm">
            <input type="checkbox" name="managers" value={c.id} defaultChecked={managerIds.includes(c.id)} className={check} />
            {c.label}
          </label>
        ))
      )}
      <Result state={state} />
      <Button variant="outline" className="self-start" disabled={pending}>
        {pending ? "Saving…" : "Save managers"}
      </Button>
    </form>
  );
}

function FieldInputs({ field, idp }: { field?: RegistryField; idp: string }) {
  const [type, setType] = useState<FieldType>(field?.type ?? "text");
  return (
    <>
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="Label" htmlFor={`${idp}-label`}>
          <input id={`${idp}-label`} name="label" defaultValue={field?.label} required maxLength={80} className={inputClass} />
        </Field>
        <Field label="Type" htmlFor={`${idp}-type`}>
          <select id={`${idp}-type`} name="type" value={type} onChange={(e) => setType(e.target.value as FieldType)} className={inputClass}>
            {FIELD_TYPES.map((t) => (
              <option key={t} value={t}>
                {FIELD_TYPE_LABELS[t]}
              </option>
            ))}
          </select>
        </Field>
      </div>
      {type === "choice" || type === "multi_choice" ? (
        <Field label="Choices (one per line)" htmlFor={`${idp}-options`}>
          <textarea id={`${idp}-options`} name="options" rows={5} defaultValue={field?.options.join("\n")} className={`${inputClass} h-auto py-3`} />
        </Field>
      ) : null}
      <Field label="Help text (optional)" htmlFor={`${idp}-help`} hint="Shown under the field on the form.">
        <input id={`${idp}-help`} name="help" defaultValue={field?.help} className={inputClass} />
      </Field>
      <Toggle name="required" label="Must be filled in" defaultChecked={field?.required ?? false} />
    </>
  );
}

export function AddFieldForm({ registryId }: { registryId: string }) {
  const [state, action, pending] = useActionState(addField, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="registry_id" value={registryId} />
      <FieldInputs idp="new" />
      <Result state={state} />
      <Button className="self-start" disabled={pending}>
        {pending ? "Adding…" : "Add field"}
      </Button>
    </form>
  );
}

export function EditFieldForm({ field }: { field: RegistryField }) {
  const [state, action, pending] = useActionState(updateField, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="id" value={field.id} />
      <input type="hidden" name="registry_id" value={field.registry_id} />
      <FieldInputs field={field} idp={field.id.slice(0, 8)} />
      <Toggle name="active" label="Field is in use (untick to retire it; what's been filled in is kept)" defaultChecked={field.active} />
      <Result state={state} />
      <Button variant="outline" className="self-start" disabled={pending}>
        {pending ? "Saving…" : "Save field"}
      </Button>
    </form>
  );
}

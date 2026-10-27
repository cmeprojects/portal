// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useRef } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FieldInput, type Option } from "@/components/field-input";
import { estimateValue, type Details, type Registry, type RegistryField } from "@/lib/registers";
import { saveRecord } from "./actions";

export function RecordForm({
  registry,
  fields,
  people,
  assets,
  record,
  today,
}: {
  registry: Registry;
  fields: RegistryField[];
  people: Option[];
  assets: Option[];
  record?: { id: string; title: string; details: Details; archived: boolean };
  today: string;
}) {
  const [state, action, pending] = useActionState(saveRecord, null);
  const formRef = useRef<HTMLFormElement>(null);
  const keys = new Set(fields.map((f) => f.key));
  const canEstimate = keys.has("purchase_value") && keys.has("purchase_date") && keys.has("current_value");

  function estimate() {
    const form = formRef.current;
    if (!form) return;
    const get = (k: string) => (form.elements.namedItem(`f_${k}`) as HTMLInputElement | null)?.value ?? "";
    const value = Number(get("purchase_value"));
    const date = get("purchase_date");
    if (!value || !date) {
      alert("Fill in the purchase value and purchase date first.");
      return;
    }
    const life = keys.has("useful_life") ? Number(get("useful_life")) || null : null;
    const target = form.elements.namedItem("f_current_value") as HTMLInputElement | null;
    if (target) target.value = String(estimateValue(value, date, life, today));
  }

  return (
    <form ref={formRef} action={action} className="flex flex-col gap-5">
      <input type="hidden" name="registry_id" value={registry.id} />
      <input type="hidden" name="record_id" value={record?.id ?? ""} />
      <Field label={registry.title_label} htmlFor="r-title">
        <input id="r-title" name="title" defaultValue={record?.title} required maxLength={200} className={inputClass} />
      </Field>
      <div className="grid gap-5 md:grid-cols-2">
        {fields.map((f) => (
          <div key={f.id} className={f.type === "long_text" || f.type === "multi_choice" ? "md:col-span-2" : ""}>
            <FieldInput field={f} value={record?.details[f.key]} people={people} assets={assets} />
            {f.key === "current_value" && canEstimate ? (
              <button type="button" onClick={estimate} className="mt-2 min-h-11 text-sm font-semibold text-brand underline">
                Estimate from purchase value and age
              </button>
            ) : null}
          </div>
        ))}
      </div>
      {record ? (
        <label className="flex min-h-11 items-center gap-3 text-sm">
          <input type="checkbox" name="archived" defaultChecked={record.archived} className="h-5 w-5 accent-[var(--brand-primary)]" />
          Archived (no longer in use; kept for the record)
        </label>
      ) : null}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button className="self-start" disabled={pending}>
        {pending ? "Saving…" : record ? "Save changes" : "Add to the list"}
      </Button>
    </form>
  );
}

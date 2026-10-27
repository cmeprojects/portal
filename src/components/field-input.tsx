// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { Field, inputClass } from "@/components/ui";
import type { RegistryField } from "@/lib/registers";

export type Option = { id: string; label: string };

const check = "h-5 w-5 accent-[var(--brand-primary)]";

// One input for a registry's custom field. The input is named f_<key>.
export function FieldInput({
  field,
  value,
  people,
  assets,
}: {
  field: RegistryField;
  value?: unknown;
  people: Option[];
  assets: Option[];
}) {
  const id = `f-${field.registry_id.slice(0, 8)}-${field.key}`;
  const name = `f_${field.key}`;
  const label = field.required ? field.label : `${field.label} (optional)`;
  const hint = field.help || undefined;
  const str = value === undefined || value === null ? "" : String(value);

  if (field.type === "multi_choice") {
    const chosen = Array.isArray(value) ? value.map(String) : [];
    return (
      <fieldset className="flex flex-col gap-1">
        <legend className="mb-1 text-[15px] font-semibold">{label}</legend>
        {field.options.map((o) => (
          <label key={o} className="flex min-h-11 items-center gap-3 text-[15px]">
            <input type="checkbox" name={name} value={o} defaultChecked={chosen.includes(o)} className={check} />
            {o}
          </label>
        ))}
        {hint ? <p className="text-sm text-muted">{hint}</p> : null}
      </fieldset>
    );
  }

  if (field.type === "yes_no") {
    const v = value === true ? "yes" : value === false ? "no" : "";
    return (
      <fieldset>
        <legend className="mb-1.5 text-[15px] font-semibold">{label}</legend>
        <div className="flex gap-2">
          {[
            ["yes", "Yes"],
            ["no", "No"],
          ].map(([val, text]) => (
            <label key={val} className="cursor-pointer">
              <input type="radio" name={name} value={val} defaultChecked={v === val} required={field.required} className="peer sr-only" />
              <span className="inline-flex min-h-11 items-center rounded-full border border-field bg-white px-5 text-[15px] font-semibold peer-checked:border-brand peer-checked:bg-brand peer-checked:text-white peer-focus-visible:outline peer-focus-visible:outline-3 peer-focus-visible:outline-brand-accent">
                {text}
              </span>
            </label>
          ))}
        </div>
        {hint ? <p className="mt-1 text-sm text-muted">{hint}</p> : null}
      </fieldset>
    );
  }

  let input: React.ReactNode;
  switch (field.type) {
    case "long_text":
      input = <textarea id={id} name={name} rows={4} defaultValue={str} required={field.required} className={`${inputClass} h-auto py-3`} />;
      break;
    case "number":
      input = <input id={id} name={name} type="number" step="any" defaultValue={str} required={field.required} className={inputClass} />;
      break;
    case "money":
      input = (
        <div className="relative">
          <span aria-hidden="true" className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">$</span>
          <input id={id} name={name} type="number" step="0.01" min="0" defaultValue={str} required={field.required} className={`${inputClass} pl-7`} />
        </div>
      );
      break;
    case "date":
      input = <input id={id} name={name} type="date" defaultValue={str.slice(0, 10)} required={field.required} className={inputClass} />;
      break;
    case "choice":
      input = (
        <select id={id} name={name} defaultValue={str} required={field.required} className={inputClass}>
          <option value="">{field.required ? "Choose one" : "Not set"}</option>
          {field.options.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      );
      break;
    case "person":
    case "asset": {
      const list = field.type === "person" ? people : assets;
      input = (
        <select id={id} name={name} defaultValue={str} required={field.required} className={inputClass}>
          <option value="">{field.required ? "Choose one" : "Not set"}</option>
          {list.map((o) => (
            <option key={o.id} value={o.id}>
              {o.label}
            </option>
          ))}
        </select>
      );
      break;
    }
    default:
      input = <input id={id} name={name} defaultValue={str} required={field.required} maxLength={500} className={inputClass} />;
  }

  return (
    <Field label={label} htmlFor={id} hint={hint}>
      {input}
    </Field>
  );
}

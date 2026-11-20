// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { useSavableForm } from "@/components/page-save";
import { NeededTag, Req } from "@/components/required";
import { IdInput } from "@/components/id-input";
import { DateInput } from "@/components/date-input";

const CHECKED: Record<string, "phone" | "email" | "ndis" | "mac"> = { phone: "phone", email: "email", ndis_number: "ndis", aged_care_id: "mac" };
// "3/22 Banksia Road, Dulwich Hill NSW 2203" -> street, suburb, postcode (older addresses: all in the street).
function splitAddress(a: string) {
  const m = a.trim().match(/^(.*?),\s*(.+?)\s+(?:NSW|VIC|QLD|WA|SA|TAS|ACT|NT)\s+(\d{4})$/i);
  return m ? { street: m[1], suburb: m[2], postcode: m[3] } : { street: a.trim(), suburb: "", postcode: "" };
}
import type { FieldSpec, SectionTable } from "@/lib/client-sections";
import { recordNoAlerts, saveClientSection } from "./actions";

// cmeprojects (Clients & Care): one form for any client section item. With an
// item it edits it; without, it adds a new one (and clears after adding).
type SectionProps = {
  table: SectionTable;
  clientId: string;
  fields: FieldSpec[];
  item?: Record<string, unknown> & { id?: string };
  choices?: Record<string, [string, string][]>;
  submit: string;
  // Fields that can wait, but are needed before services start (for example the NDIS number).
  needed?: string[];
  // Show which fields are mandatory (the basic fields only).
  marks?: boolean;
  // Fields that don't apply to this client (for example the My Aged Care ID for an NDIS participant).
  notApplicable?: string[];
};

export function SectionForm(props: SectionProps) {
  // A new item clears after it's added: a fresh form (and fresh change tracking) each time.
  const [round, setRound] = useState(0);
  return <SectionFormInner key={round} {...props} onAdded={() => setRound((r) => r + 1)} />;
}

function SectionFormInner({ table, clientId, fields, item, choices = {}, submit, needed = [], marks = false, notApplicable = [], onAdded }: SectionProps & { onAdded: () => void }) {
  // Saved by its own button, or by the page's one Save (owner, 19 Nov 2026).
  const { state, pending, ref, dirty, onSubmit, pageSave } = useSavableForm(saveClientSection, {
    label: item?.id ? `${submit.replace(/^Save /, "")}` : submit.replace(/^Add /, "new "),
    onSaved: () => {
      if (!item?.id && table !== "client_details") onAdded();
    },
  });
  const value = (f: FieldSpec) => {
    const v = item?.[f.name];
    if (!item?.id && v === undefined) return f.def ?? "";
    return v === null || v === undefined ? "" : Array.isArray(v) ? v.join(", ") : String(v);
  };
  return (
    <form ref={ref} onSubmit={onSubmit} className="flex flex-col gap-3">
      <input type="hidden" name="table" value={table} />
      <input type="hidden" name="client_id" value={clientId} />
      {item?.id ? <input type="hidden" name="id" value={item.id} /> : null}
      <div className="grid gap-3 sm:grid-cols-2">
        {fields.map((f) => {
          const id = `${table}-${item?.id ?? "new"}-${f.name}`;
          if (f.type === "checkbox") {
            return (
              <label key={f.name} className="flex min-h-9 items-center gap-2 text-sm sm:col-span-2">
                <input
                  type="checkbox"
                  name={f.name}
                  defaultChecked={item ? Boolean(item[f.name]) : Boolean(f.defaultOn)}
                  className="h-4 w-4 accent-[var(--brand-primary)]"
                />
                {f.label}
              </label>
            );
          }
          // The home address in its parts (owner, 20 Nov 2026): street, suburb and postcode (state is its own field).
          if (table === "client_details" && f.name === "home_address") {
            const parts = splitAddress(value(f));
            const star = marks && f.required ? <Req /> : null;
            return (
              <div key={f.name} className="grid gap-3 sm:col-span-2 sm:grid-cols-[2fr_1fr_8rem]">
                <label className="flex flex-col gap-1 text-xs font-medium">
                  <span>Street address{star}</span>
                  <input name="home_street" required={f.required} maxLength={200} defaultValue={parts.street} placeholder="Unit 3/22 Banksia Road" className={inputClass} />
                </label>
                <label className="flex flex-col gap-1 text-xs font-medium">
                  <span>Suburb{star}</span>
                  <input name="home_suburb" required={f.required} maxLength={60} defaultValue={parts.suburb} placeholder="Dulwich Hill" className={inputClass} />
                </label>
                <label className="flex flex-col gap-1 text-xs font-medium">
                  <span>Postcode{star}</span>
                  <input name="home_postcode" required={f.required} inputMode="numeric" pattern="\d{4}" maxLength={4} title="4 numbers" defaultValue={parts.postcode} placeholder="2203" className={inputClass} />
                </label>
              </div>
            );
          }
          const opts = f.options ?? choices[f.name] ?? [];
          return (
            <label key={f.name} htmlFor={id} className={`flex flex-col gap-1 text-xs font-medium ${f.type === "textarea" ? "sm:col-span-2" : ""}`}>
              <span>
                {f.label}
                {notApplicable.includes(f.name) ? (
                  <span className="ml-1.5 rounded-full bg-line px-1.5 py-0.5 text-[10px] font-semibold text-muted">Not applicable</span>
                ) : (
                  <>
                    {marks && f.required ? <Req /> : null}
                    {marks && !f.required && needed.includes(f.name) ? <NeededTag /> : null}
                  </>
                )}
              </span>
              {f.type === "textarea" ? (
                <textarea id={id} name={f.name} maxLength={f.max} defaultValue={value(f)} rows={2} className={inputClass} />
              ) : f.type === "select" ? (
                <select id={id} name={f.name} defaultValue={value(f) || opts[0]?.[0]} required={f.required} className={inputClass}>
                  {opts.map(([k, label]) => (
                    <option key={k} value={k}>
                      {label}
                    </option>
                  ))}
                </select>
              ) : CHECKED[f.name] ? (
                // Checked as it's typed: Australian numbers, emails, NDIS number, My Aged Care ID.
                <IdInput id={id} kind={CHECKED[f.name]} name={f.name} required={f.required} disabled={notApplicable.includes(f.name)} defaultValue={value(f)} />
              ) : f.type === "date" ? (
                <DateInput id={id} name={f.name} required={f.required} disabled={notApplicable.includes(f.name)} max={f.name === "date_of_birth" ? new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" }) : undefined} defaultValue={value(f)} />
              ) : (
                <input id={id} name={f.name} type="text" required={f.required} disabled={notApplicable.includes(f.name)} maxLength={f.max} max={f.name === "date_of_birth" ? new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" }) : undefined} defaultValue={value(f)} className={inputClass} />
              )}
              {f.hint ? <span className="font-normal text-muted">{f.hint}</span> : null}
            </label>
          );
        })}
      </div>
      <div className="flex flex-wrap items-center gap-3">
        {pageSave ? null : (
          <Button size="sm" variant={item?.id ? "outline" : undefined} disabled={pending || (Boolean(item?.id) && !dirty)}>
            {pending ? "Saving…" : submit}
          </Button>
        )}
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message && !pageSave ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export function NoAlertsButton({ clientId }: { clientId: string }) {
  const [state, action, pending] = useActionState(recordNoAlerts, null);
  return (
    <form action={action} className="flex flex-wrap items-center gap-3">
      <input type="hidden" name="client_id" value={clientId} />
      <Button size="sm" variant="outline" disabled={pending}>
        {pending ? "Saving…" : "Record: no known safety alerts"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveCatalogueService } from "./actions";

type Choice = [string, string];
export type CatalogueRow = { id: string; name: string; description: string; classification: string; schemes: string[]; shift_types: string[]; active: boolean };
const lab = "text-xs font-semibold text-ink";

export function CatalogueForm({ item, schemes, shiftTypes }: { item?: CatalogueRow; schemes: Choice[]; shiftTypes: Choice[] }) {
  const [state, action, pending] = useActionState(saveCatalogueService, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      {item ? <input type="hidden" name="id" value={item.id} /> : null}
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="flex flex-col gap-1">
          <span className={lab}>Service name</span>
          <input name="name" required maxLength={80} defaultValue={item?.name ?? ""} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Classification (optional)</span>
          <input name="classification" maxLength={60} defaultValue={item?.classification ?? ""} placeholder="e.g. Core supports" className={inputClass} />
        </label>
      </div>
      <label className="flex flex-col gap-1">
        <span className={lab}>Description</span>
        <textarea name="description" maxLength={1000} rows={2} defaultValue={item?.description ?? ""} className={`${inputClass} h-auto py-2`} />
      </label>
      <fieldset className="flex flex-col gap-1">
        <legend className={lab}>Offered under (none ticked: every program)</legend>
        <div className="flex flex-wrap gap-x-4">
          {schemes.map(([k, l]) => (
            <label key={k} className="inline-flex min-h-8 items-center gap-2 text-sm">
              <input type="checkbox" name="schemes" value={k} defaultChecked={item?.schemes.includes(k)} className="size-4" /> {l}
            </label>
          ))}
        </div>
      </fieldset>
      <fieldset className="flex flex-col gap-1">
        <legend className={lab}>Shift types it covers</legend>
        <div className="flex flex-wrap gap-x-4 gap-y-1">
          {shiftTypes.map(([k, l]) => (
            <label key={k} className="inline-flex min-h-8 items-center gap-2 text-sm">
              <input type="checkbox" name="shift_types" value={k} defaultChecked={item?.shift_types.includes(k)} className="size-4" /> {l}
            </label>
          ))}
        </div>
      </fieldset>
      {item ? (
        <label className="inline-flex items-center gap-2 text-sm">
          <input type="checkbox" name="active" defaultChecked={item.active} className="size-4" /> Offered (untick to switch off; clients keep the service they have)
        </label>
      ) : null}
      <div className="flex items-center gap-2">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : item ? "Save" : "Add to the catalogue"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

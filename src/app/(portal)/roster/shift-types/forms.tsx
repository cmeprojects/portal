// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveShiftType } from "./actions";

const USES: [string, string][] = [
  ["client", "Client shifts"],
  ["internal", "Internal work (no client)"],
  ["both", "Both"],
];
function UsedFor({ value }: { value?: string }) {
  if (value === undefined) return null; // before update 142
  return (
    <select name="used_for" defaultValue={value} aria-label="Used for" className={`${inputClass.replace("w-full", "").replace("h-11", "")} h-9 w-52`}>
      {USES.map(([k, l]) => (
        <option key={k} value={k}>
          {l}
        </option>
      ))}
    </select>
  );
}

export function ShiftTypeRow({ type, items }: { type: { key: string; label: string; active: boolean; used: number; used_for?: string; required_items?: string[] }; items: [string, string][] }) {
  const [state, action, pending] = useActionState(saveShiftType, null);
  return (
    <form action={action} className="flex flex-wrap items-center gap-3 px-4 py-2.5">
      <input type="hidden" name="key" value={type.key} />
      <input name="label" defaultValue={type.label} maxLength={60} aria-label="Name" className={`${inputClass} h-9 max-w-72 flex-1`} />
      <UsedFor value={type.used_for} />
      <label className="inline-flex items-center gap-2 text-sm">
        <input type="checkbox" name="active" defaultChecked={type.active} className="size-4" /> In use
      </label>
      <span className="text-xs text-muted">{type.used ? `${type.used} shift${type.used === 1 ? "" : "s"}` : "Not used yet"}</span>
      {type.required_items !== undefined && items.length ? (
        <details className="w-full">
          <input type="hidden" name="has_items" value="1" />
          <summary className="cursor-pointer text-xs font-semibold text-brand">
            Qualifications needed{type.required_items.length ? `: ${items.filter(([id]) => type.required_items!.includes(id)).map(([, t]) => t).join(", ")}` : " (none)"}
          </summary>
          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1">
            {items.map(([id, t]) => (
              <label key={id} className="inline-flex min-h-8 items-center gap-2 text-sm">
                <input type="checkbox" name="required_items" value={id} defaultChecked={type.required_items!.includes(id)} className="size-4" /> {t}
              </label>
            ))}
          </div>
          <p className="mt-1 text-xs text-muted">Only workers who hold these (and not expired) can be given this type of shift.</p>
        </details>
      ) : null}
      <Button size="sm" variant="outline" disabled={pending}>
        {pending ? "Saving…" : "Save"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

export function AddShiftTypeForm({ withUse }: { withUse: boolean }) {
  const [state, action, pending] = useActionState(saveShiftType, null);
  return (
    <form action={action} className="flex flex-wrap items-end gap-2">
      <label className="flex max-w-80 flex-1 flex-col gap-1 text-xs font-semibold">
        New shift type
        <input name="label" required maxLength={60} placeholder="e.g. Hydrotherapy" className={inputClass} />
      </label>
      {withUse ? <UsedFor value="client" /> : null}
      <Button size="sm" disabled={pending}>
        {pending ? "Adding…" : "Add"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

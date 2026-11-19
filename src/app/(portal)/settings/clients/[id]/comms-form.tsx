// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { COMMS_CONTACT_WAYS as CONTACT_WAYS } from "@/lib/client-sections";

import { Button, Notice, inputClass } from "@/components/ui";
import { saveComms } from "./actions";
import { useSavableForm } from "@/components/page-save";

export type Comms = { preferred_contact: string; language: string; interpreter_needed: boolean; accessibility_needs: string; notes: string };

// cmeprojects (Care block C2): how to communicate with this client.
export function CommsForm({ clientId, comms }: { clientId: string; comms: Comms | null }) {
  // Saved by its own button (greyed out until something changes), or by the page's one Save.
  const { state, pending, ref, dirty, onSubmit, pageSave } = useSavableForm(saveComms, { label: "Communication preferences" });
  return (
    <form ref={ref} onSubmit={onSubmit} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-3">
        <label className="flex flex-col gap-1 text-xs font-medium">
          Preferred contact
          <select name="preferred_contact" defaultValue={comms?.preferred_contact ?? ""} className={inputClass}>
            {CONTACT_WAYS.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Language
          <input name="language" maxLength={60} defaultValue={comms?.language ?? ""} placeholder="e.g. English, Arabic" className={inputClass} />
        </label>
        <label className="flex min-h-9 items-center gap-2 self-end text-sm">
          <input type="checkbox" name="interpreter_needed" defaultChecked={comms?.interpreter_needed ?? false} className="h-4 w-4 accent-[var(--brand-primary)]" />
          Needs an interpreter
        </label>
      </div>
      <label className="flex flex-col gap-1 text-xs font-medium">
        Accessibility or communication needs
        <textarea name="accessibility_needs" maxLength={1000} rows={2} defaultValue={comms?.accessibility_needs ?? ""} className={inputClass} />
      </label>
      <label className="flex flex-col gap-1 text-xs font-medium">
        Notes
        <textarea name="notes" maxLength={1000} rows={2} defaultValue={comms?.notes ?? ""} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        {pageSave ? null : (
          <Button size="sm" disabled={pending || !dirty}>
            {pending ? "Saving…" : "Save"}
          </Button>
        )}
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message && !pageSave ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

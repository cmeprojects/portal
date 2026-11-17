// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { PRACTITIONER_SECTIONS } from "@/lib/client-sections";
import { extendPractitionerAccess, givePractitionerAccess } from "./actions";

const field = "flex flex-col gap-1 text-xs font-medium";

function Sections({ chosen }: { chosen: string[] }) {
  return (
    <fieldset className="flex flex-col gap-1">
      <legend className="mb-1 text-xs font-medium">What they can see (their own reports and notes always)</legend>
      {PRACTITIONER_SECTIONS.map(([v, l]) => (
        <label key={v} className="inline-flex items-center gap-2 text-sm">
          <input type="checkbox" name="sections" value={v} defaultChecked={chosen.includes(v)} /> {l}
        </label>
      ))}
    </fieldset>
  );
}

// cmeprojects (update 124): give an Allied Health practitioner access to this client.
export function GiveAccessForm({ clientId, people, documents, today, defaultEnd, maxEnd }: { clientId: string; people: [string, string][]; documents: [string, string][]; today: string; defaultEnd: string; maxEnd: string }) {
  const [state, action, pending] = useActionState(givePractitionerAccess, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Practitioner
          <select name="user_id" required className={inputClass} defaultValue="">
            <option value="" disabled>
              {people.length ? "Choose…" : "No practitioner accounts yet: invite one as External"}
            </option>
            {people.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className={field}>
          Access ends (6 months suggested, 12 at most)
          <input type="date" name="ends_on" required min={today} max={maxEnd} defaultValue={defaultEnd} className={inputClass} />
        </label>
        <label className={field}>
          Date the client (or their representative) agreed
          <input type="date" name="consent_on" required max={today} defaultValue={today} className={inputClass} />
        </label>
        <label className={field}>
          Consent document (optional)
          <select name="consent_document_id" className={inputClass} defaultValue="">
            <option value="">None</option>
            {documents.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className={`${field} sm:col-span-2`}>
          How consent was given, and why they need access
          <input name="reason" maxLength={500} placeholder="e.g. Verbal consent from Zara at the 12 Nov review; OT assessment for home modifications" className={inputClass} />
        </label>
      </div>
      <Sections chosen={["details", "alerts", "care_plan", "documents"]} />
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending || !people.length}>
          {pending ? "Saving…" : "Give access"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export function ExtendAccessForm({ id, clientId, endsOn, sections, today, maxEnd }: { id: string; clientId: string; endsOn: string; sections: string[]; today: string; maxEnd: string }) {
  const [state, action, pending] = useActionState(extendPractitionerAccess, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="client_id" value={clientId} />
      <label className={`${field} max-w-60`}>
        Access ends (12 months from today at most)
        <input type="date" name="ends_on" required min={today} max={maxEnd} defaultValue={endsOn} className={inputClass} />
      </label>
      <Sections chosen={sections} />
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Save"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

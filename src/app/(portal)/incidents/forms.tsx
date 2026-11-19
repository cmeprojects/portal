// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, REPORTABLE } from "@/lib/incidents";
import { addIncidentNote, reportIncident, updateIncident } from "./actions";

const lab = "text-xs font-semibold text-ink";
const nowLocal = () => new Date().toLocaleString("sv-SE", { timeZone: "Australia/Sydney" }).slice(0, 16).replace(" ", "T");
const toLocal = (iso: string | null) => (iso ? new Date(iso).toLocaleString("sv-SE", { timeZone: "Australia/Sydney" }).slice(0, 16).replace(" ", "T") : "");

export function ReportIncidentForm({ clientId, clients, openAfter = true }: { clientId?: string; clients?: [string, string][]; openAfter?: boolean }) {
  const [state, action, pending] = useActionState(reportIncident, null);
  const router = useRouter();
  useEffect(() => {
    if (state?.spotlight && openAfter) router.push(`/incidents/${state.spotlight}`);
  }, [state, router, openAfter]);
  return (
    <form action={action} className="flex flex-col gap-3">
      {clientId ? (
        <input type="hidden" name="client_id" value={clientId} />
      ) : (
        <label className="flex flex-col gap-1">
          <span className={lab}>Client</span>
          <select name="client_id" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose the client
            </option>
            {(clients ?? []).map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
      )}
      <div className="grid gap-3 sm:grid-cols-3">
        <label className="flex flex-col gap-1">
          <span className={lab}>What happened</span>
          <select name="kind" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose
            </option>
            {INCIDENT_KINDS.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>How serious</span>
          <select name="severity" required defaultValue="medium" className={inputClass}>
            {INCIDENT_SEVERITY.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>When</span>
          <input type="datetime-local" name="occurred_at" defaultValue={nowLocal()} max={nowLocal()} className={inputClass} />
        </label>
      </div>
      <label className="flex flex-col gap-1">
        <span className={lab}>Describe what happened</span>
        <textarea name="summary" required maxLength={4000} rows={4} className={`${inputClass} h-auto py-2`} />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>What was done straight away (optional)</span>
        <textarea name="immediate_action" maxLength={2000} rows={2} className={`${inputClass} h-auto py-2`} />
      </label>
      <div className="flex items-center gap-2">
        <Button size="sm" disabled={pending}>
          {pending ? "Reporting…" : "Report incident"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message && !openAfter ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export type IncidentRow = {
  id: string;
  kind: string;
  severity: string;
  immediate_action: string;
  reportable: boolean;
  reportable_category: string | null;
  reported_to_regulator_at: string | null;
  regulator_ref: string;
  outcome: string;
  status: string;
};

export function IncidentEditForm({ inc }: { inc: IncidentRow }) {
  const [state, action, pending] = useActionState(updateIncident, null);
  const [reportable, setReportable] = useState(inc.reportable);
  const closed = inc.status === "closed";
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={inc.id} />
      <fieldset disabled={closed} className="flex flex-col gap-3">
        <div className="grid gap-3 sm:grid-cols-2">
          <label className="flex flex-col gap-1">
            <span className={lab}>What happened</span>
            <select name="kind" defaultValue={inc.kind} className={inputClass}>
              {INCIDENT_KINDS.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-1">
            <span className={lab}>How serious</span>
            <select name="severity" defaultValue={inc.severity} className={inputClass}>
              {INCIDENT_SEVERITY.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
        </div>
        <label className="flex flex-col gap-1">
          <span className={lab}>What was done straight away</span>
          <textarea name="immediate_action" maxLength={2000} rows={2} defaultValue={inc.immediate_action} className={`${inputClass} h-auto py-2`} />
        </label>
        <div className="flex flex-col gap-2 rounded-lg border border-line p-3">
          <label className="inline-flex items-center gap-2 text-sm font-medium">
            <input type="checkbox" name="reportable" checked={reportable} onChange={(e) => setReportable(e.target.checked)} className="size-4" /> NDIS reportable incident
          </label>
          {reportable ? (
            <>
              <label className="flex flex-col gap-1">
                <span className={lab}>Category</span>
                <select name="reportable_category" required defaultValue={inc.reportable_category ?? ""} className={inputClass}>
                  <option value="" disabled>
                    Choose the category
                  </option>
                  {REPORTABLE.map(([v, l]) => (
                    <option key={v} value={v}>
                      {l}
                    </option>
                  ))}
                </select>
                <span className="text-xs text-muted">Due to the NDIS Commission within 24 hours of staff becoming aware (5 business days for unauthorised restrictive practice with no harm). Check the Commission&apos;s rules for your case.</span>
              </label>
              <div className="grid gap-3 sm:grid-cols-2">
                <label className="flex flex-col gap-1">
                  <span className={lab}>Reported to the Commission on</span>
                  <input type="datetime-local" name="reported_to_regulator_at" defaultValue={toLocal(inc.reported_to_regulator_at)} max={nowLocal()} className={inputClass} />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={lab}>Commission reference</span>
                  <input name="regulator_ref" maxLength={60} defaultValue={inc.regulator_ref} className={inputClass} />
                </label>
              </div>
            </>
          ) : null}
        </div>
        <label className="flex flex-col gap-1">
          <span className={lab}>Outcome (needed to close)</span>
          <textarea name="outcome" maxLength={4000} rows={3} defaultValue={inc.outcome} placeholder="What was found, what changed, who was told" className={`${inputClass} h-auto py-2`} />
        </label>
      </fieldset>
      {closed ? null : (
        <div className="flex flex-wrap items-center gap-2">
          <Button size="sm" disabled={pending}>
            {pending ? "Saving…" : "Save"}
          </Button>
          <Button size="sm" variant="outline" name="close" value="1" disabled={pending}>
            Save and close the incident
          </Button>
          {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
          {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
        </div>
      )}
    </form>
  );
}

export function IncidentNoteForm({ id }: { id: string }) {
  const [state, action, pending] = useActionState(addIncidentNote, null);
  return (
    <form action={action} key={state?.message ?? "note"} className="flex flex-col gap-2">
      <input type="hidden" name="id" value={id} />
      <textarea name="body" required maxLength={4000} rows={2} placeholder="Add a note to the timeline (calls made, who was told, what was found)" className={`${inputClass} h-auto py-2`} />
      <div className="flex items-center gap-2">
        <Button size="sm" variant="outline" disabled={pending}>
          {pending ? "Adding…" : "Add note"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      </div>
    </form>
  );
}

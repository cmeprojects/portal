// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, REPORTABLE } from "@/lib/incidents";
import { addIncidentAction, addIncidentNote, reportIncident, saveCommissionReport, saveInvestigation, setActionDone, signOffIncident, triageIncident } from "./actions";

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
        <span className={lab}>Where (optional)</span>
        <input name="location" maxLength={200} placeholder="For example: bathroom at home, shopping centre car park" className={inputClass} />
      </label>
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
  location: string;
  immediate_action: string;
  status: string;
  investigator_id: string | null;
  reportable: boolean;
  reportable_category: string | null;
  reported_to_regulator_at: string | null;
  regulator_ref: string;
  staff_involved: string | null;
  witnesses: string;
  findings: string;
  contributing_factors: string;
  family_told_at: string | null;
  family_told_note: string;
  outcome: string;
};
type Staff = [string, string][];
const area = `${inputClass} h-auto py-2`;

function Msg({ state }: { state: { error?: string; message?: string } | null }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

function Pick({ name, staff, value, placeholder, required }: { name: string; staff: Staff; value: string | null; placeholder: string; required?: boolean }) {
  return (
    <select name={name} defaultValue={value ?? ""} required={required} className={inputClass}>
      <option value="">{placeholder}</option>
      {staff.map(([v, l]) => (
        <option key={v} value={v}>
          {l}
        </option>
      ))}
    </select>
  );
}

// Step 2: triage (a manager).
export function TriageForm({ inc, staff }: { inc: IncidentRow; staff: Staff }) {
  const [state, action, pending] = useActionState(triageIncident, null);
  const [reportable, setReportable] = useState(inc.reportable);
  const isNew = inc.status === "new";
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={inc.id} />
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
        <label className="flex flex-col gap-1">
          <span className={lab}>Where</span>
          <input name="location" maxLength={200} defaultValue={inc.location} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Who will investigate</span>
          <Pick name="investigator_id" staff={staff} value={inc.investigator_id} placeholder="Choose a staff member" />
        </label>
      </div>
      <label className="flex flex-col gap-1">
        <span className={lab}>What was done straight away</span>
        <textarea name="immediate_action" maxLength={2000} rows={2} defaultValue={inc.immediate_action} className={area} />
      </label>
      <div className="flex flex-col gap-2 rounded-lg border border-line p-3">
        <span className={lab}>Is it an NDIS reportable incident?</span>
        <label className="inline-flex items-center gap-2 text-sm">
          <input type="checkbox" name="reportable" checked={reportable} onChange={(e) => setReportable(e.target.checked)} className="size-4" /> Yes, it must be reported to the NDIS Commission
        </label>
        {reportable ? (
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
            <span className="text-xs text-muted">Due within 24 hours of staff becoming aware (5 business days for unauthorised restrictive practice with no harm). Check the Commission&apos;s rules for your case.</span>
          </label>
        ) : null}
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {isNew ? (
          <Button size="sm" name="start" value="1" disabled={pending}>
            {pending ? "Saving…" : "Save and start the investigation"}
          </Button>
        ) : null}
        <Button size="sm" variant={isNew ? "outline" : "primary"} disabled={pending}>
          {isNew ? "Save for now" : "Save"}
        </Button>
        <Msg state={state} />
      </div>
    </form>
  );
}

// Step 3: the investigation (the investigator or a manager).
export function InvestigationForm({ inc, staff, canSend }: { inc: IncidentRow; staff: Staff; canSend: boolean }) {
  const [state, action, pending] = useActionState(saveInvestigation, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={inc.id} />
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="flex flex-col gap-1">
          <span className={lab}>Staff member involved</span>
          <Pick name="staff_involved" staff={staff} value={inc.staff_involved} placeholder="None or not known" />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Witnesses</span>
          <input name="witnesses" maxLength={1000} defaultValue={inc.witnesses} className={inputClass} />
        </label>
      </div>
      <label className="flex flex-col gap-1">
        <span className={lab}>What the investigation found</span>
        <textarea name="findings" maxLength={4000} rows={4} defaultValue={inc.findings} placeholder="What happened and why, from the people involved and the records" className={area} />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Contributing factors</span>
        <textarea name="contributing_factors" maxLength={2000} rows={2} defaultValue={inc.contributing_factors} placeholder="Environment, equipment, training, communication, health…" className={area} />
      </label>
      <div className="grid gap-3 rounded-lg border border-line p-3 sm:grid-cols-[14rem_1fr]">
        <label className="flex flex-col gap-1">
          <span className={lab}>Client or family told on</span>
          <input type="datetime-local" name="family_told_at" defaultValue={toLocal(inc.family_told_at)} max={nowLocal()} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Who was told and how (or why they weren&apos;t)</span>
          <input name="family_told_note" maxLength={1000} defaultValue={inc.family_told_note} className={inputClass} />
        </label>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <Button size="sm" variant="outline" disabled={pending}>
          {pending ? "Saving…" : "Save"}
        </Button>
        {canSend ? (
          <Button size="sm" name="send" value="1" disabled={pending}>
            Send for sign-off
          </Button>
        ) : null}
        <Msg state={state} />
      </div>
    </form>
  );
}

export function CommissionForm({ inc }: { inc: IncidentRow }) {
  const [state, action, pending] = useActionState(saveCommissionReport, null);
  return (
    <form action={action} className="flex flex-wrap items-end gap-2">
      <input type="hidden" name="id" value={inc.id} />
      <label className="flex flex-col gap-1">
        <span className={lab}>Reported to the Commission on</span>
        <input type="datetime-local" name="reported_to_regulator_at" required defaultValue={toLocal(inc.reported_to_regulator_at)} max={nowLocal()} className={inputClass} />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Commission reference</span>
        <input name="regulator_ref" maxLength={60} defaultValue={inc.regulator_ref} className={inputClass} />
      </label>
      <Button size="sm" variant="outline" disabled={pending}>
        {pending ? "Saving…" : "Save"}
      </Button>
      <Msg state={state} />
    </form>
  );
}

// Step 4: manager sign-off.
export function SignOffForm({ inc }: { inc: IncidentRow }) {
  const [state, action, pending] = useActionState(signOffIncident, null);
  const [back, setBack] = useState(false);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={inc.id} />
      <label className="flex flex-col gap-1">
        <span className={lab}>Outcome</span>
        <textarea name="outcome" maxLength={4000} rows={3} defaultValue={inc.outcome} placeholder="What was decided, what changed, and who was told" className={area} />
      </label>
      {back ? (
        <label className="flex flex-col gap-1">
          <span className={lab}>What more is needed</span>
          <textarea name="back_reason" required maxLength={2000} rows={2} className={area} />
        </label>
      ) : null}
      <div className="flex flex-wrap items-center gap-2">
        {back ? (
          <>
            <Button size="sm" name="decision" value="back" disabled={pending}>
              Send back to the investigator
            </Button>
            <Button size="sm" variant="outline" type="button" onClick={() => setBack(false)}>
              Cancel
            </Button>
          </>
        ) : (
          <>
            <Button size="sm" name="decision" value="close" disabled={pending}>
              {pending ? "Signing off…" : "Sign off and close"}
            </Button>
            <Button size="sm" variant="outline" type="button" onClick={() => setBack(true)}>
              Send back
            </Button>
          </>
        )}
        <Msg state={state} />
      </div>
    </form>
  );
}

export function ActionAddForm({ incidentId, staff }: { incidentId: string; staff: Staff }) {
  const [state, action, pending] = useActionState(addIncidentAction, null);
  const today = nowLocal().slice(0, 10);
  return (
    <form action={action} key={state?.message ?? "add"} className="grid gap-2 sm:grid-cols-[1fr_12rem_10rem_auto] sm:items-end">
      <input type="hidden" name="incident_id" value={incidentId} />
      <label className="flex flex-col gap-1">
        <span className={lab}>Action</span>
        <input name="action" required maxLength={500} placeholder="For example: review the bathroom routine with the family" className={inputClass} />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Who</span>
        <Pick name="owner_id" staff={staff} value={null} placeholder="Choose" required />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Due</span>
        <input type="date" name="due_on" required min={today} className={inputClass} />
      </label>
      <Button size="sm" variant="outline" disabled={pending}>
        {pending ? "Adding…" : "Add"}
      </Button>
      <div className="sm:col-span-4">
        <Msg state={state?.error ? state : null} />
      </div>
    </form>
  );
}

export function ActionDoneForm({ id, incidentId, done }: { id: string; incidentId: string; done: boolean }) {
  const [state, action, pending] = useActionState(setActionDone, null);
  const [open, setOpen] = useState(false);
  if (done)
    return (
      <form action={action}>
        <input type="hidden" name="id" value={id} />
        <input type="hidden" name="incident_id" value={incidentId} />
        <button className="text-xs font-medium text-muted hover:text-ink" disabled={pending}>
          Mark not done
        </button>
      </form>
    );
  return open ? (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="incident_id" value={incidentId} />
      <input type="hidden" name="done" value="1" />
      <input name="done_note" maxLength={1000} placeholder="What was done (optional)" className={`${inputClass} h-8 w-56`} />
      <Button size="sm" disabled={pending}>
        Done
      </Button>
      <Msg state={state?.error ? state : null} />
    </form>
  ) : (
    <Button size="sm" variant="outline" type="button" onClick={() => setOpen(true)}>
      Mark done
    </Button>
  );
}

export function IncidentNoteForm({ id }: { id: string }) {
  const [state, action, pending] = useActionState(addIncidentNote, null);
  return (
    <form action={action} key={state?.message ?? "note"} className="flex flex-col gap-2">
      <input type="hidden" name="id" value={id} />
      <textarea name="body" required maxLength={4000} rows={2} placeholder="Add a note to the timeline (calls made, who was told, what was found)" className={area} />
      <div className="flex items-center gap-2">
        <Button size="sm" variant="outline" disabled={pending}>
          {pending ? "Adding…" : "Add note"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      </div>
    </form>
  );
}

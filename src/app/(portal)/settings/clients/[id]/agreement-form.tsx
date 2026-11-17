// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveAgreement } from "./actions";

export type Agreement = { id: string; service_id: string; scheme: string; status: string; starts_on: string; ends_on: string | null; signed_on: string | null; signed_by_name: string; document_id: string | null; notes: string };
const field = "flex flex-col gap-1 text-xs font-medium";

function Doc({ documents, value }: { documents: [string, string][]; value?: string | null }) {
  if (!documents.length) return null;
  return (
    <label className={field}>
      Document (optional)
      <select name="document_id" defaultValue={value ?? ""} className={inputClass}>
        <option value="">None</option>
        {documents.map(([v, l]) => (
          <option key={v} value={v}>
            {l}
          </option>
        ))}
      </select>
    </label>
  );
}

// cmeprojects (Care block C6): an agreement before it's signed (new or changed).
export function AgreementForm({ clientId, agreement, services, documents }: { clientId: string; agreement?: Agreement; services: [string, string][]; documents: [string, string][] }) {
  const [state, action, pending] = useActionState(saveAgreement, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      {agreement ? <input type="hidden" name="id" value={agreement.id} /> : null}
      <div className="grid gap-2 sm:grid-cols-2">
        {agreement ? null : (
          <label className={field}>
            Service
            <select name="service_id" required className={inputClass}>
              {services.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
        )}
        <label className={field}>
          Status
          <select name="status" defaultValue={agreement?.status ?? "draft"} className={inputClass}>
            <option value="draft">Draft</option>
            <option value="sent">Sent for signing</option>
          </select>
        </label>
        <label className={field}>
          Starts on
          <input type="date" name="starts_on" required defaultValue={agreement?.starts_on ?? ""} className={inputClass} />
        </label>
        <label className={field}>
          Ends on (optional)
          <input type="date" name="ends_on" defaultValue={agreement?.ends_on ?? ""} className={inputClass} />
        </label>
        <Doc documents={documents} value={agreement?.document_id} />
      </div>
      <label className={field}>
        Notes
        <textarea name="notes" maxLength={1000} rows={2} defaultValue={agreement?.notes ?? ""} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : agreement ? "Save" : "Add agreement"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export function SignAgreementForm({ clientId, agreementId, documents }: { clientId: string; agreementId: string; documents: [string, string][] }) {
  const [state, action, pending] = useActionState(saveAgreement, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="id" value={agreementId} />
      <input type="hidden" name="step" value="sign" />
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Signed on
          <input type="date" name="signed_on" required className={inputClass} />
        </label>
        <label className={field}>
          Signed by
          <input name="signed_by_name" required maxLength={120} placeholder="Name of the person or their representative" className={inputClass} />
        </label>
        <Doc documents={documents} />
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Record as signed"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

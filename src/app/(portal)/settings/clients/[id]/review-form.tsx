// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { addClientReview, closeClientReview } from "./actions";

export type SchemeWords = { key: string; label: string; review_label: string; change_review_label: string };
const field = "flex flex-col gap-1 text-xs font-medium";

// cmeprojects (Care block C5): schedule a review, or raise a change of
// situation. The review's name follows the scheme (NDIS: Plan review /
// Change of situation; Support at Home: Re-assessment ...).
export function ReviewForm({ clientId, kind, services, schemes }: { clientId: string; kind: "scheduled" | "change_of_situation"; services: { id: string; label: string; scheme: string }[]; schemes: SchemeWords[] }) {
  const [state, action, pending] = useActionState(addClientReview, null);
  const [serviceId, setServiceId] = useState(services[0]?.id ?? "");
  const [scheme, setScheme] = useState(schemes[0]?.key ?? "other");
  const chosen = schemes.find((s) => s.key === (serviceId ? services.find((v) => v.id === serviceId)?.scheme : scheme));
  const name = chosen ? (kind === "scheduled" ? chosen.review_label : chosen.change_review_label) : "Review";
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="kind" value={kind} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Service
          <select name="service_id" value={serviceId} onChange={(e) => setServiceId(e.target.value)} className={inputClass}>
            {services.map((s) => (
              <option key={s.id} value={s.id}>
                {s.label} ({schemes.find((k) => k.key === s.scheme)?.label ?? s.scheme})
              </option>
            ))}
            <option value="">Not for one service: choose the scheme</option>
          </select>
        </label>
        {serviceId ? null : (
          <label className={field}>
            Scheme
            <select name="scheme" value={scheme} onChange={(e) => setScheme(e.target.value)} className={inputClass}>
              {schemes.map((s) => (
                <option key={s.key} value={s.key}>
                  {s.label}
                </option>
              ))}
            </select>
          </label>
        )}
        {kind === "scheduled" ? (
          <label className={field}>
            Due on
            <input type="date" name="due_on" required className={inputClass} />
          </label>
        ) : null}
      </div>
      {kind === "change_of_situation" ? (
        <label className={field}>
          What changed (kept on this page only; reminders don&apos;t include it)
          <textarea name="reason" required maxLength={1000} rows={3} className={inputClass} />
        </label>
      ) : null}
      <p className="text-xs text-muted">
        This will be a <span className="font-semibold">{name}</span>
        {chosen ? ` (${chosen.label})` : ""}
        {kind === "change_of_situation" ? ", due today. The care manager or support coordinator is told straight away." : "."}
      </p>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : kind === "scheduled" ? `Add ${name.toLowerCase()}` : `Raise ${name.toLowerCase()}`}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export function CloseReviewForm({ clientId, reviewId, documents }: { clientId: string; reviewId: string; documents: [string, string][] }) {
  const [state, action, pending] = useActionState(closeClientReview, null);
  const [status, setStatus] = useState("completed");
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="id" value={reviewId} />
      <div className="grid gap-2 sm:grid-cols-3">
        <label className={field}>
          Close as
          <select name="status" value={status} onChange={(e) => setStatus(e.target.value)} className={inputClass}>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </label>
        {status === "completed" ? (
          <label className={field}>
            Completed on
            <input type="date" name="completed_on" className={inputClass} />
          </label>
        ) : null}
        {documents.length ? (
          <label className={field}>
            Document (optional)
            <select name="document_id" defaultValue="" className={inputClass}>
              <option value="">None</option>
              {documents.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
        ) : null}
      </div>
      <label className={field}>
        {status === "completed" ? "Outcome" : "Why it was cancelled (optional)"}
        <textarea name="outcome" required={status === "completed"} maxLength={2000} rows={2} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : "Close review"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

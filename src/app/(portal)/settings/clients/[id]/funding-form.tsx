// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveFunding } from "./actions";
import { useSavableForm } from "@/components/page-save";
import { PLAN_MANAGEMENT } from "@/lib/client-sections";

export type Funding = { id: string; service_id: string; scheme: string; period_start: string; period_end: string; total_amount: number; used_amount: number; used_as_of: string | null; plan_management: string | null; classification: number | null; status: string; notes: string };
const field = "flex flex-col gap-1 text-xs font-medium";

function Footer({ pending, state, submit, pageSave, unchanged = false }: { pending: boolean; state: { error?: string; message?: string } | null; submit: string; pageSave: boolean; unchanged?: boolean }) {
  return (
    <div className="flex flex-wrap items-center gap-3">
      {pageSave ? null : (
        <Button size="sm" disabled={pending || unchanged}>
          {pending ? "Saving…" : submit}
        </Button>
      )}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message && !pageSave ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

// cmeprojects (Care block C7): a new budget. Only the chosen service's scheme
// fields show (NDIS: plan management; Support at Home: classification).
type FundingProps = { clientId: string; services: { id: string; label: string; scheme: string; schemeLabel: string }[] };
export function FundingForm(props: FundingProps) {
  // A fresh form after each budget is added.
  const [round, setRound] = useState(0);
  return <FundingFormInner key={round} {...props} onAdded={() => setRound((r) => r + 1)} />;
}

function FundingFormInner({ clientId, services, onAdded }: FundingProps & { onAdded: () => void }) {
  const { state, pending, ref, onSubmit, pageSave } = useSavableForm(saveFunding, { label: "New budget", onSaved: onAdded });
  const [serviceId, setServiceId] = useState(services[0]?.id ?? "");
  const scheme = services.find((s) => s.id === serviceId)?.scheme;
  return (
    <form ref={ref} onSubmit={onSubmit} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Service
          <select name="service_id" value={serviceId} onChange={(e) => setServiceId(e.target.value)} required className={inputClass}>
            {services.map((s) => (
              <option key={s.id} value={s.id}>
                {s.label} ({s.schemeLabel})
              </option>
            ))}
          </select>
        </label>
        {scheme === "ndis" ? (
          <label className={field}>
            Plan management (NDIS)
            <select name="plan_management" required className={inputClass}>
              {PLAN_MANAGEMENT.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
        ) : scheme === "support_at_home" ? (
          <label className={field}>
            Classification (Support at Home)
            <select name="classification" required className={inputClass}>
              {[1, 2, 3, 4, 5, 6, 7, 8].map((n) => (
                <option key={n} value={n}>
                  Classification {n}
                </option>
              ))}
            </select>
          </label>
        ) : null}
        <label className={field}>
          Period starts
          <input type="date" name="period_start" required className={inputClass} />
        </label>
        <label className={field}>
          Period ends
          <input type="date" name="period_end" required className={inputClass} />
        </label>
        <label className={field}>
          Total for the period (AUD)
          <input name="total_amount" required inputMode="decimal" placeholder="e.g. 45000" className={inputClass} />
        </label>
      </div>
      <label className={field}>
        Notes
        <textarea name="notes" maxLength={1000} rows={2} className={inputClass} />
      </label>
      <Footer pending={pending} state={state} submit="Add budget" pageSave={pageSave} />
    </form>
  );
}

export function FundingUsedForm({ clientId, funding }: { clientId: string; funding: Funding }) {
  const { state, pending, ref, dirty, onSubmit, pageSave } = useSavableForm(saveFunding, { label: "Budget used so far" });
  return (
    <form ref={ref} onSubmit={onSubmit} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="id" value={funding.id} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Used so far (AUD)
          <input name="used_amount" required inputMode="decimal" defaultValue={String(funding.used_amount)} className={inputClass} />
        </label>
        <label className={field}>
          As at
          <input type="date" name="used_as_of" defaultValue={funding.used_as_of ?? ""} className={inputClass} />
        </label>
      </div>
      <label className={field}>
        Notes
        <textarea name="notes" maxLength={1000} rows={2} defaultValue={funding.notes} className={inputClass} />
      </label>
      <Footer pending={pending} state={state} submit="Save" pageSave={pageSave} unchanged={!dirty} />
    </form>
  );
}

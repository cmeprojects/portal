// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { startTransition, useActionState, useState, type FormEvent } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";
import { RECORDS_BUCKET, WORK_STATUS, type Bank, type Super, type WorkRights } from "@/lib/staff-records";
import { saveBank, saveSuper, saveWorkRights } from "./actions";

// cmeprojects: submit without the browser form reset, so a refused save
// (for example a mistyped BSB) keeps what the person typed.
const keepValues = (run: (f: FormData) => void) => (e: FormEvent<HTMLFormElement>) => {
  e.preventDefault();
  const data = new FormData(e.currentTarget);
  startTransition(() => run(data));
};

function Checked({ at }: { at: string | null }) {
  return at ? (
    <span className="rounded-full bg-good-soft px-2.5 py-0.5 text-xs font-semibold text-good">Checked</span>
  ) : (
    <span className="rounded-full bg-warn-soft px-2.5 py-0.5 text-xs font-semibold text-warn">Waiting to be checked</span>
  );
}

function Result({ state }: { state: { error?: string; message?: string } | null }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export function BankForm({ bank }: { bank: Bank | null }) {
  const [state, run, pending] = useActionState(saveBank, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form ref={ref} onSubmit={keepValues(run)} className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="heading-sm">Bank account for your pay</h2>
        {bank ? <Checked at={bank.verified_at} /> : null}
      </div>
      <div className="grid gap-4 sm:grid-cols-3">
        <Field label="Name on the account" htmlFor="b-name">
          <input id="b-name" name="account_name" defaultValue={bank?.account_name ?? ""} maxLength={100} autoComplete="off" className={inputClass} />
        </Field>
        <Field label="BSB" htmlFor="b-bsb" hint="6 digits">
          <input id="b-bsb" name="bsb" defaultValue={bank?.bsb ?? ""} inputMode="numeric" maxLength={7} autoComplete="off" placeholder="062-000" className={inputClass} />
        </Field>
        <Field label="Account number" htmlFor="b-acct" hint="5 to 9 digits">
          <input id="b-acct" name="account_number" defaultValue={bank?.account_number ?? ""} inputMode="numeric" maxLength={12} autoComplete="off" className={inputClass} />
        </Field>
      </div>
      <Result state={state} />
      <Button className="self-start" disabled={pending || !dirty}>
        {pending ? "Saving…" : "Save bank details"}
      </Button>
    </form>
  );
}

export function SuperForm({ sup, userId }: { sup: Super | null; userId: string }) {
  const [state, run, pending] = useActionState(saveSuper, null);
  const { ref, dirty, markClean } = useDirty();
  const [uploaded, setUploaded] = useState(false);
  useAfterSuccess(state, () => {
    markClean();
    setUploaded(false);
  });
  return (
    <form ref={ref} onSubmit={keepValues(run)} className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="heading-sm">Superannuation</h2>
        {sup ? <Checked at={sup.verified_at} /> : null}
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Fund name" htmlFor="s-fund">
          <input id="s-fund" name="fund_name" defaultValue={sup?.fund_name ?? ""} maxLength={120} className={inputClass} />
        </Field>
        <Field label="Member number" htmlFor="s-member">
          <input id="s-member" name="member_number" defaultValue={sup?.member_number ?? ""} maxLength={30} autoComplete="off" className={inputClass} />
        </Field>
        <Field label="Fund ABN" htmlFor="s-abn" hint="11 digits">
          <input id="s-abn" name="fund_abn" defaultValue={sup?.fund_abn ?? ""} inputMode="numeric" maxLength={14} className={inputClass} />
        </Field>
        <Field label="USI (unique superannuation identifier)" htmlFor="s-usi">
          <input id="s-usi" name="usi" defaultValue={sup?.usi ?? ""} maxLength={20} className={inputClass} />
        </Field>
      </div>
      <Field label="Choice of fund form (optional)" htmlFor="s-doc" hint={sup?.choice_name ? `On file: ${sup.choice_name}. Upload again to replace it.` : "A PDF or photo of your completed form."}>
        <FileUpload id="s-doc" bucket={RECORDS_BUCKET} folder={`payroll_tax/${userId}`} name="choice_doc" onUploaded={() => setUploaded(true)} />
      </Field>
      <Result state={state} />
      <Button className="self-start" disabled={pending || (!dirty && !uploaded)}>
        {pending ? "Saving…" : "Save super details"}
      </Button>
    </form>
  );
}

export function WorkRightsForm({ wr, userId }: { wr: WorkRights | null; userId: string }) {
  const [state, run, pending] = useActionState(saveWorkRights, null);
  const { ref, dirty, markClean } = useDirty();
  const [status, setStatus] = useState(wr?.status ?? "");
  const [uploaded, setUploaded] = useState(false);
  useAfterSuccess(state, () => {
    markClean();
    setUploaded(false);
  });
  const visa = status === "visa";
  return (
    <form ref={ref} onSubmit={keepValues(run)} className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="heading-sm">Right to work in Australia</h2>
        {wr?.status ? <Checked at={wr.verified_at} /> : null}
      </div>
      <Field label="Your work rights" htmlFor="w-status">
        <select id="w-status" name="status" required value={status} onChange={(e) => setStatus(e.target.value as WorkRights["status"])} className={inputClass}>
          <option value="" disabled>
            Choose one
          </option>
          {Object.entries(WORK_STATUS).map(([v, label]) => (
            <option key={v} value={v}>
              {label}
            </option>
          ))}
        </select>
      </Field>
      {visa ? (
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Visa subclass" htmlFor="w-sub" hint="For example 482 or 500">
            <input id="w-sub" name="visa_subclass" required defaultValue={wr?.visa_subclass ?? ""} maxLength={20} className={inputClass} />
          </Field>
          <Field label="Visa expiry date" htmlFor="w-exp">
            <input id="w-exp" name="visa_expiry" type="date" defaultValue={wr?.visa_expiry ?? ""} className={inputClass} />
          </Field>
          <div className="sm:col-span-2">
            <Field label="Work conditions (optional)" htmlFor="w-cond" hint="For example: work limited to 48 hours a fortnight.">
              <textarea id="w-cond" name="visa_conditions" rows={2} defaultValue={wr?.visa_conditions ?? ""} maxLength={500} className={`${inputClass} h-auto py-3`} />
            </Field>
          </div>
          <Field label="Visa grant notice (optional)" htmlFor="w-visa-doc" hint={wr?.visa_doc_name ? `On file: ${wr.visa_doc_name}.` : undefined}>
            <FileUpload id="w-visa-doc" bucket={RECORDS_BUCKET} folder={`identity_docs/${userId}`} name="visa_doc" onUploaded={() => setUploaded(true)} />
          </Field>
          <Field label="VEVO check (optional)" htmlFor="w-vevo-doc" hint={wr?.vevo_doc_name ? `On file: ${wr.vevo_doc_name}.` : "A PDF of your VEVO result."}>
            <FileUpload id="w-vevo-doc" bucket={RECORDS_BUCKET} folder={`identity_docs/${userId}`} name="vevo_doc" onUploaded={() => setUploaded(true)} />
          </Field>
          <Field label="Date of the VEVO check (optional)" htmlFor="w-vevo-on">
            <input id="w-vevo-on" name="vevo_checked_on" type="date" defaultValue={wr?.vevo_checked_on ?? ""} className={inputClass} />
          </Field>
        </div>
      ) : null}
      <Result state={state} />
      <Button className="self-start" disabled={pending || (!dirty && !uploaded)}>
        {pending ? "Saving…" : "Save work rights"}
      </Button>
    </form>
  );
}

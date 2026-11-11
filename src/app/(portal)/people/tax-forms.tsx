// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Download, Eye, FileText, Save, Send, Trash2, Upload } from "lucide-react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { useAfterSuccess } from "@/components/use-after-success";
import { RECORDS_BUCKET } from "@/lib/staff-records";
import { deletePrivateRecords, deleteTaxForm, openTaxForm, openTfnTemplate, saveTaxForm, saveTfnTemplate, updateTax } from "./tax-actions";

export type Tax = { user_id: string; form_path: string; form_name: string; uploaded_at: string | null; lodged_on: string | null; verified_at: string | null };

const day = (d: string | null) => (d ? new Date(d.length === 10 ? `${d}T12:00:00Z` : d).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

function DownloadBlank() {
  const [pending, start] = useTransition();
  return (
    <Button
      type="button"
      variant="outline"
      disabled={pending}
      onClick={() =>
        start(async () => {
          const r = await openTfnTemplate();
          if (r.url) window.location.href = r.url;
          else toast(r.error ?? "Couldn't open it.", "error");
        })
      }
    >
      <Download aria-hidden="true" /> {pending ? "Opening…" : "Download the blank form"}
    </Button>
  );
}

// cmeprojects: the staff member's own TFN declaration (My account → Pay and work rights).
export function TaxFormCard({ tax, userId }: { tax: Tax | null; userId: string }) {
  const router = useRouter();
  const [state, run, pending] = useActionState(saveTaxForm, null);
  const [ready, setReady] = useState(false);
  useAfterSuccess(state, (m) => {
    toast(m);
    setReady(false);
    router.refresh();
  });
  return (
    <form action={run} className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="heading-sm">Tax file number declaration</h2>
        {tax?.form_path ? (
          tax.lodged_on ? (
            <span className="rounded-full bg-good-soft px-2.5 py-0.5 text-xs font-semibold text-good">Sent to the ATO {day(tax.lodged_on)}</span>
          ) : (
            <span className="rounded-full bg-warn-soft px-2.5 py-0.5 text-xs font-semibold text-warn">Uploaded, with the office</span>
          )
        ) : null}
      </div>
      <p className="text-sm text-muted">
        Download the blank form, fill it in and sign it, then upload it here (a PDF or a clear photo). We don&apos;t type your TFN into the portal; only the people who handle payroll can open the form.
      </p>
      <DownloadBlank />
      <Field label={tax?.form_name ? `Completed form (on file: ${tax.form_name}; upload again to replace it)` : "Your completed form"} htmlFor="tfn-form">
        <FileUpload id="tfn-form" bucket={RECORDS_BUCKET} folder={`tax/${userId}`} name="tfn_form" onReady={setReady} />
      </Field>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button className="self-start" disabled={pending || !ready}>
        <Upload aria-hidden="true" /> {pending ? "Saving…" : "Save my form"}
      </Button>
    </form>
  );
}

// For people allowed to open TFN forms: open (recorded), check, record it was sent to the ATO, delete.
export function TaxAdmin({ subject, tax }: { subject: string; tax: Tax }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [lodged, setLodged] = useState(tax.lodged_on ?? "");
  const done = (r: { error?: string; message?: string } | null) => {
    toast(r?.error ?? r?.message ?? "Done.", r?.error ? "error" : "success");
    router.refresh();
  };
  return (
    <div className="flex flex-col gap-2 text-sm">
      <p>
        <FileText aria-hidden="true" className="mr-1 inline size-4 text-muted" />
        {tax.form_name || "TFN declaration"} · uploaded {day(tax.uploaded_at)}
        {tax.verified_at ? ` · checked ${day(tax.verified_at)}` : " · not checked yet"}
        {tax.lodged_on ? ` · sent to the ATO ${day(tax.lodged_on)}` : ""}
      </p>
      <div className="flex flex-wrap items-end gap-2">
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={pending}
          onClick={() =>
            start(async () => {
              const r = await openTaxForm(subject);
              if (r.url) window.open(r.url, "_blank", "noopener");
              else toast(r.error ?? "Couldn't open it.", "error");
            })
          }
        >
          <Eye aria-hidden="true" /> Open form
        </Button>
        {!tax.verified_at ? (
          <Button type="button" variant="outline" size="sm" disabled={pending} onClick={() => start(async () => done(await updateTax(subject, { checked: true })))}>
            Mark checked
          </Button>
        ) : null}
        <label className="flex items-end gap-2">
          <span className="flex flex-col gap-1 text-xs font-semibold">
            Sent to the ATO on
            <input type="date" value={lodged} onChange={(e) => setLodged(e.target.value)} className={`${inputClass} h-9 md:h-8`} />
          </span>
          <Button type="button" variant="outline" size="sm" disabled={pending || !lodged || lodged === tax.lodged_on} onClick={() => start(async () => done(await updateTax(subject, { lodgedOn: lodged })))}>
            <Send aria-hidden="true" /> Save date
          </Button>
        </label>
        <Button
          type="button"
          variant="danger"
          size="sm"
          disabled={pending}
          onClick={async () => {
            if (!(await askConfirm("Delete this TFN declaration permanently? The file and record are removed and can't be recovered. The deletion is recorded.", { action: "Delete permanently" }))) return;
            start(async () => done(await deleteTaxForm(subject)));
          }}
        >
          <Trash2 aria-hidden="true" /> Delete
        </Button>
      </div>
    </div>
  );
}

// The blank form, added by the system admin or a manager / staff admin with Payroll and tax access.
export function TemplateUpload({ current }: { current: string }) {
  const [state, run, pending] = useActionState(saveTfnTemplate, null);
  const [ready, setReady] = useState(false);
  useAfterSuccess(state, (m) => {
    toast(m);
    setReady(false);
  });
  return (
    <form action={run} className="flex flex-col gap-3">
      <h2 className="heading-sm">Blank TFN declaration form</h2>
      <p className="text-sm text-muted">{current ? "A blank form is on file. Upload a newer one to replace it." : "Upload the ATO's blank TFN declaration so staff can download it in My onboarding."}</p>
      <FileUpload id="tfn-template" bucket={RECORDS_BUCKET} folder="templates" name="template" accept="application/pdf" onReady={setReady} />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button className="self-start" disabled={pending || !ready}>
        <Save aria-hidden="true" /> {pending ? "Saving…" : "Save blank form"}
      </Button>
    </form>
  );
}

// System admin: delete all of a leaver's private records.
export function DeleteRecordsButton({ subject, name }: { subject: string; name: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  return (
    <Button
      type="button"
      variant="danger"
      size="sm"
      disabled={pending}
      onClick={async () => {
        if (!(await askConfirm(`Permanently delete ${name}'s private records (bank, super, work rights, TFN declaration) and their files? This can't be undone. The deletion is recorded.`, { action: "Delete permanently", typeWord: "DELETE" }))) return;
        start(async () => {
          const r = await deletePrivateRecords(subject);
          toast(r?.error ?? r?.message ?? "Done.", r?.error ? "error" : "success");
          router.refresh();
        });
      }}
    >
      <Trash2 aria-hidden="true" /> {pending ? "Deleting…" : "Delete records"}
    </Button>
  );
}

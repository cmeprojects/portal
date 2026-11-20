// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { saveNote, uploadReport } from "./actions";
import { DateInput } from "@/components/date-input";

const field = "flex flex-col gap-1 text-xs font-medium";

// cmeprojects (update 124): a practitioner uploads a report for their client.
export function ReportForm({ clientId }: { clientId: string }) {
  const [state, action, pending] = useActionState(uploadReport, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-3">
        <div className={field}>
          File (PDF, image or Word, up to 10 MB)
          <FileUpload id={`report-${clientId}`} bucket="client-docs" folder={clientId} name="file" accept="application/pdf,image/jpeg,image/png,image/webp,image/heic,.doc,.docx" />
        </div>
        <label className={field}>
          Title
          <input name="title" maxLength={120} placeholder="Uses the file name if empty" className={inputClass} />
        </label>
        <label className={field}>
          Type
          <select name="doc_type" defaultValue="report" className={inputClass}>
            <option value="report">Report</option>
            <option value="assessment">Assessment</option>
          </select>
        </label>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Uploading…" : "Upload report"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

// cmeprojects (update 124): write a note, or change your own within 24 hours.
export function NoteForm({ clientId, today, note }: { clientId: string; today: string; note?: { id: string; body: string; note_date: string } }) {
  const [state, action, pending] = useActionState(saveNote, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      {note ? <input type="hidden" name="id" value={note.id} /> : null}
      <label className={`${field} max-w-48`}>
        Date of the session or contact
        <DateInput name="note_date" max={today} defaultValue={note?.note_date ?? today} className={inputClass} />
      </label>
      <label className={field}>
        Note
        <textarea name="body" required rows={4} maxLength={5000} defaultValue={note?.body ?? ""} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : note ? "Save changes" : "Add note"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

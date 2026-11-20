// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { DOC_TYPE_LABELS } from "@/lib/client-sections";
import { uploadClientDocument } from "./actions";
import { DateInput } from "@/components/date-input";

// cmeprojects (Care block C3): add a client document, or a new version of one.
export function DocumentForm({ clientId, replaces }: { clientId: string; replaces?: { id: string; title: string; doc_type: string } }) {
  const [state, action, pending] = useActionState(uploadClientDocument, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      {replaces ? <input type="hidden" name="replaces_id" value={replaces.id} /> : null}
      <div className="grid gap-2 sm:grid-cols-2">
        <div className="flex flex-col gap-1 text-xs font-medium">
          File (PDF, image or Word, up to 10 MB)
          <FileUpload id={`doc-${clientId}-${replaces?.id ?? "new"}`} bucket="client-docs" folder={clientId} name="file" accept="application/pdf,image/jpeg,image/png,image/webp,image/heic,.doc,.docx" />
        </div>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Title
          <input name="title" maxLength={120} defaultValue={replaces?.title ?? ""} placeholder="Uses the file name if empty" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Type
          <select name="doc_type" defaultValue={replaces?.doc_type ?? "other"} className={inputClass}>
            {DOC_TYPE_LABELS.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Expires (optional)
          <DateInput name="expires_on" className={inputClass} />
        </label>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Uploading…" : replaces ? "Add new version" : "Add document"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { FILES_BUCKET } from "@/lib/compliance";
import type { FormState } from "@/lib/form";
import { confirmItem, submitUpload } from "./actions";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export function ConfirmButton({ itemId, label }: { itemId: string; label: string }) {
  const [state, action, pending] = useActionState(confirmItem, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <Result state={state} />
      <input type="hidden" name="item_id" value={itemId} />
      <Button className="self-start" disabled={pending}>{pending ? "Saving…" : label}</Button>
    </form>
  );
}

export function UploadForm({ itemId, userId, needsExpiry, again }: { itemId: string; userId: string; needsExpiry: boolean; again: boolean }) {
  const [state, action, pending] = useActionState(submitUpload, null);
  const [ready, setReady] = useState(false);
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <input type="hidden" name="item_id" value={itemId} />
      <div className="grid gap-3 md:grid-cols-[2fr_1fr] md:items-start">
        <Field label={again ? "Upload a new copy" : "Choose the file"} htmlFor={`file-${itemId}`}>
          <FileUpload id={`file-${itemId}`} bucket={FILES_BUCKET} folder={userId} name="file" required onReady={setReady} />
        </Field>
        {needsExpiry ? (
          <Field label="Expiry date" htmlFor={`exp-${itemId}`}>
            <input id={`exp-${itemId}`} name="expires_on" type="date" required className={inputClass} />
          </Field>
        ) : null}
      </div>
      <Button className="self-start" disabled={pending || !ready}>{pending ? "Saving…" : "Submit"}</Button>
    </form>
  );
}

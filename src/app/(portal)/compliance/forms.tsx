// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { FILES_BUCKET, LIBRARY_BUCKET, type ComplianceItem, type ItemKind } from "@/lib/compliance";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { reviewUpload, saveItem, uploadForPerson } from "./actions";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

const ROLES_FOR_ITEMS: Role[] = ["new_starter", "support_worker", "team_leader", "manager", "staff_admin"];
const check = "h-5 w-5 accent-[var(--brand-primary)]";

export function ItemForm({ kind, item, teams }: { kind: ItemKind; item?: ComplianceItem; teams: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(saveItem, null);
  const p = item?.id ?? `new-${kind}`;
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      {item ? <input type="hidden" name="id" value={item.id} /> : null}
      <input type="hidden" name="kind" value={kind} />
      <div className="grid gap-4 md:grid-cols-[3fr_1fr]">
        <Field label="Title" htmlFor={`${p}-title`}>
          <input
            id={`${p}-title`}
            name="title"
            required
            defaultValue={item?.title}
            placeholder={kind === "read" ? "e.g. Code of Conduct" : kind === "training" ? "e.g. Manual handling" : "e.g. National police check"}
            className={inputClass}
          />
        </Field>
        <Field label="Order" htmlFor={`${p}-sort`}>
          <input id={`${p}-sort`} name="sort_order" type="number" defaultValue={item?.sort_order ?? 0} className={inputClass} />
        </Field>
      </div>
      <Field label="Short description (optional)" htmlFor={`${p}-desc`}>
        <input id={`${p}-desc`} name="description" defaultValue={item?.description} className={inputClass} />
      </Field>
      {kind === "read" ? (
        <Field label="Text to read (optional if you attach a file)" htmlFor={`${p}-body`}>
          <textarea id={`${p}-body`} name="body" rows={6} defaultValue={item?.body} className={`${inputClass} min-h-32 py-3`} />
        </Field>
      ) : null}
      {kind !== "upload" ? (
        <div className="grid gap-4 md:grid-cols-2">
          <Field label={kind === "training" ? "Link to the training (optional)" : "Link (optional)"} htmlFor={`${p}-link`}>
            <input id={`${p}-link`} name="link_url" type="url" defaultValue={item?.link_url} placeholder="https://" className={inputClass} />
          </Field>
          <Field label={item?.file_name ? `File: ${item.file_name} (choose to replace)` : "File (optional)"} htmlFor={`${p}-file`}>
            <FileUpload id={`${p}-file`} bucket={LIBRARY_BUCKET} folder={`items/${kind}`} name="file" maxMb={25} />
          </Field>
        </div>
      ) : (
        <label className="flex min-h-11 items-center gap-3 text-sm">
          <input type="checkbox" name="needs_expiry" defaultChecked={item?.needs_expiry ?? true} className={check} />
          Ask for an expiry date
        </label>
      )}
      <fieldset className="flex flex-col gap-2">
        <legend className="mb-1 text-sm font-semibold">Who it&apos;s for (leave all unticked for everyone)</legend>
        <div className="flex flex-wrap gap-x-5">
          {ROLES_FOR_ITEMS.map((r) => (
            <label key={r} className="flex min-h-11 items-center gap-2 text-sm">
              <input type="checkbox" name="applies_roles" value={r} defaultChecked={item?.applies_roles.includes(r)} className={check} />
              {ROLE_LABELS[r]}
            </label>
          ))}
        </div>
        {teams.length ? (
          <div className="flex flex-wrap gap-x-5">
            {teams.map((t) => (
              <label key={t.id} className="flex min-h-11 items-center gap-2 text-sm">
                <input type="checkbox" name="applies_teams" value={t.id} defaultChecked={item?.applies_teams.includes(t.id)} className={check} />
                {t.name}
              </label>
            ))}
          </div>
        ) : null}
      </fieldset>
      {item ? (
        <div className="flex flex-col gap-1">
          {kind !== "upload" ? (
            <label className="flex min-h-11 items-center gap-3 text-sm">
              <input type="checkbox" name="new_version" className={check} />
              This is a new version: ask everyone to {kind === "training" ? "complete it" : "read and confirm it"} again
            </label>
          ) : null}
          {item.file_name ? (
            <label className="flex min-h-11 items-center gap-3 text-sm">
              <input type="checkbox" name="remove_file" className={check} />
              Remove the attached file
            </label>
          ) : null}
          <label className="flex min-h-11 items-center gap-3 text-sm">
            <input type="checkbox" name="active" defaultChecked={item.active} className={check} />
            {kind === "upload" ? "Uploads for this document are switched on" : "In use"}
          </label>
        </div>
      ) : null}
      <Button className="self-start" disabled={pending}>{pending ? "Saving…" : item ? "Save" : "Add"}</Button>
    </form>
  );
}

export function ReviewForm({ recordId }: { recordId: number }) {
  const [state, action, pending] = useActionState(reviewUpload, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <Result state={state} />
      <input type="hidden" name="record_id" value={recordId} />
      <div className="flex flex-wrap items-end gap-2">
        <div className="min-w-56 flex-1">
          <Field label="Note (needed to send it back)" htmlFor={`note-${recordId}`}>
            <input id={`note-${recordId}`} name="note" placeholder="e.g. The photo is blurry" className={inputClass} />
          </Field>
        </div>
        <Button name="decision" value="accept" className="h-12" disabled={pending}>Looks good</Button>
        <Button name="decision" value="reject" variant="outline" className="h-12" disabled={pending}>Send back</Button>
      </div>
    </form>
  );
}

export function UploadForPersonForm({
  userId,
  itemId,
  needsExpiry,
  checksItself,
}: {
  userId: string;
  itemId: string;
  needsExpiry: boolean;
  // A staff admin's upload counts as checked; a manager's gets checked.
  checksItself: boolean;
}) {
  const [state, action, pending] = useActionState(uploadForPerson, null);
  const [ready, setReady] = useState(false);
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <input type="hidden" name="user_id" value={userId} />
      <input type="hidden" name="item_id" value={itemId} />
      <div className="grid gap-3 md:grid-cols-[2fr_1fr] md:items-start">
        <Field label="File" htmlFor={`for-${itemId}`}>
          <FileUpload id={`for-${itemId}`} bucket={FILES_BUCKET} folder={userId} name="file" required onReady={setReady} />
        </Field>
        {needsExpiry ? (
          <Field label="Expiry date" htmlFor={`for-exp-${itemId}`}>
            <input id={`for-exp-${itemId}`} name="expires_on" type="date" required className={inputClass} />
          </Field>
        ) : null}
      </div>
      <p className="text-xs text-muted">
        {checksItself ? "It counts as checked, since you're the one checking." : "A staff admin will check it."}
      </p>
      <Button className="self-start" disabled={pending || !ready}>{pending ? "Saving…" : "Upload for them"}</Button>
    </form>
  );
}

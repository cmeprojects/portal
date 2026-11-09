// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { toast } from "@/components/toast";
import { useValid } from "@/components/use-valid";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";
import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { CATEGORY_LABELS, FILES_BUCKET, LIBRARY_BUCKET, type ComplianceItem, type ItemKind } from "@/lib/compliance";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { changeClearance, reviewUpload, saveItem, uploadForPerson } from "./actions";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

const ROLES_FOR_ITEMS: Role[] = ["new_starter", "support_worker", "team_leader", "manager", "staff_admin"];
const check = "h-5 w-5 accent-[var(--brand-primary)]";

export function ItemForm({ kind, item, teams, titles = [] }: { kind: ItemKind; item?: ComplianceItem; teams: { id: string; name: string }[]; titles?: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(saveItem, null);
  // cmeprojects: Save is greyed out until something changes (and the title is filled in).
  const { ref, dirty, markClean } = useDirty();
  const [title, setTitle] = useState(item?.title ?? "");
  const valid = title.trim().length > 0;
  useAfterSuccess(state, markClean);
  const p = item?.id ?? `new-${kind}`;
  return (
    <form ref={ref} action={action} className="flex flex-col gap-4">
      <Result state={state} />
      {item ? <input type="hidden" name="id" value={item.id} /> : null}
      <input type="hidden" name="kind" value={kind} />
      <div className="grid gap-4 md:grid-cols-[3fr_1fr]">
        <Field label="Title" htmlFor={`${p}-title`}>
          <input
            id={`${p}-title`}
            name="title"
            required
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={kind === "read" ? "e.g. Code of Conduct" : kind === "training" ? "e.g. Manual handling" : kind === "agreement" ? "e.g. Employment agreement" : "e.g. National police check"}
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
      {kind === "read" || kind === "agreement" ? (
        <Field label={kind === "agreement" ? "Agreement wording (optional if you attach a file)" : "Text to read (optional if you attach a file)"} htmlFor={`${p}-body`}>
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
        <div className="grid gap-4 md:grid-cols-2">
          <Field label="Category" htmlFor={`${p}-cat`}>
            <select id={`${p}-cat`} name="category" defaultValue={item?.category ?? ""} className={inputClass}>
              <option value="">None</option>
              {Object.entries(CATEGORY_LABELS).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
          </Field>
          <div className="flex flex-col">
            <label className="flex min-h-11 items-center gap-3 text-sm">
              <input type="checkbox" name="needs_expiry" defaultChecked={item?.needs_expiry ?? true} className={check} />
              Ask for an expiry date
            </label>
            <label className="flex min-h-11 items-center gap-3 text-sm">
              <input type="checkbox" name="needs_issue_date" defaultChecked={item?.needs_issue_date ?? false} className={check} />
              Ask for the issue date
            </label>
            <label className="flex min-h-11 items-center gap-3 text-sm">
              <input type="checkbox" name="needs_number" defaultChecked={item?.needs_number ?? false} className={check} />
              Ask for the document or card number
            </label>
          </div>
        </div>
      )}
      {kind === "training" ? (
        <div className="grid gap-4 md:grid-cols-2">
          <Field label="Certificate" htmlFor={`${p}-cert`} hint="Mandatory trainings (needed before working) always need one.">
            <select id={`${p}-cert`} name="certificate" defaultValue={item?.certificate ?? "optional"} className={inputClass}>
              <option value="required">Required</option>
              <option value="optional">Optional</option>
              <option value="none">Not needed</option>
            </select>
          </Field>
          <label className="flex min-h-11 items-center gap-3 self-end text-sm">
            <input type="checkbox" name="needs_expiry" defaultChecked={item?.needs_expiry ?? false} className={check} />
            Certificates expire (ask for the expiry date)
          </label>
        </div>
      ) : null}
      <label className="flex items-start gap-3 rounded-lg border border-warn/30 bg-warn-soft/40 p-3 text-sm">
        <input type="checkbox" name="before_work" defaultChecked={item?.before_work ?? false} className={`${check} mt-0.5`} />
        <span>
          <span className="block font-semibold">Needed before working</span>
          <span className="block text-muted">Must be done{kind === "upload" || kind === "training" ? " and checked" : ""} before someone can be cleared to work. Everything else can be finished in their first week.</span>
        </span>
      </label>
      <fieldset className="flex flex-col gap-2">
        <legend className="mb-1 text-sm font-semibold">Who it&apos;s for</legend>
        <p className="text-xs text-muted">
          Leave everything unticked for everyone. Tick roles, teams or both: with both, a person needs one of the roles <strong>and</strong> to be in one of the teams. Managers and staff admins usually aren&apos;t in a team, so ticking a team leaves them out.
        </p>
        <p className="pt-1 text-xs font-semibold">Roles</p>
        <div className="flex flex-wrap gap-x-5">
          {ROLES_FOR_ITEMS.map((r) => (
            <label key={r} className="flex min-h-11 items-center gap-2 text-sm">
              <input type="checkbox" name="applies_roles" value={r} defaultChecked={item?.applies_roles.includes(r)} className={check} />
              {ROLE_LABELS[r]}
            </label>
          ))}
        </div>
        {teams.length ? <p className="pt-1 text-xs font-semibold">Teams</p> : null}
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
        {titles.length ? <p className="pt-1 text-xs font-semibold">Positions (job titles)</p> : null}
        {titles.length ? (
          <div className="flex flex-wrap gap-x-5">
            {titles.map((t) => (
              <label key={t.id} className="flex min-h-11 items-center gap-2 text-sm">
                <input type="checkbox" name="applies_titles" value={t.id} defaultChecked={item?.applies_titles?.includes(t.id)} className={check} />
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
              This is a new version: ask everyone to {kind === "training" ? "complete it" : kind === "agreement" ? "sign it" : "read and confirm it"} again
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
      <Button className="self-start" disabled={pending || !valid || (Boolean(item) && !dirty)}>{pending ? "Saving…" : item ? "Save" : "Add"}</Button>
    </form>
  );
}

export function ReviewForm({ recordId }: { recordId: number }) {
  const [note, setNote] = useState("");
  // cmeprojects: the card may leave the list once it's checked, so also say so with a toast.
  const [state, action, pending] = useActionState(async (prev: FormState, f: FormData) => {
    const r = await reviewUpload(prev, f);
    if (r?.message && !r.error) toast(r.message);
    return r;
  }, null);
  // cmeprojects: once it's done, show what happened instead of the buttons.
  if (state?.message && !state.error) return <Notice tone="success">{state.message}</Notice>;
  return (
    <form action={action} className="flex flex-col gap-2">
      <Result state={state} />
      <input type="hidden" name="record_id" value={recordId} />
      <div className="flex flex-wrap items-end gap-2">
        <div className="min-w-56 flex-1">
          <Field label="Note (needed to reject or ask for a new copy)" htmlFor={`note-${recordId}`}>
            <input id={`note-${recordId}`} name="note" value={note} onChange={(e) => setNote(e.target.value)} placeholder="e.g. The photo is blurry" className={inputClass} />
          </Field>
        </div>
        <Button name="decision" value="accept" className="h-12" disabled={pending}>{pending ? "Saving…" : "Looks good"}</Button>
        <Button name="decision" value="reject" variant="outline" className="h-12" disabled={pending || !note.trim()}>Reject</Button>
        <Button name="decision" value="replace" variant="outline" className="h-12" disabled={pending || !note.trim()}>Ask for a new copy</Button>
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
  // cmeprojects: once it's done, show what happened instead of the buttons.
  if (state?.message && !state.error) return <Notice tone="success">{state.message}</Notice>;
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

// cmeprojects (update 58): clear someone to work, or let them work for now.
export function ClearancePanel({
  userId,
  name,
  cleared,
  missing,
  override,
  maxDate,
}: {
  userId: string;
  name: string;
  cleared: boolean;
  missing: string[];
  override: { id: number; until: string; reason: string; by: string } | null;
  // The latest override end date allowed (30 days from today).
  maxDate: string;
}) {
  const [state, action, pending] = useActionState(changeClearance, null);
  const [mode, setMode] = useState<"" | "grant" | "revoke" | "override">("");
  const { ref: modeRef, valid } = useValid();
  return (
    <div className="flex flex-col gap-3">
      <Result state={state} />
      <div className="flex flex-wrap gap-2">
        {!cleared ? (
          <Button type="button" onClick={() => setMode("grant")} disabled={pending || missing.length > 0}>
            Clear to work
          </Button>
        ) : (
          <Button type="button" variant="outline" onClick={() => setMode("revoke")} disabled={pending}>
            Remove clearance
          </Button>
        )}
        {!cleared ? (
          <Button type="button" variant="outline" onClick={() => setMode("override")} disabled={pending}>
            {override ? "Change override" : "Let them work for now (override)"}
          </Button>
        ) : null}
        {override ? (
          <form action={action}>
            <input type="hidden" name="user_id" value={userId} />
            <input type="hidden" name="op" value="end" />
            <input type="hidden" name="override_id" value={override.id} />
            <Button variant="outline" disabled={pending}>{pending ? "Saving…" : "End override"}</Button>
          </form>
        ) : null}
      </div>
      {!cleared && missing.length ? <p className="text-xs text-muted">Clear to work unlocks once everything needed before working is done and checked.</p> : null}
      {mode ? (
        <form ref={modeRef} key={mode} action={action} className="flex flex-col gap-3 rounded-lg border border-line bg-page p-4">
          <input type="hidden" name="user_id" value={userId} />
          <input type="hidden" name="op" value={mode} />
          <p className="text-sm font-semibold">
            {mode === "grant" ? `Clear ${name} to work` : mode === "revoke" ? `Remove ${name}'s clearance` : `Let ${name} work before they're cleared`}
          </p>
          <Field label={mode === "grant" ? "Note (optional)" : "Reason"} htmlFor={`clr-note-${userId}`}>
            <input id={`clr-note-${userId}`} name="note" required={mode !== "grant"} minLength={mode === "override" ? 3 : undefined} placeholder={mode === "override" ? "e.g. Short staffed this weekend; police check on its way" : ""} className={inputClass} />
          </Field>
          {mode === "override" ? (
            <Field label="Until (up to 30 days)" htmlFor={`clr-until-${userId}`}>
              <input id={`clr-until-${userId}`} name="until" type="date" required max={maxDate} className={inputClass} />
            </Field>
          ) : null}
          <div className="flex gap-2">
            <Button disabled={pending || !valid}>{pending ? "Saving…" : mode === "grant" ? "Clear to work" : mode === "revoke" ? "Remove clearance" : "Give override"}</Button>
            <Button type="button" variant="outline" onClick={() => setMode("")}>
              Cancel
            </Button>
          </div>
        </form>
      ) : null}
    </div>
  );
}

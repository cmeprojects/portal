// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";
import { CLIENT_STATUS } from "@/lib/client-sections";
import { addClientWithManager, archiveClient, saveClientCare, saveProgram, saveScheme } from "./actions";
import { ARCHIVE_REASONS, TITLES } from "@/lib/client-sections";

// cmeprojects (Clients step 1): a client's preferred name and status. Changing
// the status asks first; the database records who changed it and when.
export function ClientCareForm({ client }: { client: { id: string; name: string; client_ref: string; preferred_name: string; status: string; title?: string; given_name?: string; middle_name?: string; family_name?: string } }) {
  // Before update 118 (or for older records) the first and last name come from the full name.
  const parts = client.name.trim().split(/\s+/);
  const given = client.given_name || (parts.length > 1 ? parts.slice(0, -1).join(" ") : parts[0] ?? "");
  const family = client.family_name || (parts.length > 1 ? parts[parts.length - 1] : "");
  const [state, action, pending] = useActionState(saveClientCare, null);
  const [, start] = useTransition();
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form
      ref={ref}
      onSubmit={async (e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        const to = String(data.get("status"));
        if (to !== client.status && !(await askConfirm(`Change ${client.name} (${client.client_ref}) from ${CLIENT_STATUS[client.status]} to ${CLIENT_STATUS[to]}? This is recorded in the change log.`, { action: "Change status" }))) {
          return;
        }
        start(() => action(data));
      }}
      className="mt-3 flex flex-col gap-2 border-t border-line pt-3"
    >
      <input type="hidden" name="id" value={client.id} />
      <p className="text-xs text-muted">
        Client reference <span className="font-mono font-semibold text-ink">{client.client_ref}</span> (made by the portal; it never changes)
      </p>
      {client.title !== undefined ? (
        <div className="grid gap-2 sm:grid-cols-[6rem_1fr_1fr_1fr]">
          <label className="flex flex-col gap-1 text-xs font-medium">
            Title
            <select name="title" defaultValue={client.title} className={inputClass}>
              {TITLES.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            First name
            <input name="given_name" required maxLength={40} defaultValue={given} className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            Middle name (optional)
            <input name="middle_name" maxLength={40} defaultValue={client.middle_name ?? ""} className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            Last name
            <input name="family_name" required maxLength={40} defaultValue={family} className={inputClass} />
          </label>
        </div>
      ) : null}
      <div className="flex flex-wrap items-end gap-2">
        <label className="flex min-w-40 flex-1 flex-col gap-1 text-xs font-medium">
          Preferred name (optional)
          <input name="preferred_name" maxLength={80} defaultValue={client.preferred_name} className={inputClass} />
        </label>
        <label className="flex min-w-40 flex-col gap-1 text-xs font-medium">
          Status
          <select name="status" defaultValue={client.status} className={inputClass}>
            {Object.entries(CLIENT_STATUS)
              .filter(([k]) => k !== "discharged" || client.status === "discharged")
              .map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
        </label>
        <Button size="sm" variant="outline" disabled={pending || !dirty}>
          {pending ? "Saving…" : "Save"}
        </Button>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

type Program = { id: string; name: string; needs_dob: boolean; active: boolean; scheme?: string };
export type Scheme = { key: string; label: string; person_word: string | null; review_label: string; change_review_label: string; review_lead_days: number[]; needs_dob: boolean };

function SchemeSelect({ value, schemes, id }: { value?: string; schemes: Scheme[]; id: string }) {
  return (
    <select id={id} name="scheme" required defaultValue={value ?? ""} aria-label="Scheme" className={`${inputClass} w-44`}>
      <option value="" disabled>
        Scheme…
      </option>
      {schemes.map((s) => (
        <option key={s.key} value={s.key}>
          {s.label}
        </option>
      ))}
    </select>
  );
}

// One program: the system admin renames it, marks whether it needs a date of
// birth, or deactivates it. Others see the list only.
export function ProgramRow({ program, canEdit, schemes = [] }: { program: Program; canEdit: boolean; schemes?: Scheme[] }) {
  const [state, action, pending] = useActionState(saveProgram, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  if (!canEdit) {
    return (
      <li className="flex flex-wrap items-center gap-2 py-2 text-sm">
        <span className={`font-medium ${program.active ? "" : "text-muted line-through"}`}>{program.name}</span>
        {program.scheme ? <span className="text-xs text-muted">{schemes.find((s) => s.key === program.scheme)?.label ?? program.scheme}</span> : null}
        {program.needs_dob ? <span className="text-xs text-muted">needs date of birth</span> : null}
        {!program.active ? <span className="text-xs text-muted">(not in use)</span> : null}
      </li>
    );
  }
  return (
    <li className="py-2">
      <form ref={ref} action={action} className="flex flex-wrap items-center gap-x-4 gap-y-2">
        <input type="hidden" name="id" value={program.id} />
        <label className="sr-only" htmlFor={`pg-${program.id}`}>
          Program name
        </label>
        <input id={`pg-${program.id}`} name="name" required maxLength={80} defaultValue={program.name} className={`${inputClass} min-w-40 flex-1`} />
        <SchemeSelect id={`pgs-${program.id}`} value={program.scheme} schemes={schemes} />
        <label className="flex min-h-9 items-center gap-2 text-sm">
          <input type="checkbox" name="needs_dob" defaultChecked={program.needs_dob} className="h-4 w-4 accent-[var(--brand-primary)]" />
          Needs date of birth
        </label>
        <label className="flex min-h-9 items-center gap-2 text-sm">
          <input type="checkbox" name="active" defaultChecked={program.active} className="h-4 w-4 accent-[var(--brand-primary)]" />
          In use
        </label>
        <Button size="sm" variant="outline" disabled={pending || !dirty}>
          {pending ? "Saving…" : "Save"}
        </Button>
      </form>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </li>
  );
}

export function AddProgramForm({ schemes = [] }: { schemes?: Scheme[] }) {
  const [state, action, pending] = useActionState(saveProgram, null);
  return (
    <form action={action} className="flex flex-col gap-2 pt-2">
      <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
        <label className="sr-only" htmlFor="pg-new">
          New program
        </label>
        <input id="pg-new" name="name" required maxLength={80} placeholder="New program, for example Brokerage" className={`${inputClass} min-w-40 flex-1`} />
        <SchemeSelect id="pgs-new" schemes={schemes} />
        <label className="flex min-h-9 items-center gap-2 text-sm">
          <input type="checkbox" name="needs_dob" className="h-4 w-4 accent-[var(--brand-primary)]" />
          Needs date of birth
        </label>
        <Button size="sm" disabled={pending}>
          {pending ? "Adding…" : "Add program"}
        </Button>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

// cmeprojects (update 110): one scheme's wording and rules, in Care settings.
// The scheme decides what its people and reviews are called and when review
// reminders start, so NDIS and Support at Home never borrow each other's.
export function SchemeRow({ scheme, canEdit, orgWord }: { scheme: Scheme; canEdit: boolean; orgWord: string }) {
  const [state, action, pending] = useActionState(saveScheme, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  if (!canEdit) {
    return (
      <li className="py-2 text-sm">
        <span className="font-medium">{scheme.label}</span>
        <span className="block text-xs text-muted">
          {scheme.person_word ?? orgWord} · {scheme.review_label} · {scheme.change_review_label} · reminders {scheme.review_lead_days.join(", ")} days before
        </span>
      </li>
    );
  }
  const k = scheme.key;
  return (
    <li className="py-3">
      <form ref={ref} action={action} className="flex flex-col gap-2">
        <input type="hidden" name="key" value={k} />
        <div className="grid gap-2 sm:grid-cols-3">
          <label className="flex flex-col gap-1 text-xs font-medium">
            Scheme name
            <input name="label" required maxLength={60} defaultValue={scheme.label} className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            The person is called
            <input name="person_word" maxLength={30} defaultValue={scheme.person_word ?? ""} placeholder={`${orgWord} (your organisation's word)`} className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            Reminder days before a review
            <input name="review_lead_days" defaultValue={scheme.review_lead_days.join(", ")} placeholder="90, 60, 30" className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            Scheduled review is called
            <input name="review_label" required maxLength={60} defaultValue={scheme.review_label} className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs font-medium">
            Review after a change of situation is called
            <input name="change_review_label" required maxLength={60} defaultValue={scheme.change_review_label} className={inputClass} />
          </label>
          <label className="flex min-h-9 items-center gap-2 self-end text-sm">
            <input type="checkbox" name="needs_dob" defaultChecked={scheme.needs_dob} className="h-4 w-4 accent-[var(--brand-primary)]" />
            New programs need date of birth
          </label>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <Button size="sm" variant="outline" disabled={pending || !dirty}>
            {pending ? "Saving…" : `Save ${scheme.label}`}
          </Button>
          {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
          {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
        </div>
      </form>
    </li>
  );
}

// cmeprojects (Care block): add a client and choose who manages them (their
// care manager or support coordinator), when you may assign staff.
export function AddCareClientForm({ staff, word }: { staff: { id: string; name: string }[] | null; word: string }) {
  const [state, action, pending] = useActionState(addClientWithManager, null);
  const router = useRouter();
  // Added: straight on to their details.
  useEffect(() => {
    if (state?.spotlight) router.push(`/settings/clients/${state.spotlight}?edit=basic`);
  }, [state, router]);
  return (
    <form action={action} className="flex flex-col gap-2">
      <div className="grid gap-2 sm:grid-cols-2">
        <label className="flex flex-col gap-1 text-xs font-medium">
          Name
          <input name="name" required maxLength={80} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Your own reference (optional)
          <input name="reference" maxLength={60} className={inputClass} />
        </label>
        {staff ? (
          <>
            <label className="flex flex-col gap-1 text-xs font-medium">
              Managed by
              <select name="manager_id" defaultValue="" className={inputClass}>
                <option value="">Choose later</option>
                {staff.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex flex-col gap-1 text-xs font-medium">
              As
              <select name="assigned_as" defaultValue="case_manager" className={inputClass}>
                <option value="case_manager">Care manager</option>
                <option value="support_coordinator">Support coordinator</option>
              </select>
            </label>
          </>
        ) : null}
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" disabled={pending}>
          {pending ? "Adding…" : `Add ${word.toLowerCase()}`}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

// cmeprojects (update 118): archive a client, with the reason. They move to
// the Archived tab and are hidden from Cars and features; nothing is deleted.
export function ArchiveClientForm({ clientId, name }: { clientId: string; name: string }) {
  const [state, action, pending] = useActionState(archiveClient, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="id" value={clientId} />
      <div className="grid gap-2 sm:grid-cols-2">
        <label className="flex flex-col gap-1 text-xs font-medium">
          Why is {name} being archived?
          <select name="archive_reason" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose…
            </option>
            {ARCHIVE_REASONS.map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs font-medium">
          Note (needed for Other)
          <input name="archive_note" maxLength={500} placeholder="e.g. which provider, or when" className={inputClass} />
        </label>
      </div>
      <p className="text-xs text-muted">They move to Archived and are hidden from Cars and features. Nothing is deleted; they can be made active again.</p>
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" variant="outline" disabled={pending}>
          {pending ? "Archiving…" : "Archive"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

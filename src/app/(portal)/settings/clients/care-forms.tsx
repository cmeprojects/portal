// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useTransition } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";
import { CLIENT_STATUS } from "../../cars/manage/forms";
import { saveClientCare, saveProgram } from "./actions";

// cmeprojects (Clients step 1): a client's preferred name and status. Changing
// the status asks first; the database records who changed it and when.
export function ClientCareForm({ client }: { client: { id: string; name: string; client_ref: string; preferred_name: string; status: string } }) {
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
      <div className="flex flex-wrap items-end gap-2">
        <label className="flex min-w-40 flex-1 flex-col gap-1 text-xs font-medium">
          Preferred name (optional)
          <input name="preferred_name" maxLength={80} defaultValue={client.preferred_name} className={inputClass} />
        </label>
        <label className="flex min-w-40 flex-col gap-1 text-xs font-medium">
          Status
          <select name="status" defaultValue={client.status} className={inputClass}>
            {Object.entries(CLIENT_STATUS).map(([k, label]) => (
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

type Program = { id: string; name: string; needs_dob: boolean; active: boolean };

// One program: the system admin renames it, marks whether it needs a date of
// birth, or deactivates it. Others see the list only.
export function ProgramRow({ program, canEdit }: { program: Program; canEdit: boolean }) {
  const [state, action, pending] = useActionState(saveProgram, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  if (!canEdit) {
    return (
      <li className="flex flex-wrap items-center gap-2 py-2 text-sm">
        <span className={`font-medium ${program.active ? "" : "text-muted line-through"}`}>{program.name}</span>
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

export function AddProgramForm() {
  const [state, action, pending] = useActionState(saveProgram, null);
  return (
    <form action={action} className="flex flex-col gap-2 pt-2">
      <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
        <label className="sr-only" htmlFor="pg-new">
          New program
        </label>
        <input id="pg-new" name="name" required maxLength={80} placeholder="New program, for example Brokerage" className={`${inputClass} min-w-40 flex-1`} />
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

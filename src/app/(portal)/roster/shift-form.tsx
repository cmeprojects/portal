// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { copyLastWeek, saveShift } from "./actions";

export type ShiftDraft = {
  id?: string;
  date: string;
  start: string;
  end: string;
  break_minutes: number;
  worker_id: string;
  client_id: string;
  location_id: string;
  service_id: string;
  notes: string;
  status: string;
};
type Opt = { id: string; name: string };
const field = "flex flex-col gap-1 text-xs font-medium";

// cmeprojects (update 122): add or change a shift. A client's approved
// locations and current services only; the database checks the rest.
export function ShiftForm({
  shift,
  workers,
  clients,
  locations,
  services,
}: {
  shift: ShiftDraft;
  workers: (Opt & { note?: string })[];
  clients: Opt[];
  locations: (Opt & { client_id: string })[];
  services: (Opt & { client_id: string })[];
}) {
  const [state, action, pending] = useActionState(saveShift, null);
  const [client, setClient] = useState(shift.client_id);
  return (
    <form action={action} className="flex flex-col gap-2">
      {shift.id ? <input type="hidden" name="id" value={shift.id} /> : null}
      <div className="grid gap-2 sm:grid-cols-4">
        <label className={field}>
          Date
          <input type="date" name="date" required defaultValue={shift.date} className={inputClass} />
        </label>
        <label className={field}>
          Start
          <input type="time" name="start" required defaultValue={shift.start} className={inputClass} />
        </label>
        <label className={field}>
          Finish
          <input type="time" name="end" required defaultValue={shift.end} className={inputClass} />
        </label>
        <label className={field}>
          Unpaid break (minutes)
          <input type="number" name="break_minutes" min={0} max={240} step={5} defaultValue={shift.break_minutes} className={inputClass} />
        </label>
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        <label className={field}>
          Worker
          <select name="worker_id" defaultValue={shift.worker_id} className={inputClass}>
            <option value="">Open shift (anyone can put their hand up)</option>
            {workers.map((w) => (
              <option key={w.id} value={w.id}>
                {w.name}
                {w.note ? ` · ${w.note}` : ""}
              </option>
            ))}
          </select>
        </label>
        <label className={field}>
          Client (optional)
          <select name="client_id" value={client} onChange={(e) => setClient(e.target.value)} className={inputClass}>
            <option value="">No client (e.g. training, office)</option>
            {clients.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        {client ? (
          <>
            <label className={field}>
              Location
              <select name="location_id" defaultValue={shift.location_id} className={inputClass}>
                <option value="">Not set</option>
                {locations
                  .filter((l) => l.client_id === client)
                  .map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.name}
                    </option>
                  ))}
              </select>
            </label>
            <label className={field}>
              Service
              <select name="service_id" defaultValue={shift.service_id} className={inputClass}>
                <option value="">Not set</option>
                {services
                  .filter((v) => v.client_id === client)
                  .map((v) => (
                    <option key={v.id} value={v.id}>
                      {v.name}
                    </option>
                  ))}
              </select>
            </label>
          </>
        ) : null}
      </div>
      <label className={field}>
        Notes for the worker
        <textarea name="notes" maxLength={500} rows={2} defaultValue={shift.notes} className={inputClass} />
      </label>
      <div className="flex flex-wrap items-center gap-3">
        <select name="status" defaultValue={shift.status === "published" ? "published" : "draft"} aria-label="Save as" className={`${inputClass.replace("w-full", "")} w-auto`}>
          <option value="draft">Save as draft</option>
          <option value="published">Publish (the worker is told)</option>
        </select>
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : shift.id ? "Save shift" : "Add shift"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export function CopyWeekForm({ from }: { from: string }) {
  const [state, action, pending] = useActionState(copyLastWeek, null);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="from" value={from} />
      <Button size="sm" variant="outline" disabled={pending}>
        {pending ? "Copying…" : "Copy last week as drafts"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

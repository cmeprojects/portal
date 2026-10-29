// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { correctTrip, movePurpose, returnForSomeone, saveCar, saveClient, saveClientField, savePurpose, setClientShown, setPurposeShown } from "../actions";
import { CAR_FILES } from "@/lib/car-types";
import type { FormState } from "@/lib/form";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export const CAR_TYPES = ["Sedan", "Hatchback", "SUV", "People mover", "Van", "Wheelchair-accessible van", "Ute"];

export type CarRow = {
  id: string;
  name: string;
  rego: string;
  car_type: string;
  colour: string;
  odometer: number;
  rego_expires: string | null;
  service_due_date: string | null;
  service_due_km: number | null;
  notes: string;
  active: boolean;
};

function ActiveSwitch({ active, label }: { active: boolean; label: string }) {
  return (
    <label className="flex min-h-11 items-center gap-2 text-sm font-medium">
      <input type="checkbox" name="active" value="true" defaultChecked={active} className="h-5 w-5 accent-[var(--brand-primary)]" />
      {label}
    </label>
  );
}

export function CarForm({ car }: { car?: CarRow }) {
  const [state, action, pending] = useActionState(saveCar, null);
  const p = car?.id ?? "new";
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      {car ? <input type="hidden" name="id" value={car.id} /> : null}
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Name" htmlFor={`n-${p}`} hint="What staff call it, for example Kia Carnival.">
          <input id={`n-${p}`} name="name" required maxLength={80} defaultValue={car?.name} className={inputClass} />
        </Field>
        <Field label="Rego" htmlFor={`r-${p}`}>
          <input id={`r-${p}`} name="rego" required maxLength={12} defaultValue={car?.rego} className={`${inputClass} uppercase`} />
        </Field>
        <Field label="Car type" htmlFor={`t-${p}`}>
          <select id={`t-${p}`} name="car_type" defaultValue={car?.car_type ?? ""} className={inputClass}>
            <option value="">Choose a type</option>
            {[...new Set([...CAR_TYPES, ...(car?.car_type ? [car.car_type] : [])])].map((t) => (
              <option key={t}>{t}</option>
            ))}
          </select>
        </Field>
        <Field label="Colour (optional)" htmlFor={`c-${p}`}>
          <input id={`c-${p}`} name="colour" maxLength={40} defaultValue={car?.colour} className={inputClass} />
        </Field>
        <Field label="Odometer now (km)" htmlFor={`o-${p}`} hint={car ? "Trips keep this up to date." : "The reading on the dashboard today."}>
          <input id={`o-${p}`} name="odometer" inputMode="numeric" required={!car} defaultValue={car?.odometer} className={`${inputClass} tabular-nums`} />
        </Field>
        <Field label="Rego expires (optional)" htmlFor={`re-${p}`} hint="Car managers are reminded 30 days before.">
          <input id={`re-${p}`} name="rego_expires" type="date" defaultValue={car?.rego_expires ?? ""} className={inputClass} />
        </Field>
        <Field label="Next service by date (optional)" htmlFor={`sd-${p}`}>
          <input id={`sd-${p}`} name="service_due_date" type="date" defaultValue={car?.service_due_date ?? ""} className={inputClass} />
        </Field>
        <Field label="Next service at (km, optional)" htmlFor={`sk-${p}`} hint="Reminded 500 km before.">
          <input id={`sk-${p}`} name="service_due_km" inputMode="numeric" defaultValue={car?.service_due_km ?? ""} className={`${inputClass} tabular-nums`} />
        </Field>
      </div>
      <Field label="Notes (optional)" htmlFor={`no-${p}`} hint="For example where the keys are kept, or the fuel card.">
        <textarea id={`no-${p}`} name="notes" maxLength={1000} rows={2} defaultValue={car?.notes} className={`${inputClass} h-auto py-2`} />
      </Field>
      <Field label="Photo of the car (optional)" htmlFor={`ph-${p}`}>
        <FileUpload id={`ph-${p}`} bucket={CAR_FILES} folder="cars" name="photo" accept="image/*" />
      </Field>
      {car ? <ActiveSwitch active={car.active} label="In use (untick to retire the car; its trips stay in the reports)" /> : null}
      <div>
        <Button disabled={pending}>{pending ? "Saving…" : car ? "Save" : "Add car"}</Button>
      </div>
    </form>
  );
}

const CLIENT_FIELD = [
  { value: "off", label: "Off", hint: "No client on trips" },
  { value: "optional", label: "Optional", hint: "Staff can leave it blank" },
  { value: "required", label: "Required", hint: "Staff must choose one" },
];

export function ClientFieldForm({ current }: { current: string }) {
  const [state, action, pending] = useActionState(saveClientField, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <fieldset className="flex flex-col gap-2">
        <legend className="mb-1 font-semibold">Client on each trip</legend>
        <div className="grid gap-2 sm:grid-cols-3">
          {CLIENT_FIELD.map((c) => (
            <label key={c.value} className="flex min-h-14 cursor-pointer items-center gap-3 rounded-md border border-line px-3 py-2 has-[:checked]:border-brand has-[:checked]:bg-brand-soft">
              <input type="radio" name="value" value={c.value} defaultChecked={current === c.value} className="h-5 w-5 accent-[var(--brand-primary)]" />
              <span>
                <span className="block text-sm font-semibold">{c.label}</span>
                <span className="block text-xs text-muted">{c.hint}</span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <div>
        <Button disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
      </div>
    </form>
  );
}

// A small Shown / Hidden switch (staff only see shown ones).
function ShownSwitch({ id, active, action, label }: { id: string; active: boolean; action: (form: FormData) => Promise<void>; label: string }) {
  return (
    <form action={action}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="active" value={active ? "false" : "true"} />
      <button
        role="switch"
        aria-checked={active}
        aria-label={`Show ${label} to staff`}
        className={`flex h-9 min-w-20 shrink-0 items-center justify-center gap-1.5 rounded-full px-3 text-xs font-semibold ${
          active ? "bg-good-soft text-good" : "border border-field bg-surface text-muted"
        }`}
      >
        <span aria-hidden="true" className={`size-2 rounded-full ${active ? "bg-good" : "bg-muted"}`} />
        {active ? "Shown" : "Hidden"}
      </button>
    </form>
  );
}

export function AddClientForm() {
  const [state, action, pending] = useActionState(saveClient, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <div className="grid gap-3 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
        <Field label="Name" htmlFor="cn-new" hint="Staff see this in the list.">
          <input id="cn-new" name="name" required maxLength={80} className={inputClass} />
        </Field>
        <Field label="Reference (optional)" htmlFor="cr-new" hint="For example their NDIS number. Staff don't see it.">
          <input id="cr-new" name="reference" maxLength={60} className={inputClass} />
        </Field>
        <Button disabled={pending}>{pending ? "Adding…" : "Add client"}</Button>
      </div>
    </form>
  );
}

export function ClientRow({ client }: { client: { id: string; name: string; reference: string; active: boolean } }) {
  const [state, action, pending] = useActionState(saveClient, null);
  return (
    <li className="flex flex-col gap-2 px-4 py-3 sm:px-5">
      <div className="flex flex-wrap items-center gap-3">
        <span className={`min-w-0 flex-1 ${client.active ? "" : "text-muted"}`}>
          <span className="block font-semibold">{client.name}</span>
          {client.reference ? <span className="block text-xs text-muted">{client.reference}</span> : null}
        </span>
        <ShownSwitch id={client.id} active={client.active} action={setClientShown} label={client.name} />
      </div>
      <details>
        <summary className="cursor-pointer text-xs font-semibold text-brand">Edit</summary>
        <form action={action} className="mt-2 flex flex-col gap-2">
          <Result state={state} />
          <input type="hidden" name="id" value={client.id} />
          <div className="grid gap-2 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
            <Field label="Name" htmlFor={`cn-${client.id}`}>
              <input id={`cn-${client.id}`} name="name" required maxLength={80} defaultValue={client.name} className={inputClass} />
            </Field>
            <Field label="Reference" htmlFor={`cr-${client.id}`}>
              <input id={`cr-${client.id}`} name="reference" maxLength={60} defaultValue={client.reference} className={inputClass} />
            </Field>
            <Button variant="outline" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
          </div>
        </form>
      </details>
    </li>
  );
}

export function AddPurposeForm() {
  const [state, action, pending] = useActionState(savePurpose, null);
  return (
    <form action={action} className="flex flex-col gap-2">
      <Result state={state} />
      <label htmlFor="pn-new" className="sr-only">New purpose</label>
      <div className="flex gap-2">
        <input id="pn-new" name="name" required maxLength={60} placeholder="e.g. Respite outing" className={`${inputClass} min-w-0 flex-1`} />
        <Button disabled={pending}>{pending ? "Adding…" : "Add"}</Button>
      </div>
    </form>
  );
}

function MoveButton({ id, dir, disabled }: { id: string; dir: "up" | "down"; disabled: boolean }) {
  return (
    <form action={movePurpose}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="dir" value={dir} />
      <button
        disabled={disabled}
        aria-label={dir === "up" ? "Move up" : "Move down"}
        className="flex size-9 items-center justify-center rounded-md border border-field bg-surface text-muted hover:text-ink disabled:opacity-30"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden="true">
          <path d={dir === "up" ? "M6 15l6-6 6 6" : "M6 9l6 6 6-6"} />
        </svg>
      </button>
    </form>
  );
}

export function PurposeRow({ purpose, first, last }: { purpose: { id: string; name: string; active: boolean }; first: boolean; last: boolean }) {
  const [state, action, pending] = useActionState(savePurpose, null);
  return (
    <li className="flex flex-col gap-2 px-4 py-3 sm:px-5">
      <div className="flex items-center gap-2">
        <div className="flex gap-1">
          <MoveButton id={purpose.id} dir="up" disabled={first} />
          <MoveButton id={purpose.id} dir="down" disabled={last} />
        </div>
        <span className={`min-w-0 flex-1 pl-1 leading-snug font-semibold break-words ${purpose.active ? "" : "text-muted"}`}>{purpose.name}</span>
        <ShownSwitch id={purpose.id} active={purpose.active} action={setPurposeShown} label={purpose.name} />
      </div>
      <details className="pl-[5.25rem]">
        <summary className="cursor-pointer text-xs font-semibold text-brand">Rename</summary>
        <form action={action} className="mt-2 flex flex-col gap-2">
          <Result state={state} />
          <input type="hidden" name="id" value={purpose.id} />
          <label htmlFor={`pn-${purpose.id}`} className="sr-only">Name</label>
          <div className="flex gap-2">
            <input id={`pn-${purpose.id}`} name="name" required maxLength={60} defaultValue={purpose.name} className={`${inputClass} min-w-0 flex-1`} />
            <Button variant="outline" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
          </div>
        </form>
      </details>
    </li>
  );
}

export function ReturnForSomeoneForm({ tripId, startOdo, driver }: { tripId: number; startOdo: number; driver: string }) {
  const [state, action, pending] = useActionState(returnForSomeone, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <input type="hidden" name="trip_id" value={tripId} />
      <div className="grid gap-3 sm:grid-cols-[10rem_1fr_auto] sm:items-end">
        <Field label="End odometer (km)" htmlFor={`e-${tripId}`} hint={`Started at ${startOdo.toLocaleString("en-AU")}`}>
          <input id={`e-${tripId}`} name="end_odo" inputMode="numeric" required className={`${inputClass} tabular-nums`} />
        </Field>
        <Field label="Reason" htmlFor={`rn-${tripId}`} hint={`${driver.split(" ")[0]} is told it was returned for them.`}>
          <input id={`rn-${tripId}`} name="note" required maxLength={300} placeholder="e.g. Keys left at the office" className={inputClass} />
        </Field>
        <Button disabled={pending}>{pending ? "Returning…" : "Return for them"}</Button>
      </div>
    </form>
  );
}

export function CorrectTripForm({
  trip,
  purposes,
  clients,
}: {
  trip: { id: number; start_odo: number; end_odo: number | null; purpose: string; client_id: string | null };
  purposes: string[];
  clients: { id: string; name: string }[];
}) {
  const [state, action, pending] = useActionState(correctTrip, null);
  const p = trip.id;
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <input type="hidden" name="trip_id" value={trip.id} />
      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Start odometer (km)" htmlFor={`cs-${p}`}>
          <input id={`cs-${p}`} name="start_odo" inputMode="numeric" required defaultValue={trip.start_odo} className={`${inputClass} tabular-nums`} />
        </Field>
        <Field label="End odometer (km)" htmlFor={`ce-${p}`}>
          <input
            id={`ce-${p}`}
            name="end_odo"
            inputMode="numeric"
            required={trip.end_odo !== null}
            disabled={trip.end_odo === null}
            defaultValue={trip.end_odo ?? ""}
            placeholder={trip.end_odo === null ? "Still out" : undefined}
            className={`${inputClass} tabular-nums`}
          />
        </Field>
        <Field label="Purpose" htmlFor={`cp-${p}`}>
          <select id={`cp-${p}`} name="purpose" defaultValue={trip.purpose} className={inputClass}>
            {[...new Set([trip.purpose, ...purposes])].map((x) => (
              <option key={x}>{x}</option>
            ))}
          </select>
        </Field>
        <Field label="Client" htmlFor={`cc-${p}`}>
          <select id={`cc-${p}`} name="client_id" defaultValue={trip.client_id ?? ""} className={inputClass}>
            <option value="">No client</option>
            {clients.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </Field>
      </div>
      <Field label="Why is it being changed?" htmlFor={`cw-${p}`}>
        <input id={`cw-${p}`} name="reason" required maxLength={300} placeholder="e.g. Typo in the end reading" className={inputClass} />
      </Field>
      <div>
        <Button disabled={pending}>{pending ? "Saving…" : "Fix trip"}</Button>
      </div>
    </form>
  );
}

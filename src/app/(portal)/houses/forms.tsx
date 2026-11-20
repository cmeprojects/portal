// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { startTransition, useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { HOUSE_KINDS } from "@/lib/houses";
import { moveIn, moveOut, saveHouse, setHouseActive, setRoom } from "./actions";
import { DateInput } from "@/components/date-input";

const lab = "text-xs font-semibold text-ink";
const area = `${inputClass} h-auto py-2`;
const today = () => new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
type Opt = [string, string][];

function Msg({ state }: { state: { error?: string; message?: string } | null }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export type House = { id: string; name: string; kind: string; address: string; phone: string; beds: number | null; manager_id: string | null; team_id: string | null; staff_notes: string; active: boolean };

// Add a house, or change one. Typed values stay when there's a mistake.
export function HouseForm({ house, staff, teams }: { house?: House; staff: Opt; teams: Opt }) {
  const [state, action, pending] = useActionState(saveHouse, null);
  const router = useRouter();
  useEffect(() => {
    if (!house && state?.spotlight) router.push(`/houses/${state.spotlight}`);
  }, [state, house, router]);
  return (
    <form
      action={action}
      onSubmit={(e) => {
        e.preventDefault();
        const fd = new FormData(e.currentTarget);
        startTransition(() => action(fd));
      }}
      className="flex flex-col gap-3"
    >
      {house ? <input type="hidden" name="id" value={house.id} /> : null}
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="flex flex-col gap-1">
          <span className={lab}>Name</span>
          <input name="name" required maxLength={80} defaultValue={house?.name} placeholder="For example Oak House, or 4 Oak St" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Type</span>
          <select name="kind" defaultValue={house?.kind ?? "sil"} className={inputClass}>
            {HOUSE_KINDS.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 sm:col-span-2">
          <span className={lab}>Address</span>
          <input name="address" maxLength={200} defaultValue={house?.address} placeholder="4 Oak Street, Penrith NSW 2750" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>House phone</span>
          <input name="phone" type="tel" maxLength={30} defaultValue={house?.phone} placeholder="02 4700 0000" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Beds</span>
          <input name="beds" type="number" min={1} max={30} defaultValue={house?.beds ?? ""} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>House manager</span>
          <select name="manager_id" defaultValue={house?.manager_id ?? ""} className={inputClass}>
            <option value="">Not set</option>
            {staff.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Team that staffs it</span>
          <select name="team_id" defaultValue={house?.team_id ?? ""} className={inputClass}>
            <option value="">Not set</option>
            {teams.map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
      </div>
      <label className="flex flex-col gap-1">
        <span className={lab}>Notes for staff on shift</span>
        <textarea name="staff_notes" maxLength={4000} rows={4} defaultValue={house?.staff_notes} placeholder="Routines, keys and access, fire exits and assembly point, bins, house rules…" className={area} />
        <span className="text-xs text-muted">Workers see these on their shifts at the house. Don&apos;t put door codes or alarm codes here.</span>
      </label>
      <div className="flex items-center gap-2">
        <Button size="sm" disabled={pending}>
          {pending ? "Saving…" : house ? "Save" : "Add house"}
        </Button>
        <Msg state={state} />
      </div>
    </form>
  );
}

export function HouseActiveForm({ id, active }: { id: string; active: boolean }) {
  const [state, action, pending] = useActionState(setHouseActive, null);
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="active" value={active ? "0" : "1"} />
      <Button size="sm" variant="outline" disabled={pending}>
        {active ? "Close the house" : "Reopen the house"}
      </Button>
      <Msg state={state} />
    </form>
  );
}

export function MoveInForm({ houseId, clients }: { houseId: string; clients: Opt }) {
  const [state, action, pending] = useActionState(moveIn, null);
  return (
    <form action={action} key={state?.message ?? "in"} className="grid gap-2 sm:grid-cols-[1fr_8rem_10rem_auto] sm:items-end">
      <input type="hidden" name="house_id" value={houseId} />
      <label className="flex flex-col gap-1">
        <span className={lab}>Who is moving in</span>
        <select name="client_id" required defaultValue="" className={inputClass}>
          <option value="" disabled>
            Choose a client
          </option>
          {clients.map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Room</span>
        <input name="room" maxLength={40} placeholder="Room 1" className={inputClass} />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Moving in on</span>
        <DateInput name="moved_in" required defaultValue={today()} className={inputClass} />
      </label>
      <Button size="sm" disabled={pending}>
        {pending ? "Saving…" : "Move in"}
      </Button>
      <div className="sm:col-span-4">
        <Msg state={state} />
      </div>
    </form>
  );
}

export function MoveOutForm({ id, movedIn }: { id: string; movedIn: string }) {
  const [state, action, pending] = useActionState(moveOut, null);
  const [open, setOpen] = useState(false);
  if (!open)
    return (
      <Button size="sm" variant="outline" type="button" onClick={() => setOpen(true)}>
        Move out
      </Button>
    );
  return (
    <form action={action} className="flex w-full flex-wrap items-end gap-2">
      <input type="hidden" name="id" value={id} />
      <label className="flex flex-col gap-1">
        <span className={lab}>Moving out on</span>
        <DateInput name="moved_out" required min={movedIn} defaultValue={today()} className={inputClass} />
      </label>
      <label className="flex min-w-56 flex-1 flex-col gap-1">
        <span className={lab}>Why</span>
        <input name="move_reason" required maxLength={500} placeholder="Moved to another house, hospital, family…" className={inputClass} />
      </label>
      <Button size="sm" disabled={pending}>
        Move out
      </Button>
      <Button size="sm" variant="outline" type="button" onClick={() => setOpen(false)}>
        Cancel
      </Button>
      <Msg state={state} />
    </form>
  );
}

export function RoomForm({ id, room }: { id: string; room: string }) {
  const [state, action, pending] = useActionState(setRoom, null);
  return (
    <form action={action} className="flex items-center gap-1">
      <input type="hidden" name="id" value={id} />
      <input name="room" maxLength={40} defaultValue={room} placeholder="Room" aria-label="Room" className={`${inputClass} h-8 w-28`} />
      <Button size="sm" variant="outline" disabled={pending}>
        Save
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
    </form>
  );
}

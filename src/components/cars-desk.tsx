// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { returnTrip, startTrip, undoReturn, undoStart } from "@/app/(portal)/cars/actions";
import { CAR_FILES, km, type CarBoardRow, type CarScreen, type MyTrip } from "@/lib/car-types";
import type { FormState } from "@/lib/form";

const bigButton = "min-h-14 w-full text-lg";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

function useWhen(timeZone: string) {
  // Built from parts so the server and every phone show exactly the same text.
  const parts = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit", hour12: true, timeZone });
  const fmt = (iso: string) => {
    const p = Object.fromEntries(parts.formatToParts(new Date(iso)).map((x) => [x.type, x.value]));
    return { day: `${p.weekday} ${p.day} ${p.month}`, time: `${p.hour}:${p.minute} ${String(p.dayPeriod ?? "").toLowerCase()}` };
  };
  const today = fmt(new Date().toISOString()).day;
  // "9:12 am" today, "Fri 30 Oct, 9:12 am" on other days.
  return {
    full: (iso: string) => `${fmt(iso).day}, ${fmt(iso).time}`,
    short: (iso: string) => (fmt(iso).day === today ? fmt(iso).time : `${fmt(iso).day}, ${fmt(iso).time}`),
  };
}

// Seconds left to undo something done at `iso`, counting down in the browser.
function useUndoLeft(iso: string | null, minutes: number, serverNow: number) {
  // The phone's clock may be off; count from the server's time.
  const [skew] = useState(() => serverNow - Date.now());
  const deadline = iso ? new Date(iso).getTime() + minutes * 60_000 : 0;
  const [ms, setMs] = useState(() => Math.max(0, deadline - (Date.now() + skew)));
  useEffect(() => {
    if (!deadline) return;
    const tick = () => setMs(Math.max(0, deadline - (Date.now() + skew)));
    tick();
    const t = window.setInterval(tick, 1000);
    return () => window.clearInterval(t);
  }, [deadline, skew]);
  return ms;
}

const clock = (ms: number) => `${Math.floor(ms / 60_000)}:${String(Math.floor((ms % 60_000) / 1000)).padStart(2, "0")}`;

// The Cars screen: pick a car and start, or return the one you have.
export function CarsDesk({ data, userId, timeZone, preselect }: { data: CarScreen; userId: string; timeZone: string; preselect?: string }) {
  return data.open ? (
    <CarOut trip={data.open} data={data} timeZone={timeZone} userId={userId} />
  ) : (
    <PickCar data={data} timeZone={timeZone} preselect={preselect} />
  );
}

function CarOut({ trip, data, timeZone, userId }: { trip: MyTrip; data: CarScreen; timeZone: string; userId: string }) {
  const when = useWhen(timeZone);
  const [undoState, undoAction, undoing] = useActionState(undoStart, null);
  const [state, action, pending] = useActionState(returnTrip, null);
  const [end, setEnd] = useState("");
  const [photoReady, setPhotoReady] = useState(false);
  const left = useUndoLeft(trip.started_at, data.rules.undoMinutes, data.now);
  const endNum = Number(end.replace(/[^\d]/g, ""));
  const tripKm = end ? endNum - trip.start_odo : null;
  const photoNeeded = data.rules.odoPhoto === "required";

  return (
    <div className="flex flex-col gap-4">
      <Result state={undoState ?? state} />
      <section className="flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
        <h2 className="heading-sm">You have the {trip.car.split(" · ")[0]}</h2>
        <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
          <dt className="text-muted">Car</dt>
          <dd className="font-semibold">{trip.car}</dd>
          <dt className="text-muted">Started</dt>
          <dd className="font-semibold">{when.full(trip.started_at)}</dd>
          <dt className="text-muted">Purpose</dt>
          <dd className="font-semibold">
            {trip.purpose}
            {trip.details ? ` · ${trip.details}` : ""}
          </dd>
          {trip.client_name ? (
            <>
              <dt className="text-muted">Client</dt>
              <dd className="font-semibold">{trip.client_name}</dd>
            </>
          ) : null}
          <dt className="text-muted">Start odo</dt>
          <dd className="font-semibold tabular-nums">{km(trip.start_odo)}</dd>
        </dl>
      </section>

      <form action={action} className="flex flex-col gap-4 rounded-xl border border-line bg-surface p-4">
        <h2 className="heading-sm">Return the car</h2>
        <input type="hidden" name="trip_id" value={trip.id} />
        <Field
          label="End odometer (km)"
          htmlFor="end_odo"
          hint={
            tripKm === null ? (
              "The reading on the dashboard now."
            ) : tripKm < 0 ? (
              <span className="text-danger">That&apos;s lower than the start ({km(trip.start_odo)}). Check the reading.</span>
            ) : (
              <span className="font-semibold text-ink">This trip: {km(tripKm)}</span>
            )
          }
        >
          <input
            id="end_odo"
            name="end_odo"
            inputMode="numeric"
            autoComplete="off"
            required
            value={end}
            onChange={(e) => setEnd(e.target.value)}
            placeholder={String(trip.start_odo)}
            className={`${inputClass} h-14 text-xl tabular-nums`}
          />
        </Field>
        <Field label="Where did you go? (optional)" htmlFor="went_to" hint="For example the suburb, or the places you visited.">
          <input id="went_to" name="went_to" maxLength={300} autoComplete="off" className={`${inputClass} h-12`} />
        </Field>
        {data.rules.odoPhoto !== "off" ? (
          <Field label={`Photo of the odometer${photoNeeded ? "" : " (optional)"}`} htmlFor="photo">
            <FileUpload id="photo" bucket={CAR_FILES} folder={userId} name="photo" accept="image/*" required={photoNeeded} onReady={setPhotoReady} />
          </Field>
        ) : null}
        <Button className={bigButton} disabled={pending || (tripKm !== null && tripKm < 0) || (photoNeeded && !photoReady)}>
          {pending ? "Returning…" : "Return"}
        </Button>
        <p className="text-xs text-muted">The return time is recorded when you press Return.</p>
      </form>

      {left > 0 ? (
        <form action={undoAction} className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-warn-soft px-4 py-3 text-sm text-warn">
          <input type="hidden" name="trip_id" value={trip.id} />
          <span className="font-semibold" suppressHydrationWarning>
            Wrong car or pressed too early? {clock(left)} left to undo.
          </span>
          <Button variant="outline" disabled={undoing}>
            {undoing ? "Undoing…" : "Undo start"}
          </Button>
        </form>
      ) : null}
      <p className="text-xs text-muted">Still out tonight? You&apos;ll get a reminder. If it&apos;s still out tomorrow morning, a car manager is told.</p>
    </div>
  );
}

function PickCar({ data, timeZone, preselect }: { data: CarScreen; timeZone: string; preselect?: string }) {
  const when = useWhen(timeZone);
  const free = (c: CarBoardRow) => !c.trip_id;
  const [carId, setCarId] = useState<string | null>(() => (preselect && data.cars.some((c) => c.id === preselect && free(c)) ? preselect : null));
  const car = data.cars.find((c) => c.id === carId) ?? null;
  const last = data.recent[0];
  const undoLeft = useUndoLeft(last?.returned_at ?? null, data.rules.undoMinutes, data.now);
  const [undoState, undoAction, undoing] = useActionState(undoReturn, null);

  return (
    <div className="flex flex-col gap-4">
      <Result state={undoState} />
      {last && undoLeft > 0 ? (
        <form action={undoAction} className="flex flex-col gap-3 rounded-xl border border-good/40 bg-good-soft p-4 text-sm">
          <input type="hidden" name="trip_id" value={last.id} />
          <p className="text-base font-semibold text-good">
            Returned. That trip was {km(last.km)}.
          </p>
          <p className="text-ink">
            {last.car} · {km(last.start_odo)} → {km(last.end_odo)}
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Button variant="outline" disabled={undoing}>
              {undoing ? "Undoing…" : "Undo return"}
            </Button>
            <span className="text-muted" suppressHydrationWarning>
              {clock(undoLeft)} left to undo
            </span>
          </div>
        </form>
      ) : null}

      {data.cars.length === 0 ? (
        <p className="rounded-xl border border-line bg-surface p-4 text-sm text-muted">No cars have been added yet. A car manager adds them under Manage cars.</p>
      ) : (
        <fieldset className="flex flex-col gap-2">
          <legend className="heading-sm mb-2">Pick a car</legend>
          {data.cars.map((c) => {
            const out = !free(c);
            const chosen = c.id === carId;
            return (
              <label
                key={c.id}
                className={`flex min-h-16 items-center gap-3 rounded-xl border-2 bg-surface px-3 py-2 ${
                  out ? "cursor-not-allowed border-line opacity-60" : chosen ? "cursor-pointer border-brand" : "cursor-pointer border-line hover:border-muted"
                }`}
              >
                <input
                  type="radio"
                  name="car"
                  value={c.id}
                  disabled={out}
                  checked={chosen}
                  onChange={() => setCarId(c.id)}
                  className="h-5 w-5 shrink-0 accent-[var(--brand-primary)]"
                />
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold">{c.name}</span>
                  <span className="block text-sm text-muted">
                    <span className="rounded border border-current px-1 font-semibold tracking-wider">{c.rego}</span>
                    {c.car_type ? ` · ${c.car_type}` : ""}
                  </span>
                </span>
                {out ? (
                  <span className="rounded-full bg-warn-soft px-2.5 py-0.5 text-right text-xs font-semibold text-warn">
                    {c.driver_name?.split(" ")[0]} · since {when.short(c.started_at!)}
                  </span>
                ) : (
                  <span className="rounded-full bg-good-soft px-2.5 py-0.5 text-xs font-semibold text-good">Free</span>
                )}
              </label>
            );
          })}
        </fieldset>
      )}

      {car ? <StartForm key={car.id} car={car} data={data} /> : null}

      {data.recent.length ? (
        <section className="flex flex-col gap-2">
          <h2 className="heading-sm">Your recent trips</h2>
          <ul className="divide-y divide-line rounded-xl border border-line bg-surface">
            {data.recent.slice(0, 5).map((t) => (
              <li key={t.id} className="flex flex-wrap items-center justify-between gap-x-3 gap-y-0.5 px-4 py-2.5 text-sm">
                <span className="min-w-0">
                  <span className="block font-semibold">{t.car}</span>
                  <span className="block text-xs text-muted">
                    {when.full(t.started_at)} · {t.purpose}
                    {t.client_name ? ` · ${t.client_name}` : ""}
                  </span>
                </span>
                <span className="font-semibold tabular-nums">{km(t.km)}</span>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}

function StartForm({ car, data }: { car: CarBoardRow; data: CarScreen }) {
  const [state, action, pending] = useActionState(startTrip, null);
  const [purpose, setPurpose] = useState("");
  const other = data.purposes.find((p) => p.id === purpose)?.name === "Other";
  const { clientField } = data.rules;

  return (
    <form action={action} className="flex flex-col gap-4 rounded-xl border border-brand/40 bg-surface p-4">
      <Result state={state} />
      <h2 className="heading-sm">Start using the {car.name}</h2>
      <input type="hidden" name="car_id" value={car.id} />
      <Field label="Purpose" htmlFor="purpose_id">
        <select id="purpose_id" name="purpose_id" required value={purpose} onChange={(e) => setPurpose(e.target.value)} className={`${inputClass} h-12`}>
          <option value="" disabled>
            Choose one
          </option>
          {data.purposes.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </select>
      </Field>
      {other ? (
        <Field label="What's it for?" htmlFor="details">
          <input id="details" name="details" required maxLength={300} className={`${inputClass} h-12`} />
        </Field>
      ) : null}
      {clientField !== "off" ? (
        <Field label={`Client${clientField === "optional" ? " (optional)" : ""}`} htmlFor="client_id">
          <select id="client_id" name="client_id" required={clientField === "required"} defaultValue="" className={`${inputClass} h-12`}>
            <option value="">{clientField === "required" ? "Choose a client" : "No client"}</option>
            {data.clients.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </Field>
      ) : null}
      <Field label="Start odometer (km)" htmlFor="start_odo" hint="Filled in from the last return. Change it if the dashboard shows something else.">
        <input
          id="start_odo"
          name="start_odo"
          inputMode="numeric"
          autoComplete="off"
          required
          defaultValue={car.odometer}
          className={`${inputClass} h-14 text-xl tabular-nums`}
        />
      </Field>
      <Button className={bigButton} disabled={pending}>
        {pending ? "Starting…" : "Start"}
      </Button>
      <p className="text-xs text-muted">You&apos;re the driver, and the date and time are recorded when you press Start.</p>
    </form>
  );
}

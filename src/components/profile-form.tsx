// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { PhoneField } from "@/components/phone-field";
import { useActionState, useTransition } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";
import { saveProfile } from "@/app/(portal)/people/actions";
import type { PersonCard } from "@/lib/profiles";
import { DAYS, EMPLOYMENT, SHIFTS } from "@/lib/profiles-shared";

// cmeprojects: edit a staff profile. Save stays greyed out until something
// changes; employment details only show for people who manage staff.
export function ProfileForm({ person, employment }: { person: PersonCard; employment: boolean }) {
  const [state, action, pending] = useActionState(saveProfile, null);
  const { ref, dirty, markClean } = useDirty();
  const [, start] = useTransition();
  useAfterSuccess(state, markClean);
  const d = person.directory;
  const p = person.private;
  return (
    <form
      ref={ref}
      onSubmit={(e) => {
        // Keep what was typed on screen, even if saving fails (React clears a form after its action).
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        start(() => action(data));
      }}
      className="flex flex-col gap-5"
    >
      <input type="hidden" name="user_id" value={person.id} />
      {employment ? <input type="hidden" name="employment" value="1" /> : null}
      <section className="grid gap-4 sm:grid-cols-2">
        <Field label="Preferred name (optional)" htmlFor="pf-preferred" hint="What people call you, if it's not your full name.">
          <input id="pf-preferred" name="preferred_name" defaultValue={d.preferred_name} maxLength={60} className={inputClass} />
        </Field>
        <PhoneField id="pf-phone" name="work_phone" label="Contact phone" defaultValue={d.work_phone} showOptional={false} />
        <div className="sm:col-span-2">
          <Field label="Skills and qualifications (optional)" htmlFor="pf-skills" hint="Separate with commas, for example: First Aid, Driver's licence, Medication.">
            <input id="pf-skills" name="skills" defaultValue={d.skills.join(", ")} className={inputClass} />
          </Field>
        </div>
      </section>
      {employment ? (
        <section className="grid gap-4 rounded-lg border border-line p-4 sm:grid-cols-2">
          <p className="text-sm font-semibold sm:col-span-2">Employment details</p>
          <Field label="Department" htmlFor="pf-dept">
            <input id="pf-dept" name="department" defaultValue={d.department} maxLength={80} className={inputClass} />
          </Field>
          <Field label="Employment type" htmlFor="pf-type">
            <select id="pf-type" name="employment_type" defaultValue={p?.employment_type ?? ""} className={inputClass}>
              {Object.entries(EMPLOYMENT).map(([v, label]) => (
                <option key={v} value={v}>
                  {label}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Start date" htmlFor="pf-start">
            <input id="pf-start" name="start_date" type="date" defaultValue={p?.start_date ?? ""} className={inputClass} />
          </Field>
          <Field label="Employee ID" htmlFor="pf-eid">
            <input id="pf-eid" name="employee_id" defaultValue={p?.employee_id ?? ""} maxLength={40} className={inputClass} />
          </Field>
        </section>
      ) : null}
      <section className="grid gap-4 sm:grid-cols-2">
        <p className="text-sm font-semibold sm:col-span-2">Private details (optional)</p>
        <div className="sm:col-span-2">
          <Field label="Address" htmlFor="pf-address">
            <input id="pf-address" name="address" defaultValue={p?.address ?? ""} maxLength={300} className={inputClass} autoComplete="street-address" />
          </Field>
        </div>
        <Field label="Emergency contact's name" htmlFor="pf-em-name" hint="Who to call, and how they're related, for example Jo Smith (partner).">
          <input id="pf-em-name" name="emergency_name" defaultValue={p?.emergency_name ?? ""} maxLength={100} autoComplete="off" className={inputClass} />
        </Field>
        <PhoneField id="pf-em-phone" name="emergency_phone" label="Emergency contact's phone" defaultValue={p?.emergency_phone ?? ""} showOptional={false} />
      </section>
      <fieldset className="flex min-w-0 flex-col gap-2">
        <legend className="mb-1 text-sm font-semibold">Usual availability (optional)</legend>
        <div className="overflow-x-auto">
          <table className="text-center text-sm">
            <thead>
              <tr>
                <th />
                {DAYS.map(([k, label]) => (
                  <th key={k} scope="col" className="px-2 pb-1 font-medium text-muted">
                    {label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {SHIFTS.map(([s, label]) => (
                <tr key={s}>
                  <th scope="row" className="pr-3 text-left font-medium text-muted">
                    {label}
                  </th>
                  {DAYS.map(([day, dayLabel]) => (
                    <td key={day} className="px-2 py-1">
                      <input
                        type="checkbox"
                        name={`avail_${day}_${s}`}
                        aria-label={`${dayLabel} ${label}`}
                        defaultChecked={(p?.availability?.[day] ?? []).includes(s)}
                        className="h-5 w-5 accent-[var(--brand-primary)]"
                      />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </fieldset>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button className="self-start" disabled={pending || !dirty}>
        {pending ? "Saving…" : "Save profile"}
      </Button>
    </form>
  );
}

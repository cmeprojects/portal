// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { submitRequest } from "../actions";
import { LEAVE_TYPES, REQUEST_TYPES } from "@/lib/requests-shared";
import { DAYS, SHIFTS } from "@/lib/profiles-shared";

// cmeprojects: pick a request type, then fill in its short form.
export function NewRequestForm({ types, colleagues, today, initial }: { types: string[]; colleagues: { id: string; name: string }[]; today: string; initial?: string }) {
  const [state, action, pending] = useActionState(submitRequest, null);
  const offered = REQUEST_TYPES.filter((t) => types.includes(t.key));
  const [type, setType] = useState(initial && types.includes(initial) ? initial : (offered[0]?.key ?? ""));
  const [leave, setLeave] = useState("annual");
  const reason = (
    <Field label="Reason (optional)" htmlFor="rq-reason">
      <textarea id="rq-reason" name="reason" rows={3} className={`${inputClass} h-auto py-3`} />
    </Field>
  );
  return (
    <form action={action} className="flex flex-col gap-5">
      <fieldset>
        <legend className="mb-2 text-sm font-semibold">What do you need?</legend>
        <div className="grid gap-2 sm:grid-cols-2">
          {offered.map((t) => (
            <label key={t.key} className={`flex cursor-pointer items-start gap-3 rounded-lg border p-3 ${type === t.key ? "border-brand bg-brand-soft" : "border-line hover:bg-page"}`}>
              <input type="radio" name="type" value={t.key} checked={type === t.key} onChange={() => setType(t.key)} className="mt-0.5 h-5 w-5 accent-[var(--brand-primary)]" />
              <span>
                <span className="block font-semibold">{t.label}</span>
                <span className="block text-xs text-muted">{t.hint}</span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      {type === "leave" ? (
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Type of leave" htmlFor="rq-leave">
            <select id="rq-leave" name="leave_type" value={leave} onChange={(e) => setLeave(e.target.value)} className={inputClass}>
              {LEAVE_TYPES.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </Field>
          <input type="hidden" name="leave_label" value={LEAVE_TYPES.find(([v]) => v === leave)?.[1] ?? "Leave"} />
          <label className="flex items-center gap-2 self-end pb-2 text-sm">
            <input type="checkbox" name="part_day" className="h-5 w-5 accent-[var(--brand-primary)]" /> Part of a day only
          </label>
          <Field label="First day" htmlFor="rq-start">
            <input id="rq-start" name="start_date" type="date" min={today} required className={inputClass} />
          </Field>
          <Field label="Last day" htmlFor="rq-end" hint="Leave blank for one day.">
            <input id="rq-end" name="end_date" type="date" min={today} className={inputClass} />
          </Field>
          <div className="sm:col-span-2">{reason}</div>
        </div>
      ) : null}

      {type === "swap" ? (
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Date of the shift" htmlFor="rq-start">
            <input id="rq-start" name="start_date" type="date" min={today} required className={inputClass} />
          </Field>
          <Field label="Your shift" htmlFor="rq-shift" hint="For example: 3 pm to 11 pm at Unit 4.">
            <input id="rq-shift" name="my_shift" required className={inputClass} />
          </Field>
          <div className="sm:col-span-2">
            <Field label="Swapping with" htmlFor="rq-with" hint="They'll be asked to accept first.">
              <select id="rq-with" name="swap_with" required defaultValue="" className={`${inputClass} sm:max-w-md`}>
                <option value="" disabled>
                  Choose a colleague
                </option>
                {colleagues.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <div className="sm:col-span-2">{reason}</div>
        </div>
      ) : null}

      {type === "shift" ? (
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Date of the shift" htmlFor="rq-start">
            <input id="rq-start" name="start_date" type="date" min={today} required className={inputClass} />
          </Field>
          <span />
          <Field label="Current shift" htmlFor="rq-cur">
            <input id="rq-cur" name="current_shift" required placeholder="e.g. 7 am to 3 pm" className={inputClass} />
          </Field>
          <Field label="What you'd like instead" htmlFor="rq-new">
            <input id="rq-new" name="new_shift" required placeholder="e.g. 9 am to 5 pm" className={inputClass} />
          </Field>
          <div className="sm:col-span-2">{reason}</div>
        </div>
      ) : null}

      {type === "availability" ? (
        <div className="flex flex-col gap-4">
          <Field label="Starting from" htmlFor="rq-start">
            <input id="rq-start" name="start_date" type="date" min={today} required className={`${inputClass} sm:max-w-56`} />
          </Field>
          <fieldset>
            <legend className="mb-1 text-sm font-medium">When can you usually work?</legend>
            <div className="overflow-x-auto">
              <table className="text-center text-sm">
                <thead>
                  <tr>
                    <th />
                    {DAYS.map(([k, l]) => (
                      <th key={k} scope="col" className="px-2 pb-1 font-medium text-muted">
                        {l}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {SHIFTS.map(([s, l]) => (
                    <tr key={s}>
                      <th scope="row" className="pr-3 text-left font-medium text-muted">
                        {l}
                      </th>
                      {DAYS.map(([d, dl]) => (
                        <td key={d} className="px-2 py-1">
                          <input type="checkbox" name={`avail_${d}_${s}`} aria-label={`${dl} ${l}`} className="h-5 w-5 accent-[var(--brand-primary)]" />
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </fieldset>
          {reason}
        </div>
      ) : null}

      {type === "timesheet" ? (
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Date worked" htmlFor="rq-wd">
            <input id="rq-wd" name="work_date" type="date" max={today} required className={inputClass} />
          </Field>
          <span />
          <Field label="What's wrong" htmlFor="rq-wrong">
            <input id="rq-wrong" name="wrong" placeholder="e.g. finish time shows 3 pm" className={inputClass} />
          </Field>
          <Field label="Correct times" htmlFor="rq-correct">
            <input id="rq-correct" name="correct" required placeholder="e.g. 7 am to 4 pm" className={inputClass} />
          </Field>
        </div>
      ) : null}

      {type === "hr" || type === "other" ? (
        <div className="flex flex-col gap-4">
          <Field label="Subject" htmlFor="rq-subject">
            <input id="rq-subject" name="subject" required maxLength={200} className={inputClass} />
          </Field>
          <Field label="Details" htmlFor="rq-msg">
            <textarea id="rq-msg" name="message" rows={5} required className={`${inputClass} h-auto py-3`} />
          </Field>
        </div>
      ) : null}

      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button className="self-start" disabled={pending || !type}>
        {pending ? "Sending…" : "Send request"}
      </Button>
    </form>
  );
}

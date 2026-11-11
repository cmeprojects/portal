// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Cake, Save } from "lucide-react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";
import { saveBirthday } from "./birthday-actions";

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

// cmeprojects Phase 5: day and month only; shown to colleagues only if you choose.
export function BirthdayForm({ month, day, show }: { month: number | null; day: number | null; show: boolean }) {
  const [state, run, pending] = useActionState(saveBirthday, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form ref={ref} action={run} className="flex flex-col gap-3">
      <h2 className="heading-sm flex items-center gap-2">
        <Cake aria-hidden="true" className="size-5 text-brand" /> Birthday (optional)
      </h2>
      <p className="text-sm text-muted">Just the day and month: we never ask for the year or show anyone&apos;s age.</p>
      <div className="grid max-w-md grid-cols-2 gap-3">
        <Field label="Day" htmlFor="bd-day">
          <select id="bd-day" name="day" defaultValue={day ?? ""} className={inputClass}>
            <option value="">Not set</option>
            {Array.from({ length: 31 }, (_, i) => i + 1).map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Month" htmlFor="bd-month">
          <select id="bd-month" name="month" defaultValue={month ?? ""} className={inputClass}>
            <option value="">Not set</option>
            {MONTHS.map((m, i) => (
              <option key={m} value={i + 1}>
                {m}
              </option>
            ))}
          </select>
        </Field>
      </div>
      <label className="flex items-start gap-2 text-sm">
        <input type="checkbox" name="show" defaultChecked={show} className="mt-0.5 size-4 shrink-0 accent-[var(--accent)]" />
        <span>
          Show my birthday to colleagues
          <span className="block text-xs text-muted">Off by default. When on, colleagues see a birthday greeting on the day. Change it any time.</span>
        </span>
      </label>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending || !dirty}>
        <Save aria-hidden="true" className="size-4" />
        {pending ? "Saving…" : "Save birthday"}
      </Button>
    </form>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, useTransition } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { confirmSubmit } from "@/components/confirm";
import { toast } from "@/components/toast";
import { useAfterSuccess } from "@/components/use-after-success";
import { ACCESS_AREAS, ACCESS_HINT, ACCESS_LABEL, type AccessArea } from "@/lib/access";
import { giveAccess, removeAccess } from "./actions";

type Option = { id: string; name: string };

// cmeprojects: give access. The system admin chooses managers (and staff
// admins for Staff details); a manager passes on only what they hold.
export function GiveAccessForm({
  admin,
  areas,
  managers,
  staffAdmins,
  teams,
  people,
  tfnOk,
}: {
  admin: boolean;
  areas: AccessArea[];
  managers: Option[];
  staffAdmins: Option[];
  teams: Option[];
  people: Option[];
  tfnOk: boolean;
}) {
  const [state, run, pending] = useActionState(giveAccess, null);
  const [area, setArea] = useState<AccessArea>(areas[0]);
  const [scope, setScope] = useState<"all" | "teams" | "people">("all");
  const [formKey, setFormKey] = useState(0);
  useAfterSuccess(state, () => {
    setScope("all");
    setFormKey((k) => k + 1);
  });
  const who = admin ? (area === "staff_details" ? [...managers, ...staffAdmins] : managers) : staffAdmins;
  if (!areas.length) return null;
  return (
    <form key={formKey} action={run} className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Access to" htmlFor="ga-area" hint={ACCESS_HINT[area]}>
          <select id="ga-area" name="area" value={area} onChange={(e) => setArea(e.target.value as AccessArea)} className={inputClass}>
            {ACCESS_AREAS.filter((a) => areas.includes(a)).map((a) => (
              <option key={a} value={a}>
                {ACCESS_LABEL[a]}
              </option>
            ))}
          </select>
        </Field>
        <Field
          label="Give it to"
          htmlFor="ga-user"
          hint={admin ? (area === "staff_details" ? "Managers or staff admins." : "Managers only. They can pass it on to staff admins if you allow it.") : "Staff admins only."}
        >
          <select id="ga-user" name="user_id" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose a person
            </option>
            {who.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <fieldset className="flex flex-col gap-2">
        <legend className="mb-1 text-sm font-semibold">Covers</legend>
        <div className="flex flex-wrap gap-4 text-sm">
          {(
            [
              ["all", "All staff"],
              ["teams", "Chosen teams"],
              ["people", "Specific people"],
            ] as const
          ).map(([v, label]) => (
            <label key={v} className="flex items-center gap-2">
              <input type="radio" name="scope" value={v} checked={scope === v} onChange={() => setScope(v)} className="size-4 accent-[var(--accent)]" />
              {label}
            </label>
          ))}
        </div>
        {scope === "teams" ? (
          <div className="grid max-h-48 gap-1 overflow-y-auto rounded-lg border border-line p-3 text-sm sm:grid-cols-2">
            {teams.length ? (
              teams.map((t) => (
                <label key={t.id} className="flex items-center gap-2">
                  <input type="checkbox" name="teams" value={t.id} className="size-4 accent-[var(--accent)]" /> {t.name}
                </label>
              ))
            ) : (
              <p className="text-muted">No teams you can choose.</p>
            )}
          </div>
        ) : null}
        {scope === "people" ? (
          <div className="grid max-h-56 gap-1 overflow-y-auto rounded-lg border border-line p-3 text-sm sm:grid-cols-2">
            {people.map((p) => (
              <label key={p.id} className="flex items-center gap-2">
                <input type="checkbox" name="people" value={p.id} className="size-4 accent-[var(--accent)]" /> {p.name}
              </label>
            ))}
          </div>
        ) : null}
      </fieldset>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Ends on (optional)" htmlFor="ga-expires" hint="Access stops at the end of this day. Leave empty for no end date.">
          <input id="ga-expires" name="expires" type="date" className={inputClass} />
        </Field>
        <Field label="Reason (optional)" htmlFor="ga-note">
          <input id="ga-note" name="note" maxLength={300} placeholder="For example: covering payroll in December" className={inputClass} />
        </Field>
      </div>
      <div className="flex flex-col gap-2 text-sm">
        {admin ? (
          <label className="flex items-start gap-2">
            <input type="checkbox" name="pass_on" className="mt-0.5 size-4 accent-[var(--accent)]" />
            <span>
              May pass it on
              <span className="block text-xs text-muted">They can give the same access (never wider or longer) to staff admins. Removing theirs removes those too.</span>
            </span>
          </label>
        ) : null}
        {area === "payroll_tax" && tfnOk ? (
          <label className="flex items-start gap-2">
            <input type="checkbox" name="tfn" className="mt-0.5 size-4 accent-[var(--accent)]" />
            <span>
              Can reveal tax file numbers
              <span className="block text-xs text-muted">Without this, TFNs show masked. Every reveal is recorded.</span>
            </span>
          </label>
        ) : null}
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button className="self-start" disabled={pending || !who.length}>
        {pending ? "Saving…" : "Give access"}
      </Button>
    </form>
  );
}

export function RemoveAccessButton({ id, name, what, passedOn }: { id: string; name: string; what: string; passedOn: number }) {
  const [error, setError] = useState("");
  const [pending, start] = useTransition();
  // The row disappears once removed, so the confirmation is a toast (shown
  // straight from the result, before the row goes).
  const run = (form: FormData) =>
    start(async () => {
      const r = await removeAccess(null, form);
      if (r?.error) setError(r.error);
      else if (r?.message) toast(r.message);
    });
  return (
    <form
      action={run}
      onSubmit={confirmSubmit(
        `Remove ${name}'s ${what} access? It stops straight away${passedOn ? `, and so does the access they passed on to ${passedOn} ${passedOn === 1 ? "person" : "people"}` : ""}. It stays in the history.`,
        { action: "Remove access" },
      )}
      className="flex flex-col items-end gap-1"
    >
      <input type="hidden" name="id" value={id} />
      <Button variant="outline" size="sm" disabled={pending}>
        {pending ? "Removing…" : "Remove"}
      </Button>
      {error ? <span className="text-xs text-danger">{error}</span> : null}
    </form>
  );
}

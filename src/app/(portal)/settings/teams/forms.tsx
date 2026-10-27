// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import type { FormState } from "@/lib/form";
import { createTeam, saveTeam } from "./actions";

type Person = { id: string; full_name: string; email: string };

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export function NewTeamForm() {
  const [state, action, pending] = useActionState(createTeam, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <Result state={state} />
      <div className="flex flex-wrap items-end gap-3">
        <div className="min-w-60 flex-1">
          <Field label="Team name" htmlFor="team-name">
            <input id="team-name" name="name" required placeholder="e.g. Derrimut house" className={inputClass} />
          </Field>
        </div>
        <Button className="h-12" disabled={pending}>Add team</Button>
      </div>
    </form>
  );
}

export function TeamForm({
  team,
  leaderIds,
  candidates,
}: {
  team: { id: string; name: string; active: boolean };
  leaderIds: string[];
  candidates: Person[];
}) {
  const [state, action, pending] = useActionState(saveTeam, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      <input type="hidden" name="id" value={team.id} />
      <Field label="Team name" htmlFor={`name-${team.id}`}>
        <input id={`name-${team.id}`} name="name" defaultValue={team.name} required className={inputClass} />
      </Field>
      <fieldset className="flex flex-col gap-2">
        <legend className="mb-1 text-[15px] font-semibold">Team leaders</legend>
        {candidates.length === 0 ? (
          <p className="text-sm text-muted">Give someone the Team leader role on the Staff &amp; roles page first.</p>
        ) : (
          candidates.map((c) => (
            <label key={c.id} className="flex min-h-11 items-center gap-3 text-[15px]">
              <input type="checkbox" name="leaders" value={c.id} defaultChecked={leaderIds.includes(c.id)} className="h-5 w-5 accent-[var(--brand-primary)]" />
              {c.full_name || c.email}
            </label>
          ))
        )}
      </fieldset>
      <label className="flex min-h-11 items-center gap-3 text-[15px]">
        <input type="checkbox" name="active" defaultChecked={team.active} className="h-5 w-5 accent-[var(--brand-primary)]" />
        Team is in use
      </label>
      <Button className="self-start" disabled={pending}>{pending ? "Saving…" : "Save team"}</Button>
    </form>
  );
}

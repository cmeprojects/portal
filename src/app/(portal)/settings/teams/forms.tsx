// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { PeopleChecklist, type Person } from "@/components/people-picker";
import type { FormState } from "@/lib/form";
import { createTeam, saveTeam } from "./actions";

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
  memberIds,
  leaderId,
  members,
  leaders,
  needsApproval,
}: {
  team: { id: string; name: string; active: boolean };
  memberIds: string[];
  leaderId: string | null;
  // Support workers (any team) and team leaders not already in another team.
  members: Person[];
  // Team leaders who could lead this team.
  leaders: Person[];
  needsApproval: boolean;
}) {
  const [state, action, pending] = useActionState(saveTeam, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      <input type="hidden" name="id" value={team.id} />
      <Field label="Team name" htmlFor={`name-${team.id}`}>
        <input id={`name-${team.id}`} name="name" defaultValue={team.name} required className={inputClass} />
      </Field>
      <Field label="Team leader" htmlFor={`leader-${team.id}`} hint="A team leader leads one team.">
        <select id={`leader-${team.id}`} name="leader" defaultValue={leaderId ?? ""} className={inputClass}>
          <option value="">No team leader</option>
          {leaders.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </select>
      </Field>
      <PeopleChecklist
        name="members"
        label="Members"
        people={members}
        exclude={leaderId ? [leaderId] : []}
        initial={memberIds.filter((id) => id !== leaderId)}
      />
      {needsApproval ? (
        <Field label="Reason (optional)" htmlFor={`reason-${team.id}`} hint="Changes to who's in the team go to a manager to approve. The name saves straight away.">
          <input id={`reason-${team.id}`} name="reason" className={inputClass} />
        </Field>
      ) : null}
      <label className="flex min-h-11 items-center gap-3 text-sm">
        <input type="checkbox" name="active" defaultChecked={team.active} className="h-5 w-5 accent-[var(--brand-primary)]" />
        Team is in use
      </label>
      <Button className="self-start" disabled={pending}>{pending ? "Saving…" : "Save team"}</Button>
    </form>
  );
}

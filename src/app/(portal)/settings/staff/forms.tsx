// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { invitePerson, resendInvite, resetTwoFactor, setActive, updatePerson } from "./actions";

type Team = { id: string; name: string };

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

function RoleOptions({ roles }: { roles: Role[] }) {
  return roles.map((r) => (
    <option key={r} value={r}>
      {ROLE_LABELS[r]}
    </option>
  ));
}

function TeamOptions({ teams }: { teams: Team[] }) {
  return (
    <>
      <option value="">No team</option>
      {teams.map((t) => (
        <option key={t.id} value={t.id}>
          {t.name}
        </option>
      ))}
    </>
  );
}

export function InviteForm({ roles, teams }: { roles: Role[]; teams: Team[] }) {
  const [state, action, pending] = useActionState(invitePerson, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      <div className="grid gap-4 md:grid-cols-[2fr_3fr_1.4fr_1.4fr_auto] md:items-end">
        <Field label="Full name" htmlFor="inv-name">
          <input id="inv-name" name="full_name" required placeholder="e.g. Jordan Lee" className={inputClass} />
        </Field>
        <Field label="Email" htmlFor="inv-email">
          <input id="inv-email" name="email" type="email" required placeholder="name@gmail.com" className={inputClass} />
        </Field>
        <Field label="Role" htmlFor="inv-role">
          <select id="inv-role" name="role" defaultValue="support_worker" className={inputClass}>
            <RoleOptions roles={roles} />
          </select>
        </Field>
        <Field label="Team" htmlFor="inv-team">
          <select id="inv-team" name="team_id" defaultValue="" className={inputClass}>
            <TeamOptions teams={teams} />
          </select>
        </Field>
        <Button className="h-12" disabled={pending}>
          {pending ? "Sending…" : "Send invite"}
        </Button>
      </div>
    </form>
  );
}

export type PersonRow = {
  id: string;
  full_name: string;
  email: string;
  role: Role;
  team_id: string | null;
  active: boolean;
  joined: boolean;
  isMe: boolean;
  editable: boolean;
};

export function PersonEditor({
  person,
  roles,
  teams,
  canResetMfa,
}: {
  person: PersonRow;
  roles: Role[];
  teams: Team[];
  canResetMfa: boolean;
}) {
  const [saveState, saveAction, saving] = useActionState(updatePerson, null);
  const [activeState, activeAction, toggling] = useActionState(setActive, null);
  const [inviteState, inviteAction, resending] = useActionState(resendInvite, null);
  const [mfaState, mfaAction, resetting] = useActionState(resetTwoFactor, null);
  const choices = roles.includes(person.role) ? roles : [person.role, ...roles];

  return (
    <div className="flex flex-col gap-3 border-t border-line pt-4">
      <Result state={saveState ?? activeState ?? inviteState ?? mfaState} />
      <form action={saveAction} className="flex flex-wrap items-end gap-3">
        <input type="hidden" name="id" value={person.id} />
        <div className="min-w-44 flex-1">
          <Field label="Role" htmlFor={`role-${person.id}`}>
            <select id={`role-${person.id}`} name="role" defaultValue={person.role} disabled={person.isMe} className={inputClass}>
              <RoleOptions roles={choices} />
            </select>
          </Field>
        </div>
        <div className="min-w-44 flex-1">
          <Field label="Team" htmlFor={`team-${person.id}`}>
            <select id={`team-${person.id}`} name="team_id" defaultValue={person.team_id ?? ""} className={inputClass}>
              <TeamOptions teams={teams} />
            </select>
          </Field>
        </div>
        {person.isMe ? <input type="hidden" name="role" value={person.role} /> : null}
        <Button className="h-12" disabled={saving}>
          {saving ? "Saving…" : "Save"}
        </Button>
      </form>
      <div className="flex flex-wrap gap-2">
        {!person.joined && person.active ? (
          <form action={inviteAction}>
            <input type="hidden" name="id" value={person.id} />
            <Button variant="outline" disabled={resending}>Resend invite</Button>
          </form>
        ) : null}
        {canResetMfa && person.joined ? (
          <form action={mfaAction}>
            <input type="hidden" name="id" value={person.id} />
            <Button variant="outline" disabled={resetting}>Reset two-factor login</Button>
          </form>
        ) : null}
        {!person.isMe ? (
          <form
            action={activeAction}
            onSubmit={(e) => {
              if (person.active && !confirm(`Deactivate ${person.full_name || person.email}? They won't be able to sign in. Their history stays.`)) {
                e.preventDefault();
              }
            }}
          >
            <input type="hidden" name="id" value={person.id} />
            <input type="hidden" name="active" value={person.active ? "false" : "true"} />
            <Button variant={person.active ? "danger" : "outline"} disabled={toggling}>
              {person.active ? "Deactivate" : "Reactivate"}
            </Button>
          </form>
        ) : null}
      </div>
    </div>
  );
}

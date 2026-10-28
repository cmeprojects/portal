// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, roleChoiceValue, type JobTitle, type Role } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { giveConditionalRole, invitePerson, resendInvite, resetTwoFactor, setActive, updatePerson } from "./actions";

type Team = { id: string; name: string };

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

// Job titles grouped under their access level, then the plain access level.
function RoleOptions({ roles, titles }: { roles: Role[]; titles: JobTitle[] }) {
  return roles.map((r) => {
    if (r === "new_starter") {
      return (
        <option key={r} value={roleChoiceValue(r, null)}>
          New starter (general invite, no role yet)
        </option>
      );
    }
    const mine = titles.filter((t) => t.access_level === r && t.active);
    return (
      <optgroup key={r} label={ROLE_LABELS[r]}>
        {mine.map((t) => (
          <option key={t.id} value={roleChoiceValue(r, t.id)}>
            {t.name}
          </option>
        ))}
        <option value={roleChoiceValue(r, null)}>{mine.length ? `${ROLE_LABELS[r]} (no job title)` : ROLE_LABELS[r]}</option>
      </optgroup>
    );
  });
}

// A general invite: just their name and email. They join as a new starter,
// do their onboarding, and get a role and team afterwards.
export function InviteForm() {
  const [state, action, pending] = useActionState(invitePerson, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <Result state={state} />
      <div className="grid gap-4 md:grid-cols-[2fr_3fr_auto] md:items-end">
        <Field label="Full name" htmlFor="inv-name">
          <input id="inv-name" name="full_name" required placeholder="e.g. Jordan Lee" className={inputClass} />
        </Field>
        <Field label="Email" htmlFor="inv-email">
          <input id="inv-email" name="email" type="email" required placeholder="name@gmail.com" className={inputClass} />
        </Field>
        <Button className="h-12" disabled={pending}>
          {pending ? "Sending…" : "Send invite"}
        </Button>
      </div>
      <p className="text-sm text-muted">
        They&apos;ll get a welcome email and start their onboarding. Set their role and team here once onboarding is done.
      </p>
    </form>
  );
}

export type PersonRow = {
  id: string;
  full_name: string;
  email: string;
  role: Role;
  job_title_id: string | null;
  active: boolean;
  // New starters only: what's still missing from onboarding (empty = done).
  missing: string[] | null;
  joined: boolean;
  isMe: boolean;
  editable: boolean;
};

export function PersonEditor({
  person,
  roles,
  titles,
  teams,
  canResetMfa,
  needsApproval,
  isManager,
}: {
  person: PersonRow;
  roles: Role[];
  titles: JobTitle[];
  teams: Team[];
  // Managers give conditional roles straight away; staff admins ask.
  isManager: boolean;
  canResetMfa: boolean;
  // Staff admins' role changes go to a manager for approval.
  needsApproval: boolean;
}) {
  const [saveState, saveAction, saving] = useActionState(updatePerson, null);
  const [activeState, activeAction, toggling] = useActionState(setActive, null);
  const [inviteState, inviteAction, resending] = useActionState(resendInvite, null);
  const [mfaState, mfaAction, resetting] = useActionState(resetTwoFactor, null);
  // "New starter" is only for people who don't have a role yet.
  const offered = roles.filter((r) => r !== "new_starter" || person.role === "new_starter");
  const choices = offered.includes(person.role) ? offered : [person.role, ...offered];

  return (
    <div className="flex flex-col gap-3 border-t border-line pt-4">
      <Result state={saveState ?? activeState ?? inviteState ?? mfaState} />
      {person.isMe ? (
        <p className="text-sm text-muted">You can&apos;t change your own role. Ask a manager.</p>
      ) : person.role === "new_starter" && person.missing?.length ? (
        <ConditionalRoleForm person={person} roles={offered.filter((r) => r !== "new_starter")} titles={titles} teams={teams} isManager={isManager} />
      ) : (
        <form action={saveAction} className="flex flex-wrap items-end gap-3">
          <input type="hidden" name="id" value={person.id} />
          <div className="min-w-56 flex-1">
            <Field label="Role" htmlFor={`role-${person.id}`}>
              <select id={`role-${person.id}`} name="role" defaultValue={roleChoiceValue(person.role, person.job_title_id)} className={inputClass}>
                <RoleOptions roles={choices} titles={titles} />
              </select>
            </Field>
          </div>
          {needsApproval ? (
            <div className="min-w-60 flex-[2]">
              <Field label="Reason (optional)" htmlFor={`reason-${person.id}`} hint="Role changes go to a manager to approve.">
                <input id={`reason-${person.id}`} name="reason" className={inputClass} />
              </Field>
            </div>
          ) : null}
          <Button className="h-12" disabled={saving}>
            {saving ? "Saving…" : needsApproval ? "Send for approval" : "Save"}
          </Button>
        </form>
      )}
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

function inDays(n: number) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toLocaleDateString("en-CA");
}

// Onboarding isn't finished: a role can still be given, on condition.
function ConditionalRoleForm({
  person,
  roles,
  titles,
  teams,
  isManager,
}: {
  person: PersonRow;
  roles: Role[];
  titles: JobTitle[];
  teams: Team[];
  isManager: boolean;
}) {
  const [state, action, pending] = useActionState(giveConditionalRole, null);
  return (
    <form action={action} className="flex flex-col gap-4 rounded-md border border-warn/40 bg-warn-soft/40 p-4">
      <Result state={state} />
      <input type="hidden" name="id" value={person.id} />
      <div className="text-sm">
        <p className="font-semibold">Onboarding isn&apos;t finished yet. Still to do:</p>
        <ul className="mt-1 list-disc pl-5">
          {person.missing!.map((m) => (
            <li key={m}>{m}</li>
          ))}
        </ul>
        <p className="mt-2 text-muted">
          You can give a conditional role with a deadline. {isManager ? "" : "A manager needs to approve it. "}They&apos;ll get a
          &ldquo;Finish onboarding&rdquo; task (medium) due on the deadline.
        </p>
      </div>
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="Role" htmlFor={`crole-${person.id}`}>
          <select id={`crole-${person.id}`} name="role" defaultValue={roleChoiceValue("support_worker", null)} className={inputClass}>
            <RoleOptions roles={roles} titles={titles} />
          </select>
        </Field>
        <Field label="Finish onboarding by" htmlFor={`cdeadline-${person.id}`}>
          <input id={`cdeadline-${person.id}`} name="deadline" type="date" required defaultValue={inDays(14)} min={inDays(0)} className={inputClass} />
        </Field>
      </div>
      {teams.length ? (
        <fieldset className="flex flex-col gap-1">
          <legend className="mb-1 text-sm font-semibold">Teams (support workers and team leaders)</legend>
          <div className="flex flex-wrap gap-x-5">
            {teams.map((t) => (
              <label key={t.id} className="flex min-h-11 items-center gap-2 text-sm">
                <input type="checkbox" name="teams" value={t.id} className="h-5 w-5 accent-[var(--brand-primary)]" />
                {t.name}
              </label>
            ))}
          </div>
        </fieldset>
      ) : null}
      <Field label="Reason" htmlFor={`creason-${person.id}`}>
        <textarea id={`creason-${person.id}`} name="reason" required rows={2} placeholder="e.g. Rostered from Monday; police check is on its way" className={`${inputClass} min-h-20 py-3`} />
      </Field>
      <Button className="self-start" disabled={pending}>
        {pending ? "Saving…" : isManager ? "Give conditional role" : "Send to a manager for approval"}
      </Button>
    </form>
  );
}

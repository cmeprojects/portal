// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { toast } from "@/components/toast";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";
import { confirmSubmit } from "@/components/confirm";
import { startTransition, useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, inCoreTeam, roleChoiceValue, type JobTitle, type Role } from "@/lib/roles";
import type { FormState } from "@/lib/form";
import { clearCarPin,
  removePersonPhoto, giveConditionalRole, invitePerson, resendInvite, deleteUnstarted, resetTwoFactor, savePerson, sendResetLink, setActive, setMfaExempt, signOutEverywhere } from "./actions";

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
        <Button className="h-11" disabled={pending}>
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
  // The only active manager: only the system admin can change or deactivate them.
  lastManager: boolean;
  joined: boolean;
  openedLink?: boolean;
  isMe: boolean;
  editable: boolean;
  // The teams they're in (core-team roles, like managers and staff admins, don't need one).
  teamIds: string[];
  // Let off two-factor login by the system admin (cmeprojects; null before update 48).
  mfaExempt?: boolean | null;
  // Has a profile photo (cmeprojects; staff photos).
  hasPhoto?: boolean;
};

export function PersonEditor({
  person,
  roles,
  titles,
  teams,
  canResetMfa,
  canHelpSignIn = false,
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
  // Send a reset link, reset two-factor, clear the Cars app PIN.
  canHelpSignIn?: boolean;
  // Staff admins' role changes go to a manager for approval.
  needsApproval: boolean;
}) {
  const [saveState, saveAction, saving] = useActionState(savePerson, null);
  const { ref: dirtyRef, dirty, markClean } = useDirty();
  useAfterSuccess(saveState, markClean);
  const [activeState, activeAction, toggling] = useActionState(setActive, null);
  const [inviteState, inviteAction, resending] = useActionState(resendInvite, null);
  // The person's card disappears once they're deleted, so say so with a toast.
  const [removeState, removeAction, removing] = useActionState(async (prev: Awaited<ReturnType<typeof deleteUnstarted>>, f: FormData) => {
    const r = await deleteUnstarted(prev, f);
    if (r?.message && !r.error) toast(r.message);
    return r;
  }, null);
  const [mfaState, mfaAction, resetting] = useActionState(resetTwoFactor, null);
  const [linkState, linkAction, sendingLink] = useActionState(sendResetLink, null);
  const [pinState, pinAction, clearingPin] = useActionState(clearCarPin, null);
  const [photoState, photoAction, removingPhoto] = useActionState(removePersonPhoto, null);
  const [outState, outAction, signingOut] = useActionState(signOutEverywhere, null);
  const [mfaExState, mfaExAction, savingMfaEx] = useActionState(setMfaExempt, null);
  // "New starter" is only for people who don't have a role yet.
  const offered = roles.filter((r) => r !== "new_starter" || person.role === "new_starter");
  const choices = offered.includes(person.role) ? offered : [person.role, ...offered];
  const showTeams = !inCoreTeam(person.role) && person.role !== "system_admin" && person.role !== "new_starter" && teams.length > 0;
  const lockedManager = person.lastManager && !canResetMfa;
  const conditional = !person.isMe && !lockedManager && person.role === "new_starter" && !!person.missing?.length;
  const roleEditable = !person.isMe && !lockedManager && !conditional;

  const label = "text-xs font-semibold tracking-wide text-muted uppercase";
  return (
    <div className="flex flex-col gap-4 border-t border-line pt-4">
      <Result state={saveState ?? activeState ?? inviteState ?? removeState ?? mfaState ?? linkState ?? pinState ?? photoState ?? outState ?? mfaExState} />
      {/* cmeprojects: name, teams and role save together with one button. */}
      <form
        ref={dirtyRef}
        action={saveAction}
        onSubmit={(e) => {
          // Keep what was typed on screen (React resets a form after its action).
          e.preventDefault();
          const data = new FormData(e.currentTarget);
          startTransition(() => saveAction(data));
        }}
        className="flex flex-col gap-4"
      >
        <input type="hidden" name="id" value={person.id} />
        {/* Roles (job titles) switched off: keep their job title unless the access level changes. */}
        {titles.length === 0 ? <input type="hidden" name="titles_off" value="1" /> : null}
        <div className="grid gap-4 lg:grid-cols-2">
          <Field label="Name" htmlFor={`name-${person.id}`}>
            <input id={`name-${person.id}`} name="full_name" defaultValue={person.full_name} maxLength={120} className={inputClass} />
          </Field>
          {roleEditable ? (
            <Field label="Role" htmlFor={`role-${person.id}`}>
              <select
                id={`role-${person.id}`}
                name="role"
                defaultValue={roleChoiceValue(person.role, titles.some((t) => t.id === person.job_title_id) ? person.job_title_id : null)}
                className={inputClass}
              >
                <RoleOptions roles={choices} titles={titles} />
              </select>
            </Field>
          ) : (
            <div className="flex flex-col gap-1">
              <p className={label}>Role</p>
              <p className="text-sm text-muted">
                {person.isMe
                  ? "You can't change your own role. Ask a manager."
                  : lockedManager
                    ? "They're the only manager, so their role can't change and they can't be deactivated. Add another manager first."
                    : "Onboarding isn't finished. Give a conditional role below."}
              </p>
            </div>
          )}
        </div>
        {showTeams ? <input type="hidden" name="has_teams" value="1" /> : null}
        {showTeams ? (
          <fieldset className="flex flex-col gap-1">
            <legend className={`${label} mb-1`}>Teams</legend>
            <div className="flex flex-wrap gap-x-4 gap-y-1">
              {teams.map((t) => (
                <label key={t.id} className="flex min-h-9 items-center gap-2 text-sm">
                  <input type="checkbox" name="teams" value={t.id} defaultChecked={person.teamIds.includes(t.id)} className="h-5 w-5 accent-[var(--brand-primary)]" />
                  {t.name}
                </label>
              ))}
            </div>
          </fieldset>
        ) : null}
        {roleEditable && needsApproval ? (
          <Field label="Reason for a role change (optional)" htmlFor={`reason-${person.id}`} hint="Role changes go to a manager to approve.">
            <input id={`reason-${person.id}`} name="reason" className={inputClass} />
          </Field>
        ) : null}
        <Button className="self-start" disabled={saving || !dirty}>
          {saving ? "Saving…" : "Save changes"}
        </Button>
      </form>
      {conditional ? (
        <ConditionalRoleForm person={person} roles={offered.filter((r) => r !== "new_starter")} titles={titles} teams={teams} isManager={isManager} />
      ) : null}
      <p className={label}>Sign-in and account</p>
      {/* cmeprojects: say plainly where a new starter is up to. */}
      {person.role === "new_starter" && person.active ? (
        <p className="-mt-1 text-sm text-muted">
          {person.joined
            ? "Account set up: they've chosen a password. Onboarding is under way."
            : person.openedLink
              ? "Not set up yet: they opened the invite but haven't chosen a password. Resend invite emails them a fresh link."
              : "Invite sent: they haven't opened it yet. Resend invite if it's been a while or they can't find it."}
        </p>
      ) : null}
      <div className="flex flex-wrap gap-2">
        {!person.joined && person.active ? (
          <form action={inviteAction}>
            <input type="hidden" name="id" value={person.id} />
            <Button variant="outline" disabled={resending}>{resending ? "Sending…" : "Resend invite"}</Button>
          </form>
        ) : null}
        {/* cmeprojects: a new starter who never set up their account can be deleted (nothing to keep). */}
        {!person.joined && person.role === "new_starter" && !person.isMe ? (
          <form
            action={removeAction}
            onSubmit={confirmSubmit(`Delete ${person.full_name || person.email}? Their invite stops working and they're removed from the list. You can invite them again later.`, { action: "Delete", danger: true })}
          >
            <input type="hidden" name="id" value={person.id} />
            <Button variant="outline" className="border-danger/40 text-danger hover:border-danger" disabled={removing}>{removing ? "Deleting…" : "Delete (never set up)"}</Button>
          </form>
        ) : null}
        {canHelpSignIn && person.joined && person.active && !person.isMe ? (
          <>
            <form action={linkAction}>
              <input type="hidden" name="id" value={person.id} />
              <Button variant="outline" disabled={sendingLink}>{sendingLink ? "Sending…" : "Email a password reset link"}</Button>
            </form>
            <form
              action={mfaAction}
              onSubmit={confirmSubmit(`Reset two-factor login for ${person.full_name || person.email}? They'll set it up again next time they sign in.`, { action: "Reset it" })}
            >
              <input type="hidden" name="id" value={person.id} />
              <Button variant="outline" disabled={resetting}>{resetting ? "Resetting…" : "Reset two-factor login"}</Button>
            </form>
            <form
              action={pinAction}
              onSubmit={confirmSubmit(`Clear ${person.full_name || person.email}'s Cars app PIN? They'll choose a new one next time they open the app.`, { action: "Clear PIN" })}
            >
              <input type="hidden" name="id" value={person.id} />
              <Button variant="outline" disabled={clearingPin}>{clearingPin ? "Clearing…" : "Clear Cars app PIN"}</Button>
            </form>
          </>
        ) : null}
        {/* cmeprojects: anyone who can edit this person can remove an unsuitable photo. */}
        {person.hasPhoto && person.editable && !person.isMe ? (
          <form action={photoAction} onSubmit={confirmSubmit(`Remove ${person.full_name || person.email}'s photo? Their initials show instead.`, { action: "Remove photo" })}>
            <input type="hidden" name="id" value={person.id} />
            <Button variant="outline" disabled={removingPhoto}>{removingPhoto ? "Removing…" : "Remove photo"}</Button>
          </form>
        ) : null}
        {canResetMfa && person.role !== "system_admin" && person.mfaExempt !== null && person.mfaExempt !== undefined ? (
          <form action={mfaExAction}>
            <input type="hidden" name="id" value={person.id} />
            <input type="hidden" name="exempt" value={person.mfaExempt ? "false" : "true"} />
            <Button variant="outline" disabled={savingMfaEx} title="Only you can change this. System admins always need two-factor login.">
              {person.mfaExempt ? "Ask for two-factor login again" : "Let them off two-factor login"}
            </Button>
          </form>
        ) : null}
        {canResetMfa && person.joined && person.active && !person.isMe ? (
          <form
            action={outAction}
            onSubmit={confirmSubmit(`Sign ${person.full_name || person.email} out of every phone and computer? Their account stays active.`, { action: "Sign them out" })}
          >
            <input type="hidden" name="id" value={person.id} />
            <Button variant="outline" disabled={signingOut}>{signingOut ? "Signing out…" : "Sign out of all devices"}</Button>
          </form>
        ) : null}
        {!person.isMe && !(person.lastManager && !canResetMfa) ? (
          <form
            action={activeAction}
            onSubmit={person.active ? confirmSubmit(`Deactivate ${person.full_name || person.email}? They won't be able to sign in. Their history stays.`, { action: "Deactivate" }) : undefined}
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

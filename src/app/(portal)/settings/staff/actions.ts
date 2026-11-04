// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { requireRole, requireSession, PEOPLE_MANAGERS } from "@/lib/session";
import { assignableRoles, parseRoleChoice } from "@/lib/roles";
import { friendlyError } from "@/lib/db-error";
import { EMAIL, text, type FormState } from "@/lib/form";
import { sendInvite } from "@/lib/email/invite";
import { sendPasswordReset } from "@/lib/email/password-reset";
import { canInvite, getPeopleRules } from "@/lib/settings";

const PAGE = "/settings/staff";

// System admins stay hidden from staff, even in invites.
const inviterName = (me: { role: string; full_name: string }) =>
  me.role === "system_admin" || !me.full_name ? "The team" : me.full_name;
const BAN_FOREVER = "876000h";

async function activeTitles(supabase: Awaited<ReturnType<typeof createClient>>) {
  const { data } = await supabase.from("job_titles").select("id, access_level, active").eq("active", true);
  return data ?? [];
}

export async function invitePerson(_: FormState, form: FormData): Promise<FormState> {
  const { profile: me } = await requireSession();
  if (!canInvite(me.role, await getPeopleRules())) return { error: "You're not set up to send invites. Ask a staff admin." };
  const fullName = text(form, "full_name");
  const email = text(form, "email").toLowerCase();

  if (!fullName) return { error: "Enter their full name." };
  if (!EMAIL.test(email)) return { error: "Enter a valid email address." };

  const supabase = await createClient();

  const { data: existing } = await supabase
    .from("profiles")
    .select("id")
    .ilike("email", email.replace(/[\\%_]/g, "\\$&"))
    .maybeSingle();
  if (existing) return { error: `${email} already has an account.` };

  // The database checks the invitation first (who may invite which role).
  const { data: invitation, error } = await supabase
    .from("invitations")
    // Every invite is general: they join as a new starter with no team.
    .insert({ email, full_name: fullName, role: "new_starter" })
    .select("id")
    .single();
  if (error) return { error: friendlyError(error, "We couldn't create the invitation.") };

  const { error: sendError } = await sendInvite({ email, fullName, invitedBy: inviterName(me) });
  if (sendError) {
    await supabase.from("invitations").delete().eq("id", invitation.id);
    return { error: "The invite email couldn't be sent. Check the email address and try again." };
  }

  revalidatePath(PAGE);
  revalidatePath("/invite");
  return { message: `Invite sent to ${email}.` };
}

export async function updatePerson(_: FormState, form: FormData): Promise<FormState> {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  if (id === me.id) return { error: "You can't change your own role." };

  const supabase = await createClient();
  const choice = parseRoleChoice(text(form, "role"), await activeTitles(supabase));
  if (!choice) return { error: "Choose a role." };
  if (!assignableRoles(me.role).includes(choice.role)) return { error: "Only a system admin can give that role." };

  const { data: current } = await supabase.from("profiles").select("role, job_title_id").eq("id", id).single();
  if (!current) return { error: "Person not found." };
  if (current.role === choice.role && current.job_title_id === choice.titleId) return { message: "Nothing has changed." };
  // Roles (job titles) switched off: the same access level keeps their job title.
  if (form.get("titles_off") === "1" && current.role === choice.role) return { message: "Nothing has changed." };

  // Staff admins (HR) send role changes to a manager for approval (if the
  // system admin's rules say so; a new starter's first role usually doesn't).
  const rules = await getPeopleRules();
  if (
    me.role === "staff_admin" &&
    rules.staffAdminRoleApproval &&
    (current.role !== "new_starter" || rules.firstRoleApproval)
  ) {
    const { error } = await supabase.rpc("request_role_change", {
      p_user_id: id,
      p_to_role: choice.role,
      p_title_id: choice.titleId,
      p_reason: text(form, "reason"),
    });
    if (error) return { error: friendlyError(error) };
    revalidatePath(PAGE);
    return { message: "Role change sent to a manager for approval." };
  }

  // A job title brings its own access level (set by the database).
  const changes = choice.titleId ? { job_title_id: choice.titleId } : { role: choice.role, job_title_id: null };
  const { data, error } = await supabase.from("profiles").update(changes).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change this person." };
  revalidatePath(PAGE);
  revalidatePath("/settings/teams");
  return { message: "Saved." };
}

// Managers approve or decline staff admins' role and team changes.
export async function decideChangeRequest(form: FormData) {
  await requireRole(["manager", "system_admin"]);
  const supabase = await createClient();
  await supabase.rpc("decide_change_request", {
    p_request_id: text(form, "request_id"),
    p_approve: text(form, "decision") === "approve",
    p_note: text(form, "note"),
  });
  revalidatePath(PAGE);
  revalidatePath("/settings/teams");
}

export async function setActive(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const active = text(form, "active") === "true";

  const supabase = await createClient();
  const { data, error } = await supabase.from("profiles").update({ active }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change this person." };

  // Also block (or unblock) sign-in itself. Their history stays.
  await createAdminClient().auth.admin.updateUserById(id, { ban_duration: active ? "none" : BAN_FOREVER });
  revalidatePath(PAGE);
  return { message: active ? "Reactivated. They can sign in again." : "Deactivated. They can no longer sign in." };
}

export async function resendInvite(_: FormState, form: FormData): Promise<FormState> {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const supabase = await createClient();
  const { data: person } = await supabase.from("profiles").select("email, full_name").eq("id", id).single();
  if (!person) return { error: "Person not found." };

  const { error } = await sendInvite({ email: person.email, fullName: person.full_name, invitedBy: inviterName(me), resend: true });
  if (error) return { error: "The invite couldn't be resent. They may have already joined." };
  await supabase.rpc("log_admin_action", { p_action: "invite_resent", p_user_id: id });
  return { message: `Invite resent to ${person.email}.` };
}

export async function resetTwoFactor(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const supabase = await createClient();
  // Logged (and permission-checked) by the database before anything changes.
  const { error } = await supabase.rpc("log_admin_action", { p_action: "mfa_reset", p_user_id: id });
  if (error) return { error: friendlyError(error) };

  const admin = createAdminClient();
  const { data } = await admin.auth.admin.mfa.listFactors({ userId: id });
  for (const factor of data?.factors ?? []) {
    await admin.auth.admin.mfa.deleteFactor({ userId: id, id: factor.id });
  }
  return { message: "Two-factor login reset. They'll set it up again next time they sign in." };
}

// Email them a link to set a new password (the database checks who may).
export async function sendResetLink(_: FormState, form: FormData): Promise<FormState> {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const supabase = await createClient();
  const { data: allowed } = await supabase.rpc("can_help_sign_in", { p_user: id });
  if (!allowed) return { error: "You can't do this for them. Ask the system admin." };
  const { data: person } = await supabase.from("profiles").select("email").eq("id", id).single();
  if (!person) return { error: "Person not found." };
  const { error } = await sendPasswordReset(person.email, inviterName(me));
  if (error) return { error };
  await supabase.rpc("log_admin_action", { p_action: "password_reset_sent", p_user_id: id });
  return { message: `A link to set a new password has been emailed to ${person.email}.` };
}

// Forget their Cars app PIN, so they choose a new one after signing in.
export async function clearCarPin(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const supabase = await createClient();
  const { error } = await supabase.rpc("log_admin_action", { p_action: "pin_cleared", p_user_id: id });
  if (error) return { error: friendlyError(error) };
  await createAdminClient().from("car_app_pins").delete().eq("user_id", id);
  return { message: "Cars app PIN cleared. They'll choose a new one next time they sign in to the app." };
}

// A role before onboarding is finished: reason, deadline, and a "Finish
// onboarding" task. Staff admins send it to a manager; managers give it.
export async function giveConditionalRole(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const supabase = await createClient();
  const choice = parseRoleChoice(text(form, "role"), await activeTitles(supabase));
  if (!choice || choice.role === "new_starter") return { error: "Choose the role they'll have." };
  const reason = text(form, "reason");
  if (!reason) return { error: "Give a reason for the conditional role." };
  const deadline = text(form, "deadline");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(deadline)) return { error: "Choose a deadline to finish onboarding." };
  const { data: requestId, error } = await supabase.rpc("give_conditional_role", {
    p_user_id: text(form, "id"),
    p_role: choice.role,
    p_title_id: choice.titleId,
    p_teams: form.getAll("teams").map(String),
    p_reason: reason,
    p_deadline: deadline,
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(PAGE);
  revalidatePath("/settings/teams");
  // Given straight away (managers, or nothing left for that role), or sent for approval.
  const { data: request } = await supabase.from("people_change_requests").select("status, task_id").eq("id", requestId).maybeSingle();
  if (request?.status === "pending") return { message: "Sent to a manager for approval. They'll get the role once it's approved." };
  return {
    message: request?.task_id
      ? "Done. They have the role, and a \"Finish onboarding\" task due on the deadline."
      : "Done. They have the role. Nothing is left to do for that role, so there's no onboarding task.",
  };
}

// Change someone's name (people managers; only a system admin renames a system admin).
export async function renamePerson(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const name = text(form, "full_name").slice(0, 120);
  if (name.length < 2) return { error: "Type their full name." };
  const { data, error } = await (await createClient()).from("profiles").update({ full_name: name }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change this person." };
  revalidatePath(PAGE);
  return { message: "Name saved." };
}

// Which teams someone is in, from their own row on the Staff page. Each team
// that changes is saved as it would be on the Teams page (a staff admin's
// change goes to a manager when the rules say so).
export async function setPersonTeams(_: FormState, form: FormData): Promise<FormState> {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const wanted = new Set(form.getAll("teams").map(String));
  const supabase = await createClient();
  const [{ data: teams }, { data: members }, { data: leaders }] = await Promise.all([
    supabase.from("teams").select("id").eq("active", true).eq("is_core", false),
    supabase.from("team_members").select("team_id, user_id"),
    supabase.from("team_leaders").select("team_id, user_id"),
  ]);
  const ask = me.role === "staff_admin" && (await getPeopleRules()).staffAdminTeamApproval;
  let changed = 0;
  for (const t of teams ?? []) {
    const now = (members ?? []).filter((m) => m.team_id === t.id).map((m) => m.user_id);
    const isIn = now.includes(id);
    if (isIn === wanted.has(t.id)) continue;
    const next = isIn ? now.filter((u) => u !== id) : [...now, id];
    const leader = (leaders ?? []).find((l) => l.team_id === t.id)?.user_id ?? null;
    const keepLeader = leader && next.includes(leader) ? leader : null;
    const { error } = ask
      ? await supabase.rpc("request_team_change", { p_team_id: t.id, p_members: next.sort(), p_leader: keepLeader, p_reason: "" })
      : await supabase.rpc("set_team", { p_team_id: t.id, p_members: next.sort(), p_leader: keepLeader });
    if (error) return { error: friendlyError(error) };
    changed++;
  }
  revalidatePath(PAGE);
  revalidatePath("/settings/teams");
  if (!changed) return { message: "Nothing has changed." };
  return { message: ask ? "Sent to a manager to approve." : "Teams saved." };
}

// cmeprojects: one Save for a person's row. Saves the name, teams and role
// that were on the form, each with its own rules, and says what changed.
export async function savePerson(_: FormState, form: FormData): Promise<FormState> {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const id = text(form, "id");
  const supabase = await createClient();
  const { data: current } = await supabase.from("profiles").select("full_name").eq("id", id).single();
  if (!current) return { error: "Person not found." };

  const steps: (() => Promise<FormState>)[] = [];
  if (form.has("full_name") && text(form, "full_name").slice(0, 120) !== (current.full_name ?? "")) steps.push(() => renamePerson(null, form));
  if (form.has("has_teams")) steps.push(() => setPersonTeams(null, form));
  if (form.has("role") && id !== me.id) steps.push(() => updatePerson(null, form));

  const done: string[] = [];
  for (const step of steps) {
    const result = await step();
    if (result?.error) return { error: done.length ? `${done.join(" ")} But: ${result.error}` : result.error };
    if (result?.message && result.message !== "Nothing has changed.") done.push(result.message);
  }
  return { message: done.length ? done.join(" ") : "Nothing has changed." };
}

// cmeprojects: system admin only. Signs someone out of every phone and
// computer (a lost phone, a shared login). Their account stays active.
export async function signOutEverywhere(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const { data, error } = await (await createClient()).rpc("sign_out_everywhere", { p_user_id: text(form, "id") });
  if (error) return { error: error.code === "PGRST202" ? "This needs the latest database update (update 45)." : friendlyError(error) };
  const n = Number(data ?? 0);
  return { message: n ? `Signed out of ${n} device${n === 1 ? "" : "s"}. They can sign in again with their password.` : "They weren't signed in anywhere." };
}

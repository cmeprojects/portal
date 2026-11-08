// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { redirect } from "next/navigation";
import { getPeopleRules } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import type { Role } from "@/lib/roles";

export type Profile = {
  id: string;
  email: string;
  full_name: string;
  role: Role;
  team_id: string | null;
  active: boolean;
};

export type Session = {
  profile: Profile;
  features: Record<string, boolean>;
  // What's really switched on for everyone (the system admin's own view skips the switches).
  live: Record<string, boolean>;
  // Whether this person's role must use two-factor login right now.
  mfaRequired: boolean;
};

type Access = {
  role: Role;
  active: boolean;
  mfa_required: boolean;
  mfa_ok: boolean;
};

// Looks up the signed-in person once per request.
export const getSession = cache(async (): Promise<Session | null> => {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (!userId) return null;

  // Asked together so a page waits for one round trip, not three.
  const [{ data: access }, { data: profile }, { data: features }] = await Promise.all([
    supabase.rpc("my_access").maybeSingle<Access>(),
    supabase
      .from("profiles")
      .select("id, email, full_name, role, team_id, active")
      .eq("id", userId)
      .maybeSingle<Profile>(),
    // "*" so it keeps working before the premium columns exist.
    supabase.from("features").select("*"),
  ]);
  if (!access || !access.active || !profile) redirect("/deactivated");
  if (access.mfa_required && !access.mfa_ok) redirect("/mfa");

  // A premium feature only counts as on if it's included in the plan, and a
  // part of a feature (cmeprojects) only while its feature is on too.
  const own = new Map((features ?? []).map((f) => [f.key as string, Boolean(f.enabled) && f.included !== false]));
  // The system admin is never locked out by a switch, except two-factor login,
  // emails and auto-escalation, which apply to everyone (cmeprojects).
  const admin = profile.role === "system_admin";
  const EVERYONE = ["two_factor", "email_notifications", "auto_escalation"];
  const liveOn = (f: { key: string; parent?: string | null }) => Boolean(own.get(f.key)) && (!f.parent || own.get(f.parent) === true);
  return {
    profile,
    live: Object.fromEntries((features ?? []).map((f) => [f.key, liveOn(f)])),
    features: Object.fromEntries(
      (features ?? []).map((f) => [
        f.key,
        (admin && !EVERYONE.includes(f.key)) || (Boolean(own.get(f.key)) && (!f.parent || own.get(f.parent) === true)),
      ]),
    ),
    mfaRequired: access.mfa_required,
  };
});

// For pages: signed in, active and past two-factor login if needed.
export async function requireSession(): Promise<Session> {
  const session = await getSession();
  if (!session) redirect("/login");
  return session;
}

export async function requireRole(roles: Role[]): Promise<Session> {
  const session = await requireSession();
  if (!roles.includes(session.profile.role)) redirect("/");
  return session;
}

// For task, register and record pages: new starters wait for a role (unless
// the system admin lets them use tasks).
export async function requireTaskAccess(): Promise<Session> {
  const session = await requireSession();
  if (session.profile.role === "external") redirect("/");
  if (session.profile.role === "new_starter" && !(await getPeopleRules()).newStarterTasks) redirect("/");
  return session;
}

export const STAFF_ADMINS: Role[] = ["staff_admin", "system_admin"];
// Who can use Staff & roles and Teams.
export const PEOPLE_MANAGERS: Role[] = ["manager", "staff_admin", "system_admin"];

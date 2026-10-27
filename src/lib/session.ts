// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { redirect } from "next/navigation";
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

  const { data: access } = await supabase.rpc("my_access").maybeSingle<Access>();
  if (!access) redirect("/deactivated");
  if (!access.active) redirect("/deactivated");
  if (access.mfa_required && !access.mfa_ok) redirect("/mfa");

  const [{ data: profile }, { data: features }] = await Promise.all([
    supabase
      .from("profiles")
      .select("id, email, full_name, role, team_id, active")
      .eq("id", userId)
      .single<Profile>(),
    supabase.from("features").select("key, enabled"),
  ]);
  if (!profile) redirect("/deactivated");

  return {
    profile,
    features: Object.fromEntries((features ?? []).map((f) => [f.key, f.enabled])),
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

export const STAFF_ADMINS: Role[] = ["staff_admin", "system_admin"];

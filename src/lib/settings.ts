// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { parseSla, type Sla } from "@/lib/tasks";
import { isRole, type Role } from "@/lib/roles";
import type { RequiredWhen } from "@/lib/registers";

export type SlaSettings = { days: Sla; weekdaysOnly: boolean };

// Default due dates by priority (System settings → Tasks).
export const getSla = cache(async (): Promise<SlaSettings> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("key, value").in("key", ["tasks.sla_days", "tasks.sla_weekdays_only"]);
  const get = (k: string) => data?.find((r) => r.key === k)?.value;
  return { days: parseSla(get("tasks.sla_days")), weekdaysOnly: get("tasks.sla_weekdays_only") === true };
});

// When required register fields must be filled in (System settings → Tasks).
export const getRequiredWhen = cache(async (): Promise<RequiredWhen> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("value").eq("key", "tasks.required_fields_when").maybeSingle();
  return data?.value === "create" ? "create" : "complete";
});

// The company's time zone (System settings → Region).
export const getTimeZone = cache(async (): Promise<string> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("value").eq("key", "region.timezone").maybeSingle();
  const zone = typeof data?.value === "string" ? data.value : "Australia/Melbourne";
  try {
    new Intl.DateTimeFormat("en-AU", { timeZone: zone });
    return zone;
  } catch {
    return "Australia/Melbourne";
  }
});

// People rules the system admin switches on and off (System settings → People rules).
export type PeopleRules = {
  staffAdminRoleApproval: boolean;
  staffAdminTeamApproval: boolean;
  firstRoleApproval: boolean;
  generalInvitesOnly: boolean;
  newStarterTasks: boolean;
  // Besides the system admin: who sends invites and who manages Compliance.
  inviteRoles: Role[];
  complianceRoles: Role[];
  scoreboardRoles: Role[];
};

export const getPeopleRules = cache(async (): Promise<PeopleRules> => {
  const supabase = await createClient();
  const { data } = await supabase
    .from("app_settings")
    .select("key, value")
    .or("key.like.people.%,key.eq.compliance.manager_roles");
  const on = (k: string, fallback: boolean) => {
    const v = data?.find((r) => r.key === k)?.value;
    return typeof v === "boolean" ? v : fallback;
  };
  const roles = (k: string, fallback: Role[]) => {
    const v = data?.find((r) => r.key === k)?.value;
    return Array.isArray(v) ? v.filter(isRole) : fallback;
  };
  return {
    staffAdminRoleApproval: on("people.staff_admin_role_approval", true),
    staffAdminTeamApproval: on("people.staff_admin_team_approval", true),
    firstRoleApproval: on("people.first_role_approval", false),
    generalInvitesOnly: on("people.general_invites_only", false),
    newStarterTasks: on("people.new_starter_tasks", false),
    inviteRoles: roles("people.invite_roles", ["staff_admin", "manager"]),
    complianceRoles: roles("compliance.manager_roles", ["staff_admin"]),
    scoreboardRoles: roles("people.scoreboard_roles", ["staff_admin", "manager"]),
  };
});

export const canInvite = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.inviteRoles.includes(role);
export const canSeeScoreboard = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.scoreboardRoles.includes(role);
export const canManageCompliance = (role: Role, rules: PeopleRules) =>
  role === "system_admin" || rules.complianceRoles.includes(role);
// Who sees onboarding progress (not the files): Compliance managers, managers and team leaders.
export const seesCompliance = (role: Role, rules: PeopleRules) =>
  canManageCompliance(role, rules) || role === "manager" || role === "team_leader";

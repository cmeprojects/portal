// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { parseSla, type Sla } from "@/lib/tasks";
import { isRole, type Role } from "@/lib/roles";
import type { RequiredWhen } from "@/lib/registers";
import { AREAS, isArea, type Area } from "@/lib/delegation";

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

// The System settings areas the signed-in person looks after: everything for
// the system admin, the delegated ones for a manager, none for anyone else.
export const getMyAdminAreas = cache(async (role: Role): Promise<Area[]> => {
  if (role === "system_admin") return [...AREAS];
  if (role !== "manager") return [];
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const { data } = await supabase.from("admin_delegations").select("areas").eq("user_id", claims?.claims?.sub ?? "").maybeSingle();
  return ((data?.areas ?? []) as string[]).filter(isArea);
});

// Minutes without activity before people are signed out (0 = never).
export const getIdleMinutes = cache(async (): Promise<number> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("value").eq("key", "security.idle_minutes").maybeSingle();
  const n = Number(data?.value ?? 30);
  return Number.isFinite(n) && n >= 0 ? Math.min(Math.round(n), 1440) : 30;
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
  reportRoles: Role[];
  complianceReportRoles: Role[];
  registersRoles: Role[];
  accessResetRoles: Role[];
};

export const getPeopleRules = cache(async (): Promise<PeopleRules> => {
  const supabase = await createClient();
  const { data } = await supabase
    .from("app_settings")
    .select("key, value")
    .or("key.like.people.%,key.eq.compliance.manager_roles,key.eq.reports.roles,key.eq.reports.compliance_roles,key.eq.tasks.registers_roles");
  // people.access_reset_roles is included by "people.%".
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
    reportRoles: roles("reports.roles", ["manager"]),
    complianceReportRoles: roles("reports.compliance_roles", ["staff_admin"]),
    registersRoles: roles("tasks.registers_roles", ["team_leader", "manager", "staff_admin"]),
    accessResetRoles: roles("people.access_reset_roles", []),
  };
});

export const canInvite = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.inviteRoles.includes(role);
export const canSeeReports = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.reportRoles.includes(role);
// Send a password reset link, reset two-factor, clear the Cars app PIN (Staff & roles).
export const canHelpSignIn = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.accessResetRoles.includes(role);
export const canSeeRegisters = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.registersRoles.includes(role);
export const canSeeComplianceReport = (role: Role, rules: PeopleRules) =>
  role === "system_admin" || rules.complianceReportRoles.includes(role);
export const canSeeScoreboard = (role: Role, rules: PeopleRules) => role === "system_admin" || rules.scoreboardRoles.includes(role);
export const canManageCompliance = (role: Role, rules: PeopleRules) =>
  role === "system_admin" || rules.complianceRoles.includes(role);
// Who sees onboarding progress (not the files): Compliance managers, managers and team leaders.
export const seesCompliance = (role: Role, rules: PeopleRules) =>
  canManageCompliance(role, rules) || role === "manager" || role === "team_leader";

// Staff Portal · © cmeproject. All rights reserved.

export const ROLES = [
  "support_worker",
  "team_leader",
  "manager",
  "staff_admin",
  "system_admin",
] as const;

export type Role = (typeof ROLES)[number];

export const ROLE_LABELS: Record<Role, string> = {
  support_worker: "Support worker",
  team_leader: "Team leader",
  manager: "Manager",
  staff_admin: "Staff admin",
  system_admin: "System admin",
};

export const ROLE_HELP: Record<Role, string> = {
  support_worker: "Sees only tasks they're assigned to, helping on or created.",
  team_leader: "Also sees the tasks of the support workers in their team.",
  manager: "Sees every task in the registries they manage. Approvals and reports. Invites support workers and team leaders.",
  staff_admin: "Invites people (up to manager), sets roles and manages teams and registries. Can't create admins.",
  system_admin: "Everything, plus System settings. The only role that can create staff admins and system admins. Never given tasks.",
};

// Roles someone may give out: managers up to team leader, staff admins up to
// manager, and only a system admin creates staff admins or system admins
// (the database enforces this too).
export function assignableRoles(myRole: Role): Role[] {
  if (myRole === "system_admin") return [...ROLES];
  if (myRole === "staff_admin") return ["support_worker", "team_leader", "manager"];
  if (myRole === "manager") return ["support_worker", "team_leader"];
  return [];
}

// System admins look after the portal itself, so they're never given tasks.
export function canTakeTasks(role: Role): boolean {
  return role !== "system_admin";
}

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

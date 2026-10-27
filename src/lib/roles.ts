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
  manager: "Sees every task in the registries they manage. Approvals and reports.",
  staff_admin: "Invites people, sets roles and manages teams and registries.",
  system_admin: "Everything, plus System settings.",
};

// Roles a staff admin may give out. Only a system admin can create staff
// admins or system admins (the database enforces this too).
export function assignableRoles(myRole: Role): Role[] {
  return myRole === "system_admin"
    ? [...ROLES]
    : ["support_worker", "team_leader", "manager"];
}

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

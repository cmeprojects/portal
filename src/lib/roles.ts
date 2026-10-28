// Staff Portal · © cmeproject. All rights reserved.

export const ROLES = [
  "new_starter",
  "support_worker",
  "team_leader",
  "manager",
  "staff_admin",
  "system_admin",
] as const;

export type Role = (typeof ROLES)[number];

export const ROLE_LABELS: Record<Role, string> = {
  new_starter: "New starter",
  support_worker: "Support worker",
  team_leader: "Team leader",
  manager: "Manager",
  staff_admin: "Staff admin",
  system_admin: "System admin",
};

export const ROLE_HELP: Record<Role, string> = {
  new_starter: "Joined with a general invite and waiting for a role. Sees their own account only (trainings and documents are coming).",
  support_worker: "Sees only tasks they're assigned to, helping on or created. Can be in several teams.",
  team_leader: "Leads one team, and also sees the tasks of everyone in it.",
  manager: "In the core team: sees every team's tasks. Approvals, reports and due-date SLAs. Invites people, changes roles and teams, and adds job titles.",
  staff_admin: "In the core team, like HR: invites people and manages their details. Role and team changes go to a manager to approve. Doesn't see other people's tasks.",
  system_admin: "Everything, plus System settings. The only role that can create system admins. Hidden from other staff and never given tasks.",
};

// Access levels someone may give out: managers and staff admins (HR) give any
// level except system admin; only a system admin creates system admins. Staff
// admins' changes wait for a manager, and nobody changes their own role (the
// database enforces both).
export function assignableRoles(myRole: Role): Role[] {
  if (myRole === "system_admin") return [...ROLES];
  if (myRole === "manager" || myRole === "staff_admin") return ROLES.filter((r) => r !== "system_admin");
  return [];
}

// Job titles (shown as "roles" to staff) sit on top of access levels.
export type JobTitle = {
  id: string;
  name: string;
  access_level: Role;
  description: string;
  active: boolean;
  sort_order: number;
};

export const JOB_TITLE_COLUMNS = "id, name, access_level, description, active, sort_order";

// A role choice in a form: "title:<id>" or "level:<access level>".
export type RoleChoice = { role: Role; titleId: string | null };

export function parseRoleChoice(value: string, titles: Pick<JobTitle, "id" | "access_level" | "active">[]): RoleChoice | null {
  const [kind, rest] = value.split(":", 2);
  if (kind === "level" && isRole(rest)) return { role: rest, titleId: null };
  if (kind === "title") {
    const t = titles.find((x) => x.id === rest && x.active);
    if (t) return { role: t.access_level, titleId: t.id };
  }
  return null;
}

export function roleChoiceValue(role: Role, titleId: string | null): string {
  return titleId ? `title:${titleId}` : `level:${role}`;
}

// Managers and staff admins are the core team, which works across every team.
export function inCoreTeam(role: Role): boolean {
  return role === "manager" || role === "staff_admin";
}

// System admins look after the portal itself, so they're never given tasks.
// New starters wait for a role, unless the system admin allows it.
export function canTakeTasks(role: Role, newStarterTasks = false): boolean {
  return role !== "system_admin" && (role !== "new_starter" || newStarterTasks);
}

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

// Staff Portal · © cmeproject. All rights reserved.

export const ROLES = [
  "new_starter",
  "support_worker",
  "team_leader",
  "manager",
  "staff_admin",
  "system_admin",
  // cmeprojects: for later (allied health). No access to anything yet.
  "external",
] as const;

export type Role = (typeof ROLES)[number];

export const ROLE_LABELS: Record<Role, string> = {
  new_starter: "New starter",
  support_worker: "Support worker",
  team_leader: "Team leader",
  manager: "Manager",
  staff_admin: "Staff admin",
  system_admin: "System admin",
  external: "External contractor (allied health)",
};

export const ROLE_HELP: Record<Role, string> = {
  new_starter: "Joined with a general invite. Does their onboarding (reading, trainings, documents) and gets a role once it's done, or earlier as a conditional role.",
  support_worker: "Their own tasks (assigned, helping on or created), and their teams' clients' locations and alerts. Most roles start here and get more from their role on the Access page (for example Case Manager: their assigned clients).",
  team_leader: "Leads one team: also sees their team's tasks, onboarding progress and staff requests.",
  manager: "In the core team: every team's tasks, staff, teams, staff requests, clients, due dates, cars, forms and reports. Approves role and team changes.",
  staff_admin: "In the core team, like HR: staff, teams, staff requests, onboarding, clients and the compliance report. Role and team changes go to a manager to approve. Doesn't see other people's tasks.",
  system_admin: "Everything, plus System settings. The only role that can create system admins. Hidden from other staff and never given tasks.",
  external: "Allied health and other outside practitioners. Nothing by default; access to their assigned clients comes with the next stage.",
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

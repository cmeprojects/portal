// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";

// People who oversee others' work land on the dashboard instead of My tasks.
// cmeprojects: who has a Dashboard as their home (support workers' home is My
// tasks), and where their task lists live.
export function hasHomeDashboard(role: Role): boolean {
  return role === "manager" || role === "staff_admin" || role === "team_leader" || role === "system_admin";
}
export function myTasksHref(role: Role): string {
  return seesDashboard(role) ? "/my-tasks" : hasHomeDashboard(role) ? "/tasks" : "/";
}

// Sees everyone's (or their team's) tasks in the Tasks view.
export function seesDashboard(role: Role): boolean {
  return role === "team_leader" || role === "manager" || role === "system_admin";
}

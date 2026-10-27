// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";

// People who oversee others' work land on the dashboard instead of My tasks.
export function seesDashboard(role: Role): boolean {
  return role === "team_leader" || role === "manager" || role === "system_admin";
}

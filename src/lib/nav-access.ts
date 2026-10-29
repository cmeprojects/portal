// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import type { NavAccess } from "@/components/nav";
import type { Role } from "@/lib/roles";
import { canInvite, canSeeReports, canSeeScoreboard, getMyAdminAreas, getPeopleRules, seesCompliance } from "@/lib/settings";
import { canManageCars, canSeeCarReports, getCarRules } from "@/lib/cars";

// What the menu and the section tabs show this person (worked out once per page).
export const getNavAccess = cache(async (role: Role): Promise<NavAccess> => {
  const [rules, carRules, adminAreas] = await Promise.all([getPeopleRules(), getCarRules(), getMyAdminAreas(role)]);
  return {
    newStarterTasks: rules.newStarterTasks,
    canInvite: canInvite(role, rules),
    seesCompliance: seesCompliance(role, rules),
    seesScoreboard: canSeeScoreboard(role, rules),
    seesReports: canSeeReports(role, rules),
    carManager: canManageCars(role, carRules),
    carReports: canSeeCarReports(role, carRules),
    adminAreas,
  };
});

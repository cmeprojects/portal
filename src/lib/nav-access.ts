// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import type { NavAccess } from "@/components/nav";
import type { Role } from "@/lib/roles";
import { canInvite, canSeeComplianceReport, canSeeRegisters, canSeeReports, canSeeScoreboard, getMyAdminAreas, getPeopleRules, seesCompliance } from "@/lib/settings";
import { canManageCars, canSeeCarReports, getCarRules } from "@/lib/cars";
import { getMenuFeatures, getReportFeatures } from "@/lib/custom-features";
import { requireSession } from "@/lib/session";
import { getBranding, initialsOf } from "@/lib/branding";
import { canUseCars } from "@/lib/cars";
import { carsAppOffered, getStaffAppTiles, staffAppOn } from "@/lib/staff-app";

// What the menu and the section tabs show this person (worked out once per page).
export const getNavAccess = cache(async (role: Role): Promise<NavAccess> => {
  const [rules, carRules, adminAreas, customFeatures, featureReports] = await Promise.all([
    getPeopleRules(),
    getCarRules(),
    getMyAdminAreas(role),
    getMenuFeatures(role),
    getReportFeatures(role),
  ]);
  // The company's phone apps: the Cars app and/or the Staff app.
  const { profile, features } = await requireSession();
  const [brand, tiles, carsOffered] = await Promise.all([getBranding(), getStaffAppTiles(profile.id, role, features), carsAppOffered(features)]);
  const hasApps = (canUseCars(role, features) && carsOffered) || (staffAppOn(features) && (tiles.length > 0 || role === "system_admin"));
  return {
    newStarterTasks: rules.newStarterTasks,
    canInvite: canInvite(role, rules),
    seesCompliance: seesCompliance(role, rules),
    seesScoreboard: canSeeScoreboard(role, rules),
    seesReports: canSeeReports(role, rules),
    complianceReport: canSeeComplianceReport(role, rules),
    seesRegisters: role !== "new_starter" && canSeeRegisters(role, rules),
    carManager: canManageCars(role, carRules),
    carReports: canSeeCarReports(role, carRules),
    adminAreas,
    customFeatures,
    featureReports,
    forms: features.forms === true && role !== "new_starter",
    assistant: features.assistant === true && role === "system_admin",
    enquiries: features.assistant === true && (role === "manager" || role === "system_admin"),
    website: features.assistant === true && (role === "manager" || role === "system_admin"),
    appsLabel: hasApps ? `${initialsOf(brand.companyName) || "Our"} Apps` : undefined,
  };
});

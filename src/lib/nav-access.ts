// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import type { NavAccess } from "@/components/nav";
import type { Role } from "@/lib/roles";
import { canInvite, canSeeComplianceReport, canSeeRegisters, canSeeReports, canSeeScoreboard, getMyAdminAreas, getPeopleRules, seesCompliance } from "@/lib/settings";
import { canManageCars, canSeeCarReports, getCarRules } from "@/lib/cars";
import { getMenuFeatures, getReportFeatures } from "@/lib/custom-features";
import { canMakeForms } from "@/lib/forms";
import { requireSession } from "@/lib/session";
import { getBranding, initialsOf } from "@/lib/branding";
import { canUseCars } from "@/lib/cars";
import { onboardingOn } from "@/lib/feature-parts";
import { createClient } from "@/lib/supabase/server";
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
    // Compliance is a premium add-on (on for companies that already use it).
    seesCompliance: features.compliance !== false && seesCompliance(role, rules),
    seesScoreboard: canSeeScoreboard(role, rules),
    seesReports: canSeeReports(role, rules),
    complianceReport: features.compliance !== false && canSeeComplianceReport(role, rules),
    seesRegisters: role !== "new_starter" && canSeeRegisters(role, rules),
    carManager: canManageCars(role, carRules),
    carReports: canSeeCarReports(role, carRules),
    adminAreas,
    customFeatures,
    featureReports,
    // cmeprojects: Forms. Form makers get "Forms" in the main menu (their forms
    // and the ones to fill in); everyone else gets "My forms" under My account.
    // New starters fill theirs in My onboarding.
    ...(await formsMenu(role, features)),
    // The website's Assistant is for every staff member; enquiries for those the system admin chose.
    assistant: features.assistant === true && role !== "new_starter",
    enquiries: features.assistant === true && (await canSeeEnquiries()),
    tools: role === "manager" || role === "system_admin",
    staffAccess: role === "manager" && (await holdsGrant()),
    appsLabel: hasApps ? `${initialsOf(brand.companyName) || "Our"} Apps` : undefined,
  };
});

// Who sees website enquiries is set by the system admin (managers by default).
async function canSeeEnquiries(): Promise<boolean> {
  const { data, error } = await (await createClient()).rpc("can_see_enquiries");
  if (error) {
    const { data: role } = await (await createClient()).rpc("my_role");
    return role === "manager" || role === "system_admin";
  }
  return data === true;
}

async function formsMenu(role: Role, features: Record<string, boolean>): Promise<Pick<NavAccess, "forms" | "myForms">> {
  if (features.forms !== true || (role === "new_starter" && onboardingOn(features))) return { forms: false, myForms: false };
  const maker = role === "system_admin" || (await canMakeForms());
  return { forms: maker, myForms: !maker };
}

// cmeprojects: does this manager hold any staff-records access (shows the Staff access page)?
async function holdsGrant(): Promise<boolean> {
  const { count, error } = await (await createClient()).from("access_grants").select("id", { count: "exact", head: true }).is("revoked_at", null);
  return !error && (count ?? 0) > 0;
}

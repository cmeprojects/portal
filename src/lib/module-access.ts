// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import type { Role } from "@/lib/roles";
import { canManageCompliance, canSeeComplianceReport, canSeeReports, seesCompliance, type PeopleRules } from "@/lib/settings";
import { canManageCars, canSeeCarReports } from "@/lib/cars";
import type { CarRules } from "@/lib/car-types";

// cmeprojects module framework step 4: pages follow the access given on the
// Access page as well as the existing role rules. Each check is "the old rule,
// or can(module, action)", so nobody loses access; the database checks the
// same thing (can_manage_cars, can_manage_compliance).

// May the signed-in person do this in that module (Access page)? Once per page.
export const canDo = cache(async (module: string, action = "view"): Promise<boolean> => {
  const { data, error } = await (await createClient()).rpc("can", { p_module: module, p_action: action });
  return !error && data === true;
});

// Only managers and staff admins can be given admin access, so nobody else
// needs the extra check (saves a database call on every page).
const MAY_HOLD: Role[] = ["manager", "staff_admin"];
const given = async (role: Role, module: string, action: string) => MAY_HOLD.includes(role) && (await canDo(module, action));

// Onboarding: see progress / approve uploads and set it up.
export const seesComplianceFor = async (role: Role, rules: PeopleRules) => seesCompliance(role, rules) || (await given(role, "hr.onboarding", "view"));
export const managesComplianceFor = async (role: Role, rules: PeopleRules) => canManageCompliance(role, rules) || (await given(role, "hr.onboarding", "approve"));
// Just the Expiry list (a submodule can be given on its own).
export const seesExpiryFor = async (role: Role, rules: PeopleRules) => seesCompliance(role, rules) || (await given(role, "hr.onboarding.expiry", "view"));

// Cars: manage the cars (add, change, set up).
export const managesCarsFor = async (role: Role, rules: CarRules) => canManageCars(role, rules) || (await given(role, "ops.cars.manage", "configure"));

// Reports (each report on its own; "export" = the Excel download).
export const seesTaskReportFor = async (role: Role, rules: PeopleRules, action = "view") => canSeeReports(role, rules) || (await given(role, "insights.reports.tasks", action));
export const seesComplianceReportFor = async (role: Role, rules: PeopleRules, action = "view") =>
  canSeeComplianceReport(role, rules) || (await given(role, "insights.reports.compliance", action));
export const seesCarReportFor = async (role: Role, rules: CarRules, action = "view") => canSeeCarReports(role, rules) || (await given(role, "insights.reports.cars", action));

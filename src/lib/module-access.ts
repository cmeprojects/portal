// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import type { Role } from "@/lib/roles";

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
// The same, for other helpers (built features).
export const givenFor = given;

// Onboarding (switched over, update 95, D-049): only the one permission check.
// Who has it is set on the Access page (person, role, function group, access
// level); the database uses the same check (can_manage_compliance).
export const seesComplianceFor = async () => canDo("hr.onboarding", "view");
export const managesComplianceFor = async () => canDo("hr.onboarding", "approve");
// Just the Expiry list (a submodule can be given on its own).
export const seesExpiryFor = async () => canDo("hr.onboarding.expiry", "view");

// Cars: manage the cars (add, change, set up).
// Switched over (update 96, D-049): only the one permission check; set on the Access page.
export const managesCarsFor = async () => canDo("ops.cars.manage", "configure");

// Reports (each report on its own; "export" = the Excel download). Switched
// over (update 98, D-049): only the one permission check, set on the Access
// page. Car managers also see the car reports.
export const seesTaskReportFor = async (action = "view") => canDo("insights.reports.tasks", action);
export const seesComplianceReportFor = async (action = "view") => canDo("insights.reports.compliance", action);
export const seesCarReportFor = async (action = "view") => (await managesCarsFor()) || (await canDo("insights.reports.cars", action));

// Contracts: any of its ticks (view, prepare and send, sign for the employer, download).
export const anyContractAccess = async (role: Role) => {
  if (!MAY_HOLD.includes(role)) return false;
  const all = await Promise.all(["view", "create", "sign_for_employer", "download"].map((a) => canDo("hr.contracts", a)));
  return all.some(Boolean);
};

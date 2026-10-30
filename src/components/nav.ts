// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";
import { seesDashboard } from "@/lib/dashboard";

// cmeprojects: the menu is a short list of sections. Pages in the same
// section share a row of tabs at the top (see SectionTabs), so the menu
// stays short and each person only sees what they can use.

export type NavItem = { href: string; label: string; match?: string[] };
export type NavGroup = { heading?: string; items: NavItem[] };

export type NavAccess = {
  newStarterTasks: boolean;
  canInvite: boolean;
  seesCompliance: boolean;
  seesScoreboard?: boolean;
  seesReports?: boolean;
  complianceReport?: boolean;
  seesRegisters?: boolean;
  carManager?: boolean;
  carReports?: boolean;
  // Live features built in the Feature builder that this person uses.
  customFeatures?: { slug: string; label: string }[];
  // Their reports, for those ticked under "Who sees every entry".
  featureReports?: { slug: string; label: string }[];
  // "EC Apps": the company's phone apps this person can use (none = no menu item).
  appsLabel?: string;
  // Areas of System settings delegated to this manager.
  adminAreas?: string[];
};

export type Section = "tasks" | "cars" | "people" | "reports" | "settings";
export type Tab = { href: string; text: string };

// The tabs in each section that this person can open, in order.
export function sectionTabs(section: Section, role: Role, features: Record<string, boolean>, access: NavAccess): Tab[] {
  const admin = role === "system_admin";
  const peopleManager = role === "manager" || role === "staff_admin" || admin;
  const cars = features.vehicles === true && role !== "new_starter";
  const settingsAreas = (access.adminAreas ?? []).filter((a) => a !== "audit");
  const tabs: (Tab | false)[] = {
    tasks: [
      { href: seesDashboard(role) ? "/my-tasks" : "/", text: "My tasks" },
      features.tasks !== false && { href: "/tasks/new", text: "New task" },
    ],
    cars: cars
      ? [
          { href: "/cars", text: "Use a car" },
          Boolean(access.carManager) && { href: "/cars/manage", text: "Manage cars" },
          { href: "/cars/install", text: "Get the app" },
        ]
      : [],
    people: [
      peopleManager && { href: "/settings/staff", text: "Staff" },
      peopleManager && { href: "/settings/teams", text: "Teams" },
      (role === "manager" || admin) && { href: "/settings/roles", text: "Roles" },
      peopleManager && { href: "/settings/clients", text: "Clients" },
      access.seesCompliance && { href: "/compliance", text: "Compliance" },
      !peopleManager && access.canInvite && { href: "/invite", text: "Invite staff" },
    ],
    reports: [
      Boolean(access.seesReports) && features.reports !== false && { href: "/reports", text: "Tasks" },
      cars && Boolean(access.carReports) && { href: "/reports/cars", text: "Cars" },
      Boolean(access.complianceReport) && features.reports !== false && { href: "/reports/compliance", text: "Compliance" },
      ...(access.featureReports ?? []).map((f) => ({ href: `/reports/f/${f.slug}`, text: f.label })),
    ],
    settings: [
      (role === "manager" || admin) && { href: "/settings/sla", text: "Due dates (SLA)" },
      (admin || settingsAreas.length > 0) && { href: "/system", text: "System settings" },
      (admin || (access.adminAreas ?? []).includes("audit")) && { href: "/system/audit", text: "Change log" },
      admin && { href: "/system/builder", text: "Feature builder" },
      admin && { href: "/system/health", text: "System health" },
    ],
  }[section];
  return tabs.filter((t): t is Tab => Boolean(t));
}

const SECTION_LABELS: Record<Section, string> = { tasks: "Tasks", cars: "Cars", people: "People", reports: "Reports", settings: "Settings" };

function sectionItem(section: Section, role: Role, features: Record<string, boolean>, access: NavAccess, label?: string): NavItem[] {
  const tabs = sectionTabs(section, role, features, access);
  if (!tabs.length) return [];
  return [{ href: tabs[0].href, label: label ?? SECTION_LABELS[section], match: tabs.map((t) => t.href) }];
}

export function navFor(
  role: Role,
  features: Record<string, boolean>,
  access: NavAccess = { newStarterTasks: false, canInvite: false, seesCompliance: false },
): NavGroup[] {
  const mine: NavItem[] = [
    ...(role !== "system_admin" ? [{ href: "/onboarding", label: "My onboarding" }] : []),
    { href: "/account", label: "My account" },
  ];

  // New starters: just their welcome page and onboarding until they have a role.
  if (role === "new_starter" && !access.newStarterTasks) {
    return [{ items: [{ href: "/", label: "Home" }] }, { items: mine }];
  }

  const dashboard = seesDashboard(role);
  return [
    {
      items: [
        ...(dashboard ? [{ href: "/", label: "Dashboard" }] : []),
        ...sectionItem("tasks", role, features, access, dashboard ? "Tasks" : "My tasks"),
        // Who sees Registers is set by the system admin (System settings → Tasks).
        ...(access.seesRegisters ? [{ href: "/registers", label: "Registers" }] : []),
        ...sectionItem("cars", role, features, access),
        ...(access.customFeatures ?? []).map((f) => ({ href: `/f/${f.slug}`, label: f.label })),
        ...(access.appsLabel ? [{ href: "/apps", label: access.appsLabel }] : []),
        ...sectionItem("people", role, features, access),
        ...(access.seesScoreboard ? [{ href: "/scoreboard", label: "Scoreboard" }] : []),
        ...sectionItem("reports", role, features, access),
        ...sectionItem("settings", role, features, access),
      ],
    },
    { items: mine },
  ];
}

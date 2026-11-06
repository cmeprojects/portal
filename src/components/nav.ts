// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";
import { seesDashboard } from "@/lib/dashboard";
import { onboardingOn, rolesOn, teamsOn } from "@/lib/feature-parts";

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
  // Forms (premium): forms sent to them, and the forms they make.
  forms?: boolean;
  // Website and Assistant: the system admin manages it; managers follow up enquiries.
  assistant?: boolean;
  enquiries?: boolean;
  // Managers: built features, Cars and the apps under one "Tools" item.
  tools?: boolean;
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
  // Areas with settings on the System settings page (registers, roles, the
  // website and the change log have their own pages) (cmeprojects).
  const settingsAreas = (access.adminAreas ?? []).filter((a) => !["audit", "registers", "roles", "website"].includes(a));
  const tabs: (Tab | false)[] = {
    tasks: [
      { href: seesDashboard(role) ? "/my-tasks" : "/", text: "My tasks" },
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
      // Switched off: only the system admin still sees them (cmeprojects).
      peopleManager && (admin || teamsOn(features)) && { href: "/settings/teams", text: "Teams" },
      (admin || (rolesOn(features) && (access.adminAreas ?? []).includes("roles"))) && { href: "/settings/roles", text: "Roles" },
      peopleManager && { href: "/settings/clients", text: "Clients" },
      access.seesCompliance && { href: "/compliance", text: "Compliance" },
      !peopleManager && access.canInvite && { href: "/invite", text: "Invite staff" },
    ],
    reports: [
      Boolean(access.seesReports) && features.reports !== false && { href: "/reports", text: "Tasks" },
      cars && Boolean(access.carReports) && features.reports !== false && { href: "/reports/cars", text: "Cars" },
      Boolean(access.complianceReport) && features.reports !== false && { href: "/reports/compliance", text: "Compliance" },
      ...(features.reports !== false ? (access.featureReports ?? []) : []).map((f) => ({ href: `/reports/f/${f.slug}`, text: f.label })),
    ],
    settings: [
      // The system admin sets due dates in Features → Tasks; managers here.
      role === "manager" && { href: "/settings/sla", text: "Due dates (SLA)" },
      (admin || settingsAreas.length > 0) && { href: "/system", text: "System settings" },
      // The system admin always sees Website settings (to set it up before switching it on).
      (admin || (features.assistant === true && (access.adminAreas ?? []).includes("website"))) && { href: "/assistant", text: "Website settings" },
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
    // Only while at least one compliance part is on.
    ...(role !== "system_admin" && onboardingOn(features) ? [{ href: "/onboarding", label: "My onboarding" }] : []),
    { href: "/account", label: "My account" },
  ];

  // External contractors (for later): nothing yet but their account.
  if (role === "external") return [{ items: [{ href: "/", label: "Home" }] }, { items: [{ href: "/account", label: "My account" }] }];

  // New starters: just their welcome page and onboarding until they have a role.
  if (role === "new_starter" && !access.newStarterTasks) {
    return [{ items: [{ href: "/", label: "Home" }] }, { items: mine }];
  }

  const dashboard = seesDashboard(role);
  const admin = role === "system_admin";
  // Tools as their own part of the menu: built features, cars and the apps.
  const tools: NavItem[] = [
    ...(access.customFeatures ?? []).map((f) => ({ href: `/f/${f.slug}`, label: f.label })),
    ...sectionItem("cars", role, features, access),
    ...(access.appsLabel ? [{ href: "/apps", label: access.appsLabel }] : []),
  ];
  return [
    {
      items: [
        // Your tasks and questions are on your home page (cmeprojects); the
        // system admin's home is the platform, with everyone's tasks under Tasks.
        { href: "/", label: "Dashboard", match: dashboard && !admin ? ["/", "/my-tasks"] : undefined },
        ...(admin ? [{ href: "/tasks", label: "Tasks", match: ["/tasks", "/my-tasks"] }] : []),
        // Who sees Registers is set by the system admin (System settings → Tasks).
        ...(access.seesRegisters ? [{ href: "/registers", label: "Registers" }] : []),
        ...(access.forms ? [{ href: "/forms", label: "Forms", match: ["/forms"] }] : []),
        ...(access.enquiries ? [{ href: "/enquiries", label: "Enquiries" }] : []),
        ...(access.assistant ? [{ href: "/ask", label: "Assistant" }] : []),
        ...sectionItem("people", role, features, access),
        ...(access.seesScoreboard ? [{ href: "/scoreboard", label: "Scoreboard" }] : []),
        ...sectionItem("reports", role, features, access),
        ...sectionItem("settings", role, features, access),
      ],
    },
    ...(tools.length ? [{ heading: "Tools", items: tools }] : []),
    { items: mine },
  ];
}

// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: the module catalogue. One list of every module and submodule:
// its category, place in the menu, route, icon, sensitivity and whether it can
// be delegated. The database holds the same ids (public.app_modules, checked by
// scripts/check-modules.mjs); permissions and delegation build on them.
//
// Adding a module: add it here AND as a row in a new migration. It shows in
// the menu only where the person can already open its page; it's never given
// to anyone automatically.

export type CategoryId = "workspace" | "operations" | "people" | "hr" | "clients" | "workflows" | "insights" | "engagement" | "system";
export type Sensitivity = "normal" | "sensitive" | "protected";

export type ModuleDef = {
  id: string;
  category: CategoryId;
  parent?: string;
  label: string;
  icon: string; // a lucide-react icon name (see src/components/module-icons.tsx)
  href: string;
  // Other addresses that light this item up.
  match?: string[];
  sensitivity?: Sensitivity;
  delegable?: boolean;
  description?: string;
};

export const CATEGORIES: { id: CategoryId; label: string }[] = [
  { id: "workspace", label: "My workspace" },
  { id: "operations", label: "Operations" },
  { id: "people", label: "People & organisation" },
  { id: "hr", label: "HR & workforce" },
  { id: "clients", label: "Clients & care" },
  { id: "workflows", label: "Forms & workflows" },
  { id: "insights", label: "Reports & insights" },
  { id: "engagement", label: "Website & engagement" },
  { id: "system", label: "Administration" },
];

export const MODULES: ModuleDef[] = [
  // My workspace (everyone, for themselves)
  { id: "workspace.dashboard", category: "workspace", label: "Dashboard", icon: "LayoutDashboard", href: "/" },
  { id: "workspace.onboarding", category: "workspace", label: "My onboarding", icon: "GraduationCap", href: "/onboarding" },
  { id: "workspace.requests", category: "workspace", label: "My requests", icon: "ClipboardCheck", href: "/requests" },
  { id: "workspace.forms", category: "workspace", label: "My forms", icon: "ClipboardList", href: "/forms" },
  { id: "workspace.contracts", category: "workspace", label: "My contracts", icon: "FileSignature", href: "/account/contracts" },
  { id: "workspace.directory", category: "workspace", label: "Directory", icon: "Contact", href: "/people" },

  // Operations
  { id: "ops.tasks", category: "operations", label: "Tasks", icon: "ListChecks", href: "/tasks", match: ["/tasks", "/my-tasks"], delegable: true },
  { id: "ops.registers", category: "operations", label: "Registers", icon: "FolderKanban", href: "/registers", match: ["/registers", "/records"], delegable: true },
  { id: "ops.cars", category: "operations", label: "Cars", icon: "Car", href: "/cars", delegable: true },
  { id: "ops.cars.use", category: "operations", parent: "ops.cars", label: "Use a car", icon: "Car", href: "/cars" },
  { id: "ops.cars.manage", category: "operations", parent: "ops.cars", label: "Manage cars", icon: "Wrench", href: "/cars/manage" },
  { id: "ops.cars.app", category: "operations", parent: "ops.cars", label: "Get the app", icon: "Smartphone", href: "/cars/install" },
  { id: "ops.features", category: "operations", label: "Built features", icon: "Puzzle", href: "/f", delegable: true },
  { id: "ops.scoreboard", category: "operations", label: "Scoreboard", icon: "Trophy", href: "/scoreboard" },
  { id: "ops.apps", category: "operations", label: "Apps", icon: "Smartphone", href: "/apps" },

  // People & organisation
  { id: "people.staff", category: "people", label: "Staff", icon: "Users", href: "/settings/staff", delegable: true },
  { id: "people.invite", category: "people", label: "Invite staff", icon: "UserPlus", href: "/invite" },
  { id: "people.teams", category: "people", label: "Teams", icon: "UsersRound", href: "/settings/teams", delegable: true },
  { id: "people.roles", category: "people", label: "Roles", icon: "ShieldCheck", href: "/settings/roles", delegable: true },

  // HR & workforce
  { id: "hr.onboarding", category: "hr", label: "Onboarding", icon: "GraduationCap", href: "/compliance", delegable: true },
  { id: "hr.onboarding.overview", category: "hr", parent: "hr.onboarding", label: "Overview and checks", icon: "GraduationCap", href: "/compliance" },
  { id: "hr.onboarding.expiry", category: "hr", parent: "hr.onboarding", label: "Expiry list", icon: "CalendarClock", href: "/compliance/expiry" },
  { id: "hr.contracts", category: "hr", label: "Contracts", icon: "FileSignature", href: "/contracts", sensitivity: "sensitive", delegable: true },
  { id: "hr.requests", category: "hr", label: "Staff requests", icon: "Inbox", href: "/people/requests", delegable: true },

  // Clients & care
  { id: "clients.list", category: "clients", label: "Clients", icon: "HeartHandshake", href: "/settings/clients", delegable: true },

  // Forms & workflows
  { id: "workflows.forms", category: "workflows", label: "Forms", icon: "ClipboardList", href: "/forms", delegable: true },
  { id: "workflows.request_rules", category: "workflows", label: "Request approvals", icon: "ClipboardCheck", href: "/settings/requests", delegable: true },
  { id: "workflows.sla", category: "workflows", label: "SLA settings", icon: "Clock", href: "/settings/sla", delegable: true },

  // Reports & insights
  { id: "insights.reports", category: "insights", label: "Reports", icon: "BarChart3", href: "/reports", delegable: true },
  { id: "insights.reports.tasks", category: "insights", parent: "insights.reports", label: "Tasks", icon: "BarChart3", href: "/reports" },
  { id: "insights.reports.cars", category: "insights", parent: "insights.reports", label: "Cars", icon: "Car", href: "/reports/cars" },
  { id: "insights.reports.compliance", category: "insights", parent: "insights.reports", label: "Compliance", icon: "GraduationCap", href: "/reports/compliance" },

  // Website & engagement
  { id: "engagement.assistant", category: "engagement", label: "Assistant", icon: "MessageCircle", href: "/ask" },
  { id: "engagement.enquiries", category: "engagement", label: "Enquiries", icon: "Inbox", href: "/enquiries", delegable: true },
  { id: "engagement.website", category: "engagement", label: "Website settings", icon: "Globe", href: "/assistant", delegable: true },

  // Administration (system & configuration)
  { id: "system.settings", category: "system", label: "System settings", icon: "Settings", href: "/system", sensitivity: "protected" },
  { id: "system.access", category: "system", label: "Staff access", icon: "KeyRound", href: "/settings/access", sensitivity: "protected" },
  { id: "system.audit", category: "system", label: "Change log", icon: "History", href: "/system/audit", delegable: true },
  { id: "system.builder", category: "system", label: "Feature builder", icon: "Puzzle", href: "/system/builder", sensitivity: "protected" },
  { id: "system.health", category: "system", label: "System health", icon: "Activity", href: "/system/health", sensitivity: "protected" },
];

export const moduleById = (id: string) => MODULES.find((m) => m.id === id);

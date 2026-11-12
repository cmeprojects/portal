// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: the module catalogue. One list of every module and submodule:
// its category, place in the menu, route, icon, sensitivity and whether it can
// be delegated. The database holds the same ids (public.app_modules, checked by
// scripts/check-modules.mjs); permissions and delegation build on them.
//
// Adding a module: add it here AND as a row in a new migration. It shows in
// the menu only where the person can already open its page; it's never given
// to anyone automatically. The menu has one item per module. A module's
// sub-pages are hidden until the person chooses to show them (up to 3 modules
// at a time); href "" = never a menu item (permission-only).

export type CategoryId = "workspace" | "operations" | "apps" | "people" | "hr" | "clients" | "workflows" | "insights" | "engagement" | "system";
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
  // A hub page that lists its sub-pages as cards (they're never menu items).
  hub?: boolean;
};

export const CATEGORIES: { id: CategoryId; label: string }[] = [
  { id: "workspace", label: "My workspace" },
  { id: "operations", label: "Operations" },
  { id: "apps", label: "Apps" },
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
  { id: "ops.cars", category: "apps", label: "Cars", icon: "Car", href: "/cars", match: ["/cars", "/cars/manage", "/cars/install"], delegable: true },
  { id: "ops.cars.use", category: "apps", parent: "ops.cars", label: "Use a car", icon: "Car", href: "/cars" },
  { id: "ops.cars.manage", category: "apps", parent: "ops.cars", label: "Manage cars", icon: "Wrench", href: "/cars/manage" },
  { id: "ops.cars.app", category: "apps", parent: "ops.cars", label: "Get the app", icon: "Smartphone", href: "/cars/install" },
  { id: "ops.features", category: "apps", label: "Built features", icon: "Puzzle", href: "/f", delegable: true },
  { id: "ops.scoreboard", category: "operations", label: "Scoreboard", icon: "Trophy", href: "/scoreboard" },
  { id: "ops.apps", category: "apps", label: "Phone apps", icon: "Smartphone", href: "/apps" },

  // People & organisation
  { id: "people.staff", category: "people", label: "Staff", icon: "Users", href: "/settings/staff", delegable: true },
  { id: "people.invite", category: "people", label: "Invite staff", icon: "UserPlus", href: "/invite" },
  { id: "people.teams", category: "people", label: "Teams", icon: "UsersRound", href: "/settings/teams", delegable: true },
  { id: "people.roles", category: "people", label: "Roles", icon: "ShieldCheck", href: "/settings/roles", delegable: true },

  // HR & workforce
  { id: "hr.onboarding", category: "hr", label: "Onboarding", icon: "GraduationCap", href: "/compliance", match: ["/compliance", "/compliance/expiry"], delegable: true },
  { id: "hr.onboarding.overview", category: "hr", parent: "hr.onboarding", label: "Overview and checks", icon: "GraduationCap", href: "/compliance" },
  { id: "hr.onboarding.expiry", category: "hr", parent: "hr.onboarding", label: "Expiry list", icon: "CalendarClock", href: "/compliance/expiry" },
  { id: "hr.contracts", category: "hr", label: "Contracts", icon: "FileSignature", href: "/contracts", sensitivity: "sensitive", delegable: true },
  { id: "hr.requests", category: "hr", label: "Staff requests", icon: "Inbox", href: "/people/requests", delegable: true },

  // Permission-only modules (no page of their own; never shown in the menu).
  { id: "hr.records", category: "hr", label: "Staff records", icon: "Users", href: "", delegable: true },
  { id: "hr.records.details", category: "hr", parent: "hr.records", label: "Staff details", icon: "Users", href: "", delegable: true },
  { id: "hr.records.payroll", category: "hr", parent: "hr.records", label: "Payroll and tax (bank, super, TFN)", icon: "Landmark", href: "", sensitivity: "sensitive", delegable: true },
  { id: "hr.records.identity", category: "hr", parent: "hr.records", label: "Identity and work rights", icon: "ShieldCheck", href: "", sensitivity: "sensitive", delegable: true },

  // Clients & care
  { id: "clients.list", category: "clients", label: "Clients", icon: "HeartHandshake", href: "/settings/clients", delegable: true },

  // Forms & workflows
  { id: "workflows.forms", category: "operations", label: "Forms", icon: "ClipboardList", href: "/forms", delegable: true },
  { id: "workflows.request_rules", category: "system", parent: "system.settings", label: "Request approvals", icon: "ClipboardCheck", href: "/settings/requests", delegable: true, description: "Who approves each kind of staff request, and when it escalates." },
  { id: "workflows.sla", category: "system", parent: "system.settings", label: "SLA settings", icon: "Clock", href: "/settings/sla", delegable: true, description: "Due dates by priority, reminders and escalation." },

  // Reports & insights
  { id: "insights.reports", category: "insights", label: "Reports", icon: "BarChart3", href: "/reports", match: ["/reports", "/reports/cars", "/reports/compliance", "/reports/f"], delegable: true },
  { id: "insights.reports.tasks", category: "insights", parent: "insights.reports", label: "Tasks", icon: "BarChart3", href: "/reports" },
  { id: "insights.reports.cars", category: "insights", parent: "insights.reports", label: "Cars", icon: "Car", href: "/reports/cars" },
  { id: "insights.reports.compliance", category: "insights", parent: "insights.reports", label: "Compliance", icon: "GraduationCap", href: "/reports/compliance" },

  // Website & engagement
  { id: "engagement.assistant", category: "engagement", label: "Assistant", icon: "MessageCircle", href: "/ask" },
  { id: "engagement.enquiries", category: "engagement", label: "Enquiries", icon: "Inbox", href: "/enquiries", delegable: true },
  { id: "engagement.website", category: "engagement", label: "Website settings", icon: "Globe", href: "/assistant", delegable: true },

  // Administration (system & configuration)
  { id: "system.settings", category: "system", label: "Portal settings", icon: "Settings", href: "/settings", match: ["/settings", "/system", "/settings/sla", "/settings/requests"], hub: true, sensitivity: "protected" },
  { id: "system.settings.general", category: "system", parent: "system.settings", label: "System settings", icon: "Settings", href: "/system", sensitivity: "protected", description: "Features, branding, messages, people rules, notifications, security and delegation areas." },
  { id: "system.settings.branding", category: "system", parent: "system.settings", label: "Branding", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.messages", category: "system", parent: "system.settings", label: "Messages", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.people", category: "system", parent: "system.settings", label: "People rules", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.compliance", category: "system", parent: "system.settings", label: "Compliance settings", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.tasks", category: "system", parent: "system.settings", label: "Task settings", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.reports", category: "system", parent: "system.settings", label: "Who can see reports", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.vehicles", category: "system", parent: "system.settings", label: "Car settings", icon: "Settings", href: "", delegable: true },
  { id: "system.settings.hr", category: "system", parent: "system.settings", label: "HR Pack settings", icon: "Settings", href: "", delegable: true },
  { id: "ops.registers.setup", category: "operations", parent: "ops.registers", label: "Set up any register", icon: "FolderKanban", href: "", delegable: true },
  { id: "system.access", category: "system", label: "Access", icon: "KeyRound", href: "/settings/access", sensitivity: "protected" },
  { id: "system.audit", category: "system", parent: "system.settings", label: "Change log", icon: "History", href: "/system/audit", delegable: true, description: "Who changed what in the settings, and when." },
  { id: "system.builder", category: "system", parent: "system.settings", label: "Feature builder", icon: "Puzzle", href: "/system/builder", sensitivity: "protected", description: "Build new apps: registers with their own forms and reports." },
  { id: "system.health", category: "system", parent: "system.settings", label: "System health", icon: "Activity", href: "/system/health", sensitivity: "protected", description: "Database, storage, email and speed checks." },
];

export const moduleById = (id: string) => MODULES.find((m) => m.id === id);

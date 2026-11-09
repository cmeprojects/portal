// Staff Portal · © cmeproject. All rights reserved.

// Areas the system admin can hand to all managers or to chosen managers and
// staff admins (cmeprojects settings revamp). Security, Features,
// Notifications, Demo data, General and Delegation always stay with the system admin.
export const AREAS = ["registers", "register_setup", "roles", "branding", "messages", "people", "compliance", "tasks", "reports", "vehicles", "website", "audit", "hr"] as const;
export type Area = (typeof AREAS)[number];

export const AREA_LABELS: Record<Area, string> = {
  registers: "Adding registers (new registers and their set-up)",
  register_setup: "Setting up registers (change any register)",
  roles: "Roles (adding and changing job titles)",
  branding: "Branding (name, logos, colours, wording)",
  messages: "Messages (support contact, announcement, invite note)",
  people: "People rules",
  compliance: "Compliance settings",
  tasks: "Task settings",
  reports: "Who can see Reports",
  vehicles: "Car settings",
  website: "Website (where the Assistant looks, and its documents)",
  audit: "Read the change log",
  hr: "HR Pack (request approvals, clearing people to work)",
};

// What each area lets the manager do, shown under it on the Delegation tab.
export const AREA_HINTS: Record<Area, string> = {
  registers: "Make new registers (like Incidents or Complaints) and set up their fields. Using registers doesn't need this.",
  register_setup: "Change every register's settings, fields, managers and who can create tasks in it, not only the registers they manage. Seeing and approving tasks doesn't change.",
  roles: "Add job titles and choose which access level each one has. Giving people a role doesn't need this.",
  branding: "Change the company name, portal name, logos, colours, and the words the portal uses (for example Client or Participant).",
  messages: "Edit the support contact on the sign-in page, the announcement banner for all staff, and the note in welcome invites.",
  people: "Which staff admin changes need a manager's approval, who can send invites, what new starters can do, who sees the Scoreboard, who can help staff sign in (reset links, two-factor, Cars app PIN), and when a task counts as stuck.",
  compliance: "Who manages Compliance (onboarding documents, trainings and uploads), and how many days before expiry reminders start.",
  tasks: "Default due dates, reminders, escalation, weekdays only, when required fields must be filled in, the morning summary, and who sees Registers.",
  reports: "Choose who sees Reports (tasks) and the Compliance report.",
  vehicles: "Odometer photo, undo time, the car-still-out reminder, Cars app sign-in days, and who manages or reports on cars.",
  website: "Choose where the website's Assistant looks for answers (documents, listed websites or both), the listed websites, and upload or remove its documents.",
  audit: "Read the change log: who changed what in System settings, and when. They can't change anything with this alone.",
  hr: "Who approves each kind of request (leave, swaps, timesheets and more) and when they escalate, and which roles besides managers can clear people to work and give overrides.",
};

const MESSAGES = ["brand.support_contact", "brand.announcement", "people.invite_message"];

// Which area a setting belongs to (null = system admin only). Matches
// public.setting_area() in the database, which has the final say.
export function areaOf(key: string): Area | null {
  if (MESSAGES.includes(key)) return "messages";
  if (key.startsWith("brand.") || key.startsWith("wording.")) return "branding";
  if (key.startsWith("people.")) return "people";
  // cmeprojects: who can clear people to work belongs to HR Pack (update 59).
  if (key === "compliance.clearance_roles") return "hr";
  if (key === "compliance.clearance_started") return null;
  if (key === "cars.cleared_only") return "vehicles";
  if (key.startsWith("compliance.")) return "compliance";
  if (key.startsWith("tasks.")) return "tasks";
  if (key.startsWith("website.") || key.startsWith("assistant.")) return "website";
  if (key.startsWith("reports.")) return "reports";
  if (key.startsWith("vehicles.")) return "vehicles";
  return null;
}

export function isArea(v: unknown): v is Area {
  return typeof v === "string" && (AREAS as readonly string[]).includes(v);
}

// Staff Portal · © cmeproject. All rights reserved.

// Areas of System settings the system admin can hand to a named manager.
// Security, Features, General and Delegation always stay with the system admin.
export const AREAS = ["branding", "messages", "people", "compliance", "tasks", "reports", "vehicles", "audit"] as const;
export type Area = (typeof AREAS)[number];

export const AREA_LABELS: Record<Area, string> = {
  branding: "Branding (name, logos, colours, wording)",
  messages: "Messages (support contact, announcement, invite note)",
  people: "People rules",
  compliance: "Compliance settings",
  tasks: "Task settings",
  reports: "Who can see Reports",
  vehicles: "Car settings",
  audit: "Read the change log",
};

// What each area lets the manager do, shown under it on the Delegation tab.
export const AREA_HINTS: Record<Area, string> = {
  branding: "Change the company name, portal name, logos, colours, and the words the portal uses (for example Client or Participant).",
  messages: "Edit the support contact on the sign-in page, the announcement banner for all staff, and the note in welcome invites.",
  people: "Which staff admin changes need a manager's approval, who can send invites, what new starters can do, who sees the Scoreboard, and when a task counts as stuck.",
  compliance: "Who manages Compliance (onboarding documents, trainings and uploads), and how many days before expiry reminders start.",
  tasks: "Default due dates, reminders, escalation, weekdays only, when required fields must be filled in, the morning summary, and who sees Registers.",
  reports: "Choose who sees Reports (tasks) and the Compliance report.",
  vehicles: "Odometer photo, undo time, the car-still-out reminder, Cars app sign-in days, and who manages or reports on cars.",
  audit: "Read the change log: who changed what in System settings, and when. They can't change anything with this alone.",
};

const MESSAGES = ["brand.support_contact", "brand.announcement", "people.invite_message"];

// Which area a setting belongs to (null = system admin only). Matches
// public.setting_area() in the database, which has the final say.
export function areaOf(key: string): Area | null {
  if (MESSAGES.includes(key)) return "messages";
  if (key.startsWith("brand.") || key.startsWith("wording.")) return "branding";
  if (key.startsWith("people.")) return "people";
  if (key.startsWith("compliance.")) return "compliance";
  if (key.startsWith("tasks.")) return "tasks";
  if (key.startsWith("reports.")) return "reports";
  if (key.startsWith("vehicles.")) return "vehicles";
  return null;
}

export function isArea(v: unknown): v is Area {
  return typeof v === "string" && (AREAS as readonly string[]).includes(v);
}

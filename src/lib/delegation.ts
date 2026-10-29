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

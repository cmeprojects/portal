// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (update 149): incident words shared by the screens.
export const INCIDENT_KINDS: [string, string][] = [
  ["injury", "Injury"],
  ["fall", "Fall"],
  ["medication", "Medication"],
  ["behaviour", "Behaviour of concern"],
  ["abuse_neglect", "Suspected abuse or neglect"],
  ["health", "Health or medical"],
  ["missing_person", "Missing person"],
  ["property", "Property damage or loss"],
  ["complaint", "Complaint"],
  ["restrictive_practice", "Restrictive practice"],
  ["other", "Other"],
];
export const INCIDENT_SEVERITY: [string, string][] = [
  ["low", "Low"],
  ["medium", "Medium"],
  ["high", "High"],
  ["critical", "Critical"],
];
// NDIS reportable incident categories (the deadline is set by the database).
export const REPORTABLE: [string, string][] = [
  ["death", "Death of a person with disability"],
  ["serious_injury", "Serious injury"],
  ["abuse_neglect", "Abuse or neglect"],
  ["unlawful_contact", "Unlawful sexual or physical contact, or assault"],
  ["sexual_misconduct", "Sexual misconduct"],
  ["restrictive_practice", "Unauthorised use of a restrictive practice"],
];
export const INCIDENT_STATUS: Record<string, [string, string]> = {
  new: ["New", "bg-danger text-white"],
  acknowledged: ["Acknowledged", "bg-warn-soft text-ink"],
  investigating: ["Investigating", "bg-brand-soft text-brand"],
  closed: ["Closed", "bg-line text-muted"],
};
export const label = (list: [string, string][], k: string | null) => list.find(([v]) => v === k)?.[1] ?? k ?? "";

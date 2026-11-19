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
  ["near_miss", "Near miss"],
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
// The usual flow: reported -> triage -> investigation -> manager sign-off -> closed.
export const INCIDENT_STATUS: Record<string, [string, string]> = {
  new: ["Reported, needs triage", "bg-danger text-white"],
  investigating: ["Under investigation", "bg-brand-soft text-brand"],
  review: ["Awaiting sign-off", "bg-warn-soft text-ink"],
  closed: ["Closed", "bg-line text-muted"],
};
export const INCIDENT_STAGES: [string, string][] = [
  ["new", "Reported"],
  ["triage", "Triage"],
  ["investigating", "Investigation"],
  ["review", "Sign-off"],
  ["closed", "Closed"],
];
export const label = (list: [string, string][], k: string | null) => list.find(([v]) => v === k)?.[1] ?? k ?? "";

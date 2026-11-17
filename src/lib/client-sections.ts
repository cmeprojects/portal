// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects (Clients & Care steps 2 to 5): the fields each client section
// may save, shared by the profile page (to draw the forms) and the server
// action (which only accepts these). The database checks everything again.

export type FieldType = "text" | "textarea" | "date" | "select" | "checkbox";
export type FieldSpec = {
  name: string;
  label: string;
  type: FieldType;
  required?: boolean;
  max?: number;
  options?: [string, string][];
  hint?: string;
  defaultOn?: boolean;
  // Pre-filled on a new item.
  def?: string;
};

export const STATES: [string, string][] = [["", "—"], ...["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"].map((s) => [s, s] as [string, string])];
export const PERSON_KINDS: [string, string][] = [
  ["emergency", "Emergency contact"],
  ["next_of_kin", "Next of kin"],
  ["nominee", "Nominee"],
  ["guardian", "Guardian"],
  ["representative", "Authorised representative"],
];
export const ALERT_KINDS: [string, string][] = [
  ["safety", "Safety"],
  ["medical", "Medical"],
  ["behaviour", "Behaviour"],
  ["environment", "Home or environment"],
  ["mobility", "Mobility"],
  ["other", "Other"],
];
export const SEVERITIES: [string, string][] = [["high", "High"], ["medium", "Medium"], ["low", "Low"]];
export const SERVICE_STATUS: [string, string][] = [["planned", "Planned"], ["active", "Active"], ["on_hold", "On hold"], ["ended", "Ended"]];
export const CONTACT_WAYS: [string, string][] = [
  ["", "—"],
  ["phone", "Phone call"],
  ["sms", "Text message"],
  ["email", "Email"],
  ["post", "Post"],
  ["through_representative", "Through their representative"],
];

export type SectionTable = "client_locations" | "client_details" | "client_people" | "client_alerts" | "client_services";

export const SECTION_FIELDS: Record<SectionTable, FieldSpec[]> = {
  client_locations: [
    { name: "label", label: "Name for this place", type: "text", required: true, max: 60, hint: "For example Home or Day program", def: "Home" },
    { name: "address", label: "Street address", type: "text", required: true, max: 200 },
    { name: "suburb", label: "Suburb", type: "text", max: 60 },
    { name: "state", label: "State", type: "select", options: STATES },
    { name: "postcode", label: "Postcode", type: "text", max: 4 },
    { name: "access_notes", label: "Access instructions for workers", type: "textarea", max: 1000, hint: "Shown to the client's team once approved, for example parking or the key safe" },
    { name: "from_date", label: "From (optional)", type: "date" },
    { name: "to_date", label: "Until (optional)", type: "date", hint: "Set an end date instead of deleting" },
    { name: "approved", label: "Approved for services", type: "checkbox" },
  ],
  client_details: [
    { name: "date_of_birth", label: "Date of birth", type: "date", hint: "Needed for NDIS and Support at Home" },
    { name: "phone", label: "Phone", type: "text", max: 30 },
    { name: "email", label: "Email", type: "text", max: 120 },
    { name: "home_address", label: "Home address", type: "textarea", max: 300 },
    { name: "preferred_contact", label: "Best way to contact", type: "select", options: CONTACT_WAYS },
    { name: "communication_needs", label: "Communication or accessibility needs", type: "textarea", max: 1000 },
    { name: "ndis_number", label: "NDIS number", type: "text", max: 9, hint: "Nine numbers" },
    { name: "aged_care_id", label: "My Aged Care ID", type: "text", max: 30 },
  ],
  client_people: [
    { name: "kind", label: "Who they are", type: "select", options: PERSON_KINDS },
    { name: "name", label: "Name", type: "text", required: true, max: 100 },
    { name: "relationship", label: "Relationship", type: "text", max: 60 },
    { name: "phone", label: "Phone", type: "text", max: 30 },
    { name: "email", label: "Email", type: "text", max: 120 },
    { name: "authority", label: "Authority or consent they hold", type: "textarea", max: 500 },
    { name: "primary_contact", label: "Main contact", type: "checkbox" },
    { name: "active", label: "Current", type: "checkbox", defaultOn: true },
  ],
  client_alerts: [
    { name: "kind", label: "Type", type: "select", options: ALERT_KINDS },
    { name: "severity", label: "Severity", type: "select", options: SEVERITIES },
    { name: "title", label: "Alert", type: "text", required: true, max: 120, hint: "Short, for example Severe nut allergy" },
    { name: "worker_instructions", label: "What workers must do", type: "textarea", max: 2000, hint: "Shown to the client's team" },
    { name: "escalation", label: "Who to call if something happens", type: "textarea", max: 500 },
    { name: "notes", label: "Detailed risk notes (managers only)", type: "textarea", max: 5000 },
    { name: "review_date", label: "Review by", type: "date" },
    { name: "active", label: "Current", type: "checkbox", defaultOn: true },
  ],
  client_services: [
    { name: "label", label: "Service", type: "text", required: true, max: 80, hint: "For example Daily living support" },
    { name: "program_id", label: "Program", type: "select" },
    { name: "location_id", label: "Where", type: "select" },
    { name: "start_date", label: "Start", type: "date", required: true },
    { name: "end_date", label: "End (optional)", type: "date" },
    { name: "status", label: "Status", type: "select", options: SERVICE_STATUS },
    { name: "scheduling_notes", label: "Scheduling restrictions", type: "textarea", max: 1000, hint: "For example mornings only, no Sundays" },
    { name: "consent_required", label: "Consent needed", type: "checkbox" },
    { name: "consent_given_on", label: "Consent given on", type: "date" },
    { name: "consent_note", label: "Consent note", type: "text", max: 500 },
  ],
};

// The update number each section arrives with (for the "after update" note).
export const SECTION_UPDATE: Record<SectionTable, number> = {
  client_locations: 87,
  client_details: 88,
  client_people: 88,
  client_alerts: 89,
  client_services: 90,
};

// cmeprojects (Stage 5): what a staff member is assigned to a client as.
export const ASSIGNED_AS: [string, string][] = [
  ["case_manager", "Case manager"],
  ["intake", "Intake"],
  ["key_worker", "Key worker"],
  ["other", "Other"],
];

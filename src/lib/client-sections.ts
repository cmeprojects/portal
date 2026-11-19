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

// cmeprojects (update 151): schemes whose clients need their My Aged Care ID.
export const MAC_SCHEMES = ["support_at_home", "chsp"];
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
export const SERVICE_STATUS: [string, string][] = [["planned", "Pending"], ["active", "Active"], ["on_hold", "Suspended"], ["ended", "Ended"]];
export const CONTACT_WAYS: [string, string][] = [
  ["", "—"],
  ["phone", "Phone call"],
  ["sms", "Text message"],
  ["email", "Email"],
  ["post", "Post"],
  ["through_representative", "Through their representative"],
];

// cmeprojects (update 118): client details the owner chose. Sensitive ones
// (religion, marital status, cultural identity) are optional, with consent.
export const TITLES: [string, string][] = [["", "—"], ["mr", "Mr"], ["mrs", "Mrs"], ["ms", "Ms"], ["miss", "Miss"], ["mx", "Mx"], ["dr", "Dr"]];
export const GENDERS: [string, string][] = [["", "—"], ["female", "Female"], ["male", "Male"], ["non_binary", "Non-binary"], ["different_term", "Uses a different term"], ["prefer_not_to_say", "Prefer not to say"]];
export const TIME_ZONES: [string, string][] = [
  ["Australia/Sydney", "Sydney, Canberra (NSW, ACT)"],
  ["Australia/Melbourne", "Melbourne (VIC)"],
  ["Australia/Brisbane", "Brisbane (QLD)"],
  ["Australia/Adelaide", "Adelaide (SA)"],
  ["Australia/Darwin", "Darwin (NT)"],
  ["Australia/Perth", "Perth (WA)"],
  ["Australia/Hobart", "Hobart (TAS)"],
  ["Australia/Lord_Howe", "Lord Howe Island"],
];
export const LIVING: [string, string][] = [["", "—"], ["own_home", "Own home"], ["with_family", "With family"], ["supported_accommodation", "Supported accommodation"], ["residential_care", "Residential care"], ["other", "Other"]];
export const MARITAL: [string, string][] = [["", "—"], ["single", "Single"], ["partnered", "Partnered"], ["married", "Married"], ["separated", "Separated"], ["divorced", "Divorced"], ["widowed", "Widowed"], ["prefer_not_to_say", "Prefer not to say"]];
export const ATSI: [string, string][] = [["", "—"], ["aboriginal", "Aboriginal"], ["torres_strait_islander", "Torres Strait Islander"], ["both", "Both Aboriginal and Torres Strait Islander"], ["neither", "Neither"], ["prefer_not_to_say", "Prefer not to say"]];
export const ARCHIVE_REASONS: [string, string][] = [
  ["transferred", "Transferred to another provider"],
  ["moved_away", "Moved away"],
  ["no_longer_needed", "No longer needs support"],
  ["funding_ended", "Funding ended"],
  ["passed_away", "Passed away"],
  ["client_choice", "Their choice"],
  ["other", "Other (say why)"],
];

export type SectionTable = "client_locations" | "client_details" | "client_people" | "client_alerts" | "client_services";

export const SECTION_FIELDS: Record<SectionTable, FieldSpec[]> = {
  client_locations: [
    { name: "label", label: "Name for this place", type: "text", required: true, max: 60, hint: "For example Home or Day program", def: "Home" },
    { name: "address", label: "Street address", type: "text", required: true, max: 200 },
    { name: "suburb", label: "Suburb", type: "text", required: true, max: 60 },
    { name: "state", label: "State", type: "select", required: true, options: STATES },
    { name: "postcode", label: "Postcode", type: "text", required: true, max: 4 },
    { name: "access_notes", label: "Access instructions for workers", type: "textarea", max: 1000, hint: "Shown to the client's team once approved, for example parking or the key safe" },
    { name: "from_date", label: "From (optional)", type: "date" },
    { name: "to_date", label: "Until (optional)", type: "date", hint: "Set an end date instead of deleting" },
    { name: "approved", label: "Approved for services", type: "checkbox" },
  ],
  client_details: [
    { name: "date_of_birth", label: "Date of birth", type: "date", required: true },
    { name: "gender", label: "Gender (optional)", type: "select", options: GENDERS },
    { name: "phone", label: "Mobile", type: "text", required: true, max: 30, hint: "If they don't have one, enter the mobile of the family carer or person assisting them." },
    { name: "email", label: "Email", type: "text", required: true, max: 120, hint: "If they don't have one, enter the email of the family carer or person assisting them." },
    { name: "home_address", label: "Home address", type: "textarea", required: true, max: 300, hint: "Street, then suburb, state and postcode, for example 12 Smith Street, Dulwich Hill NSW 2203" },
    { name: "state", label: "State", type: "select", required: true, options: STATES },
    { name: "time_zone", label: "Time zone", type: "select", options: TIME_ZONES },
    { name: "living_situation", label: "Living situation (optional)", type: "select", options: LIVING },
    { name: "preferred_contact", label: "Best way to contact", type: "select", options: CONTACT_WAYS },
    { name: "communication_needs", label: "Communication or accessibility needs", type: "textarea", max: 1000 },
    { name: "ndis_number", label: "NDIS number", type: "text", max: 9, hint: "Nine numbers. Required for NDIS services" },
    { name: "aged_care_id", label: "My Aged Care ID", type: "text", max: 30, hint: "Required for Support at Home and CHSP services" },
    { name: "about", label: "About them (optional)", type: "textarea", max: 2000, hint: "What matters to them, likes and dislikes, how they like support" },
    { name: "atsi_status", label: "Aboriginal and/or Torres Strait Islander (optional)", type: "select", options: ATSI, hint: "Ask; never assume. Only with consent" },
    { name: "country_of_birth", label: "Country of birth (optional)", type: "text", max: 60 },
    { name: "nationality", label: "Nationality (optional)", type: "text", max: 60 },
    { name: "religion", label: "Religion or beliefs (optional)", type: "text", max: 60, hint: "Sensitive: only with consent, if it matters for their support" },
    { name: "marital_status", label: "Marital status (optional)", type: "select", options: MARITAL, hint: "Sensitive: only with consent" },
    { name: "tags", label: "Tags (optional)", type: "text", max: 300, hint: "Separate with commas, up to 10" },
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
  ["support_coordinator", "Support coordinator"],
  ["intake", "Intake"],
  ["key_worker", "Key worker"],
  ["other", "Other"],
];

// cmeprojects (Care block C3): kinds of client document.
export const DOC_TYPE_LABELS: [string, string][] = [
  ["consent", "Consent"],
  ["assessment", "Assessment"],
  ["plan", "Plan"],
  ["report", "Report"],
  ["agreement", "Agreement"],
  ["correspondence", "Correspondence"],
  ["identity", "Identity"],
  ["other", "Other"],
];

// cmeprojects (Care block C7): how an NDIS plan is managed (NDIS budgets only).
export const PLAN_MANAGEMENT: [string, string][] = [
  ["ndia", "NDIA-managed"],
  ["plan", "Plan-managed"],
  ["self", "Self-managed"],
];

// cmeprojects (update 124): what an Allied Health practitioner can be given.
export const PRACTITIONER_SECTIONS: [string, string][] = [
  ["details", "Client details (DOB, communication needs)"],
  ["alerts", "Alerts"],
  ["care_plan", "Care plan and support instructions"],
  ["documents", "Documents marked “Share with practitioners”"],
  ["notes", "Other practitioners' notes"],
];

// cmeprojects: shared with server pages (a server page can't use lists from a "use client" file).
export const CLIENT_STATUS: Record<string, string> = { pending: "To check", active: "Active", suspended: "Suspended", discharged: "Discharged" };
export const COMMS_CONTACT_WAYS: [string, string][] = [
  ["", "Not set"],
  ["phone", "Phone call"],
  ["sms", "Text message"],
  ["email", "Email"],
  ["in_person", "In person"],
  ["through_representative", "Through their representative"],
];

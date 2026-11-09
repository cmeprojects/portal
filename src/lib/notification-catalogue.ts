// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: every notification the portal sends, for the Notifications tab.
// Each can go to the bell, by email, or both (where the portal sends it that way).
// The setting `notify.channels` stores only what's been changed; anything not
// listed is on. The database checks the same setting before sending.

export type Channel = "bell" | "email";
export type NotificationDef = { code: string; label: string; channels: Channel[] };
// feature: the switch the group follows (null: always available).
export type NotificationGroup = { key: string; label: string; feature: string | null; items: NotificationDef[] };

const both: Channel[] = ["bell", "email"];

export const NOTIFICATION_GROUPS: NotificationGroup[] = [
  {
    key: "tasks",
    label: "Tasks",
    feature: null,
    items: [
      { code: "task_assigned", label: "A task is given to someone", channels: both },
      { code: "helper_added", label: "Someone is added as a helper", channels: both },
      { code: "task_created_manager", label: "New task in a register a manager looks after", channels: ["email"] },
      { code: "task_reminder", label: "Reminder before a task is due", channels: both },
      { code: "task_due_today", label: "A task is due today", channels: both },
      { code: "task_overdue", label: "A task is overdue", channels: both },
      { code: "task_escalated", label: "A task is escalated", channels: both },
      { code: "overdue_summary", label: "Daily summary of overdue work (managers)", channels: ["email"] },
      { code: "approval_needed", label: "A task is waiting for approval", channels: both },
      { code: "sent_back", label: "A task is sent back", channels: both },
      { code: "task_reassigned", label: "A task is reassigned", channels: both },
    ],
  },
  {
    key: "requests",
    label: "My requests",
    feature: "hr_requests",
    items: [
      { code: "request_submitted", label: "A request is waiting for an approver", channels: both },
      { code: "request_partner", label: "A colleague asks to swap a shift", channels: both },
      { code: "request_decided", label: "A request is approved, declined or needs more information", channels: both },
      { code: "request_escalated", label: "A request nobody acted on is escalated", channels: both },
    ],
  },
  {
    key: "people",
    label: "People",
    feature: null,
    items: [
      { code: "role_changed", label: "Your role has changed", channels: ["bell"] },
      { code: "joined", label: "A new person has joined", channels: both },
      { code: "people_request", label: "A role or team change was approved or declined", channels: ["bell"] },
    ],
  },
  {
    key: "compliance",
    label: "Compliance and onboarding",
    feature: "compliance",
    items: [
      { code: "onboarding_item", label: "Something new to read, complete or upload", channels: both },
      { code: "upload_submitted", label: "An upload is waiting to be checked", channels: both },
      { code: "upload_rejected", label: "An upload was sent back", channels: both },
      { code: "uploaded_for_you", label: "A document was uploaded for you", channels: both },
      { code: "document_expiring", label: "A document expires soon", channels: both },
      { code: "document_expired", label: "A document has expired", channels: both },
      { code: "onboarded", label: "Someone finished onboarding", channels: both },
    ],
  },
  {
    key: "forms",
    label: "Forms",
    feature: "forms",
    items: [
      { code: "form_sent", label: "A form is sent to fill in", channels: both },
      { code: "form_reply", label: "A form has a new reply", channels: both },
      { code: "form_question", label: "A question about a form", channels: both },
    ],
  },
  {
    key: "cars",
    label: "Cars",
    feature: "vehicles",
    items: [
      { code: "car_still_out", label: "A car is still out", channels: both },
      { code: "car_not_returned", label: "A car wasn't returned overnight", channels: both },
      { code: "car_returned_for_you", label: "A car was returned for you", channels: both },
      { code: "car_weekly", label: "Weekly car report", channels: both },
      { code: "car_rego", label: "A car's registration is due", channels: both },
      { code: "car_service", label: "A car's service is due", channels: both },
    ],
  },
  {
    key: "assistant",
    label: "Website and enquiries",
    feature: "assistant",
    items: [{ code: "website_enquiry", label: "A new enquiry from the website", channels: both }],
  },
  {
    key: "built",
    label: "Built features",
    feature: null,
    items: [{ code: "feature_alert", label: "An alert from a built feature (like a missed target)", channels: both }],
  },
];

export type ChannelMap = Record<string, Partial<Record<Channel, boolean>>>;

export function asChannelMap(v: unknown): ChannelMap {
  return v && typeof v === "object" && !Array.isArray(v) ? (v as ChannelMap) : {};
}

// Is this notification on for this channel? (Anything not set is on.)
export function channelOn(map: ChannelMap, code: string, channel: Channel): boolean {
  return map[code]?.[channel] !== false;
}

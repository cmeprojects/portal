// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: My requests, shared by the server and the browser.
export type RequestStatus = "pending" | "info_needed" | "approved" | "declined" | "withdrawn";

export const REQUEST_TYPES: { key: string; label: string; feature: string; hint: string }[] = [
  { key: "leave", label: "Leave", feature: "hr_req_leave", hint: "Annual, personal/carer's, unpaid, long service, compassionate or other leave." },
  { key: "swap", label: "Shift swap", feature: "hr_req_swap", hint: "Swap a shift with a colleague. They accept first, then it goes for approval." },
  { key: "shift", label: "Shift change", feature: "hr_req_shift", hint: "Ask to change one of your shifts." },
  { key: "availability", label: "Availability change", feature: "hr_req_availability", hint: "Change the days and times you can usually work." },
  { key: "timesheet", label: "Timesheet correction", feature: "hr_req_timesheet", hint: "Fix the times on a timesheet." },
  { key: "hr", label: "HR or employment enquiry", feature: "hr_req_hr", hint: "Questions about pay, contracts or your employment." },
  { key: "other", label: "Other request", feature: "hr_req_other", hint: "Anything else." },
];
export const TYPE_LABEL: Record<string, string> = Object.fromEntries(REQUEST_TYPES.map((t) => [t.key, t.label]));

export const LEAVE_TYPES: [string, string][] = [
  ["annual", "Annual leave"],
  ["personal", "Personal/carer's leave"],
  ["unpaid", "Unpaid leave"],
  ["long_service", "Long service leave"],
  ["compassionate", "Compassionate leave"],
  ["other", "Other leave"],
];
export const LEAVE_LABEL: Record<string, string> = Object.fromEntries(LEAVE_TYPES);

export const REQUEST_STATUS: Record<RequestStatus, { label: string; cls: string }> = {
  pending: { label: "Pending", cls: "bg-warn-soft text-warn" },
  info_needed: { label: "More info needed", cls: "bg-brand-soft text-brand" },
  approved: { label: "Approved", cls: "bg-good-soft text-good" },
  declined: { label: "Declined", cls: "bg-danger-soft text-danger" },
  withdrawn: { label: "Withdrawn", cls: "bg-page text-muted ring-1 ring-line ring-inset" },
};

export const EVENT_LABEL: Record<string, string> = {
  submitted: "sent the request",
  comment: "commented",
  info_requested: "asked for more information",
  approved_first: "gave the first approval",
  approved: "approved it",
  declined: "declined it",
  withdrawn: "withdrew it",
  partner_accepted: "accepted the swap",
  partner_declined: "declined the swap",
  escalated: "It was escalated",
};

export const refOf = (n: number) => `REQ-${String(n).padStart(4, "0")}`;

// Who can be chosen as an approver (roles; "team_leader" means the person's own team leader).
export const APPROVER_ROLES: [string, string][] = [
  ["team_leader", "Their team leader"],
  ["staff_admin", "Staff admins"],
  ["manager", "Managers"],
];

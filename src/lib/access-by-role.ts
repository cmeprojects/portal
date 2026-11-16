// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects (QA-007, decision D-040): modules in the catalogue whose access
// isn't read from the Access page. Their pages decide access by role (or by a
// settings area), so a grant here would look like it works but do nothing.
// The Access page shows them without a switch, and the save action refuses
// new or changed grants for them. Existing grants are kept exactly as they
// are. The permission engine, database and RLS are unchanged. Remove an id
// here only when its module really follows the Access page.
export type Unsupported = { kind: "role" | "unavailable"; badge: string; note: string };

const ROLE_NOTE = "can't be given or removed here.";

export const UNSUPPORTED_DELEGATION: Record<string, Unsupported> = {
  "ops.tasks": {
    kind: "role",
    badge: "Set by role",
    note: `Who sees and changes tasks follows their role (managers see every team's tasks; team leaders their team's; staff their own). It ${ROLE_NOTE}`,
  },
  "people.staff": { kind: "role", badge: "Set by role", note: `Managers, staff admins and the system admin manage staff through their role. It ${ROLE_NOTE}` },
  "people.teams": { kind: "role", badge: "Set by role", note: `Managers, staff admins and the system admin manage teams through their role. It ${ROLE_NOTE}` },
  "clients.list": { kind: "role", badge: "Set by role", note: `Managers, staff admins and the system admin manage clients through their role. It ${ROLE_NOTE}` },
  "hr.requests": { kind: "role", badge: "Set by role", note: `Managers, staff admins and team leaders see staff requests through their role (who approves follows Request approvals). It ${ROLE_NOTE}` },
  "workflows.sla": {
    kind: "unavailable",
    badge: "Not available",
    note: "Can't be given here. Managers and the system admin have it; a staff admin gets it with the Tasks settings area (Settings areas, further down).",
  },
  "workflows.request_rules": {
    kind: "unavailable",
    badge: "Not available",
    note: "Can't be given here. The system admin has it; a manager or staff admin gets it with the HR settings area (Settings areas, further down).",
  },
};

export const unsupportedDelegation = (id: string): Unsupported | undefined => UNSUPPORTED_DELEGATION[id];

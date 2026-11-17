// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects (QA-007, decision D-040): modules in the catalogue whose access
// isn't read from the Access page. Their pages decide access by role (or by a
// settings area), so a grant here would look like it works but do nothing.
// The Access page shows them without a switch, and the save action refuses
// new or changed grants for them. Existing grants are kept exactly as they
// are. The permission engine, database and RLS are unchanged. Remove an id
// here only when its module really follows the Access page.
export type Unsupported = { kind: "role" | "unavailable"; badge: string; note: string };

// cmeprojects (update 107): empty. Every part now follows the Access page; kept
// for any future part that can't be given yet.
export const UNSUPPORTED_DELEGATION: Record<string, Unsupported> = {};

export const unsupportedDelegation = (id: string): Unsupported | undefined => UNSUPPORTED_DELEGATION[id];

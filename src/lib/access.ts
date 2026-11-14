// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects Phase 2: the three kinds of access to staff records. Ordinary
// profile access never includes the sensitive ones. The database
// (access_grants, has_access) has the final say.
export const ACCESS_AREAS = ["staff_details", "payroll_tax", "identity_docs"] as const;
export type AccessArea = (typeof ACCESS_AREAS)[number];

export const ACCESS_LABEL: Record<AccessArea, string> = {
  staff_details: "Staff details",
  payroll_tax: "Payroll and tax",
  identity_docs: "Identity and work rights",
};

export const ACCESS_HINT: Record<AccessArea, string> = {
  staff_details: "Change staff names, contact and employment details, and business cards.",
  payroll_tax: "Bank, super and tax file number records. Revealing a TFN needs its own tick.",
  identity_docs: "Citizenship, residency, visa details and documents, and VEVO checks.",
};

export const isAccessArea = (v: unknown): v is AccessArea => typeof v === "string" && (ACCESS_AREAS as readonly string[]).includes(v);

export type Grant = {
  id: string;
  area: AccessArea;
  user_id: string;
  scope: "all" | "teams" | "people";
  scope_ids: string[];
  can_pass_on: boolean;
  can_reveal_tfn: boolean;
  expires_at: string | null;
  parent_id: string | null;
  granted_by: string | null;
  note: string;
  created_at: string;
  revoked_at: string | null;
  revoked_by: string | null;
};

// The current time, for working out whether a grant has ended (server pages).
export const nowMs = (): number => Date.now();

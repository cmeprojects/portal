// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects Phase 3: bank, super and work-rights records. The database
// (RLS + has_access) decides who sees them; these are the shared checks and
// labels. Format checks only: they don't prove an account or fund is theirs.

export type Bank = { user_id: string; account_name: string; bsb: string; account_number: string; verified_at: string | null; verified_by: string | null; updated_at: string };
export type Super = {
  user_id: string;
  fund_name: string;
  fund_abn: string;
  usi: string;
  member_number: string;
  choice_doc: string;
  choice_name: string;
  verified_at: string | null;
  verified_by: string | null;
  updated_at: string;
};
export type WorkRights = {
  user_id: string;
  status: "" | "citizen" | "permanent_resident" | "nz_citizen" | "visa";
  visa_subclass: string;
  visa_conditions: string;
  visa_expiry: string | null;
  vevo_checked_on: string | null;
  visa_doc: string;
  visa_doc_name: string;
  vevo_doc: string;
  vevo_doc_name: string;
  verified_at: string | null;
  verified_by: string | null;
  updated_at: string;
};

export const RECORDS_BUCKET = "staff-records";

export const WORK_STATUS: Record<Exclude<WorkRights["status"], "">, string> = {
  citizen: "Australian citizen",
  permanent_resident: "Permanent resident",
  nz_citizen: "New Zealand citizen",
  visa: "Visa holder",
};

// BSB as NNN-NNN.
export function cleanBsb(raw: string): string | null {
  const d = raw.replace(/\D/g, "");
  if (!d) return "";
  return d.length === 6 ? `${d.slice(0, 3)}-${d.slice(3)}` : null;
}

// Account number: 5 to 9 digits.
export function cleanAccount(raw: string): string | null {
  const d = raw.replace(/[\s-]/g, "");
  if (!d) return "";
  return /^\d{5,9}$/.test(d) ? d : null;
}

// ABN: 11 digits with the ATO check (weights 10,1,3,...,19; first digit less one; sum divisible by 89).
export function cleanAbn(raw: string): string | null {
  const d = raw.replace(/\s/g, "");
  if (!d) return "";
  if (!/^\d{11}$/.test(d)) return null;
  const w = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
  const sum = d.split("").reduce((a, c, i) => a + (Number(c) - (i === 0 ? 1 : 0)) * w[i], 0);
  return sum % 89 === 0 ? d : null;
}

// USI: letters and numbers, up to 20.
export function cleanUsi(raw: string): string | null {
  const d = raw.trim().toUpperCase();
  if (!d) return "";
  return /^[A-Z0-9]{3,20}$/.test(d) ? d : null;
}

// Last three digits only.
export function maskAccount(n: string): string {
  return n ? `•••• ${n.slice(-3)}` : "";
}

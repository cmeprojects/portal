// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects Phase 4: employment contracts. The database decides who sees
// and changes what (RLS + guard_contract); these are shared labels.

export type ContractStatus = "draft" | "awaiting_employee" | "awaiting_employer" | "fully_signed" | "cancelled" | "expired" | "superseded";

export type Contract = {
  id: string;
  user_id: string;
  title: string;
  body: string;
  version: number;
  supersedes: string | null;
  status: ContractStatus;
  sign_by: string | null;
  content_hash: string;
  sent_at: string | null;
  sent_by: string | null;
  signed_pdf_path: string;
  signed_pdf_hash: string;
  completed_at: string | null;
  created_by: string | null;
  created_at: string;
  // Logo and letterhead on the signed copy (update 66; on by default).
  letterhead?: boolean;
};

export type Signature = {
  id: number;
  contract_id: string;
  party: "employee" | "employer";
  signer_id: string;
  signed_name: string;
  signature_path: string;
  consent_text: string;
  content_hash: string;
  identity_check: "password" | "authenticator";
  ip: string;
  user_agent: string;
  signed_at: string;
};

export const CONTRACT_STATUS: Record<ContractStatus, { label: string; cls: string }> = {
  draft: { label: "Draft", cls: "bg-page text-muted ring-1 ring-line ring-inset" },
  awaiting_employee: { label: "Awaiting employee signature", cls: "bg-warn-soft text-warn" },
  awaiting_employer: { label: "Awaiting employer signature", cls: "bg-brand-soft text-brand" },
  fully_signed: { label: "Fully signed", cls: "bg-good-soft text-good" },
  cancelled: { label: "Cancelled", cls: "bg-page text-muted ring-1 ring-line ring-inset" },
  expired: { label: "Expired", cls: "bg-danger-soft text-danger" },
  superseded: { label: "Superseded", cls: "bg-page text-muted ring-1 ring-line ring-inset" },
};

export const CONTRACTS_BUCKET = "contracts";

// The exact consent wording; it's stored with every signature.
export const CONSENT_TEXT =
  "I have read this document. I agree to sign it electronically, and that my electronic signature has the same effect as signing on paper. I agree to receive the signed copy electronically.";

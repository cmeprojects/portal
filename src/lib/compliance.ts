// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";

// "form": a form made in Forms, filled in as part of Compliance.
export type ItemKind = "read" | "training" | "upload" | "form" | "agreement";

export type ComplianceItem = {
  id: string;
  kind: ItemKind;
  title: string;
  description: string;
  body: string;
  link_url: string;
  file_path: string | null;
  file_name: string | null;
  version: number;
  needs_expiry: boolean;
  active: boolean;
  applies_roles: Role[];
  applies_teams: string[];
  sort_order: number;
  form_id?: string | null;
  // cmeprojects (update 58)
  category?: string;
  before_work?: boolean;
  certificate?: "none" | "optional" | "required";
  needs_issue_date?: boolean;
  needs_number?: boolean;
  applies_titles?: string[];
  // cmeprojects Phase 4: only these people (empty: everyone the other choices cover).
  applies_people?: string[];
};

export const ITEM_COLUMNS =
  "id, kind, title, description, body, link_url, file_path, file_name, version, needs_expiry, active, applies_roles, applies_teams, sort_order";

export type ItemState = "todo" | "update" | "done" | "submitted" | "accepted" | "rejected" | "replace_requested" | "expiring" | "expired";

export type StatusRow = {
  item_id: string;
  kind: ItemKind;
  title: string;
  state: ItemState;
  record_id: number | null;
  expires_on: string | null;
  note: string;
  // cmeprojects (update 58)
  before_work?: boolean;
  category?: string;
  needs_check?: boolean;
};

export const KIND_LABELS: Record<ItemKind, string> = {
  read: "Read and confirm",
  training: "Trainings",
  upload: "Documents to upload",
  form: "Forms to fill in",
  agreement: "Employment agreement",
};

export const KIND_TAB: Record<ItemKind, string> = { read: "Documents to read", training: "Trainings", upload: "Uploads", form: "Forms", agreement: "Agreements" };

// Done, or done enough (uploaded and waiting to be checked, or expiring soon).
export const isDone = (s: ItemState) => s === "done" || s === "submitted" || s === "accepted" || s === "expiring";

export const STATE_LABELS: Record<ItemState, string> = {
  todo: "To do",
  update: "Updated: confirm again",
  done: "Done",
  submitted: "Uploaded, being checked",
  accepted: "Checked",
  rejected: "Upload again",
  replace_requested: "New copy needed",
  expiring: "Expires soon",
  expired: "Expired",
};

export const STATE_TONE: Record<ItemState, "good" | "warn" | "grey" | "soft"> = {
  todo: "grey",
  update: "warn",
  done: "good",
  submitted: "soft",
  accepted: "good",
  rejected: "warn",
  replace_requested: "warn",
  expiring: "warn",
  expired: "warn",
};

export const LIBRARY_BUCKET = "compliance-library";
export const FILES_BUCKET = "compliance-files";

// A safe file name for storage: letters, numbers, dots and dashes.
export function safeFileName(name: string): string {
  const clean = name.normalize("NFKD").replace(/[^\w.-]+/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "");
  return (clean || "file").slice(-80);
}

// Badges for an item: the upload's own status, plus "Expiring" or "Expired"
// beside it (so a checked document about to expire shows both).
export function stateBadges(state: ItemState, recordStatus?: string | null): { label: string; tone: "good" | "warn" | "grey" | "soft" }[] {
  if (state === "expired") return [{ label: "Expired", tone: "warn" }];
  if (state === "expiring") {
    const base =
      recordStatus === "accepted"
        ? [{ label: "Checked", tone: "good" as const }]
        : recordStatus === "submitted"
          ? [{ label: "Uploaded, being checked", tone: "soft" as const }]
          : [];
    return [...base, { label: "Expiring", tone: "warn" }];
  }
  return [{ label: STATE_LABELS[state], tone: STATE_TONE[state] }];
}

// cmeprojects: document categories (update 58).
export const CATEGORY_LABELS: Record<string, string> = {
  qualification: "Qualification",
  certificate: "Certificate",
  screening: "Screening check",
  licence: "Licence",
  insurance: "Insurance",
  identity: "Identity",
  other: "Other",
};

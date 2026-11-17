// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects (HR block): lists shared by server pages and browser forms.
export const LEAVING_REASONS: [string, string][] = [
  ["resigned", "Resigned"],
  ["contract_ended", "Contract ended"],
  ["retired", "Retired"],
  ["redundancy", "Redundancy"],
  ["dismissed", "Dismissed"],
  ["other", "Other"],
];

// cmeprojects (update 121): performance and development reviews.
export const REVIEW_KINDS: [string, string][] = [
  ["probation", "Probation review"],
  ["annual", "Annual review"],
  ["check_in", "Check-in"],
];
export const REVIEW_OUTCOMES: [string, string][] = [
  ["", "—"],
  ["passed", "Probation passed"],
  ["extended", "Probation extended"],
  ["not_passed", "Probation not passed"],
  ["on_track", "On track"],
  ["needs_support", "Needs support"],
];

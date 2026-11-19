// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (update 150): SIL house words shared by the screens.
export const HOUSE_KINDS: [string, string][] = [
  ["sil", "SIL (Supported Independent Living)"],
  ["sda", "SDA (Specialist Disability Accommodation)"],
  ["respite", "Respite house"],
  ["sta", "Short-term accommodation (STA)"],
  ["other", "Other"],
];
export const houseKind = (k: string) => HOUSE_KINDS.find(([v]) => v === k)?.[1].replace(/ \(.*\)$/, "") ?? k;

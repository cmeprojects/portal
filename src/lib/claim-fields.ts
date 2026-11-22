// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (update 163): what each column of an official claim template is
// filled with. The columns themselves come from the official file (kept exactly,
// in order); the nominee chooses what goes in each one before verifying it.
// A mapping value is a field key below, or "=text" for fixed text, or "" (blank).
export const CLAIM_FIELDS: [string, string][] = [
  ["", "Leave blank"],
  ["provider_registration", "Our NDIS registration number"],
  ["provider_abn", "Our ABN"],
  ["sah_provider_id", "Our Support at Home provider ID"],
  ["sah_service_branch", "Our Support at Home service or branch"],
  ["ndis_number", "Participant's NDIS number"],
  ["aged_care_id", "Care recipient's aged care ID"],
  ["client_ref", "Client reference"],
  ["client_name", "Client name"],
  ["date_from", "Service date (from)"],
  ["date_to", "Service date (to)"],
  ["support_item", "NDIS support item number"],
  ["service_type", "Service (rate band, or Care management)"],
  ["sah_category", "Support at Home category"],
  ["claim_reference", "Our claim reference (unique per line)"],
  ["quantity", "Quantity"],
  ["hours", "Hours (hourly items only)"],
  ["unit_price", "Unit price"],
  ["amount", "Amount (full service value)"],
  ["gst_code", "GST code (portal: gst_free, taxable, input_taxed)"],
  ["ndis_gst_code", "NDIS GST code (P1 taxable, P2 GST free, P5 out of scope; check the NDIA guide)"],
  ["cancellation", "Cancellation flag (CANC for late cancellations)"],
];

// A first guess from the column's name; the nominee checks every one before verifying.
export function guessField(header: string): string {
  const h = header.toLowerCase().replace(/[^a-z]/g, "");
  const pairs: [RegExp, string][] = [
    [/registrationnumber|providerregistration/, "provider_registration"],
    [/abn/, "provider_abn"],
    [/ndisnumber|participantnumber/, "ndis_number"],
    [/agedcareid|carerecipientid|recipientid/, "aged_care_id"],
    [/providerid/, "sah_provider_id"],
    [/deliveredto|dateto|enddate/, "date_to"],
    [/deliveredfrom|datefrom|startdate|servicedate/, "date_from"],
    [/supportnumber|supportitem|itemnumber/, "support_item"],
    [/claimreference|reference/, "claim_reference"],
    [/servicetype|service/, "service_type"],
    [/quantity|units/, "quantity"],
    [/hours/, "hours"],
    [/unitprice|price|rate/, "unit_price"],
    [/gstcode|gst/, "ndis_gst_code"],
    [/amount|total/, "amount"],
    [/cancel/, "cancellation"],
  ];
  return pairs.find(([re]) => re.test(h))?.[1] ?? "";
}

// The first row of an uploaded CSV, exactly as written (quotes removed).
export function headerRow(text: string): string[] {
  const line = text.replace(/^﻿/, "").split(/\r?\n/)[0] ?? "";
  const out: string[] = [];
  let cur = "";
  let q = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) {
      if (c === '"' && line[i + 1] === '"') { cur += '"'; i++; }
      else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ",") { out.push(cur); cur = ""; }
    else cur += c;
  }
  out.push(cur);
  return out.map((s) => s.trim()).filter((s, i, a) => s !== "" || i < a.length - 1);
}

// All rows of a CSV (for the NDIS catalogue import).
export function csvRows(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let cur = "";
  let q = false;
  const s = text.replace(/^﻿/, "");
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) {
      if (c === '"' && s[i + 1] === '"') { cur += '"'; i++; }
      else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ",") { row.push(cur); cur = ""; }
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && s[i + 1] === "\n") i++;
      row.push(cur); cur = "";
      if (row.some((x) => x.trim() !== "")) rows.push(row);
      row = [];
    } else cur += c;
  }
  row.push(cur);
  if (row.some((x) => x.trim() !== "")) rows.push(row);
  return rows;
}

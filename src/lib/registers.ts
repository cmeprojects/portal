// Staff Portal · © cmeproject. All rights reserved.

export const FIELD_TYPES = [
  "text",
  "long_text",
  "number",
  "money",
  "date",
  "choice",
  "multi_choice",
  "yes_no",
  "person",
  "asset",
] as const;
export type FieldType = (typeof FIELD_TYPES)[number];

export const FIELD_TYPE_LABELS: Record<FieldType, string> = {
  text: "Short text",
  long_text: "Long text",
  number: "Number",
  money: "Money ($)",
  date: "Date",
  choice: "Dropdown (pick one)",
  multi_choice: "Checkboxes (pick several)",
  yes_no: "Yes / No",
  person: "Staff member",
  asset: "Link to an asset",
};

export type RegistryField = {
  id: string;
  registry_id: string;
  key: string;
  label: string;
  type: FieldType;
  required: boolean;
  options: string[];
  help: string;
  sort_order: number;
  active: boolean;
};

export type Registry = {
  id: string;
  name: string;
  description: string;
  kind: "tasks" | "records";
  prefix: string;
  requires_approval: boolean;
  active: boolean;
  is_default: boolean;
  title_label: string;
  description_label: string;
  show_due_date: boolean;
  show_review_date: boolean;
  review_label: string;
  show_outcome: boolean;
  outcome_label: string;
  sort_order: number;
};

export const REGISTRY_COLUMNS =
  "id, name, description, kind, prefix, requires_approval, active, is_default, title_label, description_label, show_due_date, show_review_date, review_label, show_outcome, outcome_label, sort_order";

export const FIELD_COLUMNS = "id, registry_id, key, label, type, required, options, help, sort_order, active";

export type Details = Record<string, unknown>;

// "RSK-0001"
export function refLabel(prefix: string | null | undefined, n: number): string {
  return `${prefix ?? "T"}-${String(n).padStart(4, "0")}`;
}

// Turns a label into a field key: "Person declaring" -> "person_declaring".
export function keyFromLabel(label: string): string {
  const key = label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 40);
  return /^[a-z]/.test(key) ? key : `f_${key}`.slice(0, 40);
}

// Reads custom field values out of a submitted form (inputs are named f_<key>).
export function detailsFromForm(form: FormData, fields: RegistryField[]): Details {
  const out: Details = {};
  for (const f of fields) {
    if (!f.active) continue;
    const name = `f_${f.key}`;
    if (f.type === "multi_choice") {
      const values = form.getAll(name).map(String).filter(Boolean);
      if (values.length) out[f.key] = values;
      continue;
    }
    const raw = form.get(name);
    const value = typeof raw === "string" ? raw.trim() : "";
    if (!value) continue;
    switch (f.type) {
      case "number":
      case "money": {
        const n = Number(value.replace(/[$,\s]/g, ""));
        out[f.key] = Number.isFinite(n) ? n : value;
        break;
      }
      case "yes_no":
        out[f.key] = value === "yes";
        break;
      default:
        out[f.key] = value;
    }
  }
  return out;
}

const MONEY = new Intl.NumberFormat("en-AU", { style: "currency", currency: "AUD" });
const DATE = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" });

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return "";
  const d = new Date(`${iso.slice(0, 10)}T00:00:00Z`);
  return Number.isNaN(d.getTime()) ? iso : DATE.format(d);
}

// Shows a stored value as text. People and assets are looked up by id.
export function formatValue(
  field: Pick<RegistryField, "type">,
  value: unknown,
  lookup: { person?: (id: string) => string; asset?: (id: string) => string } = {},
): string {
  if (value === null || value === undefined || value === "") return "";
  switch (field.type) {
    case "money":
      return typeof value === "number" ? MONEY.format(value) : String(value);
    case "number":
      return typeof value === "number" ? value.toLocaleString("en-AU") : String(value);
    case "date":
      return formatDate(String(value));
    case "yes_no":
      return value === true ? "Yes" : value === false ? "No" : "";
    case "multi_choice":
      return Array.isArray(value) ? value.join(", ") : String(value);
    case "person":
      return lookup.person ? lookup.person(String(value)) : String(value);
    case "asset":
      return lookup.asset ? lookup.asset(String(value)) : String(value);
    default:
      return String(value);
  }
}

// Suggested current value: straight-line from purchase value over its useful
// life (5 years if not given), never below zero.
export function estimateValue(purchaseValue: number, purchaseDate: string, usefulLifeYears: number | null, today: string): number {
  const life = usefulLifeYears && usefulLifeYears > 0 ? usefulLifeYears : 5;
  const ageYears = (Date.parse(`${today}T00:00:00Z`) - Date.parse(`${purchaseDate}T00:00:00Z`)) / (365.25 * 24 * 3600 * 1000);
  const remaining = Math.max(0, 1 - Math.max(0, ageYears) / life);
  return Math.round(purchaseValue * remaining * 100) / 100;
}

// Makes a CSV file that opens cleanly in Excel (with a byte-order mark).
export function toCsv(rows: (string | number | null | undefined)[][]): string {
  const cell = (v: string | number | null | undefined) => {
    const s = v === null || v === undefined ? "" : String(v);
    // Stop spreadsheet formulas sneaking in from typed text.
    const safe = /^[=+\-@]/.test(s) ? `'${s}` : s;
    return /[",\n\r]/.test(safe) ? `"${safe.replace(/"/g, '""')}"` : safe;
  };
  return "﻿" + rows.map((r) => r.map(cell).join(",")).join("\r\n") + "\r\n";
}

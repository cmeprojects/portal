// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";

// Feature builder (cmeprojects): shared by the builder, the live preview and
// the staff form.

export type FieldType = "text" | "long" | "number" | "choice" | "multi" | "yesno" | "date" | "time" | "client" | "staff" | "photo";

export const FIELD_TYPES: Record<FieldType, { label: string; hint: string }> = {
  client: { label: "Client", hint: "Pick from your client list" },
  choice: { label: "Drop-down", hint: "One answer from a list" },
  multi: { label: "Tick boxes", hint: "Several answers from a list" },
  number: { label: "Number", hint: "With a unit, limits and quick buttons" },
  yesno: { label: "Yes / no", hint: "Two buttons" },
  text: { label: "Short text", hint: "One line" },
  long: { label: "Long text", hint: "Notes" },
  date: { label: "Date", hint: "A calendar date" },
  time: { label: "Time", hint: "A time of day" },
  staff: { label: "Staff member", hint: "Pick a person" },
  photo: { label: "Photo or file", hint: "Taken on the phone, made smaller" },
};

export type FeatureField = {
  id: string;
  label: string;
  type: FieldType;
  required: boolean;
  help: string;
  unit: string;
  min_value: number | null;
  max_value: number | null;
  options: string[];
  allow_other: boolean;
  quick: number[];
  sort_order: number;
  archived: boolean;
};

export type Feature = {
  id: string;
  slug: string;
  name: string;
  menu_label: string;
  description: string;
  status: "draft" | "published";
  enabled: boolean;
  fill_roles: Role[];
  see_roles: Role[];
  undo_minutes: number;
  record_team: boolean;
  total_field: string | null;
  group_field: string | null;
  default_target: number | null;
};

export const FEATURE_COLUMNS =
  "id, slug, name, menu_label, description, status, enabled, fill_roles, see_roles, undo_minutes, record_team, total_field, group_field, default_target";
export const FIELD_COLUMNS = "id, label, type, required, help, unit, min_value, max_value, options, allow_other, quick, sort_order, archived";

export type Option = { id: string; name: string };

// What staff typed or picked, by field id.
export type Answers = Record<string, string | string[]>;

// Quick buttons for a number: the ones set in the builder, or sensible ones for millilitres.
export function quickValues(f: Pick<FeatureField, "quick" | "unit">): number[] {
  if (f.quick.length) return f.quick;
  return f.unit.trim().toLowerCase() === "ml" ? [50, 100, 150, 200, 250] : [];
}

export const newFieldId = () => `new-${Math.random().toString(36).slice(2, 10)}`;

export function blankField(type: FieldType, sort: number): FeatureField {
  return {
    id: newFieldId(),
    label: FIELD_TYPES[type].label,
    type,
    required: false,
    help: "",
    unit: "",
    min_value: null,
    max_value: null,
    options: type === "choice" || type === "multi" ? ["Option 1", "Option 2"] : [],
    allow_other: false,
    quick: [],
    sort_order: sort,
    archived: false,
  };
}

// A starting point: the Fluid intake chart from the preview.
export function fluidIntakeTemplate(): { fields: FeatureField[]; description: string } {
  const f = (type: FieldType, label: string, extra: Partial<FeatureField>, i: number): FeatureField => ({ ...blankField(type, i), label, ...extra });
  return {
    description: "Record every drink offered, so each client's daily total is clear.",
    fields: [
      f("client", "Client", { required: true }, 1),
      f("choice", "Drink", { required: true, options: ["Water", "Juice", "Tea / coffee", "Milk", "Soup"], allow_other: true }, 2),
      f("number", "Amount", { required: true, unit: "ml", min_value: 0, max_value: 2000 }, 3),
      f("choice", "Thickness", { options: ["Regular", "Mildly thick (IDDSI 2)", "Moderately thick (IDDSI 3)", "Extremely thick (IDDSI 4)"] }, 4),
      f("yesno", "Offered but refused", {}, 5),
      f("long", "Notes", {}, 6),
    ],
  };
}

export const slugify = (name: string) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40) || "feature";

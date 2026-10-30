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
  // A typed answer joins the list for everyone next time.
  add_typed: boolean;
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
  // What managers may change (the system admin always can).
  managers_fix: boolean;
  managers_targets: boolean;
  managers_options: boolean;
  // The Staff app: shown there or not, and its icon and colour.
  in_app: boolean;
  app_icon: string;
  app_colour: string;
};

export const FEATURE_COLUMNS =
  "id, slug, name, menu_label, description, status, enabled, fill_roles, see_roles, undo_minutes, record_team, total_field, group_field, default_target, managers_fix, managers_targets, managers_options, in_app, app_icon, app_colour";
export const FIELD_COLUMNS = "id, label, type, required, help, unit, min_value, max_value, options, allow_other, add_typed, quick, sort_order, archived";

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
    add_typed: false,
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
      f("choice", "Drink", { required: true, options: ["Water", "Juice", "Tea / coffee", "Milk", "Soup"], allow_other: true, add_typed: true }, 2),
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

// Icons a feature can have in the Staff app (24 × 24 line drawings).
export const APP_ICONS: Record<string, { label: string; path: string }> = {
  clipboard: { label: "Checklist", path: "M9 4h6v3H9zM6 5h3M15 5h3v15H6V5M9 11h6M9 15h4" },
  drop: { label: "Drop", path: "M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z" },
  cup: { label: "Cup", path: "M6 3h12l-1.5 18h-9zM7 9h10" },
  thermometer: { label: "Temperature", path: "M10 14V5a2 2 0 1 1 4 0v9a4 4 0 1 1-4 0zM12 9v6" },
  pulse: { label: "Health", path: "M3 12h4l2-5 4 10 2-5h6" },
  pill: { label: "Medication", path: "M7.5 16.5l9-9a3.5 3.5 0 0 0-5-5l-9 9a3.5 3.5 0 0 0 5 5zM7 7l5 5" },
  person: { label: "Person", path: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c1-4 4-6 8-6s7 2 8 6" },
  home: { label: "House", path: "M3 11l9-7 9 7M5 10v10h14V10M10 20v-6h4v6" },
  food: { label: "Meals", path: "M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10M16 21V3c-2 1-3 4-3 8h3" },
  note: { label: "Notes", path: "M5 4h14v16H5zM9 9h6M9 13h6M9 17h3" },
  alert: { label: "Incident", path: "M12 4l9 16H3zM12 10v4M12 17h.01" },
  star: { label: "Star", path: "M12 3l2.8 5.7 6.2.9-4.5 4.4 1 6.2L12 17.3 6.5 20.2l1-6.2L3 9.6l6.2-.9z" },
};
export const APP_COLOURS = ["#134f8e", "#1f8ab8", "#2f8f6a", "#c46a1b", "#8a4fb3", "#b3261e", "#0f2f57", "#5b6b80"];

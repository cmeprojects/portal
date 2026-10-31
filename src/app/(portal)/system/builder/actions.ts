// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { requireRole } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { isRole } from "@/lib/roles";
import { text, type FormState } from "@/lib/form";
import { APP_ICONS, FIELD_TYPES, fluidIntakeTemplate, slugify, type Feature, type FeatureField } from "@/lib/feature-types";

// Only the system admin builds features.
const requireBuilder = () => requireRole(["system_admin"]);

function refresh() {
  revalidatePath("/system/builder", "layout");
  revalidatePath("/f", "layout");
  revalidatePath("/", "layout");
}

export async function createFeature(_: FormState, form: FormData): Promise<FormState> {
  await requireBuilder();
  const name = text(form, "name").slice(0, 60);
  if (!name) return { error: "Give the feature a name, for example Fluid intake." };
  const supabase = await createClient();
  // A web address that isn't taken yet: fluid-intake, fluid-intake-2, …
  const base = slugify(name);
  const { data: taken } = await supabase.from("custom_features").select("slug").like("slug", `${base}%`);
  const used = new Set((taken ?? []).map((t) => t.slug));
  let slug = base;
  for (let n = 2; used.has(slug); n++) slug = `${base.slice(0, 36)}-${n}`;
  const template = text(form, "template") === "fluid" ? fluidIntakeTemplate() : null;
  const { data: feature, error } = await supabase
    .from("custom_features")
    .insert({
      slug,
      name,
      menu_label: name.slice(0, 30),
      description: template?.description ?? "",
      default_target: template ? 1500 : null,
      ...(template ? { app_icon: "drop", app_colour: "#1f8ab8" } : {}),
    })
    .select("id")
    .single();
  if (error || !feature) return { error: friendlyError(error) };
  if (template) {
    const { data: rows } = await supabase
      .from("custom_fields")
      .insert(
        template.fields.map((f) => ({
          feature_id: feature.id,
          label: f.label,
          type: f.type,
          required: f.required,
          unit: f.unit,
          min_value: f.min_value,
          max_value: f.max_value,
          options: f.options,
          allow_other: f.allow_other,
          add_typed: f.add_typed,
          sort_order: f.sort_order,
        })),
      )
      .select("id, label");
    const id = (label: string) => rows?.find((r) => r.label === label)?.id ?? null;
    await supabase.from("custom_features").update({ total_field: id("Amount"), group_field: id("Client") }).eq("id", feature.id);
  }
  refresh();
  redirect(`/system/builder/${feature.id}`);
}

type Draft = { feature: Omit<Feature, "id" | "slug" | "status" | "enabled">; fields: FeatureField[] };

// Saves the whole draft: the feature's details and its fields, in order.
// Removed fields that already have answers are hidden (archived), never deleted.
export async function saveFeature(featureId: string, draft: Draft): Promise<{ error?: string; message?: string; ids?: Record<string, string> }> {
  await requireBuilder();
  const f = draft.feature;
  if (!f.name.trim()) return { error: "Give the feature a name." };
  if (!f.menu_label.trim()) return { error: "Give it a menu label." };
  const fields = draft.fields.filter((x) => !x.archived);
  for (const x of fields) {
    if (!x.label.trim()) return { error: "Every field needs a question." };
    if (!(x.type in FIELD_TYPES)) return { error: `${x.label}: choose a type.` };
    if ((x.type === "choice" || x.type === "multi") && x.options.filter((o) => o.trim()).length === 0 && !x.allow_other) {
      return { error: `${x.label}: add at least one option.` };
    }
    if (x.min_value != null && x.max_value != null && x.min_value > x.max_value) return { error: `${x.label}: the smallest is bigger than the largest.` };
  }
  const supabase = await createClient();
  const { data: existing } = await supabase.from("custom_fields").select("id").eq("feature_id", featureId);
  const ids = new Map<string, string>();
  for (const [i, x] of fields.entries()) {
    const row = {
      label: x.label.trim().slice(0, 80),
      type: x.type,
      required: x.required,
      help: x.help.trim().slice(0, 200),
      unit: x.unit.trim().slice(0, 12),
      min_value: x.min_value,
      max_value: x.max_value,
      options: [...new Set(x.options.map((o) => o.trim()).filter(Boolean))].slice(0, 60),
      allow_other: x.allow_other,
      add_typed: x.allow_other && x.add_typed,
      quick: x.quick.filter((q) => Number.isFinite(q)).slice(0, 8),
      sort_order: i + 1,
      archived: false,
    };
    if (x.id.startsWith("new-")) {
      const { data, error } = await supabase.from("custom_fields").insert({ ...row, feature_id: featureId }).select("id").single();
      if (error || !data) return { error: friendlyError(error) };
      ids.set(x.id, data.id);
    } else {
      const { error } = await supabase.from("custom_fields").update(row).eq("id", x.id).eq("feature_id", featureId);
      if (error) return { error: friendlyError(error) };
      ids.set(x.id, x.id);
    }
  }
  // Fields taken off the form: delete if never answered, otherwise hide.
  for (const old of existing ?? []) {
    if ([...ids.values()].includes(old.id)) continue;
    const { data: gone } = await supabase.from("custom_fields").delete().eq("id", old.id).select("id");
    if (!gone?.length) await supabase.from("custom_fields").update({ archived: true }).eq("id", old.id);
  }
  const roles = (list: unknown[]) => list.map(String).filter(isRole).filter((r) => r !== "system_admin" && r !== "new_starter");
  const mapId = (id: string | null) => (id ? ids.get(id) ?? null : null);
  const update = {
      name: f.name.trim().slice(0, 60),
      menu_label: f.menu_label.trim().slice(0, 30),
      description: f.description.trim().slice(0, 300),
      fill_roles: roles(f.fill_roles),
      see_roles: roles(f.see_roles),
      undo_minutes: Math.max(0, Math.min(1440, Math.round(Number(f.undo_minutes) || 0))),
      record_team: f.record_team,
      total_field: mapId(f.total_field),
      group_field: mapId(f.group_field),
      default_target: f.default_target == null || Number.isNaN(Number(f.default_target)) ? null : Number(f.default_target),
      managers_fix: f.managers_fix,
      managers_targets: f.managers_targets,
      managers_options: f.managers_options,
      in_app: f.in_app,
      app_icon: f.app_icon in APP_ICONS ? f.app_icon : "clipboard",
      app_colour: /^#[0-9a-fA-F]{6}$/.test(f.app_colour) ? f.app_colour : "#134f8e",
      updated_at: new Date().toISOString(),
  };
  let { error } = await supabase.from("custom_features").update(update).eq("id", featureId);
  // Before live update 30 there are no Staff app columns yet: save the rest.
  if (error && /in_app|app_icon|app_colour/.test(error.message)) {
    const { in_app: _a, app_icon: _b, app_colour: _c, ...rest } = update;
    void _a;
    void _b;
    void _c;
    ({ error } = await supabase.from("custom_features").update(rest).eq("id", featureId));
  }
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Saved.", ids: Object.fromEntries(ids) };
}

export async function publishFeature(featureId: string): Promise<{ error?: string; message?: string }> {
  await requireBuilder();
  const supabase = await createClient();
  const { count } = await supabase.from("custom_fields").select("id", { count: "exact", head: true }).eq("feature_id", featureId).eq("archived", false);
  if (!count) return { error: "Add at least one field before publishing." };
  const { error } = await supabase.from("custom_features").update({ status: "published", published_at: new Date().toISOString() }).eq("id", featureId);
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Published. Staff can use it now." };
}

// In this company's package (premium add-on), or not.
export async function setFeatureIncluded(form: FormData) {
  await requireBuilder();
  const supabase = await createClient();
  await supabase.from("custom_features").update({ enabled: text(form, "enabled") === "true" }).eq("id", text(form, "id"));
  refresh();
}

export async function deleteDraft(form: FormData) {
  await requireBuilder();
  const supabase = await createClient();
  await supabase.from("custom_features").delete().eq("id", text(form, "id")).eq("status", "draft");
  refresh();
  redirect("/system/builder");
}

// ---------------------------------------------------------------------------
// Alerts: who's told when an entry matches, by bell and/or email
// ---------------------------------------------------------------------------

export type AlertDraft = {
  id: string;
  name: string;
  when_kind: "any" | "choice" | "above" | "below" | "total_over" | "total_met" | "total_under_by" | "no_entry_by";
  // Time-based alerts: the hour of the day to check (0 to 23).
  at_hour: number | null;
  field_id: string | null;
  match_text: string;
  limit_value: number | null;
  notify_roles: string[];
  notify_leader: boolean;
  notify_people: string[];
  by_bell: boolean;
  by_email: boolean;
  on_fix: boolean;
  message: string;
  active: boolean;
};

export async function saveAlert(featureId: string, a: AlertDraft): Promise<{ error?: string; message?: string; id?: string }> {
  await requireBuilder();
  if (!a.by_bell && !a.by_email) return { error: "Tick the bell, email, or both." };
  if (!a.notify_roles.length && !a.notify_leader && !a.notify_people.length) return { error: "Choose who's told." };
  if ((a.when_kind === "choice" || a.when_kind === "above" || a.when_kind === "below") && !a.field_id) return { error: "Choose the question it looks at." };
  if (a.when_kind === "choice" && !a.match_text.trim()) return { error: "Choose the answer that sets it off." };
  if ((a.when_kind === "above" || a.when_kind === "below") && (a.limit_value == null || Number.isNaN(a.limit_value))) return { error: "Enter the limit." };
  const timed = a.when_kind === "total_under_by" || a.when_kind === "no_entry_by";
  if (timed && (a.at_hour == null || a.at_hour < 0 || a.at_hour > 23)) return { error: "Choose the time to check." };
  const row = {
    feature_id: featureId,
    name: a.name.trim().slice(0, 80),
    when_kind: a.when_kind,
    field_id: a.when_kind === "choice" || a.when_kind === "above" || a.when_kind === "below" ? a.field_id : null,
    match_text: a.when_kind === "choice" ? a.match_text.trim().slice(0, 80) : "",
    limit_value: a.when_kind === "above" || a.when_kind === "below" ? a.limit_value : null,
    notify_roles: a.notify_roles.filter(isRole).filter((r) => r !== "system_admin" && r !== "new_starter"),
    notify_leader: !timed && a.notify_leader,
    notify_people: a.notify_people.filter((p) => /^[0-9a-f-]{36}$/.test(p)),
    by_bell: a.by_bell,
    by_email: a.by_email,
    on_fix: !timed && a.on_fix,
    at_hour: timed ? a.at_hour : null,
    message: a.message.trim().slice(0, 200),
    active: a.active,
  };
  const supabase = await createClient();
  const q = a.id.startsWith("new-")
    ? supabase.from("custom_alerts").insert(row).select("id").single()
    : supabase.from("custom_alerts").update(row).eq("id", a.id).eq("feature_id", featureId).select("id").single();
  const { data, error } = await q;
  if (error || !data) return { error: friendlyError(error) };
  revalidatePath("/system/builder", "layout");
  return { message: "Alert saved.", id: data.id };
}

export async function deleteAlert(id: string): Promise<{ error?: string; message?: string }> {
  await requireBuilder();
  const supabase = await createClient();
  const { error } = await supabase.from("custom_alerts").delete().eq("id", id);
  if (error) return { error: friendlyError(error) };
  revalidatePath("/system/builder", "layout");
  return { message: "Alert deleted." };
}

// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import type { Role } from "@/lib/roles";
import { FEATURE_COLUMNS, FIELD_COLUMNS, type Feature, type FeatureField, type Option } from "@/lib/feature-types";

// Features built with the Feature builder (cmeprojects).

const asField = (f: Record<string, unknown>): FeatureField => ({
  ...(f as unknown as FeatureField),
  min_value: f.min_value == null ? null : Number(f.min_value),
  max_value: f.max_value == null ? null : Number(f.max_value),
  options: Array.isArray(f.options) ? (f.options as string[]) : [],
  add_typed: Boolean(f.add_typed),
  quick: Array.isArray(f.quick) ? (f.quick as number[]).map(Number) : [],
});
const asFeature = (f: Record<string, unknown>): Feature => ({
  ...(f as unknown as Feature),
  default_target: f.default_target == null ? null : Number(f.default_target),
});

export async function loadFeature(by: { slug?: string; id?: string }): Promise<{ feature: Feature; fields: FeatureField[] } | null> {
  const supabase = await createClient();
  let q = supabase.from("custom_features").select(FEATURE_COLUMNS);
  q = by.id ? q.eq("id", by.id) : q.eq("slug", by.slug ?? "");
  const { data } = await q.maybeSingle();
  if (!data) return null;
  const { data: fields } = await supabase.from("custom_fields").select(FIELD_COLUMNS).eq("feature_id", data.id).order("sort_order");
  return { feature: asFeature(data), fields: (fields ?? []).map(asField) };
}

// What the form needs besides its fields: clients, staff, targets and who's filling it in.
export async function formContext(featureId: string, userId: string) {
  const supabase = await createClient();
  const [{ data: clients }, { data: staff }, { data: targets }, { data: me }, { data: teams }, timeZone] = await Promise.all([
    supabase.rpc("client_options"),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).neq("role", "system_admin").order("full_name"),
    supabase.from("custom_client_targets").select("client_id, target").eq("feature_id", featureId),
    supabase.from("profiles").select("full_name, email").eq("id", userId).maybeSingle(),
    supabase.from("team_members").select("teams(name)").eq("user_id", userId),
    getTimeZone(),
  ]);
  return {
    timeZone,
    clients: (clients ?? []) as Option[],
    staff: (staff ?? []).map((s) => ({ id: s.id, name: s.full_name || s.email })) as Option[],
    targets: Object.fromEntries((targets ?? []).map((t) => [t.client_id, Number(t.target)])) as Record<string, number>,
    me: {
      id: userId,
      name: me?.full_name || me?.email || "",
      teams: ((teams ?? []) as unknown as { teams: { name: string } | null }[]).map((t) => t.teams?.name).filter(Boolean).join(", "),
    },
  };
}

// Live features this person can fill in or look at, for the menu.
export const getMenuFeatures = cache(async (role: Role): Promise<{ slug: string; label: string }[]> => {
  if (role === "new_starter") return [];
  const supabase = await createClient();
  const { data } = await supabase
    .from("custom_features")
    .select("slug, menu_label, fill_roles, see_roles, status, enabled, sort_order, managers_fix, managers_targets, managers_options")
    .eq("status", "published")
    .eq("enabled", true)
    .order("sort_order")
    .order("menu_label");
  return (data ?? [])
    .filter(
      (f) =>
        role === "system_admin" ||
        (f.fill_roles as Role[]).includes(role) ||
        (f.see_roles as Role[]).includes(role) ||
        (role === "manager" && (f.managers_fix || f.managers_targets || f.managers_options)),
    )
    .map((f) => ({ slug: f.slug, label: f.menu_label }));
});

// Live features whose report this person sees (Reports → the feature's tab).
export const getReportFeatures = cache(async (role: Role): Promise<{ slug: string; label: string }[]> => {
  if (role === "new_starter") return [];
  const supabase = await createClient();
  const { data } = await supabase
    .from("custom_features")
    .select("slug, menu_label, see_roles, sort_order")
    .eq("status", "published")
    .eq("enabled", true)
    .order("sort_order")
    .order("menu_label");
  return (data ?? []).filter((f) => role === "system_admin" || (f.see_roles as Role[]).includes(role)).map((f) => ({ slug: f.slug, label: f.menu_label }));
});

// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { FIELD_COLUMNS, REGISTRY_COLUMNS, refLabel, type Registry, type RegistryField } from "@/lib/registers";
import { ROLE_LABELS, type Role } from "@/lib/roles";

export const getRegistries = cache(async (): Promise<Registry[]> => {
  const supabase = await createClient();
  const { data } = await supabase
    .from("registries")
    .select(REGISTRY_COLUMNS)
    .order("sort_order")
    .order("name")
    .returns<Registry[]>();
  return data ?? [];
});

export const getFields = cache(async (): Promise<RegistryField[]> => {
  const supabase = await createClient();
  const { data } = await supabase.from("registry_fields").select(FIELD_COLUMNS).order("sort_order").returns<RegistryField[]>();
  return (data ?? []).map((f) => ({
    ...f,
    options: Array.isArray(f.options) ? f.options : [],
    option_colors: f.option_colors && typeof f.option_colors === "object" ? f.option_colors : {},
  }));
});

export type PersonOption = { id: string; label: string; name: string; active: boolean; role: Role };

export const getPeople = cache(async (): Promise<PersonOption[]> => {
  const supabase = await createClient();
  const { data } = await supabase.from("profiles").select("id, full_name, email, role, active").order("full_name");
  return (data ?? []).map((p) => ({
    id: p.id,
    name: p.full_name || p.email,
    label: `${p.full_name || p.email} · ${ROLE_LABELS[p.role as Role]}`,
    active: p.active,
    role: p.role as Role,
  }));
});

export type AssetOption = { id: string; label: string; archived: boolean };

// Every record in every records register (used by "Link to an asset" fields).
export const getAssets = cache(async (): Promise<AssetOption[]> => {
  const supabase = await createClient();
  const { data } = await supabase
    .from("records")
    .select("id, ref_number, title, archived, registries(prefix)")
    .order("title");
  return (data ?? []).map((r) => {
    const reg = r.registries as unknown as { prefix: string } | null;
    return { id: r.id, label: `${refLabel(reg?.prefix, r.ref_number)} · ${r.title}`, archived: r.archived };
  });
});

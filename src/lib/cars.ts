// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { isRole, type Role } from "@/lib/roles";
import type { CarBoardRow, CarRules, CarScreen, MyTrip } from "@/lib/car-types";

// Car settings (System settings → Cars).
export const getCarRules = cache(async (): Promise<CarRules> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("key, value").like("key", "vehicles.%");
  const get = (k: string) => data?.find((r) => r.key === k)?.value;
  const roles = (k: string, fallback: Role[]) => {
    const v = get(k);
    return Array.isArray(v) ? v.filter(isRole) : fallback;
  };
  const choice = (k: string) => {
    const v = get(k);
    return v === "off" || v === "required" ? v : "optional";
  };
  const num = (k: string, fallback: number) => {
    const n = Number(get(k));
    return Number.isFinite(n) && n >= 0 ? n : fallback;
  };
  return {
    managerRoles: roles("vehicles.manager_roles", ["manager"]),
    reportRoles: roles("vehicles.report_roles", ["manager"]),
    clientField: choice("vehicles.client_field"),
    odoPhoto: choice("vehicles.odo_photo"),
    undoMinutes: num("vehicles.undo_minutes", 10),
    appDays: num("vehicles.app_days", 90) || 90,
  };
});

export const canUseCars = (role: Role, features: Record<string, boolean>) => features.vehicles === true && role !== "new_starter";
export const canManageCars = (role: Role, rules: CarRules) => role === "system_admin" || rules.managerRoles.includes(role);
export const canSeeCarReports = (role: Role, rules: CarRules) =>
  canManageCars(role, rules) || rules.reportRoles.includes(role);

const TRIP_COLUMNS = "id, car_id, purpose, details, client_name, started_at, start_odo, gap_km, returned_at, end_odo, km, returned_by, driver_id";

// Everything the Cars screen needs, in one go (the portal page and the app share it).
export async function loadCarScreen(userId: string): Promise<CarScreen> {
  const supabase = await createClient();
  const [rules, { data: board }, { data: purposes }, { data: clients }, { data: trips }] = await Promise.all([
    getCarRules(),
    supabase.rpc("car_board"),
    supabase.from("car_purposes").select("id, name").eq("active", true).order("sort_order").order("name"),
    supabase.rpc("car_client_options"),
    supabase.from("car_trips").select(TRIP_COLUMNS).eq("driver_id", userId).order("started_at", { ascending: false }).limit(8),
  ]);
  const cars = (board ?? []) as CarBoardRow[];
  const carName = new Map(cars.map((c) => [c.id, `${c.name} · ${c.rego}`]));
  // Cars switched off since still show their name in your history.
  const missing = [...new Set(((trips ?? []) as { car_id: string }[]).map((t) => t.car_id).filter((id) => !carName.has(id)))];
  if (missing.length) {
    const { data } = await supabase.from("cars").select("id, name, rego").in("id", missing);
    (data ?? []).forEach((c) => carName.set(c.id, `${c.name} · ${c.rego}`));
  }
  const mine: MyTrip[] = ((trips ?? []) as Omit<MyTrip, "car">[]).map((t) => ({ ...t, car: carName.get(t.car_id) ?? "A car" }));
  return {
    cars,
    purposes: purposes ?? [],
    clients: rules.clientField === "off" ? [] : ((clients ?? []) as { id: string; name: string }[]),
    open: mine.find((t) => !t.returned_at) ?? null,
    recent: mine.filter((t) => t.returned_at),
    rules: { clientField: rules.clientField, odoPhoto: rules.odoPhoto, undoMinutes: rules.undoMinutes },
    now: Date.now(),
  };
}

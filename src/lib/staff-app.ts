// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { getStaffAppLook } from "@/lib/branding";
import { canUseCars } from "@/lib/cars";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import type { Role } from "@/lib/roles";

// What's in the Staff app for this person (cmeprojects): the built features the
// system admin put in the app that they can fill in, and Cars if it's inside.
export type AppTile = { key: string; href: string; label: string; icon: string; colour: string; note: string };

export const staffAppOn = (features: Record<string, boolean>) => features.staff_app === true;

export const getStaffAppTiles = cache(async (userId: string, role: Role, features: Record<string, boolean>): Promise<AppTile[]> => {
  if (!staffAppOn(features) || role === "new_starter") return [];
  const supabase = await createClient();
  const [look, { data }, timeZone] = await Promise.all([
    getStaffAppLook(),
    supabase
      .from("custom_features")
      .select("id, slug, menu_label, fill_roles, app_icon, app_colour, in_app, sort_order")
      .eq("status", "published")
      .eq("enabled", true)
      .eq("in_app", true)
      .order("sort_order")
      .order("menu_label"),
    getTimeZone(),
  ]);
  const mine = (data ?? []).filter((f) => role === "system_admin" || (f.fill_roles as Role[]).includes(role));
  // How many they've entered today, as the line under each icon.
  const since = new Date(`${todayIn(timeZone)}T00:00:00`);
  since.setDate(since.getDate() - 1);
  const { data: entries } = mine.length
    ? await supabase.from("custom_entries").select("feature_id, created_at").eq("created_by", userId).in("feature_id", mine.map((f) => f.id)).gte("created_at", since.toISOString())
    : { data: [] };
  const day = new Intl.DateTimeFormat("en-CA", { timeZone });
  const today = todayIn(timeZone);
  const countToday = (id: string) => (entries ?? []).filter((e) => e.feature_id === id && day.format(new Date(e.created_at)) === today).length;

  const tiles: AppTile[] = [];
  if (look.cars && canUseCars(role, features)) tiles.push({ key: "cars", href: "/app/cars", label: "Cars", icon: "car", colour: "#134f8e", note: "Start or return" });
  for (const f of mine) {
    const n = countToday(f.id);
    tiles.push({ key: f.slug, href: `/app/f/${f.slug}`, label: f.menu_label, icon: f.app_icon, colour: f.app_colour, note: n ? `${n} by you today` : "None by you today" });
  }
  return tiles;
});

// The separate Cars app is offered for download unless Cars is inside the
// Staff app; then staff are only offered the one app. (Phones that already
// have the Cars app keep using it.)
export async function carsAppOffered(features: Record<string, boolean>): Promise<boolean> {
  const look = await getStaffAppLook();
  return !(staffAppOn(features) && look.cars);
}

// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";

export type Branding = {
  companyName: string;
  portalName: string;
  logoUrl: string;
  logoMarkUrl: string;
  colorPrimary: string;
  colorDark: string;
  colorAccent: string;
  // Optional messages (blank = hidden).
  supportContact: string;
  announcement: string;
};

const DEFAULTS: Branding = {
  companyName: "Staff Portal",
  portalName: "Staff Portal",
  logoUrl: "/logo.svg",
  logoMarkUrl: "/logo.svg",
  colorPrimary: "#134F8E",
  colorDark: "#0F2F57",
  colorAccent: "#6497C8",
  supportContact: "",
  announcement: "",
};

const KEYS: Record<string, keyof Branding> = {
  "brand.company_name": "companyName",
  "brand.portal_name": "portalName",
  "brand.logo_url": "logoUrl",
  "brand.logo_mark_url": "logoMarkUrl",
  "brand.color_primary": "colorPrimary",
  "brand.color_dark": "colorDark",
  "brand.color_accent": "colorAccent",
  "brand.support_contact": "supportContact",
  "brand.announcement": "announcement",
};

const HEX = /^#[0-9a-f]{6}$/i;

// Each company's name, logo and colours come from its System settings.
export const getBranding = cache(async (): Promise<Branding> => {
  const branding = { ...DEFAULTS };
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("app_settings")
      .select("key, value")
      .like("key", "brand.%");
    for (const row of data ?? []) {
      const field = KEYS[row.key];
      if (!field || typeof row.value !== "string") continue;
      if (field.startsWith("color") && !HEX.test(row.value)) continue;
      branding[field] = row.value;
    }
  } catch {
    // Not connected to Supabase yet: fall back to the defaults.
  }
  return branding;
});

export type CarsAppLook = { name: string; icon: "car" | "mark" | "logo" | "own"; iconUrl: string };

// The Cars app on staff phones (cmeprojects): its name and icon, from
// System settings → Cars. Public, so phones can read them while installing.
export const getCarsAppLook = cache(async (): Promise<CarsAppLook> => {
  const look: CarsAppLook = { name: "Cars", icon: "car", iconUrl: "" };
  try {
    const supabase = await createClient();
    const { data } = await supabase.from("app_settings").select("key, value").in("key", ["vehicles.app_name", "vehicles.app_icon", "vehicles.app_icon_url"]);
    for (const row of data ?? []) {
      if (typeof row.value !== "string") continue;
      if (row.key === "vehicles.app_name" && row.value.trim()) look.name = row.value.trim().slice(0, 20);
      if (row.key === "vehicles.app_icon" && ["car", "mark", "logo", "own"].includes(row.value)) look.icon = row.value as CarsAppLook["icon"];
      if (row.key === "vehicles.app_icon_url") look.iconUrl = row.value;
    }
  } catch {
    // Not connected yet: the defaults.
  }
  if (look.icon === "own" && !look.iconUrl) look.icon = "car";
  return look;
});

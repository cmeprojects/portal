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

export type CarsAppLook = {
  name: string;
  // "car", "mark" (small logo), "logo", or the address of an uploaded picture.
  icon: string;
  uploads: string[];
};

// The Cars app on staff phones (cmeprojects): its name and icon, from
// System settings → Cars. Public, so phones can read them while installing.
export const getCarsAppLook = cache(async (): Promise<CarsAppLook> => {
  const look: CarsAppLook = { name: "Cars", icon: "car", uploads: [] };
  try {
    const supabase = await createClient();
    const { data } = await supabase.from("app_settings").select("key, value").in("key", ["vehicles.app_name", "vehicles.app_icon", "vehicles.app_icon_uploads"]);
    for (const row of data ?? []) {
      if (row.key === "vehicles.app_name" && typeof row.value === "string" && row.value.trim()) look.name = row.value.trim().slice(0, 20);
      if (row.key === "vehicles.app_icon" && typeof row.value === "string") look.icon = row.value;
      if (row.key === "vehicles.app_icon_uploads" && Array.isArray(row.value)) look.uploads = row.value.filter((u): u is string => typeof u === "string");
    }
  } catch {
    // Not connected yet: the defaults.
  }
  if (!isIconChoice(look.icon, look.uploads)) look.icon = "car";
  return look;
});

export const isIconChoice = (icon: string, uploads: string[]) => ["car", "mark", "logo"].includes(icon) || uploads.includes(icon);

// The picture to draw for an icon choice ("" = the car).
export const iconPicture = (icon: string, brand: Branding) => (icon === "mark" ? brand.logoMarkUrl : icon === "logo" ? brand.logoUrl : icon === "car" ? "" : icon);

export type StaffAppLook = CarsAppLook & { cars: boolean; separateCars: boolean };

// The Staff app (premium): its name, icon, and whether Cars is inside it.
export const getStaffAppLook = cache(async (): Promise<StaffAppLook> => {
  const look: StaffAppLook = { name: "Staff", icon: "car", uploads: [], cars: false, separateCars: true };
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("app_settings")
      .select("key, value")
      .in("key", ["staff_app.name", "staff_app.icon", "staff_app.icon_uploads", "staff_app.cars", "vehicles.separate_app"]);
    for (const row of data ?? []) {
      if (row.key === "staff_app.name" && typeof row.value === "string" && row.value.trim()) look.name = row.value.trim().slice(0, 20);
      if (row.key === "staff_app.icon" && typeof row.value === "string") look.icon = row.value;
      if (row.key === "staff_app.icon_uploads" && Array.isArray(row.value)) look.uploads = row.value.filter((u): u is string => typeof u === "string");
      if (row.key === "staff_app.cars") look.cars = row.value === true;
      if (row.key === "vehicles.separate_app") look.separateCars = row.value !== false;
    }
  } catch {
    // Not connected yet: the defaults.
  }
  if (!isIconChoice(look.icon, look.uploads)) look.icon = "car";
  return look;
});

// The company's initials, e.g. "EC" for Engaged Care (for "EC Apps" and the icons).
export const initialsOf = (name: string) =>
  name
    .split(/\s+/)
    .filter((w) => /^[A-Za-z]/.test(w))
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join("");

// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";

export type Branding = {
  companyName: string;
  portalName: string;
  logoUrl: string;
  colorPrimary: string;
  colorDark: string;
  colorAccent: string;
};

const DEFAULTS: Branding = {
  companyName: "Staff Portal",
  portalName: "Staff Portal",
  logoUrl: "/logo.svg",
  colorPrimary: "#134F8E",
  colorDark: "#0F2F57",
  colorAccent: "#6497C8",
};

const KEYS: Record<string, keyof Branding> = {
  "brand.company_name": "companyName",
  "brand.portal_name": "portalName",
  "brand.logo_url": "logoUrl",
  "brand.color_primary": "colorPrimary",
  "brand.color_dark": "colorDark",
  "brand.color_accent": "colorAccent",
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

// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { getBranding, getStaffAppLook } from "@/lib/branding";

// What a phone needs to install the Staff app: its name, icon and colours,
// and (on Android) long-press shortcuts to what's inside.
export async function GET() {
  const [brand, look] = await Promise.all([getBranding(), getStaffAppLook()]);
  // Read before anyone signs in, so with the server's own access (names only).
  const { data } = await createAdminClient()
    .from("custom_features")
    .select("slug, menu_label")
    .eq("status", "published")
    .eq("enabled", true)
    .eq("in_app", true)
    .order("sort_order")
    .order("menu_label")
    .limit(3);
  const shortcuts = [
    ...(look.cars ? [{ name: "Cars", url: "/app/cars" }] : []),
    ...(data ?? []).map((f) => ({ name: f.menu_label, url: `/app/f/${f.slug}` })),
  ].slice(0, 4);
  return NextResponse.json(
    {
      id: "/app",
      name: look.name === "Staff" ? `${brand.companyName} Staff` : look.name,
      short_name: look.name,
      description: "The company's staff app.",
      start_url: "/app",
      scope: "/app",
      display: "standalone",
      orientation: "portrait",
      background_color: "#ffffff",
      theme_color: brand.colorDark,
      icons: [
        { src: "/app/icon/192", sizes: "192x192", type: "image/png", purpose: "any" },
        { src: "/app/icon/512", sizes: "512x512", type: "image/png", purpose: "any" },
        { src: "/app/icon/512?maskable=1", sizes: "512x512", type: "image/png", purpose: "maskable" },
      ],
      shortcuts: shortcuts.map((s) => ({ ...s, icons: [{ src: "/app/icon/192", sizes: "192x192", type: "image/png" }] })),
    },
    { headers: { "Content-Type": "application/manifest+json", "Cache-Control": "public, max-age=3600" } },
  );
}

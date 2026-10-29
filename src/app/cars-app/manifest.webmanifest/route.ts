// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse } from "next/server";
import { getBranding } from "@/lib/branding";

// What a phone needs to install the Cars app: its name, icon and colours.
export async function GET() {
  const brand = await getBranding();
  return NextResponse.json(
    {
      id: "/cars-app",
      name: `${brand.companyName} Cars`,
      short_name: "Cars",
      description: "Start and return company cars.",
      start_url: "/cars-app",
      scope: "/cars-app",
      display: "standalone",
      orientation: "portrait",
      background_color: "#ffffff",
      theme_color: brand.colorDark,
      icons: [
        { src: "/cars-app/icon/192", sizes: "192x192", type: "image/png", purpose: "any" },
        { src: "/cars-app/icon/512", sizes: "512x512", type: "image/png", purpose: "any" },
        { src: "/cars-app/icon/512?maskable=1", sizes: "512x512", type: "image/png", purpose: "maskable" },
      ],
    },
    { headers: { "Content-Type": "application/manifest+json", "Cache-Control": "public, max-age=3600" } },
  );
}

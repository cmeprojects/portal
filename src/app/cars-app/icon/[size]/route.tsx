// Staff Portal · © cmeproject. All rights reserved.
import { ImageResponse } from "next/og";
import type { NextRequest } from "next/server";
import { getBranding } from "@/lib/branding";

// The Cars app's home-screen icon, in the company's colours: a car with the
// company's initials. "maskable" leaves room for phones that crop icons round.
export async function GET(request: NextRequest, ctx: RouteContext<"/cars-app/icon/[size]">) {
  const { size: raw } = await ctx.params;
  const size = [180, 192, 512].includes(Number(raw)) ? Number(raw) : 192;
  const maskable = request.nextUrl.searchParams.has("maskable");
  const brand = await getBranding();
  const initials = brand.companyName
    .split(/\s+/)
    .filter((w) => /^[A-Za-z]/.test(w))
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join("");
  const inner = maskable ? size * 0.62 : size * 0.8;

  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: brand.colorDark }}>
        <div style={{ width: inner, height: inner, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          <svg width={inner * 0.78} height={inner * 0.5} viewBox="0 0 64 40" fill="none">
            <path d="M6 30v-9l6-12h40l6 12v9z" fill="#ffffff" />
            <path d="M15 12h34l4 9H11z" fill={brand.colorPrimary} />
            <circle cx="17" cy="31" r="6" fill={brand.colorDark} stroke="#ffffff" strokeWidth="3" />
            <circle cx="47" cy="31" r="6" fill={brand.colorDark} stroke="#ffffff" strokeWidth="3" />
          </svg>
          {initials ? (
            <div style={{ marginTop: inner * 0.04, color: "#ffffff", fontSize: inner * 0.26, fontWeight: 700, letterSpacing: inner * 0.02 }}>{initials}</div>
          ) : null}
        </div>
      </div>
    ),
    { width: size, height: size, headers: { "Cache-Control": "public, max-age=86400" } },
  );
}

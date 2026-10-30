// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { ImageResponse } from "next/og";
import type { NextRequest } from "next/server";
import { iconPicture, initialsOf, isIconChoice, type Branding, type CarsAppLook } from "@/lib/branding";

// A phone app's home-screen icon (cmeprojects): the drawn icon (a car for the
// Cars app, a checklist for the Staff app) with the company's initials in its
// colours, or a logo or uploaded picture chosen in System settings.
// "maskable" leaves room for phones that crop icons round. ?as= previews a choice.
export async function appIcon(request: NextRequest, rawSize: string, brand: Branding, look: CarsAppLook, glyph: "car" | "staff") {
  const size = [180, 192, 512].includes(Number(rawSize)) ? Number(rawSize) : 192;
  const maskable = request.nextUrl.searchParams.has("maskable");
  const headers = { "Cache-Control": "public, max-age=3600" };
  const asked = request.nextUrl.searchParams.get("as");
  const icon = asked !== null && isIconChoice(asked, look.uploads) ? asked : look.icon;
  const picture = iconPicture(icon, brand);
  const src = picture ? await asDataUrl(picture.startsWith("/") ? `${request.nextUrl.origin}${picture}` : picture) : null;
  if (src) {
    // An uploaded picture fills the icon; a logo sits on white with some space round it.
    const uploaded = look.uploads.includes(icon);
    const box = uploaded ? (maskable ? size * 0.8 : size) : maskable ? size * 0.6 : size * 0.78;
    return new ImageResponse(
      (
        <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: "#ffffff" }}>
          {/* eslint-disable-next-line @next/next/no-img-element -- drawn into the icon image */}
          <img src={src} width={box} height={box} alt="" style={{ objectFit: uploaded && !maskable ? "cover" : "contain" }} />
        </div>
      ),
      { width: size, height: size, headers },
    );
  }

  const initials = initialsOf(brand.companyName);
  const inner = maskable ? size * 0.62 : size * 0.8;
  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: brand.colorDark }}>
        <div style={{ width: inner, height: inner, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          {glyph === "car" ? (
            <svg width={inner * 0.78} height={inner * 0.5} viewBox="0 0 64 40" fill="none">
              <path d="M6 30v-9l6-12h40l6 12v9z" fill="#ffffff" />
              <path d="M15 12h34l4 9H11z" fill={brand.colorPrimary} />
              <circle cx="17" cy="31" r="6" fill={brand.colorDark} stroke="#ffffff" strokeWidth="3" />
              <circle cx="47" cy="31" r="6" fill={brand.colorDark} stroke="#ffffff" strokeWidth="3" />
            </svg>
          ) : (
            <svg width={inner * 0.62} height={inner * 0.5} viewBox="0 0 48 40" fill="none">
              <rect x="2" y="2" width="44" height="36" rx="7" fill="#ffffff" />
              <rect x="9" y="10" width="7" height="7" rx="2" fill={brand.colorPrimary} />
              <rect x="20" y="11" width="19" height="5" rx="2.5" fill={brand.colorPrimary} />
              <rect x="9" y="23" width="7" height="7" rx="2" fill={brand.colorPrimary} />
              <rect x="20" y="24" width="14" height="5" rx="2.5" fill={brand.colorPrimary} />
            </svg>
          )}
          {initials ? (
            <div style={{ marginTop: inner * 0.04, color: "#ffffff", fontSize: inner * 0.26, fontWeight: 700, letterSpacing: inner * 0.02 }}>{initials}</div>
          ) : null}
        </div>
      </div>
    ),
    { width: size, height: size, headers },
  );
}

// The logo or picture as data, so it can be drawn into the icon. Null (and the
// drawn icon instead) if it can't be loaded.
async function asDataUrl(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, { cache: "no-store" });
    const type = res.headers.get("content-type")?.split(";")[0] ?? "";
    if (!res.ok || !/^image\/(png|jpeg|svg\+xml|webp|gif)$/.test(type)) return null;
    const bytes = Buffer.from(await res.arrayBuffer());
    if (bytes.length > 3_000_000) return null;
    return `data:${type};base64,${bytes.toString("base64")}`;
  } catch {
    return null;
  }
}

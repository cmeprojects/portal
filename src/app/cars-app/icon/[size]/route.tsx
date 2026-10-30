// Staff Portal · © cmeproject. All rights reserved.
import { ImageResponse } from "next/og";
import type { NextRequest } from "next/server";
import { getBranding, getCarsAppLook } from "@/lib/branding";

// The Cars app's home-screen icon: a car with the company's initials in its
// colours, or a logo or picture chosen in System settings → Cars.
// "maskable" leaves room for phones that crop icons round.
export async function GET(
  request: NextRequest,
  ctx: RouteContext<"/cars-app/icon/[size]">,
) {
  const { size: raw } = await ctx.params;
  const size = [180, 192, 512].includes(Number(raw)) ? Number(raw) : 192;
  const maskable = request.nextUrl.searchParams.has("maskable");
  const [brand, look] = await Promise.all([getBranding(), getCarsAppLook()]);
  const headers = { "Cache-Control": "public, max-age=3600" };
  const picture =
    look.icon === "own"
      ? look.iconUrl
      : look.icon === "mark"
        ? brand.logoMarkUrl
        : look.icon === "logo"
          ? brand.logoUrl
          : "";
  const src = picture
    ? await asDataUrl(
        picture.startsWith("/")
          ? `${request.nextUrl.origin}${picture}`
          : picture,
      )
    : null;
  if (src) {
    // Your own picture fills the icon; a logo sits on white with some space round it.
    const box =
      look.icon === "own"
        ? maskable
          ? size * 0.8
          : size
        : maskable
          ? size * 0.6
          : size * 0.78;
    return new ImageResponse(
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#ffffff",
        }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element -- drawn into the icon image */}
        <img
          src={src}
          width={box}
          height={box}
          alt=""
          style={{ objectFit: "contain" }}
        />
      </div>,
      { width: size, height: size, headers },
    );
  }
  const initials = brand.companyName
    .split(/\s+/)
    .filter((w) => /^[A-Za-z]/.test(w))
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join("");
  const inner = maskable ? size * 0.62 : size * 0.8;

  return new ImageResponse(
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: brand.colorDark,
      }}
    >
      <div
        style={{
          width: inner,
          height: inner,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <svg
          width={inner * 0.78}
          height={inner * 0.5}
          viewBox="0 0 64 40"
          fill="none"
        >
          <path d="M6 30v-9l6-12h40l6 12v9z" fill="#ffffff" />
          <path d="M15 12h34l4 9H11z" fill={brand.colorPrimary} />
          <circle
            cx="17"
            cy="31"
            r="6"
            fill={brand.colorDark}
            stroke="#ffffff"
            strokeWidth="3"
          />
          <circle
            cx="47"
            cy="31"
            r="6"
            fill={brand.colorDark}
            stroke="#ffffff"
            strokeWidth="3"
          />
        </svg>
        {initials ? (
          <div
            style={{
              marginTop: inner * 0.04,
              color: "#ffffff",
              fontSize: inner * 0.26,
              fontWeight: 700,
              letterSpacing: inner * 0.02,
            }}
          >
            {initials}
          </div>
        ) : null}
      </div>
    </div>,
    { width: size, height: size, headers },
  );
}

// The logo or picture as data, so it can be drawn into the icon. Null (and the
// car icon instead) if it can't be loaded.
async function asDataUrl(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, { cache: "no-store" });
    const type = res.headers.get("content-type")?.split(";")[0] ?? "";
    if (!res.ok || !/^image\/(png|jpeg|svg\+xml|webp|gif)$/.test(type))
      return null;
    const bytes = Buffer.from(await res.arrayBuffer());
    if (bytes.length > 3_000_000) return null;
    return `data:${type};base64,${bytes.toString("base64")}`;
  } catch {
    return null;
  }
}

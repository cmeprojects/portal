// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

// A quick check that the website is up, and where it's running.
export function GET() {
  const region = process.env.VERCEL_REGION ?? process.env.FLY_REGION ?? "local";
  return NextResponse.json(
    { ok: true, region, sydney: region === "syd1" },
    { headers: { "Cache-Control": "no-store" } },
  );
}

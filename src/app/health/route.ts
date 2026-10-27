// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

async function time(url: string, key: string): Promise<number | string> {
  const start = performance.now();
  try {
    const res = await fetch(url, { headers: { apikey: key, Authorization: `Bearer ${key}` }, cache: "no-store" });
    await res.arrayBuffer();
    if (!res.ok) return `error ${res.status}`;
    return Math.round(performance.now() - start);
  } catch {
    return "unreachable";
  }
}

// A quick check that the website is up, where it's running, and how long it
// takes to reach the database (in milliseconds).
export async function GET() {
  const region = process.env.VERCEL_REGION ?? "local";
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const result: Record<string, unknown> = { ok: true, region, sydney: region === "syd1" };

  if (url && key) {
    const db = `${url}/rest/v1/app_settings?select=key&is_public=eq.true&limit=1`;
    const auth = `${url}/auth/v1/health`;
    const dbTimes = [await time(db, key), await time(db, key), await time(db, key)];
    result.database_ms = dbTimes;
    result.signin_service_ms = await time(auth, key);
  }

  return NextResponse.json(result, { headers: { "Cache-Control": "no-store" } });
}

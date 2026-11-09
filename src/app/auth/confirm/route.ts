// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";

// Links in emails (invite, sign-in link, password reset) land here.
// cmeprojects: the link is only used when the person presses the button on
// /auth/setup. Opening it doesn't use it up, so email security scanners that
// "click" links to check them can't spend someone's one-time link.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  // A sign-in code (from Supabase's own emails) goes to the callback as before.
  if (searchParams.get("code")) return NextResponse.redirect(new URL(`/auth/callback${request.nextUrl.search}`, origin));
  const out = new URL("/auth/setup", origin);
  for (const k of ["token_hash", "type", "next"]) {
    const v = searchParams.get(k);
    if (v) out.searchParams.set(k, v);
  }
  return NextResponse.redirect(out);
}

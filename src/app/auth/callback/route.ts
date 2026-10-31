// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { safeNext } from "@/lib/safe-next";
import { PORTAL_LOCK_COOKIE } from "@/lib/app-lock";

// Google sign-in comes back here with a one-time code.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const code = searchParams.get("code");
  const next = safeNext(searchParams.get("next"));

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      const out = NextResponse.redirect(`${origin}${next}`);
      out.cookies.delete(PORTAL_LOCK_COOKIE);
      return out;
    }
  }
  return NextResponse.redirect(`${origin}/login?error=google`);
}

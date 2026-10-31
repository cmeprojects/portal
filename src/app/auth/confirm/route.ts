// Staff Portal · © cmeproject. All rights reserved.
import type { EmailOtpType } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { safeNext } from "@/lib/safe-next";
import { PORTAL_LOCK_COOKIE } from "@/lib/app-lock";

// Links in emails (invite, sign-in link, password reset) land here.
// The email templates are set up in Supabase as described in docs/SETUP.md.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const tokenHash = searchParams.get("token_hash");
  const type = searchParams.get("type") as EmailOtpType | null;

  if (tokenHash && type) {
    const supabase = await createClient();
    const { error } = await supabase.auth.verifyOtp({ type, token_hash: tokenHash });
    if (!error) {
      const next =
        type === "invite" ? "/welcome" : type === "recovery" ? "/set-password" : safeNext(searchParams.get("next"));
      const out = NextResponse.redirect(`${origin}${next}`);
      out.cookies.delete(PORTAL_LOCK_COOKIE);
      return out;
    }
  }
  return NextResponse.redirect(`${origin}/login?error=link`);
}

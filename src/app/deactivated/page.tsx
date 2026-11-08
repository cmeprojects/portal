// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { AutoSignOut } from "./auto-sign-out";

export const metadata: Metadata = { title: "Account turned off" };

export default async function DeactivatedPage() {
  // cmeprojects: only turned-off accounts belong here. Someone whose account is
  // on (an old link or bookmark) goes back to the portal instead of being
  // signed out and told their account is off.
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (userId) {
    const { data: me } = await supabase.from("profiles").select("active").eq("id", userId).maybeSingle();
    if (me?.active) redirect("/");
  }
  const brand = await getBranding();
  return (
    <AuthShell brand={brand}>
      <AutoSignOut />
      <h1 className="heading">Your account is turned off</h1>
      <p className="text-sm text-muted">
        You can&apos;t use the portal at the moment. If you think this is a mistake, please talk to your manager or
        the office. You&apos;ve been signed out.
      </p>
      <Link href="/login" className="text-sm font-semibold text-brand underline">
        Back to the sign-in page
      </Link>
    </AuthShell>
  );
}

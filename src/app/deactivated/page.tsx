// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import Link from "next/link";
import { AutoSignOut } from "./auto-sign-out";

export const metadata: Metadata = { title: "Account turned off" };

export default async function DeactivatedPage() {
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

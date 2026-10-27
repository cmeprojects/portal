// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import { Button } from "@/components/ui";
import { signOut } from "@/app/login/actions";

export const metadata: Metadata = { title: "Account turned off" };

export default async function DeactivatedPage() {
  const brand = await getBranding();
  return (
    <AuthShell brand={brand}>
      <h1 className="heading">Your account is turned off</h1>
      <p className="text-sm text-muted">
        You can&apos;t use the portal at the moment. If you think this is a mistake, please talk to your manager or
        the office.
      </p>
      <form action={signOut}>
        <Button variant="outline" className="w-full">Sign out</Button>
      </form>
    </AuthShell>
  );
}

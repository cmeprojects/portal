// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import { ForgotPasswordForm } from "./form";

export const metadata: Metadata = { title: "Forgot password" };

export default async function ForgotPasswordPage() {
  const brand = await getBranding();
  return (
    <AuthShell brand={brand}>
      <div className="flex flex-col gap-1">
        <h1 className="heading">Forgot your password?</h1>
        <p className="text-sm text-muted">We&apos;ll email you a link to set a new one.</p>
      </div>
      <ForgotPasswordForm />
      <Link href="/login" className="text-center text-sm font-semibold text-brand">
        Back to sign in
      </Link>
    </AuthShell>
  );
}

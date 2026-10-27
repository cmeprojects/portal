// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import { BrandMark } from "@/components/brand-mark";
import { ForgotPasswordForm } from "./form";

export const metadata: Metadata = { title: "Forgot password" };

export default async function ForgotPasswordPage() {
  const brand = await getBranding();
  return (
    <AuthShell brand={brand} hero={<BrandMark brand={brand} size={56} onDark />}>
      <div className="flex flex-col gap-1">
        <h1 className="text-[22px] font-bold">Forgot your password?</h1>
        <p className="text-[15px] text-muted">We&apos;ll email you a link to set a new one.</p>
      </div>
      <ForgotPasswordForm />
      <Link href="/login" className="text-center text-[15px] font-semibold text-brand">
        Back to sign in
      </Link>
    </AuthShell>
  );
}

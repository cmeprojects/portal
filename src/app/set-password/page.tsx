// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import { SetPasswordForm } from "./form";

export const metadata: Metadata = { title: "Set a new password" };

export default async function SetPasswordPage() {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  if (!claims?.claims?.sub) redirect("/login?error=link");
  const brand = await getBranding();

  return (
    <AuthShell brand={brand}>
      <h1 className="text-[22px] font-bold">Set a new password</h1>
      <SetPasswordForm />
    </AuthShell>
  );
}

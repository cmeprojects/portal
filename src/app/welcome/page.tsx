// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getBranding } from "@/lib/branding";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { AuthShell } from "@/components/auth-shell";
import { Badge } from "@/components/ui";
import { WelcomeForm } from "./welcome-form";

export const metadata: Metadata = { title: "Welcome" };

export default async function WelcomePage() {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");

  const [brand, { data: profile }] = await Promise.all([
    getBranding(),
    supabase.from("profiles").select("full_name, email, role, active").eq("id", userId).maybeSingle(),
  ]);
  if (!profile?.active) redirect("/deactivated");

  const firstName = profile.full_name.split(" ")[0];

  return (
    <AuthShell brand={brand}>
      <div className="flex flex-col gap-2">
        <span className="self-start"><Badge>Welcome aboard</Badge></span>
        <h1 className="heading">
          {firstName ? `Hi ${firstName}, welcome` : "Welcome"} to the {brand.companyName} portal
        </h1>
        <p className="text-sm text-muted">
          {profile.role === "new_starter" ? (
            <>First, set up how you&apos;d like to sign in. Next you&apos;ll do your onboarding: reading our policies, any trainings, and uploading your documents.</>
          ) : (
            <>
              You&apos;ve been added as <strong className="text-ink">{ROLE_LABELS[profile.role as Role]}</strong>. Set up how
              you&apos;d like to sign in.
            </>
          )}
        </p>
      </div>
      <WelcomeForm name={profile.full_name} email={profile.email} />
    </AuthShell>
  );
}

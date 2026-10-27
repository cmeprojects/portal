// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getBranding } from "@/lib/branding";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { AuthShell } from "@/components/auth-shell";
import { Button } from "@/components/ui";
import { signOut } from "@/app/login/actions";
import { MfaForm } from "./mfa-form";

export const metadata: Metadata = { title: "Two-factor login" };

export default async function MfaPage() {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  if (!claims?.claims?.sub) redirect("/login");

  const [brand, { data: access }] = await Promise.all([
    getBranding(),
    supabase.rpc("my_access").maybeSingle<{ role: Role; active: boolean; mfa_ok: boolean }>(),
  ]);
  if (!access?.active) redirect("/deactivated");
  if (claims.claims.aal === "aal2") redirect("/");

  return (
    <AuthShell brand={brand}>
      <div className="flex flex-col gap-1.5">
        <h1 className="heading">Two-factor login</h1>
        <p className="text-sm leading-relaxed text-muted">
          As a <strong className="text-ink">{ROLE_LABELS[access.role]}</strong> you can see more records, so we need a
          code from your phone as well as your password.
        </p>
      </div>
      <MfaForm />
      <p className="text-sm text-muted">Lost your phone? A system admin can reset your two-factor login.</p>
      <form action={signOut}>
        <Button variant="outline" className="w-full">Sign out</Button>
      </form>
    </AuthShell>
  );
}

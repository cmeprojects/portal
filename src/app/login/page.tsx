// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getBranding } from "@/lib/branding";
import { createClient } from "@/lib/supabase/server";
import { safeNext } from "@/lib/safe-next";
import { AuthShell } from "@/components/auth-shell";
import { LoginForm } from "./login-form";

export const metadata: Metadata = { title: "Sign in" };

const ERRORS: Record<string, string> = {
  google: "Google sign-in didn't work. Make sure you use the email you were invited with.",
  link: "That link has expired or was already used. Ask for a new one below.",
};

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  const params = await searchParams;
  const next = safeNext(params.next);
  const supabase = await createClient();

  const { data: claims } = await supabase.auth.getClaims();
  if (claims?.claims?.sub) redirect(next);

  const [brand, { data: options }] = await Promise.all([
    getBranding(),
    supabase.from("features").select("key, enabled").like("key", "sign_in_%"),
  ]);
  const on = (key: string) => options?.find((o) => o.key === key)?.enabled ?? true;
  const errorKey = typeof params.error === "string" ? params.error : "";

  return (
    <AuthShell brand={brand}>
      <div className="flex flex-col gap-1">
        <h1 className="heading">Welcome back</h1>
        <p className="text-sm text-muted">Sign in with the email you were invited with.</p>
      </div>
      <LoginForm
        next={next}
        googleOn={on("sign_in_google")}
        linkOn={on("sign_in_magic_link")}
        initialError={ERRORS[errorKey]}
      />
      <p className="text-center text-sm text-muted">
        No account yet? This portal is invite-only. Ask your manager to add you.
      </p>
    </AuthShell>
  );
}

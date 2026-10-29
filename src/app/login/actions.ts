// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { env } from "@/lib/env";
import { safeNext } from "@/lib/safe-next";
import { EMAIL, text, type FormState } from "@/lib/form";

// Plain-English reasons, so a set-up problem isn't mistaken for a wrong password.
function signInProblem(code: string | undefined, status: number | undefined): string {
  switch (code) {
    case "invalid_credentials":
      return "That email and password don't match. Try again, or use a sign-in link.";
    case "user_banned":
      return "Your account has been turned off. Please talk to your manager.";
    case "email_not_confirmed":
      return "This account's email address hasn't been confirmed yet. Ask your admin to confirm it, or use the link in your invite email.";
    case "email_provider_disabled":
      return "Email sign-in is switched off for this portal. An admin needs to turn the Email provider back on in Supabase.";
    case "over_request_rate_limit":
    case "over_email_send_rate_limit":
      return "Too many attempts. Please wait a few minutes and try again.";
    default:
      return `We couldn't reach the sign-in service. Please try again shortly. If this keeps happening, tell your admin (code: ${code ?? status ?? "unknown"}).`;
  }
}

export async function signInWithPassword(_: FormState, form: FormData): Promise<FormState> {
  const email = text(form, "email").toLowerCase();
  const password = String(form.get("password") ?? "");
  if (!EMAIL.test(email) || !password) return { error: "Enter your email and password." };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: signInProblem(error.code, error.status) };
  redirect(safeNext(text(form, "next")));
}

export async function sendSignInLink(_: FormState, form: FormData): Promise<FormState> {
  const email = text(form, "email").toLowerCase();
  if (!EMAIL.test(email)) return { error: "Enter the email you were invited with." };

  const supabase = await createClient();
  await supabase.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: false,
      emailRedirectTo: `${env.siteUrl}/auth/confirm?next=${encodeURIComponent(safeNext(text(form, "next")))}`,
    },
  });
  // Same answer either way, so the page never reveals who has an account.
  return { message: `If ${email} has an account, a sign-in link is on its way. Check your inbox.` };
}

export async function signInWithGoogle(form: FormData) {
  const supabase = await createClient();
  const next = safeNext(text(form, "next"));
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo: `${env.siteUrl}/auth/callback?next=${encodeURIComponent(next)}` },
  });
  if (error || !data.url) redirect("/login?error=google");
  redirect(data.url);
}

// Signed out after too long without activity.
export async function signOutIdle() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login?error=idle");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

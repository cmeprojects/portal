// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { env } from "@/lib/env";
import { safeNext } from "@/lib/safe-next";
import { sendSignInLinkEmail } from "@/lib/email/password-reset";
import { EMAIL, text, type FormState } from "@/lib/form";
import { APP_COOKIE, PORTAL_LOCK_COOKIE } from "@/lib/app-lock";

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

// Wrong-password counting, kept by the database (0 = not locked; before live
// update 37 there's no lock).
async function signInGuard(email: string, event: "check" | "fail" | "ok"): Promise<number> {
  const { data, error } = await createAdminClient().rpc("sign_in_guard", { p_email: email, p_event: event });
  return error ? 0 : Number(data ?? 0);
}

const lockedMessage = (minutes: number) =>
  `Too many wrong passwords, so this account is locked for ${minutes} minute${minutes === 1 ? "" : "s"}. You can still sign in with a sign-in link below.`;

// The inactivity timer starts again from now (and a stale time from before
// can't sign them straight back out).
async function freshActivity() {
  const jar = await cookies();
  jar.delete(PORTAL_LOCK_COOKIE);
  jar.set("portal_last_active", String(Date.now()), { path: "/", maxAge: 31536000, sameSite: "lax", secure: process.env.NODE_ENV === "production" });
}

export async function signInWithPassword(_: FormState, form: FormData): Promise<FormState> {
  const email = text(form, "email").toLowerCase();
  const password = String(form.get("password") ?? "");
  if (!EMAIL.test(email) || !password) return { error: "Enter your email and password." };

  // Five wrong passwords lock the email for 15 minutes (a sign-in link still works).
  const lockedFor = await signInGuard(email, "check");
  if (lockedFor > 0) return { error: lockedMessage(lockedFor) };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    if (error.code === "invalid_credentials") {
      const locked = await signInGuard(email, "fail");
      if (locked > 0) return { error: lockedMessage(locked) };
    }
    return { error: signInProblem(error.code, error.status) };
  }
  await signInGuard(email, "ok");
  await freshActivity();
  redirect(safeNext(text(form, "next")));
}

export async function sendSignInLink(_: FormState, form: FormData): Promise<FormState> {
  const email = text(form, "email").toLowerCase();
  if (!EMAIL.test(email)) return { error: "Enter the email you were invited with." };

  // Branded email through Resend once it's set up; Supabase's email until then.
  await sendSignInLinkEmail(email, safeNext(text(form, "next")));
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
  const jar = await cookies();
  // A phone with an app: lock only the portal, so the apps stay signed in behind their PIN.
  if (jar.has(APP_COOKIE)) {
    jar.set(PORTAL_LOCK_COOKIE, "1", { path: "/", httpOnly: true, sameSite: "lax", maxAge: 31536000, secure: process.env.NODE_ENV === "production" });
    redirect("/login?error=idle");
  }
  const supabase = await createClient();
  await supabase.auth.signOut({ scope: "local" });
  jar.delete("portal_last_active");
  redirect("/login?error=idle");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut({ scope: "local" });
  const jar = await cookies();
  jar.delete("portal_last_active");
  jar.delete(PORTAL_LOCK_COOKIE);
  redirect("/login");
}

// The account was turned off: sign out of this browser without any questions.
export async function signOutDeactivated() {
  const supabase = await createClient();
  await supabase.auth.signOut({ scope: "local" });
  (await cookies()).delete("portal_last_active");
}

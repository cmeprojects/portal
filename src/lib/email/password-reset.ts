// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { getBranding } from "@/lib/branding";
import { env } from "@/lib/env";
import { sendEmail } from "./send";
import { renderPasswordReset, renderSignInLink } from "./templates";

const emailReady = () => Boolean(process.env.RESEND_API_KEY || process.env.MAILPIT_URL);
const THROTTLE_SECONDS = 120;

// Emails a link to set a new password. With email set up (Resend), it's the
// portal's own branded email; otherwise Supabase sends its reset email.
// Never says whether the address has an account. At most one every 2 minutes.
export async function sendPasswordReset(email: string, sentBy?: string): Promise<{ error: string | null }> {
  const admin = createAdminClient();
  const key = `reset:${email.toLowerCase()}`;
  const { data: last } = await admin.from("email_throttle").select("sent_at").eq("key", key).maybeSingle();
  if (last && Date.now() - new Date(last.sent_at).getTime() < THROTTLE_SECONDS * 1000) {
    return { error: sentBy ? "A reset link was sent in the last 2 minutes. Ask them to check their inbox (and junk folder)." : null };
  }
  await admin.from("email_throttle").upsert({ key, sent_at: new Date().toISOString() });

  if (!emailReady()) {
    const { error } = await admin.auth.resetPasswordForEmail(email, { redirectTo: `${env.siteUrl}/set-password` });
    return { error: sentBy && error ? error.message : null };
  }
  const link = await admin.auth.admin.generateLink({ type: "recovery", email });
  const hash = link.data?.properties?.hashed_token;
  // No account with that address: say nothing (the person sees the same message either way).
  if (link.error || !hash) return { error: sentBy ? "That person doesn't have a sign-in yet. Resend their invite instead." : null };
  const { data: person } = await admin.from("profiles").select("full_name").ilike("email", email).maybeSingle();
  const brand = await getBranding();
  const logo = /^https?:\/\//.test(brand.logoUrl) ? brand.logoUrl : `${env.siteUrl}${brand.logoUrl}`;
  const msg = renderPasswordReset({
    recipientName: (person?.full_name ?? "").split(" ")[0],
    companyName: brand.companyName,
    logo,
    link: `${env.siteUrl}/auth/confirm?token_hash=${encodeURIComponent(hash)}&type=recovery`,
    brand: brand.colorPrimary,
    sentBy,
  });
  try {
    await sendEmail({ to: { email, name: person?.full_name ?? undefined }, cc: [], ...msg });
    return { error: null };
  } catch (e) {
    return { error: sentBy ? (e instanceof Error ? e.message : String(e)) : null };
  }
}

// The "Email me a sign-in link" button: the portal's own branded email once
// Resend is set up; Supabase's email until then. Only for existing accounts.
export async function sendSignInLinkEmail(email: string, next: string): Promise<void> {
  const admin = createAdminClient();
  const key = `link:${email.toLowerCase()}`;
  const { data: last } = await admin.from("email_throttle").select("sent_at").eq("key", key).maybeSingle();
  if (last && Date.now() - new Date(last.sent_at).getTime() < THROTTLE_SECONDS * 1000) return;
  await admin.from("email_throttle").upsert({ key, sent_at: new Date().toISOString() });
  const { data: person } = await admin.from("profiles").select("full_name, active").ilike("email", email).maybeSingle();
  if (!person?.active) return;

  if (!emailReady()) {
    await admin.auth.signInWithOtp({
      email,
      options: { shouldCreateUser: false, emailRedirectTo: `${env.siteUrl}/auth/confirm?next=${encodeURIComponent(next)}` },
    });
    return;
  }
  const link = await admin.auth.admin.generateLink({ type: "magiclink", email });
  const hash = link.data?.properties?.hashed_token;
  if (link.error || !hash) return;
  const brand = await getBranding();
  const logo = /^https?:\/\//.test(brand.logoUrl) ? brand.logoUrl : `${env.siteUrl}${brand.logoUrl}`;
  const msg = renderSignInLink({
    recipientName: (person.full_name ?? "").split(" ")[0],
    companyName: brand.companyName,
    logo,
    link: `${env.siteUrl}/auth/confirm?token_hash=${encodeURIComponent(hash)}&type=magiclink&next=${encodeURIComponent(next)}`,
    brand: brand.colorPrimary,
  });
  await sendEmail({ to: { email, name: person.full_name ?? undefined }, cc: [], ...msg }).catch(() => undefined);
}

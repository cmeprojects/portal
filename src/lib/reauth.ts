// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient as createSupabase } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { env } from "@/lib/env";

// cmeprojects: "prove it's you" before something sensitive (changing your
// password, signing everyone out). Accepts your current password, or a 6-digit
// code from your authenticator app if you've set one up. Wrong passwords count
// towards the same 5-try lockout as signing in.
export async function confirmIdentity(secret: string): Promise<{ ok: true } | { ok: false; error: string }> {
  const value = secret.trim();
  if (!value) return { ok: false, error: "Enter your current password (or a code from your authenticator app)." };
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const email = String(claims?.claims?.email ?? "").toLowerCase();
  if (!email) return { ok: false, error: "Please sign in again." };

  // A 6-digit code from the authenticator app.
  if (/^\d{6}$/.test(value)) {
    const { data: factors } = await supabase.auth.mfa.listFactors();
    const totp = factors?.totp?.[0];
    if (totp) {
      const { error } = await supabase.auth.mfa.challengeAndVerify({ factorId: totp.id, code: value });
      return error ? { ok: false, error: "That code didn't work. Check the time on your phone and try a new code." } : { ok: true };
    }
  }

  // The current password, checked without touching this device's sign-in.
  const guard = async (event: "check" | "fail" | "ok") => {
    const { data, error } = await createAdminClient().rpc("sign_in_guard", { p_email: email, p_event: event });
    return error ? 0 : Number(data ?? 0);
  };
  if ((await guard("check")) > 0) return { ok: false, error: "Too many wrong passwords. Please wait 15 minutes and try again." };
  const probe = createSupabase(env.supabaseUrl, env.supabaseAnonKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { error } = await probe.auth.signInWithPassword({ email, password: value });
  if (error) {
    await guard("fail");
    return { ok: false, error: "That password isn't right." };
  }
  await guard("ok");
  // End the check's own sign-in straight away (only that one).
  await probe.auth.signOut({ scope: "local" });
  return { ok: true };
}

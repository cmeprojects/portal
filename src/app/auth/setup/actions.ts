// Staff Portal · © cmeproject. All rights reserved.
"use server";

import type { EmailOtpType } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { safeNext } from "@/lib/safe-next";
import { PORTAL_LOCK_COOKIE } from "@/lib/app-lock";

const TYPES = ["invite", "recovery", "magiclink", "email", "signup"];

// cmeprojects: use the one-time link (only when the person presses the button).
export async function useOneTimeLink(_: { error?: string } | null, form: FormData): Promise<{ error?: string }> {
  const tokenHash = String(form.get("token_hash") ?? "");
  const type = String(form.get("type") ?? "");
  if (!tokenHash || !TYPES.includes(type)) return { error: "This link isn't complete. Open it again from the email." };
  const supabase = await createClient();
  const { error } = await supabase.auth.verifyOtp({ type: type as EmailOtpType, token_hash: tokenHash });
  if (error) return { error: "This link has expired or was already used. Ask for a new one." };
  (await cookies()).delete(PORTAL_LOCK_COOKIE);
  // A new starter who never finished setting up goes to set up (name and password).
  const { data: claims } = await supabase.auth.getClaims();
  const me = claims?.claims?.sub
    ? (await supabase.from("profiles").select("role, joined_at").eq("id", claims.claims.sub).maybeSingle()).data
    : null;
  if (me?.role === "new_starter" && !me.joined_at) redirect("/welcome");
  redirect(type === "invite" ? "/welcome" : type === "recovery" ? "/set-password" : safeNext(String(form.get("next") ?? "")));
}

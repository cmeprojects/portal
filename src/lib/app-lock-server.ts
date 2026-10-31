// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";

// Signed in with their password (or a link) in the last two minutes: the
// app doesn't ask for the PIN straight after.
export async function signedInLately(): Promise<boolean> {
  const { data } = await (await createClient()).auth.getClaims();
  const amr = (data?.claims?.amr ?? []) as { timestamp?: number }[];
  const at = Math.max(0, ...amr.map((a) => (a.timestamp ?? 0) * 1000));
  return at > 0 && Date.now() - at < 120_000;
}

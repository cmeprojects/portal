// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects: sign out every other device; this one stays signed in.
export async function signOutOtherDevices(): Promise<FormState> {
  await requireSession();
  const { data, error } = await (await createClient()).rpc("sign_out_my_other_devices");
  if (error) return { error: error.code === "PGRST202" ? "This needs the latest database update (update 45)." : friendlyError(error) };
  const n = Number(data ?? 0);
  return { message: n ? `Signed out ${n} other device${n === 1 ? "" : "s"}. This one stays signed in.` : "No other devices were signed in." };
}

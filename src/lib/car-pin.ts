// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";

// Has this person chosen a PIN for the Cars app? (PINs are never readable from the browser.)
export async function hasPin(userId: string): Promise<boolean> {
  const { data } = await createAdminClient().from("car_app_pins").select("user_id").eq("user_id", userId).maybeSingle();
  return Boolean(data);
}

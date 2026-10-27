// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@supabase/supabase-js";
import { env } from "@/lib/env";

// Service-role client: bypasses Row Level Security. Only used on the server
// for sign-in admin jobs (sending invites, blocking a deactivated person),
// and only after the same change has been accepted by the database as the
// signed-in person.
export function createAdminClient() {
  return createClient(env.supabaseUrl, env.serviceRoleKey(), {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

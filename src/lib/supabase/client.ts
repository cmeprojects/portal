// Staff Portal · © cmeproject. All rights reserved.
import { createBrowserClient } from "@supabase/ssr";

// Supabase client for the browser (used for two-factor setup).
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}

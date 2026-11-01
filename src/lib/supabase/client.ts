// Staff Portal · © cmeproject. All rights reserved.
import { createBrowserClient } from "@supabase/ssr";

// Supabase client for the browser (two-factor set-up, uploads, live updates).
// cmeprojects: the server keeps the sign-in fresh on every page and action.
// The browser doesn't refresh it on its own timer as well: when a phone wakes
// up, both refreshing at once looks like a reused token to Supabase, which
// then ends the session (people were "signed out when inactive").
export function createClient() {
  return createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    auth: { autoRefreshToken: false },
  });
}

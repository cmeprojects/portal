// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Notice } from "@/components/ui";

// cmeprojects: Supabase's own emails (used when the portal's email service
// isn't set up) put the sign-in in the address after "#", which the server
// can't see. Pick it up here and carry on to setting a password.
export function HashLink() {
  const [error, setError] = useState("");
  useEffect(() => {
    const h = new URLSearchParams(window.location.hash.slice(1));
    if (h.get("error_description")) {
      const msg = h.get("error_code") === "otp_expired" ? "That link has expired or was already used. Ask for a new one below." : (h.get("error_description") ?? "");
      queueMicrotask(() => setError(msg));
      return;
    }
    const access = h.get("access_token");
    const refresh = h.get("refresh_token");
    if (!access || !refresh) return;
    const type = h.get("type");
    createClient()
      .auth.setSession({ access_token: access, refresh_token: refresh })
      .then(({ error: e }) => {
        if (e) return setError("That link has expired or was already used. Ask for a new one below.");
        window.location.replace(type === "invite" ? "/welcome" : type === "recovery" ? "/set-password" : "/");
      });
  }, []);
  return error ? <Notice tone="error">{error}</Notice> : null;
}

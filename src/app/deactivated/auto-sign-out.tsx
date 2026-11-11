// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";
import { signOutDeactivated } from "@/app/login/actions";
import { saveRememberedEmail } from "@/lib/remembered-email";

// Signs a turned-off account out as soon as this page shows, and forgets the
// email this device remembered for the sign-in page (cmeprojects).
export function AutoSignOut() {
  useEffect(() => {
    saveRememberedEmail(null);
    void signOutDeactivated();
  }, []);
  return null;
}

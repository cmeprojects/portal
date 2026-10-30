// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";
import { signOutDeactivated } from "@/app/login/actions";

// Signs a turned-off account out as soon as this page shows.
export function AutoSignOut() {
  useEffect(() => {
    void signOutDeactivated();
  }, []);
  return null;
}

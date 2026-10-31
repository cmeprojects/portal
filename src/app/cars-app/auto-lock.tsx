// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

const KEY = "app-unlocked";
const AWAY = "app-away-since";
// A quick look at another app (the camera, a message) doesn't lock it.
const GRACE_MS = 60_000;

// cmeprojects: the phone apps ask for the PIN each time they're opened, and
// after being away from them for more than a minute (unless the person turned
// the PIN off in Settings). The server also locks after 15 minutes.
export function AppAutoLock({ base, pinOff, justSignedIn }: { base: string; pinOff: boolean; justSignedIn: boolean }) {
  const path = usePathname();

  useEffect(() => {
    if (pinOff || path.startsWith(`${base}/unlock`)) return;
    const lock = () => {
      try {
        sessionStorage.removeItem(KEY);
      } catch {}
      window.location.replace(`${base}/unlock`);
    };
    const params = new URLSearchParams(window.location.search);
    let unlocked = false;
    try {
      // Just entered the PIN, or just signed in with their password.
      if (params.has("unlocked") || justSignedIn) sessionStorage.setItem(KEY, String(Date.now()));
      unlocked = Boolean(sessionStorage.getItem(KEY));
    } catch {
      unlocked = true;
    }
    // A fresh opening of the app: PIN first.
    if (!unlocked) return lock();

    const onVisibility = () => {
      try {
        if (document.visibilityState === "hidden") sessionStorage.setItem(AWAY, String(Date.now()));
        else {
          const since = Number(sessionStorage.getItem(AWAY) ?? 0);
          sessionStorage.removeItem(AWAY);
          if (since && Date.now() - since > GRACE_MS) lock();
        }
      } catch {}
    };
    document.addEventListener("visibilitychange", onVisibility);
    return () => document.removeEventListener("visibilitychange", onVisibility);
  }, [base, pinOff, path, justSignedIn]);

  return null;
}

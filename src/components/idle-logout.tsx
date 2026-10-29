// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useCallback, useEffect, useState } from "react";
import { Button } from "@/components/ui";
import { signOutIdle } from "@/app/login/actions";

// Shared with the proxy, which signs people out on their next visit if the
// browser was closed for longer than the limit.
export const LAST_ACTIVE = "portal_last_active";
export const IDLE_MINUTES = "portal_idle_minutes";

function setCookie(name: string, value: string) {
  document.cookie = `${name}=${value}; path=/; max-age=31536000; samesite=lax${location.protocol === "https:" ? "; secure" : ""}`;
}

function lastActive(): number {
  const m = document.cookie.match(new RegExp(`(?:^|; )${LAST_ACTIVE}=(\\d+)`));
  return m ? Number(m[1]) : Date.now();
}

// Signs people out after a set time without activity, with a one-minute
// warning. Activity in any tab counts.
export function IdleLogout({ minutes }: { minutes: number }) {
  const [warning, setWarning] = useState(false);
  const limit = minutes * 60_000;

  const touch = useCallback(() => {
    setCookie(LAST_ACTIVE, String(Date.now()));
    setWarning(false);
  }, []);

  useEffect(() => {
    setCookie(IDLE_MINUTES, String(minutes));
    if (!minutes) return;
    if (Date.now() - lastActive() > limit) {
      void signOutIdle();
      return;
    }
    setCookie(LAST_ACTIVE, String(Date.now()));
    let last = 0;
    const onActivity = () => {
      if (Date.now() - last < 30_000) return; // at most every 30 seconds
      last = Date.now();
      setCookie(LAST_ACTIVE, String(last));
    };
    const events = ["pointerdown", "keydown", "scroll", "touchstart"] as const;
    events.forEach((e) => window.addEventListener(e, onActivity, { passive: true }));
    const timer = window.setInterval(() => {
      const idle = Date.now() - lastActive();
      if (idle > limit) void signOutIdle();
      else setWarning(idle > limit - 60_000);
    }, 15_000);
    return () => {
      events.forEach((e) => window.removeEventListener(e, onActivity));
      window.clearInterval(timer);
    };
  }, [minutes, limit]);

  if (!warning) return null;
  return (
    <div role="alertdialog" aria-live="assertive" aria-label="You're about to be signed out" className="fixed inset-x-4 bottom-4 z-50 mx-auto flex max-w-md flex-col gap-3 rounded-xl border border-line bg-surface p-4 text-ink shadow-xl sm:flex-row sm:items-center">
      <p className="flex-1 text-sm">You&apos;ll be signed out in about a minute because you haven&apos;t been active.</p>
      <Button onClick={touch}>Stay signed in</Button>
    </div>
  );
}

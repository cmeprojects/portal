// Staff Portal · © cmeproject. All rights reserved.
"use client";

// cmeprojects: the "Remember my email on this device" choice on the sign-in
// page. Only the email address is kept, in this browser's storage; never a
// password, token or anything else. Off unless the person ticks it, and
// "Use a different account" or a turned-off account clears it.
const KEY = "portal.remembered-email";
const listeners = new Set<() => void>();

export function readRememberedEmail(): string | null {
  try {
    return window.localStorage.getItem(KEY);
  } catch {
    return null;
  }
}

export function saveRememberedEmail(email: string | null) {
  try {
    if (email) window.localStorage.setItem(KEY, email);
    else window.localStorage.removeItem(KEY);
  } catch {
    // Private browsing or blocked storage: the sign-in page just won't remember.
  }
  listeners.forEach((l) => l());
}

export function subscribeRememberedEmail(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

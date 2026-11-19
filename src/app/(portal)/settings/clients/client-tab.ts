// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useSyncExternalStore } from "react";

// cmeprojects (owner, 19 Nov 2026): the client list's scheme tab (NDIS, Support
// at Home, CHSP …), remembered on this device and shared by the list, the page
// title and the New button, so they all use the same word.
const TAB_KEY = "portal.clientSchemeTab";
const TAB_EVENT = "portal-client-tab";
const readTab = () => {
  try {
    return window.localStorage.getItem(TAB_KEY) ?? "";
  } catch {
    return "";
  }
};
const watchTab = (cb: () => void) => {
  window.addEventListener("storage", cb);
  window.addEventListener(TAB_EVENT, cb);
  return () => {
    window.removeEventListener("storage", cb);
    window.removeEventListener(TAB_EVENT, cb);
  };
};

export function useStoredClientTab() {
  return useSyncExternalStore(watchTab, readTab, () => "");
}

export function storeClientTab(v: string) {
  try {
    window.localStorage.setItem(TAB_KEY, v);
  } catch {
    /* private window: not remembered */
  }
  window.dispatchEvent(new Event(TAB_EVENT));
}

// The word for each scheme's people: NDIS participants, aged care clients. A word
// set in Programs and schemes wins; otherwise the organisation's own word.
export const DEFAULT_WORD: Record<string, string> = { ndis: "Participant", support_at_home: "Client", chsp: "Client" };
export const pluralOf = (w: string) => (w.endsWith("s") ? w : `${w}s`);
export function wordForTab(tab: string, word: string, schemeWords: Record<string, string> = {}) {
  return (tab && (schemeWords[tab] || DEFAULT_WORD[tab])) || word;
}

// The tab now showing (a scheme that exists, or "" for All).
export function useClientTab(schemes: [string, string][]) {
  const stored = useStoredClientTab();
  return schemes.some(([k]) => k === stored) ? stored : "";
}

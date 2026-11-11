// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";

// cmeprojects: choosing a section in the onboarding list (or opening a link
// to one) unfolds it, then scrolls to it.
export function OpenSectionOnHash() {
  useEffect(() => {
    const open = () => {
      const id = decodeURIComponent(window.location.hash.slice(1));
      const el = id ? document.getElementById(id) : null;
      if (el instanceof HTMLDetailsElement && !el.open) {
        el.open = true;
        el.scrollIntoView({ block: "start" });
      }
    };
    open();
    window.addEventListener("hashchange", open);
    return () => window.removeEventListener("hashchange", open);
  }, []);
  return null;
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";

// cmeprojects: the roster's small menus (<details data-menu>) close on a click
// elsewhere or Esc, like any menu.
export function CloseMenus() {
  useEffect(() => {
    const closeAll = (except?: Node | null) => {
      document.querySelectorAll<HTMLDetailsElement>("details[data-menu][open]").forEach((d) => {
        if (!except || !d.contains(except)) d.open = false;
      });
    };
    const onDown = (e: MouseEvent) => closeAll(e.target as Node);
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") closeAll();
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, []);
  return null;
}

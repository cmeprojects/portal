// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";

// cmeprojects: the calendar fills the screen below the toolbar and scrolls on
// its own, so the title, figures and toolbar stay in view.
export function FitCalendar() {
  useEffect(() => {
    const grid = document.querySelector<HTMLElement>(".roster-grid");
    if (!grid) return;
    const fit = () => {
      if (window.innerWidth < 768) {
        grid.style.height = "";
        return;
      }
      const top = grid.getBoundingClientRect().top + window.scrollY;
      grid.style.height = `${Math.max(384, window.innerHeight - top - 36)}px`;
    };
    fit();
    window.addEventListener("resize", fit);
    const t = window.setTimeout(fit, 400);
    return () => {
      window.removeEventListener("resize", fit);
      window.clearTimeout(t);
    };
  }, []);
  return null;
}

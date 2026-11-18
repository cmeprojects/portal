// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";

// cmeprojects: after a shift is added or changed (or its panel is closed),
// the roster dims for a moment while that shift stays lit with a short tag
// saying why, and the page scrolls to it. Calm, and skipped motion for people
// who ask for reduced motion (the outline and tag still show).
export function Spotlight({ id, label }: { id: string; label: string }) {
  useEffect(() => {
    // A drag-and-drop copy is no longer needed once the fresh roster is here.
    document.querySelectorAll("[data-dnd-ghost]").forEach((g) => g.remove());
    let grid: HTMLElement | null = null;
    let el: HTMLElement | null = null;
    // Start just after the page settles (it refreshes once after a save).
    const start = window.setTimeout(() => {
      el = document.querySelector<HTMLElement>(`[data-shift-id="${CSS.escape(id)}"]`);
      grid = document.querySelector<HTMLElement>(".roster-grid");
      if (!el || !grid) return;
      el.dataset.spotLabel = label;
      el.dataset.spotlit = "on";
      grid.dataset.spotlight = "on";
      el.scrollIntoView({ block: "center", inline: "center", behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
      // Drop the marker from the address so a refresh doesn't replay it.
      const url = new URL(window.location.href);
      url.searchParams.delete("spot");
      url.searchParams.delete("spotlabel");
      window.history.replaceState(window.history.state, "", url);
    }, 250);
    const stop = window.setTimeout(() => {
      if (grid) delete grid.dataset.spotlight;
      if (el) delete el.dataset.spotlit;
    }, 3000);
    return () => {
      window.clearTimeout(start);
      window.clearTimeout(stop);
      if (grid) delete grid.dataset.spotlight;
      if (el) delete el.dataset.spotlit;
    };
  }, [id, label]);
  return null;
}

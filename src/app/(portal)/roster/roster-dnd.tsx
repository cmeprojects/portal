// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useTransition } from "react";
import { useRouter } from "next/navigation";
import { moveShift } from "./actions";

// cmeprojects: drag a shift to another day or worker (or to Vacant). The shift
// follows the mouse, the cell under it lights up, and on drop it sits in the
// new cell at once while the server checks. If the move is refused it goes
// back. Nothing is left behind once the fresh roster arrives.
export function RosterDnd({ byClient, base }: { byClient: boolean; base: string }) {
  const router = useRouter();
  const [, startTransition] = useTransition();
  useEffect(() => {
    const grid = document.querySelector<HTMLElement>(".roster-grid");
    if (!grid) return;
    let chip: HTMLElement | null = null;
    let float: HTMLElement | null = null;
    let over: HTMLElement | null = null;
    let startX = 0;
    let startY = 0;
    let offX = 0;
    let offY = 0;
    let x = 0;
    let y = 0;
    let frame = 0;
    let dragging = false;
    let swallowClick = false;

    const cellAt = (px: number, py: number) => {
      const el = document.elementFromPoint(px, py);
      return el instanceof Element ? el.closest<HTMLElement>(".roster-grid [data-drop-date]") : null;
    };
    const light = (cell: HTMLElement | null) => {
      if (over === cell) return;
      if (over) delete over.dataset.dropOver;
      over = cell;
      if (cell) cell.dataset.dropOver = "on";
    };
    // Scroll the calendar when the shift is held near its edge.
    const edgeScroll = () => {
      const box = grid.getBoundingClientRect();
      const edge = 40;
      let dx = 0;
      let dy = 0;
      if (x < box.left + edge) dx = -12;
      else if (x > box.right - edge) dx = 12;
      if (y < box.top + edge) dy = -12;
      else if (y > box.bottom - edge) dy = 12;
      if (dx || dy) grid.scrollBy(dx, dy);
    };
    const tick = () => {
      frame = 0;
      if (!float) return;
      float.style.transform = `translate3d(${x - offX}px, ${y - offY}px, 0) rotate(1.5deg)`;
      edgeScroll();
      light(cellAt(x, y));
      if (dragging) frame = requestAnimationFrame(tick);
    };
    const finish = () => {
      if (frame) cancelAnimationFrame(frame);
      frame = 0;
      float?.remove();
      float = null;
      light(null);
      delete grid.dataset.dragging;
      document.body.style.userSelect = "";
      dragging = false;
    };
    const begin = () => {
      if (!chip) return;
      dragging = true;
      const box = chip.getBoundingClientRect();
      offX = startX - box.left;
      offY = startY - box.top;
      float = chip.cloneNode(true) as HTMLElement;
      float.removeAttribute("data-shift-id");
      float.removeAttribute("href");
      float.setAttribute("aria-hidden", "true");
      Object.assign(float.style, {
        position: "fixed",
        left: "0",
        top: "0",
        width: `${box.width}px`,
        zIndex: "70",
        pointerEvents: "none",
        boxShadow: "0 8px 20px rgb(0 0 0 / 0.18)",
        cursor: "grabbing",
        willChange: "transform",
      });
      document.body.appendChild(float);
      chip.style.opacity = "0.35";
      grid.dataset.dragging = "on";
      document.body.style.userSelect = "none";
      frame = requestAnimationFrame(tick);
    };

    const onDown = (e: PointerEvent) => {
      if (e.button !== 0 || e.pointerType === "touch") return;
      const c = e.target instanceof Element ? e.target.closest<HTMLElement>("[data-shift-id][data-can-drag]") : null;
      if (!c) return;
      chip = c;
      startX = x = e.clientX;
      startY = y = e.clientY;
      window.addEventListener("pointermove", onMove);
      window.addEventListener("pointerup", onUp);
    };
    const onMove = (e: PointerEvent) => {
      x = e.clientX;
      y = e.clientY;
      if (!dragging && Math.hypot(x - startX, y - startY) > 5) begin();
      if (dragging && !frame) frame = requestAnimationFrame(tick);
    };
    const stopListening = () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
    };
    const onUp = (e: PointerEvent) => {
      stopListening();
      const moved = chip;
      chip = null;
      if (!dragging || !moved) return;
      swallowClick = true;
      const cell = cellAt(e.clientX, e.clientY);
      finish();
      const id = moved.dataset.shiftId ?? "";
      const home = moved.closest<HTMLElement>("[data-drop-date]");
      if (!cell || !id || cell === home) {
        moved.style.opacity = "";
        return;
      }
      drop(moved, id, cell);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== "Escape" || !dragging) return;
      stopListening();
      if (chip) chip.style.opacity = "";
      chip = null;
      finish();
    };
    // A drag ends with a click on the shift: don't open it.
    const onClick = (e: MouseEvent) => {
      if (!swallowClick) return;
      swallowClick = false;
      e.preventDefault();
      e.stopPropagation();
    };

    const drop = (moved: HTMLElement, id: string, cell: HTMLElement) => {
      const date = cell.dataset.dropDate ?? "";
      const row = cell.dataset.dropRow ?? "";
      // Sit it in the new cell straight away, as a copy, and hide the original.
      const copy = moved.cloneNode(true) as HTMLElement;
      copy.removeAttribute("data-shift-id");
      copy.removeAttribute("href");
      copy.setAttribute("aria-hidden", "true");
      copy.dataset.dndGhost = "on";
      copy.style.opacity = "0.85";
      cell.appendChild(copy);
      moved.style.display = "none";
      let watch: MutationObserver | null = null;
      let safety = 0;
      const tidy = () => {
        watch?.disconnect();
        window.clearTimeout(safety);
        copy.remove();
        moved.style.display = "";
        moved.style.opacity = "";
      };
      startTransition(async () => {
        const res = await moveShift(id, date, row, byClient);
        if (res?.error) {
          tidy();
          router.push(`${base}&saved=${encodeURIComponent(`Not moved: ${res.error}`)}`, { scroll: false });
          return;
        }
        if (!res?.message) return tidy();
        // The copy goes the moment the real shift shows up in its new place.
        watch = new MutationObserver(() => {
          const real = grid.querySelector<HTMLElement>(`[data-shift-id="${CSS.escape(id)}"]`);
          if (real && real !== moved) tidy();
        });
        watch.observe(grid, { childList: true, subtree: true });
        safety = window.setTimeout(tidy, 8000);
        router.push(`${base}&saved=${encodeURIComponent(res.message)}&spot=${id}&spotlabel=moved`, { scroll: false });
      });
    };

    grid.addEventListener("pointerdown", onDown);
    grid.addEventListener("click", onClick, true);
    window.addEventListener("keydown", onKey);
    return () => {
      stopListening();
      finish();
      grid.removeEventListener("pointerdown", onDown);
      grid.removeEventListener("click", onClick, true);
      window.removeEventListener("keydown", onKey);
    };
  }, [byClient, base, router]);
  return null;
}

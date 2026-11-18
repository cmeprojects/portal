// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useTransition } from "react";
import { useRouter } from "next/navigation";
import { moveShift } from "./actions";

// cmeprojects: drag a shift to another day or worker (or to Vacant). The
// roster lights the cell under it; the database decides if the move is allowed.
export function RosterDnd({ byClient, base }: { byClient: boolean; base: string }) {
  const router = useRouter();
  const [, startTransition] = useTransition();
  useEffect(() => {
    const grid = document.querySelector<HTMLElement>(".roster-grid");
    if (!grid) return;
    let dragging = "";
    let over: HTMLElement | null = null;
    const cellOf = (t: EventTarget | null) => (t instanceof Element ? t.closest<HTMLElement>("[data-drop-date]") : null);
    const clear = () => {
      if (over) delete over.dataset.dropOver;
      over = null;
    };
    const onStart = (e: DragEvent) => {
      const chip = e.target instanceof Element ? e.target.closest<HTMLElement>("[data-shift-id][draggable='true']") : null;
      if (!chip || !e.dataTransfer) return;
      dragging = chip.dataset.shiftId ?? "";
      e.dataTransfer.effectAllowed = "move";
      e.dataTransfer.setData("text/plain", dragging);
      grid.dataset.dragging = "on";
    };
    const onOver = (e: DragEvent) => {
      if (!dragging) return;
      const cell = cellOf(e.target);
      if (!cell) return;
      e.preventDefault();
      if (e.dataTransfer) e.dataTransfer.dropEffect = "move";
      if (over !== cell) {
        clear();
        over = cell;
        cell.dataset.dropOver = "on";
      }
    };
    const onEnd = () => {
      dragging = "";
      clear();
      delete grid.dataset.dragging;
    };
    const onDrop = (e: DragEvent) => {
      const cell = cellOf(e.target);
      const id = dragging || e.dataTransfer?.getData("text/plain") || "";
      onEnd();
      if (!cell || !id) return;
      e.preventDefault();
      const date = cell.dataset.dropDate ?? "";
      const row = cell.dataset.dropRow ?? "";
      startTransition(async () => {
        const res = await moveShift(id, date, row, byClient);
        if (res?.error) router.push(`${base}&saved=${encodeURIComponent(`Not moved: ${res.error}`)}`, { scroll: false });
        else if (res?.message) router.push(`${base}&saved=${encodeURIComponent(res.message)}&spot=${id}&spotlabel=moved`, { scroll: false });
      });
    };
    grid.addEventListener("dragstart", onStart);
    grid.addEventListener("dragover", onOver);
    grid.addEventListener("drop", onDrop);
    grid.addEventListener("dragend", onEnd);
    return () => {
      grid.removeEventListener("dragstart", onStart);
      grid.removeEventListener("dragover", onOver);
      grid.removeEventListener("drop", onDrop);
      grid.removeEventListener("dragend", onEnd);
    };
  }, [byClient, base, router]);
  return null;
}

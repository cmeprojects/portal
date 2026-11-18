// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { askConfirm } from "@/components/confirm";
import { cancelShiftNow, pasteShift } from "./actions";

type Menu = { x: number; y: number; shift?: string; date?: string; row?: string; nextDate?: string };
const addDay = (d: string) => {
  const t = new Date(`${d}T12:00:00Z`);
  t.setUTCDate(t.getUTCDate() + 1);
  return t.toISOString().slice(0, 10);
};

// cmeprojects: right-click a shift (Open, Copy, Copy to next day, Cancel) or a
// cell (Paste here). Ctrl+C / Ctrl+V work too. Pasted shifts are drafts.
export function RosterMenu({ byClient, base }: { byClient: boolean; base: string }) {
  const router = useRouter();
  const [, start] = useTransition();
  const [menu, setMenu] = useState<Menu | null>(null);
  const [copied, setCopied] = useState<string>("");
  const [hover, setHover] = useState<{ shift?: string; date?: string; row?: string }>({});

  const paste = (id: string, date: string, row: string) =>
    start(async () => {
      const res = await pasteShift(id, date, row, byClient);
      if (res?.error) router.push(`${base}&saved=${encodeURIComponent(`Not pasted: ${res.error}`)}`, { scroll: false });
      else router.push(`${base}&saved=${encodeURIComponent(res?.message ?? "Pasted.")}&spot=${res?.spotlight ?? ""}&spotlabel=added`, { scroll: false });
    });

  useEffect(() => {
    const grid = document.querySelector<HTMLElement>(".roster-grid");
    if (!grid) return;
    const where = (t: EventTarget | null) => {
      const el = t instanceof Element ? t : null;
      const chip = el?.closest<HTMLElement>("[data-shift-id]");
      const cell = el?.closest<HTMLElement>("[data-drop-date]");
      return { shift: chip?.dataset.shiftId, date: cell?.dataset.dropDate, row: cell?.dataset.dropRow };
    };
    const onMenu = (e: MouseEvent) => {
      const w = where(e.target);
      if (!w.shift && !w.date) return;
      e.preventDefault();
      setMenu({ x: e.clientX, y: e.clientY, ...w, nextDate: w.date ? addDay(w.date) : undefined });
    };
    const onMove = (e: MouseEvent) => setHover(where(e.target));
    grid.addEventListener("contextmenu", onMenu);
    grid.addEventListener("mouseover", onMove);
    return () => {
      grid.removeEventListener("contextmenu", onMenu);
      grid.removeEventListener("mouseover", onMove);
    };
  }, []);

  // Keyboard: Ctrl/Cmd+C on a shift, Ctrl/Cmd+V on a cell.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (!(e.ctrlKey || e.metaKey) || (e.target instanceof HTMLElement && /^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName))) return;
      if (e.key === "c" && hover.shift) {
        setCopied(hover.shift);
      } else if (e.key === "v" && copied && hover.date && hover.row) {
        e.preventDefault();
        paste(copied, hover.date, hover.row);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  useEffect(() => {
    if (!menu) return;
    const close = () => setMenu(null);
    const esc = (e: KeyboardEvent) => e.key === "Escape" && close();
    window.addEventListener("click", close);
    window.addEventListener("scroll", close, true);
    window.addEventListener("keydown", esc);
    return () => {
      window.removeEventListener("click", close);
      window.removeEventListener("scroll", close, true);
      window.removeEventListener("keydown", esc);
    };
  }, [menu]);

  if (!menu) return copied ? <p className="sr-only" role="status">Shift copied. Right-click a cell and choose Paste here.</p> : null;
  const item = "block w-full px-3 py-1.5 text-left text-sm hover:bg-page disabled:cursor-not-allowed disabled:opacity-50";
  return (
    <div role="menu" style={{ left: Math.min(menu.x, window.innerWidth - 220), top: Math.min(menu.y, window.innerHeight - 220) }} className="fixed z-[70] w-52 overflow-hidden rounded-lg border border-line bg-surface py-1 shadow-xl">
      {menu.shift ? (
        <>
          <button role="menuitem" className={item} onClick={() => router.push(`${base}&shift=${menu.shift}`, { scroll: false })}>
            Open
          </button>
          <button role="menuitem" className={item} onClick={() => setCopied(menu.shift!)}>
            Copy
          </button>
          {menu.nextDate && menu.row ? (
            <button role="menuitem" className={item} onClick={() => paste(menu.shift!, menu.nextDate!, menu.row!)}>
              Copy to next day
            </button>
          ) : null}
          <button
            role="menuitem"
            className={`${item} text-danger`}
            onClick={() =>
              void askConfirm("Cancel this shift? It stays in the log, and a worker who was told is told again.", { action: "Cancel the shift" }).then((ok) => {
                if (!ok) return;
                start(async () => {
                  const res = await cancelShiftNow(menu.shift!);
                  router.push(`${base}&saved=${encodeURIComponent(res?.error ? `Not cancelled: ${res.error}` : "Shift cancelled.")}`, { scroll: false });
                });
              })
            }
          >
            Cancel shift
          </button>
        </>
      ) : null}
      {menu.date && menu.row ? (
        <button role="menuitem" className={`${item} ${menu.shift ? "border-t border-line" : ""}`} disabled={!copied} onClick={() => paste(copied, menu.date!, menu.row!)}>
          {copied ? "Paste here (as a draft)" : "Paste here (copy a shift first)"}
        </button>
      ) : null}
    </div>
  );
}

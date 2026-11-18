// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState } from "react";
import { ChevronDown, Send } from "lucide-react";
import { buttonClass } from "@/components/ui";
import { publishWeek } from "./actions";

export type PublishPeriod = { key: string; label: string; dates: string; from: string; to: string; drafts: number; workers: number };

// cmeprojects: Publish the view on screen, or pick another period from the
// menu beside it. Either way, what will be published is shown before confirming.
export function PublishControl({ periods }: { periods: PublishPeriod[] }) {
  const [menu, setMenu] = useState(false);
  const [chosen, setChosen] = useState<PublishPeriod | null>(null);
  const current = periods[0];
  const box = useRef<HTMLSpanElement>(null);
  // Close the menu on a click elsewhere or Esc.
  useEffect(() => {
    if (!menu) return;
    const away = (e: MouseEvent) => {
      if (box.current && !box.current.contains(e.target as Node)) setMenu(false);
    };
    const esc = (e: KeyboardEvent) => {
      if (e.key === "Escape") setMenu(false);
    };
    document.addEventListener("mousedown", away);
    document.addEventListener("keydown", esc);
    return () => {
      document.removeEventListener("mousedown", away);
      document.removeEventListener("keydown", esc);
    };
  }, [menu]);
  return (
    <span ref={box} className="relative inline-flex">
      <button type="button" onClick={() => setChosen(current)} disabled={!current.drafts} className={`${buttonClass("outline")} rounded-r-none`}>
        <Send aria-hidden="true" className="size-4" />
        Publish shifts{current.drafts ? ` (${current.drafts})` : ""}
      </button>
      <button type="button" aria-label="Choose what to publish" aria-expanded={menu} onClick={() => setMenu(!menu)} className={`${buttonClass("outline")} -ml-px rounded-l-none px-2`}>
        <ChevronDown aria-hidden="true" className="size-4" />
      </button>
      {menu ? (
        <div className="absolute top-full right-0 z-30 mt-1 w-72 overflow-hidden rounded-lg border border-line bg-surface shadow-lg">
          {periods.map((p) => (
            <button
              key={p.key}
              type="button"
              disabled={!p.drafts}
              onClick={() => {
                setMenu(false);
                setChosen(p);
              }}
              className="block w-full border-b border-line px-3 py-2 text-left text-sm font-semibold last:border-b-0 hover:bg-page disabled:cursor-not-allowed disabled:opacity-50"
            >
              {p.label} ({p.drafts} draft{p.drafts === 1 ? "" : "s"})
              <span className="block text-xs font-normal text-muted">{p.dates}</span>
            </button>
          ))}
        </div>
      ) : null}
      {chosen ? (
        <div role="dialog" aria-modal="true" aria-labelledby="publish-title" className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
          <div className="w-full max-w-md rounded-xl border border-line bg-surface p-5 shadow-2xl">
            <h2 id="publish-title" className="heading-sm">
              Publish {chosen.label.toLowerCase()}?
            </h2>
            <dl className="mt-3 grid grid-cols-[7rem_1fr] gap-y-1 text-sm">
              <dt className="text-muted">Covers</dt>
              <dd className="font-semibold">{chosen.dates}</dd>
              <dt className="text-muted">Draft shifts</dt>
              <dd className="font-semibold">{chosen.drafts}</dd>
              <dt className="text-muted">Workers told</dt>
              <dd className="font-semibold">{chosen.workers}</dd>
            </dl>
            <p className="mt-2 text-xs text-muted">Only drafts in these dates are published. Shifts outside them stay as they are. Vacant shifts become open shifts staff can put their hand up for.</p>
            <form action={publishWeek} onSubmit={() => setChosen(null)} className="mt-4 flex justify-end gap-2">
              <input type="hidden" name="from" value={chosen.from} />
              <input type="hidden" name="to" value={chosen.to} />
              <button type="button" onClick={() => setChosen(null)} className={buttonClass("outline")}>
                Cancel
              </button>
              <button className={buttonClass("primary")}>Publish {chosen.drafts} shift{chosen.drafts === 1 ? "" : "s"}</button>
            </form>
          </div>
        </div>
      ) : null}
    </span>
  );
}

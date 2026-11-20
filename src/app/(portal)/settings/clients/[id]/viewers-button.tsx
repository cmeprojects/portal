// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";
import { Eye, X } from "lucide-react";

export type Viewer = { name: string; first: string; last: string; times: number };

// cmeprojects (owner, 20 Nov 2026): who has opened this client's page, ever, in
// a small pop-up from an icon next to Edit (only people who assign staff to
// this client see it). Each person is recorded at most once an hour.
export function ViewersButton({ viewers }: { viewers: Viewer[] }) {
  const [open, setOpen] = useState(false);
  useEffect(() => {
    if (!open) return;
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [open]);
  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        title="Who opened this page"
        aria-label={`Who opened this page (${viewers.length})`}
        className="relative inline-flex size-9 items-center justify-center rounded-lg border border-line text-muted hover:bg-page hover:text-ink"
      >
        <Eye aria-hidden="true" className="size-4" />
        {viewers.length ? <span className="absolute -top-1.5 -right-1.5 rounded-full bg-ink px-1.5 text-[10px] leading-4 font-bold text-white">{viewers.length}</span> : null}
      </button>
      {open ? (
        <>
          <button type="button" aria-label="Close" onClick={() => setOpen(false)} className="fixed inset-0 z-40 bg-black/30" />
          <div role="dialog" aria-modal="true" aria-label="Who opened this page" className="fixed inset-x-4 top-[10vh] z-50 mx-auto flex max-h-[80vh] max-w-lg flex-col overflow-hidden rounded-xl bg-surface shadow-2xl">
            <div className="flex items-center gap-2 border-b border-line px-4 py-3">
              <Eye aria-hidden="true" className="size-4 text-brand" />
              <h2 className="heading-sm flex-1">Who opened this page</h2>
              <button type="button" onClick={() => setOpen(false)} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
                <X aria-hidden="true" className="size-5" />
              </button>
            </div>
            <div className="thin-scroll overflow-y-auto p-4">
              <p className="mb-3 text-xs text-muted">Everyone who has opened it, most recent first. Recorded at most once an hour for each person.</p>
              {viewers.length ? (
                <ul className="divide-y divide-line rounded-md border border-line text-sm">
                  {viewers.map((v) => (
                    <li key={v.name + v.last} className="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-0.5 px-3 py-2">
                      <span className="font-semibold">{v.name}</span>
                      <span className="text-xs text-muted">
                        last {v.last} · first {v.first} · {v.times} time{v.times === 1 ? "" : "s"}
                      </span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted">Nobody yet.</p>
              )}
            </div>
          </div>
        </>
      ) : null}
    </>
  );
}

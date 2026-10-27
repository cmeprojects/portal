// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { markAllSeen } from "./bell-actions";

export type BellItem = { id: string; ref: string; title: string; kind: "assigned" | "helping"; by: string; when: string };

// The bell beside the logo: tasks newly given to you. Opening one clears it.
export function Bell({ items }: { items: BellItem[] }) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const count = items.length;
  const words = count ? `${count} new task${count === 1 ? "" : "s"} for you` : "No new tasks";

  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent | KeyboardEvent) => {
      if (e instanceof KeyboardEvent ? e.key === "Escape" : !box.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", close);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", close);
    };
  }, [open]);

  return (
    <div ref={box} className="relative">
      <button
        type="button"
        aria-label={words}
        title={words}
        aria-expanded={open}
        onClick={() => setOpen(!open)}
        className={`relative inline-flex size-11 items-center justify-center rounded-full hover:bg-side-hover md:size-9 ${count ? "text-side-fg" : "text-side-muted"}`}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" />
          <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" />
        </svg>
        {count > 0 ? (
          <span className="absolute -top-0.5 -right-0.5 grid min-w-[18px] place-items-center rounded-full bg-[#d64545] px-1 text-[10px] leading-[18px] font-semibold text-white tabular-nums">
            {count > 99 ? "99+" : count}
          </span>
        ) : null}
      </button>

      {open ? (
        <div className="absolute top-full right-0 z-50 mt-2 w-[min(22rem,calc(100vw-2rem))] overflow-hidden rounded-lg border border-line bg-surface text-ink shadow-lg md:fixed md:top-4 md:right-auto md:left-[238px] md:mt-0">
          <div className="flex items-center justify-between gap-2 border-b border-line px-4 py-3">
            <p className="heading-sm">New for you</p>
            {count ? (
              <form action={markAllSeen}>
                <button className="min-h-9 text-xs font-medium text-brand underline">Mark all as seen</button>
              </form>
            ) : null}
          </div>
          {count === 0 ? (
            <p className="px-4 py-5 text-sm text-muted">You&apos;re all caught up.</p>
          ) : (
            <ul className="max-h-96 divide-y divide-line overflow-y-auto">
              {items.map((i) => (
                <li key={i.id}>
                  <Link href={`/tasks/${i.id}`} onClick={() => setOpen(false)} className="block px-4 py-3 hover:bg-page">
                    <span className="block text-sm font-semibold">{i.title}</span>
                    <span className="block text-xs text-muted">
                      {i.ref} · {i.kind === "helping" ? "help needed" : "for you to look after"} · from {i.by} · {i.when}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}
    </div>
  );
}

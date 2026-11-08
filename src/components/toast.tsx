// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";

// cmeprojects: a short message at the bottom of the screen ("Saved.") for
// actions whose form closes when they work, so the person still sees that
// it worked. One at a time; it fades after a few seconds.
type Toast = { id: number; text: string; tone: "success" | "error" };
const EVENT = "portal:toast";

// A message sent before the pop-up area is ready (on a fresh page load) waits here.
let waiting: Omit<Toast, "id"> | null = null;
let ready = false;

export function toast(text: string, tone: Toast["tone"] = "success") {
  if (typeof window === "undefined" || !text) return;
  if (!ready) {
    waiting = { text, tone };
    return;
  }
  window.dispatchEvent(new CustomEvent<Omit<Toast, "id">>(EVENT, { detail: { text, tone } }));
}

export function Toaster() {
  const [current, setCurrent] = useState<Toast | null>(null);
  useEffect(() => {
    const show = (e: Event) => {
      const { text, tone } = (e as CustomEvent<Omit<Toast, "id">>).detail;
      setCurrent({ id: Date.now(), text, tone });
    };
    window.addEventListener(EVENT, show);
    ready = true;
    if (waiting) {
      const w = waiting;
      waiting = null;
      queueMicrotask(() => setCurrent({ id: Date.now(), ...w }));
    }
    return () => {
      ready = false;
      window.removeEventListener(EVENT, show);
    };
  }, []);
  useEffect(() => {
    if (!current) return;
    const t = setTimeout(() => setCurrent(null), 4500);
    return () => clearTimeout(t);
  }, [current]);
  return (
    <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-4 z-50 flex justify-center px-4 print:hidden">
      {current ? (
        <p
          key={current.id}
          role={current.tone === "error" ? "alert" : "status"}
          className={`pointer-events-auto flex max-w-md items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium shadow-lg ${current.tone === "error" ? "bg-danger text-white" : "bg-ink text-surface"}`}
        >
          <span className="min-w-0 flex-1">{current.text}</span>
          <button type="button" onClick={() => setCurrent(null)} className="shrink-0 opacity-80 hover:opacity-100" aria-label="Dismiss">
            ✕
          </button>
        </p>
      ) : null}
    </div>
  );
}

// cmeprojects: shows a success message as a pop-up when it appears, instead of
// a box inside the form. Used by <Notice tone="success">.
export function ToastOnMount({ text }: { text: string }) {
  useEffect(() => {
    toast(text);
  }, [text]);
  return null;
}

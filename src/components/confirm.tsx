// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";

// cmeprojects: one branded "Are you sure?" box for the whole portal, instead of
// the browser's plain pop-up. Call askConfirm() anywhere; <ConfirmHost /> (in
// the root layout) shows it.
type Ask = { text: string; action: string; danger: boolean; resolve: (ok: boolean) => void };
const EVENT = "portal:confirm";

export function askConfirm(text: string, opts: { action?: string; danger?: boolean } = {}): Promise<boolean> {
  if (typeof window === "undefined") return Promise.resolve(false);
  return new Promise((resolve) => {
    window.dispatchEvent(new CustomEvent<Ask>(EVENT, { detail: { text, action: opts.action ?? "Yes, go ahead", danger: opts.danger ?? true, resolve } }));
  });
}

// For a <form onSubmit>: asks first, then sends the form if they say yes.
export function confirmSubmit(text: string, opts?: { action?: string; danger?: boolean }) {
  return (e: FormEvent<HTMLFormElement>) => {
    const form = e.currentTarget;
    if (form.dataset.confirmed === "1") {
      delete form.dataset.confirmed;
      return;
    }
    e.preventDefault();
    void askConfirm(text, opts).then((ok) => {
      if (!ok) return;
      form.dataset.confirmed = "1";
      form.requestSubmit();
    });
  };
}

export function ConfirmHost() {
  const [ask, setAsk] = useState<Ask | null>(null);
  const dialog = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const show = (e: Event) => setAsk((e as CustomEvent<Ask>).detail);
    window.addEventListener(EVENT, show);
    return () => window.removeEventListener(EVENT, show);
  }, []);
  useEffect(() => {
    if (ask && !dialog.current?.open) dialog.current?.showModal();
  }, [ask]);
  const answer = (ok: boolean) => {
    ask?.resolve(ok);
    setAsk(null);
    dialog.current?.close();
  };
  return (
    <dialog
      ref={dialog}
      onCancel={(e) => {
        e.preventDefault();
        answer(false);
      }}
      aria-labelledby="confirm-text"
      className="m-auto w-[min(28rem,calc(100vw-2rem))] rounded-xl border border-line bg-surface p-0 text-ink shadow-xl backdrop:bg-black/40"
    >
      {ask ? (
        <div className="flex flex-col gap-5 p-5">
          <p id="confirm-text" className="text-base leading-relaxed">
            {ask.text}
          </p>
          <div className="flex flex-wrap justify-end gap-2">
            <button type="button" autoFocus onClick={() => answer(false)} className="min-h-11 rounded-md border border-line px-4 text-sm font-semibold hover:bg-page">
              Cancel
            </button>
            <button
              type="button"
              onClick={() => answer(true)}
              className={`min-h-11 rounded-md px-4 text-sm font-semibold text-white ${ask.danger ? "bg-danger hover:opacity-90" : "bg-brand hover:opacity-90"}`}
            >
              {ask.action}
            </button>
          </div>
        </div>
      ) : null}
    </dialog>
  );
}

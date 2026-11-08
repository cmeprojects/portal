// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";

// cmeprojects: one branded "Are you sure?" box for the whole portal, instead of
// the browser's plain pop-up. Call askConfirm() anywhere; <ConfirmHost /> (in
// the root layout) shows it.
type Ask = {
  text: string;
  action: string;
  danger: boolean;
  // Type this word to unlock the action (for things that can't be undone).
  typeWord?: string;
  // Also ask for the person's password or 6-digit code.
  secretLabel?: string;
  resolve: (ok: boolean, secret?: string) => void;
};
const EVENT = "portal:confirm";

type Opts = { action?: string; danger?: boolean; typeWord?: string; secretLabel?: string };

export function askConfirm(text: string, opts: Opts = {}): Promise<boolean> {
  return askDetails(text, opts).then((r) => r !== null);
}

// Like askConfirm, but also returns what they typed in the password box.
export function askDetails(text: string, opts: Opts = {}): Promise<{ secret: string } | null> {
  if (typeof window === "undefined") return Promise.resolve(null);
  return new Promise((resolve) => {
    const detail: Ask = {
      text,
      action: opts.action ?? "Yes, go ahead",
      danger: opts.danger ?? true,
      typeWord: opts.typeWord,
      secretLabel: opts.secretLabel,
      resolve: (ok, secret) => resolve(ok ? { secret: secret ?? "" } : null),
    };
    window.dispatchEvent(new CustomEvent<Ask>(EVENT, { detail }));
  });
}

// For a <form onSubmit>: asks first, then sends the form if they say yes.
export function confirmSubmit(text: string, opts?: Opts) {
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
  const [typed, setTyped] = useState("");
  const [secret, setSecret] = useState("");
  const dialog = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const show = (e: Event) => {
      setTyped("");
      setSecret("");
      setAsk((e as CustomEvent<Ask>).detail);
    };
    window.addEventListener(EVENT, show);
    return () => window.removeEventListener(EVENT, show);
  }, []);
  useEffect(() => {
    if (ask && !dialog.current?.open) dialog.current?.showModal();
  }, [ask]);
  const unlocked = !!ask && (!ask.typeWord || typed.trim() === ask.typeWord) && (!ask.secretLabel || secret.length > 0);
  const answer = (ok: boolean) => {
    ask?.resolve(ok && unlocked, secret);
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
          {ask.typeWord ? (
            <label className="flex flex-col gap-1.5 text-sm">
              <span>
                Type <strong>{ask.typeWord}</strong> to confirm.
              </span>
              <input value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" className="h-11 rounded-lg border border-field bg-surface px-3 text-base focus:border-brand focus:ring-3 focus:ring-brand/15 focus:outline-none md:text-sm" />
            </label>
          ) : null}
          {ask.secretLabel ? (
            <label className="flex flex-col gap-1.5 text-sm">
              <span>{ask.secretLabel}</span>
              <input type="password" autoComplete="current-password" value={secret} onChange={(e) => setSecret(e.target.value)} className="h-11 rounded-lg border border-field bg-surface px-3 text-base focus:border-brand focus:ring-3 focus:ring-brand/15 focus:outline-none md:text-sm" />
            </label>
          ) : null}
          <div className="flex flex-wrap justify-end gap-2">
            <button type="button" autoFocus={!ask.typeWord && !ask.secretLabel} onClick={() => answer(false)} className="min-h-11 rounded-md border border-line px-4 text-sm font-semibold hover:bg-page">
              Cancel
            </button>
            <button
              type="button"
              disabled={!unlocked}
              onClick={() => answer(true)}
              className={`min-h-11 rounded-md px-4 text-sm font-semibold text-white disabled:opacity-40 ${ask.danger ? "bg-danger hover:opacity-90" : "bg-brand hover:opacity-90"}`}
            >
              {ask.action}
            </button>
          </div>
        </div>
      ) : null}
    </dialog>
  );
}

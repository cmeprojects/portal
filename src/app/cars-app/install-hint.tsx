// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui";

type InstallPrompt = Event & { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> };

// Shown in the phone's browser (not once installed): how to put the app on the home screen.
export function InstallHint({ name = "Cars", storageKey = "cars-install-hint" }: { name?: string; storageKey?: string }) {
  const [mode, setMode] = useState<"hidden" | "ios" | "android" | "other">("hidden");
  const [prompt, setPrompt] = useState<InstallPrompt | null>(null);

  useEffect(() => {
    const installed = window.matchMedia("(display-mode: standalone)").matches || (navigator as { standalone?: boolean }).standalone === true;
    let dismissed = false;
    try {
      dismissed = localStorage.getItem(storageKey) === "no";
    } catch {}
    if (installed || dismissed) return;
    const ua = navigator.userAgent;
    const next = /iPhone|iPad|iPod/.test(ua) ? "ios" : /Android/.test(ua) ? "android" : "other";
    const onPrompt = (e: Event) => {
      e.preventDefault();
      setPrompt(e as InstallPrompt);
    };
    window.addEventListener("beforeinstallprompt", onPrompt);
    const t = window.setTimeout(() => setMode(next), 0);
    return () => {
      window.removeEventListener("beforeinstallprompt", onPrompt);
      window.clearTimeout(t);
    };
  }, [storageKey]);

  if (mode === "hidden") return null;
  const hide = () => {
    try {
      localStorage.setItem(storageKey, "no");
    } catch {}
    setMode("hidden");
  };

  return (
    <section className="flex flex-col gap-2 rounded-xl border border-brand/30 bg-brand-soft p-4 text-sm text-ink">
      <p className="font-semibold">Put {name} on your home screen</p>
      {prompt ? (
        <Button
          onClick={async () => {
            await prompt.prompt();
            setPrompt(null);
            hide();
          }}
        >
          Install the app
        </Button>
      ) : mode === "ios" ? (
        <p>
          In Safari, tap <strong>Share</strong> (the square with an arrow), then <strong>Add to Home Screen</strong>, then <strong>Add</strong>.
        </p>
      ) : mode === "android" ? (
        <p>
          In Chrome, tap the <strong>⋮</strong> menu, then <strong>Install app</strong> (or <strong>Add to Home screen</strong>).
        </p>
      ) : (
        <p>Open this page on your phone to install it. You can still use it here.</p>
      )}
      <button type="button" onClick={hide} className="self-start text-xs text-muted underline">
        Not now
      </button>
    </section>
  );
}

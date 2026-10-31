// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useSyncExternalStore } from "react";

// Device / Light / Dark. Saved on this device only; the script in the root
// layout applies it before the page paints, so there's no flash of the wrong colours.
type Theme = "device" | "light" | "dark";
const KEY = "portal-theme";
const EVENT = "portal-theme";

function read(): Theme {
  try {
    const t = localStorage.getItem(KEY);
    return t === "light" || t === "dark" ? t : "device";
  } catch {
    return "device";
  }
}

function subscribe(onChange: () => void) {
  window.addEventListener(EVENT, onChange);
  window.addEventListener("storage", onChange);
  return () => {
    window.removeEventListener(EVENT, onChange);
    window.removeEventListener("storage", onChange);
  };
}

function choose(t: Theme) {
  try {
    if (t === "device") localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, t);
  } catch {}
  if (t === "device") delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = t;
  window.dispatchEvent(new Event(EVENT));
}

const OPTIONS: { value: Theme; label: string }[] = [
  { value: "device", label: "Device" },
  { value: "light", label: "Light" },
  { value: "dark", label: "Dark" },
];

// onPage: the larger version for a page (the apps' settings) rather than the menu.
export function ThemeSwitch({ onPage = false }: { onPage?: boolean }) {
  const theme = useSyncExternalStore(subscribe, read, () => "device" as Theme);
  if (onPage) {
    return (
      <div role="group" aria-label="Colours" className="flex w-full max-w-sm rounded-lg border border-line bg-surface p-1 text-sm">
        {OPTIONS.map((o) => (
          <button
            key={o.value}
            type="button"
            aria-pressed={theme === o.value}
            onClick={() => choose(o.value)}
            className={`min-h-11 flex-1 rounded-md font-semibold ${theme === o.value ? "bg-brand text-brand-fg" : "text-muted hover:text-ink"}`}
          >
            {o.label}
          </button>
        ))}
      </div>
    );
  }
  return (
    <div role="group" aria-label="Colours" className="flex rounded-md border border-side-active p-0.5 text-xs">
      {OPTIONS.map((o) => (
        <button
          key={o.value}
          type="button"
          aria-pressed={theme === o.value}
          onClick={() => choose(o.value)}
          className={`min-h-9 rounded px-2.5 ${theme === o.value ? "bg-side-active text-side-fg" : "text-side-muted hover:text-side-fg"}`}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

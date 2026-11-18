// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";

// cmeprojects: the "Shift saved" bar fades after 3 seconds (errors stay until closed).
export function SavedNotice({ text, error }: { text: string; error: boolean }) {
  const [shown, setShown] = useState(true);
  useEffect(() => {
    if (error) return;
    const t = window.setTimeout(() => {
      setShown(false);
    }, 3000);
    return () => window.clearTimeout(t);
  }, [text, error]);
  if (!shown) return null;
  return (
    // Floats over the page, so nothing moves when it shows or hides.
    <p role="status" className={`fixed top-20 right-6 z-[65] flex max-w-md items-center justify-between gap-3 rounded-lg px-4 py-2.5 text-sm font-semibold shadow-xl ring-1 ${error ? "bg-danger-soft text-danger ring-danger/30" : "bg-good-soft text-ink ring-good/30"}`}>
      {text}
      {error ? (
        <button type="button" onClick={() => setShown(false)} className="text-xs underline">
          Close
        </button>
      ) : null}
    </p>
  );
}

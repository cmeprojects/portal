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
      // Let the calendar grow into the space the bar leaves.
      window.setTimeout(() => window.dispatchEvent(new Event("resize")), 50);
    }, 3000);
    return () => window.clearTimeout(t);
  }, [text, error]);
  if (!shown) return null;
  return (
    <p role="status" className={`flex items-center justify-between gap-2 rounded-lg px-3 py-2 text-sm font-semibold ${error ? "bg-danger-soft text-danger" : "bg-good-soft"}`}>
      {text}
      {error ? (
        <button type="button" onClick={() => setShown(false)} className="text-xs underline">
          Close
        </button>
      ) : null}
    </p>
  );
}

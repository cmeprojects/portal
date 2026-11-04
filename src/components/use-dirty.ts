// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useCallback, useEffect, useRef, useState } from "react";

// cmeprojects: has anything in this form changed since it loaded (or since
// the last successful save)? Save buttons stay greyed out until it has.
export function useDirty() {
  const ref = useRef<HTMLFormElement>(null);
  const base = useRef("");
  const [dirty, setDirty] = useState(false);

  const snapshot = useCallback(() => {
    const form = ref.current;
    if (!form) return "";
    return JSON.stringify([...new FormData(form).entries()].map(([k, v]) => [k, typeof v === "string" ? v : v.name]));
  }, []);

  useEffect(() => {
    const form = ref.current;
    if (!form) return;
    base.current = snapshot();
    const check = () => setDirty(snapshot() !== base.current);
    form.addEventListener("input", check);
    form.addEventListener("change", check);
    return () => {
      form.removeEventListener("input", check);
      form.removeEventListener("change", check);
    };
  }, [snapshot]);

  // After a successful save: what's on screen is the new starting point.
  const markClean = useCallback(() => {
    base.current = snapshot();
    setDirty(false);
  }, [snapshot]);
  // For changes that don't fire an input event (an uploaded picture).
  const markDirty = useCallback(() => setDirty(true), []);

  return { ref, dirty, markClean, markDirty };
}

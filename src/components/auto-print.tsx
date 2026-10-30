// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";

// Opens the print window once the page has drawn (for "tap a sticker to print it").
export function AutoPrint() {
  useEffect(() => {
    const t = window.setTimeout(() => window.print(), 600);
    return () => window.clearTimeout(t);
  }, []);
  return null;
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useCallback, useEffect, useState } from "react";

// cmeprojects: is everything this form needs filled in (required fields,
// ticked boxes, chosen files)? Submit buttons stay greyed out until it is.
// Put the returned ref on the form (it works for forms that appear later).
export function useValid() {
  const [node, setNode] = useState<HTMLFormElement | null>(null);
  const [valid, setValid] = useState(false);
  const ref = useCallback((el: HTMLFormElement | null) => setNode(el), []);
  useEffect(() => {
    if (!node) return;
    const check = () => setValid(node.checkValidity());
    const frame = requestAnimationFrame(check);
    node.addEventListener("input", check);
    node.addEventListener("change", check);
    // Files finish uploading after the change event; check again then.
    const timer = window.setInterval(check, 800);
    return () => {
      cancelAnimationFrame(frame);
      node.removeEventListener("input", check);
      node.removeEventListener("change", check);
      window.clearInterval(timer);
    };
  }, [node]);
  return { ref, valid };
}

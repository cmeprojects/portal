// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef } from "react";
import type { FormState } from "@/lib/form";

// cmeprojects: run something once each time a form action succeeds, for
// example closing the form and refreshing what the page shows.
export function useAfterSuccess(state: FormState, run: (message: string) => void) {
  const seen = useRef(state);
  useEffect(() => {
    if (state === seen.current) return;
    seen.current = state;
    if (state?.message && !state.error) run(state.message);
  });
}

// Close the expandable section a form sits in.
export function closeParentDetails(el: Element | null) {
  el?.closest("details")?.removeAttribute("open");
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef } from "react";
import { useFormStatus } from "react-dom";

// cmeprojects: sits inside every submit button. While its form is saving,
// the button greys out, can't be pressed twice and shows it's busy, even
// where the form itself doesn't track it. A button disabled for another
// reason stays as it was.
export function FormPending() {
  const { pending } = useFormStatus();
  const ref = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const button = ref.current?.closest("button");
    if (!button || button.type !== "submit") return;
    if (pending && !button.disabled) {
      button.disabled = true;
      button.dataset.autoBusy = "1";
      button.setAttribute("aria-busy", "true");
    } else if (!pending && button.dataset.autoBusy) {
      button.disabled = false;
      delete button.dataset.autoBusy;
      button.removeAttribute("aria-busy");
    }
  }, [pending]);
  return <span ref={ref} hidden />;
}

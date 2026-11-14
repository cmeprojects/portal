// Staff Portal · © cmeproject. All rights reserved.
"use client";

import type { ReactNode } from "react";
import { confirmSubmit } from "@/components/confirm";

// cmeprojects: a form (usable from server pages) that asks before sending,
// for actions that can't be undone, such as deleting a document.
export function ConfirmForm({ action, text, confirmLabel, children }: { action: (form: FormData) => void | Promise<void>; text: string; confirmLabel: string; children: ReactNode }) {
  return (
    <form action={action} onSubmit={confirmSubmit(text, { action: confirmLabel })}>
      {children}
    </form>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui";
import { remindForm } from "../../actions";

// Sends a reminder (bell and email) to everyone still to do it.
export function RemindButton({ formId }: { formId: string }) {
  const [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  return (
    <span className="flex items-center gap-3 print:hidden">
      {message ? <span className="text-sm text-muted">{message}</span> : null}
      <Button
        type="button"
        variant="outline"
        disabled={pending}
        onClick={() =>
          start(async () => {
            const r = await remindForm(formId);
            setMessage(r.error ?? r.message ?? "");
          })
        }
      >
        {pending ? "Sending…" : "Remind them"}
      </Button>
    </span>
  );
}

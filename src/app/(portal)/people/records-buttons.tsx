// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui";
import { toast } from "@/components/toast";
import { confirmSubmit } from "@/components/confirm";
import { openRecordFile, revealAccount, verifyRecord } from "./records-actions";

// cmeprojects: shows the full account number for 30 seconds (recorded), then masks it again.
export function RevealAccount({ subject, masked }: { subject: string; masked: string }) {
  const [value, setValue] = useState("");
  const [pending, start] = useTransition();
  return (
    <span className="inline-flex items-center gap-2">
      <span className="font-mono">{value || masked}</span>
      {!value ? (
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={pending}
          onClick={() =>
            start(async () => {
              const r = await revealAccount(subject);
              if (r.error) return toast(r.error, "error");
              setValue(r.value ?? "");
              setTimeout(() => setValue(""), 30_000);
            })
          }
        >
          {pending ? "…" : "Reveal"}
        </Button>
      ) : null}
    </span>
  );
}

export function OpenFile({ subject, which, label }: { subject: string; which: "choice" | "visa" | "vevo"; label: string }) {
  const [pending, start] = useTransition();
  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      disabled={pending}
      onClick={() =>
        start(async () => {
          const r = await openRecordFile(subject, which);
          if (r.error || !r.url) return toast(r.error ?? "Couldn't open it.", "error");
          window.open(r.url, "_blank", "noopener");
        })
      }
    >
      {pending ? "Opening…" : label}
    </Button>
  );
}

export function VerifyRecord({ subject, table, what }: { subject: string; table: "staff_bank" | "staff_super" | "staff_work_rights"; what: string }) {
  const [pending, start] = useTransition();
  return (
    <form
      action={() =>
        start(async () => {
          const r = await verifyRecord(subject, table);
          toast(r.error ?? r.message ?? "", r.error ? "error" : "success");
        })
      }
      onSubmit={confirmSubmit(`Mark their ${what} as checked? Your name and the time are recorded.`, { action: "Mark checked", danger: false })}
    >
      <Button variant="outline" size="sm" disabled={pending}>
        {pending ? "Saving…" : "Mark checked"}
      </Button>
    </form>
  );
}

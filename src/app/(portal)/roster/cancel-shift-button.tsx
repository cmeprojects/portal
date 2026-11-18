// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import { askConfirm } from "@/components/confirm";
import { cancelShiftNow } from "./actions";

// cmeprojects: cancelling a shift asks first, then closes the panel and says so.
export function CancelShiftButton({ id, published, closeHref }: { id: string; published: boolean; closeHref: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  return (
    <button
      type="button"
      disabled={pending}
      onClick={() =>
        void askConfirm(`Cancel this shift?${published ? " The worker will be told." : ""} It stays in the log.`, { action: "Cancel the shift" }).then((ok) => {
          if (!ok) return;
          start(async () => {
            const res = await cancelShiftNow(id);
            const msg = res?.error ? `Not cancelled: ${res.error}` : "Shift cancelled.";
            router.push(`${closeHref}${closeHref.includes("?") ? "&" : "?"}saved=${encodeURIComponent(msg)}`, { scroll: false });
          });
        })
      }
      className="text-sm font-semibold text-danger underline disabled:opacity-50"
    >
      {pending ? "Cancelling…" : "Cancel this shift"}
    </button>
  );
}

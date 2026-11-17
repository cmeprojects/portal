// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useRef } from "react";
import { UserPlus, X } from "lucide-react";
import { buttonClass } from "@/components/ui";
import { InviteForm } from "./forms";

// cmeprojects (owner, 17 Nov 2026): "Invite staff member" opens as a pop-up
// over the Staff page.
export function InviteDialog() {
  const ref = useRef<HTMLDialogElement>(null);
  return (
    <>
      <button type="button" onClick={() => ref.current?.showModal()} className={buttonClass("primary")}>
        <UserPlus aria-hidden="true" className="size-4" /> Invite staff member
      </button>
      <dialog
        ref={ref}
        aria-labelledby="invite-title"
        onClick={(e) => e.target === ref.current && ref.current?.close()}
        className="m-auto w-[min(40rem,calc(100vw-2rem))] rounded-xl border border-line bg-surface p-0 text-ink shadow-2xl backdrop:bg-black/40"
      >
        <div className="flex items-center justify-between border-b border-line px-5 py-3">
          <h2 id="invite-title" className="heading-sm">
            Invite staff member
          </h2>
          <button type="button" onClick={() => ref.current?.close()} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
            <X aria-hidden="true" className="size-5" />
          </button>
        </div>
        <div className="p-5">
          <InviteForm />
        </div>
      </dialog>
    </>
  );
}

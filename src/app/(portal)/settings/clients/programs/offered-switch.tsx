// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { setSchemeOffered } from "../actions";

// cmeprojects (update 158): which schemes the organisation offers. Turning one
// off only stops new use (new clients, programs and services); everything
// already recorded under it stays as it is.
export function OfferedSwitch({ schemeKey, label, offered }: { schemeKey: string; label: string; offered: boolean }) {
  const [on, setOn] = useState(offered);
  const [pending, start] = useTransition();
  // Ask first (outside the transition, so the question can show), then save.
  const flip = async () => {
    const next = !on;
    if (!next && !(await askConfirm(`Stop offering ${label}? It can't be chosen for new clients, programs or services. Clients already in ${label} keep it, and nothing recorded is changed or hidden.`, { action: "Stop offering" }))) return;
    start(async () => {
      const r = await setSchemeOffered(schemeKey, next);
      if (r?.error) toast(r.error, "error");
      else {
        setOn(next);
        toast(next ? `${label} is offered.` : `${label} is no longer offered for new use.`);
      }
    });
  };
  return (
    <label className="flex min-h-11 items-center justify-between gap-3 px-1 py-1.5 text-sm">
      <span className="font-semibold">{label}</span>
      <span className="flex items-center gap-2 text-xs text-muted">
        {on ? "Offered" : "Not offered"}
        <button
          type="button"
          role="switch"
          aria-checked={on}
          aria-label={`Offer ${label}`}
          disabled={pending}
          onClick={flip}
          className={`relative h-6 w-11 rounded-full transition-colors disabled:opacity-50 ${on ? "bg-brand" : "bg-line"}`}
        >
          <span className={`absolute top-0.5 size-5 rounded-full bg-white shadow transition-[left] ${on ? "left-[22px]" : "left-0.5"}`} />
        </button>
      </span>
    </label>
  );
}

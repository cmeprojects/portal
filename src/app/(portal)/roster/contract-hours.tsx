// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { saveContractHours } from "./actions";

// cmeprojects (update 169): set a worker's contracted weekly hours from their roster row.
export function ContractHoursForm({ userId, hours }: { userId: string; hours: number | null }) {
  const router = useRouter();
  const [v, setV] = useState(hours === null ? "" : String(hours));
  const [msg, setMsg] = useState("");
  const [pending, start] = useTransition();
  return (
    <span className="mt-1 flex flex-wrap items-center gap-1">
      <label className="text-[11px] font-medium text-ink">Contracted h/week
        <input value={v} onChange={(e) => setV(e.target.value)} inputMode="decimal" className="ml-1 w-14 rounded border border-field bg-surface px-1 py-0.5 text-xs" aria-label="Contracted hours a week" />
      </label>
      <button type="button" disabled={pending} onClick={() => start(async () => { const r = await saveContractHours(userId, v); setMsg(r?.error ?? "Saved"); if (!r?.error) router.refresh(); })} className="text-[11px] font-semibold text-brand underline">Save</button>
      {msg ? <span className="text-[11px] text-muted">{msg}</span> : null}
    </span>
  );
}

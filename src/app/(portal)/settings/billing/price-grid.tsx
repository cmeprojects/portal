// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import type { FormState } from "@/lib/form";
import { savePriceGrid } from "./actions";

// cmeprojects (update 167): prices filled from the catalogue. Each catalogue service offered under the
// list's scheme is a row (with its code); client services not in the catalogue are rows too, priced by
// name. Type a price per rate band; existing prices are shown and can be changed in the draft.
export type GridService = { key: string; catalogue_id: string; code: string; label: string; unit: string; gst_code: string; sah_category: string; ndis_item: string; prices: Record<string, string>; ids: Record<string, string>; fromClient?: boolean };
export function PriceGrid({ versionId, listId, scheme, bands, services, editable }: { versionId: string; listId: string; scheme: string; bands: [string, string][]; services: GridService[]; editable: boolean }) {
  const router = useRouter();
  const [rows, setRows] = useState(services);
  const [pending, start] = useTransition();
  const [state, setState] = useState<FormState>(null);
  const cols: [string, string][] = bands.length ? bands : [["_any", "Any time"]];
  const set = (i: number, k: keyof GridService, v: string) => setRows((rs) => rs.map((r, j) => (j === i ? { ...r, [k]: v } : r)));
  const setPrice = (i: number, b: string, v: string) => setRows((rs) => rs.map((r, j) => (j === i ? { ...r, prices: { ...r.prices, [b]: v } } : r)));
  const missing = rows.filter((r) => cols.every(([b]) => !r.prices[b])).length;
  return (
    <div className="flex flex-col gap-2">
      <p className="text-xs text-muted">{rows.length} service(s) offered under this scheme{missing ? `; ${missing} not priced yet` : ""}. Leave a band blank if the service isn&apos;t offered then.</p>
      <div className="relative overflow-x-auto">
        <table className="w-full text-left text-sm" style={{ minWidth: `${36 + cols.length * 7}rem` }}>
          <thead className="text-xs text-muted">
            <tr>
              <th className="py-1 pr-2">Service</th><th className="py-1 pr-2">Per</th><th className="py-1 pr-2">GST</th>
              {scheme === "support_at_home" ? <th className="py-1 pr-2">Category</th> : scheme === "ndis" ? <th className="py-1 pr-2">NDIS item</th> : null}
              {cols.map(([k, l]) => <th key={k} className="py-1 pr-2 text-right">{l}</th>)}
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {rows.map((r, i) => (
              <tr key={r.key} className={cols.every(([b]) => !r.prices[b]) ? "bg-warn-soft/40" : ""}>
                <td className="py-1 pr-2">{r.code ? <span className="mr-1 font-mono text-xs">{r.code}</span> : null}{r.label}{r.fromClient ? <span className="block text-xs text-muted">Client service, not in the catalogue (priced by name)</span> : null}</td>
                <td className="py-1 pr-2">
                  <select value={r.unit} disabled={!editable} onChange={(e) => set(i, "unit", e.target.value)} aria-label={`Unit for ${r.label}`} className={`${inputClass} w-24`}>
                    <option value="hour">Hour</option><option value="visit">Visit</option><option value="each">Each</option><option value="km">Km</option><option value="day">Day</option>
                  </select>
                </td>
                <td className="py-1 pr-2">
                  <select value={r.gst_code} disabled={!editable} onChange={(e) => set(i, "gst_code", e.target.value)} aria-label={`GST for ${r.label}`} className={`${inputClass} w-28`}>
                    <option value="gst_free">GST-free</option><option value="taxable">Taxable</option><option value="input_taxed">Input-taxed</option>
                  </select>
                </td>
                {scheme === "support_at_home" ? (
                  <td className="py-1 pr-2">
                    <select value={r.sah_category} disabled={!editable} onChange={(e) => set(i, "sah_category", e.target.value)} aria-label={`Category for ${r.label}`} className={`${inputClass} w-36`}>
                      <option value="">Choose…</option><option value="clinical">Clinical</option><option value="independence">Independence</option><option value="everyday_living">Everyday living</option>
                    </select>
                  </td>
                ) : scheme === "ndis" ? (
                  <td className="py-1 pr-2"><input value={r.ndis_item} disabled={!editable} onChange={(e) => set(i, "ndis_item", e.target.value)} maxLength={40} aria-label={`NDIS item for ${r.label}`} className={`${inputClass} w-36`} /></td>
                ) : null}
                {cols.map(([b, l]) => (
                  <td key={b} className="py-1 pr-2 text-right">
                    <input value={r.prices[b] ?? ""} disabled={!editable} onChange={(e) => setPrice(i, b, e.target.value)} inputMode="decimal" placeholder="–" aria-label={`${r.label}, ${l}`} className={`${inputClass} w-24 text-right`} />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {editable ? (
        <div><Button type="button" size="sm" disabled={pending} onClick={() => start(async () => { const r = await savePriceGrid(versionId, listId, rows); setState(r); if (!r?.error) router.refresh(); })}>{pending ? "Saving…" : "Save prices"}</Button></div>
      ) : <p className="text-xs text-muted">Only a draft version&apos;s prices change. Start a new version to change prices.</p>}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

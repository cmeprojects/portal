// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useMemo, useState } from "react";
import { BookOpen, PencilLine, Plus, Search, X } from "lucide-react";
import { Button, Notice, inputClass } from "@/components/ui";
import { SERVICE_STATUS } from "@/lib/client-sections";
import { addClientService, updateClientService } from "./actions";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";

export type CatalogueItem = { id: string; name: string; description: string; schemes: string[]; shift_types: string[] };
export type ServiceRow = {
  id: string;
  origin: string;
  label: string;
  description: string;
  shift_types: string[];
  program_id: string;
  location_id: string;
  start_date: string;
  end_date: string | null;
  status: string;
  scheduling_notes: string;
  consent_required: boolean;
  consent_given_on: string | null;
  consent_note: string;
};
type Choice = [string, string];
const lab = "text-xs font-semibold text-ink";
const field = "flex flex-col gap-1";
const hint = "text-xs text-muted";

// The client-specific part of a service: program, place, dates, status, consent.
function Details({ s, programs, locations }: { s?: ServiceRow; programs: (Choice & { 2?: string })[]; locations: Choice[] }) {
  const [consent, setConsent] = useState(Boolean(s?.consent_required));
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <label className={field}>
        <span className={lab}>Program</span>
        <select name="program_id" required defaultValue={s?.program_id ?? ""} className={inputClass}>
          <option value="" disabled>
            Choose the program
          </option>
          {programs.map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <label className={field}>
        <span className={lab}>Delivered at</span>
        <select name="location_id" required defaultValue={s?.location_id ?? (locations.length === 1 ? locations[0][0] : "")} className={inputClass}>
          <option value="" disabled>
            Choose the location
          </option>
          {locations.map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <label className={field}>
        <span className={lab}>Start date</span>
        <input type="date" name="start_date" required defaultValue={s?.start_date ?? ""} className={inputClass} />
      </label>
      <label className={field}>
        <span className={lab}>End date (optional)</span>
        <input type="date" name="end_date" defaultValue={s?.end_date ?? ""} className={inputClass} />
      </label>
      <label className={field}>
        <span className={lab}>Status</span>
        <select name="status" defaultValue={s?.status ?? "planned"} className={inputClass}>
          {SERVICE_STATUS.map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
        <span className={hint}>Active only once the client is ready for it.</span>
      </label>
      <label className={field}>
        <span className={lab}>Scheduling restrictions (optional)</span>
        <input name="scheduling_notes" maxLength={1000} defaultValue={s?.scheduling_notes ?? ""} placeholder="e.g. mornings only, no Sundays" className={inputClass} />
      </label>
      <label className="inline-flex items-center gap-2 text-sm sm:col-span-2">
        <input type="checkbox" name="consent_required" checked={consent} onChange={(e) => setConsent(e.target.checked)} className="size-4" /> Consent needed
      </label>
      {consent ? (
        <>
          <label className={field}>
            <span className={lab}>Consent given on</span>
            <input type="date" name="consent_given_on" defaultValue={s?.consent_given_on ?? ""} className={inputClass} />
          </label>
          <label className={field}>
            <span className={lab}>Consent note</span>
            <input name="consent_note" maxLength={500} defaultValue={s?.consent_note ?? ""} className={inputClass} />
          </label>
        </>
      ) : null}
    </div>
  );
}

function ShiftTypePicks({ types, chosen }: { types: Choice[]; chosen: string[] }) {
  return (
    <fieldset className="flex flex-col gap-1">
      <legend className={lab}>Shift types this service covers</legend>
      <div className="flex flex-wrap gap-x-4 gap-y-1">
        {types.map(([k, l]) => (
          <label key={k} className="inline-flex min-h-8 items-center gap-2 text-sm">
            <input type="checkbox" name="shift_types" value={k} defaultChecked={chosen.includes(k)} className="size-4" /> {l}
          </label>
        ))}
      </div>
      <span className={hint}>Only these can be rostered under this service.</span>
    </fieldset>
  );
}

// cmeprojects (update 143): Add Service, from the catalogue or "Add other service".
export function AddServicePanel({
  clientId,
  catalogue,
  programs,
  locations,
  shiftTypes,
}: {
  clientId: string;
  catalogue: CatalogueItem[];
  programs: [string, string, string][];
  locations: Choice[];
  shiftTypes: Choice[];
}) {
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<"catalogue" | "custom">("catalogue");
  const [q, setQ] = useState("");
  const [picked, setPicked] = useState<CatalogueItem | null>(null);
  const [state, action, pending] = useActionState(async (prev: Awaited<ReturnType<typeof addClientService>>, f: FormData) => {
    const r = await addClientService(prev, f);
    if (r?.message) {
      setOpen(false);
      setPicked(null);
    }
    return r;
  }, null);
  const found = useMemo(() => catalogue.filter((c) => !q || `${c.name} ${c.description}`.toLowerCase().includes(q.toLowerCase())), [catalogue, q]);
  const typeName = new Map(shiftTypes);
  // A catalogue service is only offered under the programs it's set up for.
  const programsFor = (c: CatalogueItem | null) => programs.filter(([, , scheme]) => !c || !c.schemes.length || c.schemes.includes(scheme)).map(([v, l]) => [v, l] as Choice);
  if (!open)
    return (
      <div className="flex flex-col gap-2">
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
        <Button type="button" icon={Plus} onClick={() => setOpen(true)} className="self-start">
          Add Service
        </Button>
      </div>
    );
  return (
    <div className="flex flex-col gap-4 rounded-xl border border-brand/30 bg-surface p-4 shadow-sm">
      <div className="flex items-center justify-between gap-2">
        <h3 className="text-sm font-semibold">Add a service</h3>
        <button type="button" onClick={() => setOpen(false)} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page">
          <X aria-hidden="true" className="size-4" />
        </button>
      </div>
      <div role="tablist" className="grid grid-cols-2 gap-2">
        {(
          [
            ["catalogue", "Select from the catalogue", BookOpen],
            ["custom", "Add other service", PencilLine],
          ] as const
        ).map(([k, l, Icon]) => (
          <button
            key={k}
            type="button"
            role="tab"
            aria-selected={mode === k}
            onClick={() => setMode(k)}
            className={`flex items-center justify-center gap-2 rounded-lg border px-3 py-2.5 text-sm font-semibold ${mode === k ? "border-brand bg-brand-soft text-brand" : "border-line text-muted hover:bg-page"}`}
          >
            <Icon aria-hidden="true" className="size-4" /> {l}
          </button>
        ))}
      </div>
      <form action={action} className="flex flex-col gap-4">
        <input type="hidden" name="client_id" value={clientId} />
        <input type="hidden" name="mode" value={mode} />
        {mode === "catalogue" ? (
          picked ? (
            <div className="rounded-lg border border-line bg-page p-3">
              <input type="hidden" name="catalogue_id" value={picked.id} />
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="font-semibold">{picked.name}</p>
                  <p className="text-sm text-muted">{picked.description || "No description in the catalogue yet."}</p>
                  {picked.shift_types.length ? <p className="mt-1 text-xs text-muted">Covers: {picked.shift_types.map((k) => typeName.get(k) ?? k).join(", ")}</p> : null}
                </div>
                <button type="button" onClick={() => setPicked(null)} className="text-xs font-semibold text-brand underline">
                  Change
                </button>
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              <label className="relative">
                <Search aria-hidden="true" className="absolute top-3.5 left-3 size-4 text-muted" />
                <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search services" aria-label="Search services" className={`${inputClass} pl-9`} />
              </label>
              <ul className="thin-scroll flex max-h-72 flex-col divide-y divide-line overflow-y-auto rounded-lg border border-line">
                {found.map((c) => (
                  <li key={c.id}>
                    <button type="button" onClick={() => setPicked(c)} className="w-full px-3 py-2 text-left hover:bg-page">
                      <span className="block text-sm font-semibold">{c.name}</span>
                      {c.description ? <span className="block text-xs text-muted">{c.description}</span> : null}
                    </button>
                  </li>
                ))}
                {!found.length ? <li className="px-3 py-2 text-sm text-muted">No match. Use &ldquo;Add other service&rdquo;.</li> : null}
              </ul>
            </div>
          )
        ) : (
          <div className="flex flex-col gap-3">
            <label className={field}>
              <span className={lab}>Service name</span>
              <input name="label" required maxLength={80} placeholder="e.g. Pet care" className={inputClass} />
            </label>
            <label className={field}>
              <span className={lab}>Service description</span>
              <textarea name="description" required maxLength={1000} rows={2} className={`${inputClass} h-auto py-2`} />
            </label>
            <ShiftTypePicks types={shiftTypes} chosen={[]} />
            <p className={hint}>Saved for this client only. It isn&apos;t added to the catalogue, and it needs the same program, approval and funding as any service.</p>
          </div>
        )}
        {mode === "custom" || picked ? (
          <>
            <Details programs={programsFor(mode === "catalogue" ? picked : null)} locations={locations} />
            <div className="flex items-center gap-2">
              <Button disabled={pending}>{pending ? "Adding…" : "Add service"}</Button>
              {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
            </div>
          </>
        ) : null}
      </form>
    </div>
  );
}

export function ServiceEditForm({ clientId, s, programs, locations, shiftTypes }: { clientId: string; s: ServiceRow; programs: Choice[]; locations: Choice[]; shiftTypes: Choice[] }) {
  const [state, action, pending] = useActionState(updateClientService, null);
  // Save stays greyed out until something changes, and again once it's saved.
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form ref={ref} action={action} className="flex flex-col gap-3">
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="id" value={s.id} />
      <input type="hidden" name="origin" value={s.origin} />
      {s.origin === "catalogue" ? null : (
        <>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className={field}>
              <span className={lab}>Service name</span>
              <input name="label" required maxLength={80} defaultValue={s.label} className={inputClass} />
            </label>
            <label className={field}>
              <span className={lab}>Description</span>
              <input name="description" maxLength={1000} defaultValue={s.description} required={s.origin === "custom"} className={inputClass} />
            </label>
          </div>
          <ShiftTypePicks types={shiftTypes} chosen={s.shift_types} />
        </>
      )}
      <Details s={s} programs={programs} locations={locations} />
      <div className="flex items-center gap-2">
        <Button size="sm" disabled={pending || !dirty}>
          {pending ? "Saving…" : dirty ? "Save" : "Saved"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

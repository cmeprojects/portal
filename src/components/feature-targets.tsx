// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import type { Option } from "@/lib/feature-types";
import { saveTargets } from "@/app/(portal)/f/actions";

const numOrNull = (v: string) => (v.trim() === "" || Number.isNaN(Number(v)) ? null : Number(v));

// cmeprojects: the daily target for everyone and each client's own. Used by
// the Feature builder and by managers when the feature allows it.
export function TargetsEditor({
  featureId,
  unit,
  clients,
  targets: initial,
  defaultTarget,
}: {
  featureId: string;
  unit: string;
  clients: Option[];
  targets: Record<string, number>;
  defaultTarget: number | null;
}) {
  const [targets, setTargets] = useState<Record<string, string>>(() => Object.fromEntries(Object.entries(initial).map(([k, v]) => [k, String(v)])));
  const [def, setDef] = useState(defaultTarget == null ? "" : String(defaultTarget));
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();

  return (
    <div className="flex flex-col gap-3">
      {result?.error ? <Notice tone="error">{result.error}</Notice> : result?.message ? <Notice tone="success">{result.message}</Notice> : null}
      <Field label={`Daily target for everyone${unit ? ` (${unit})` : ""}`} htmlFor="tt-def" hint="Used for any client without their own target. Leave blank for no target.">
        <input id="tt-def" inputMode="decimal" value={def} onChange={(e) => setDef(e.target.value)} className={`${inputClass} max-w-48`} />
      </Field>
      <div>
        <p className="text-sm font-semibold">Each client&apos;s own target</p>
        <p className="text-xs text-muted">For example a fluid restriction, or a higher goal. Blank uses the target for everyone.</p>
        {clients.length === 0 ? <p className="mt-2 text-sm text-muted">No clients yet. Add them under People → Clients.</p> : null}
        <ul className="mt-2 divide-y divide-line rounded-md border border-line">
          {clients.map((c) => (
            <li key={c.id} className="flex items-center justify-between gap-3 px-3 py-2">
              <label htmlFor={`tg-${c.id}`} className="text-sm font-medium">
                {c.name}
              </label>
              <span className="flex items-center gap-2 text-sm">
                <input
                  id={`tg-${c.id}`}
                  inputMode="decimal"
                  value={targets[c.id] ?? ""}
                  placeholder={def || "—"}
                  onChange={(e) => setTargets((t) => ({ ...t, [c.id]: e.target.value }))}
                  className={`${inputClass} w-28 text-right tabular-nums`}
                />
                <span className="w-8 text-muted">{unit}</span>
              </span>
            </li>
          ))}
        </ul>
      </div>
      <Button
        type="button"
        disabled={pending}
        className="self-start"
        onClick={() =>
          start(async () => {
            setResult(await saveTargets(featureId, numOrNull(def), Object.fromEntries(clients.map((c) => [c.id, numOrNull(targets[c.id] ?? "")]))));
          })
        }
      >
        {pending ? "Saving…" : "Save targets"}
      </Button>
    </div>
  );
}

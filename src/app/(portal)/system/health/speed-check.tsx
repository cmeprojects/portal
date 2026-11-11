// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { Button } from "@/components/ui";

// cmeprojects (performance stage 0): how fast is this copy, from this browser?
// Times the database round trip (via /health) and each main page, exactly as a
// menu click asks for it (3 tries each, the middle one counts). Read-only.
const PAGES: [string, string][] = [
  ["Dashboard", "/"],
  ["Tasks", "/tasks"],
  ["Registers", "/registers"],
  ["Staff", "/settings/staff"],
  ["Onboarding", "/compliance"],
  ["Directory", "/people"],
  ["My requests", "/requests"],
  ["Reports", "/reports"],
  ["My account", "/account"],
  ["System settings", "/system"],
];
type Row = { name: string; ms: number | null; kb: number | null; note?: string };
type Health = { region?: string; database_ms?: (number | string)[]; signin_service_ms?: number | string };

const median = (xs: number[]) => [...xs].sort((a, b) => a - b)[Math.floor(xs.length / 2)];

export function SpeedCheck() {
  const [running, setRunning] = useState(false);
  const [health, setHealth] = useState<Health | null>(null);
  const [rows, setRows] = useState<Row[]>([]);
  const [when, setWhen] = useState("");

  async function run() {
    setRunning(true);
    setRows([]);
    try {
      setHealth((await (await fetch("/health", { cache: "no-store" })).json()) as Health);
    } catch {
      setHealth(null);
    }
    const out: Row[] = [];
    for (const [name, path] of PAGES) {
      const times: number[] = [];
      let kb: number | null = null;
      let note = "";
      for (let i = 0; i < 3; i++) {
        const t0 = performance.now();
        try {
          const res = await fetch(path, { headers: { RSC: "1" }, cache: "no-store" });
          const body = await res.arrayBuffer();
          if (!res.ok) note = `error ${res.status}`;
          kb = Math.round(body.byteLength / 1024);
          times.push(Math.round(performance.now() - t0));
        } catch {
          note = "couldn't load";
        }
      }
      out.push({ name, ms: times.length ? median(times) : null, kb, note });
      setRows([...out]);
    }
    setWhen(new Date().toLocaleString("en-AU", { timeZone: "Australia/Sydney" }));
    setRunning(false);
  }

  const db = (health?.database_ms ?? []).filter((x): x is number => typeof x === "number");
  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" onClick={run} disabled={running}>
          {running ? "Measuring…" : "Measure"}
        </Button>
        <p className="text-xs text-muted">Takes about 30 seconds. Times include your internet connection. Nothing is changed.</p>
      </div>
      {health ? (
        <dl className="grid gap-x-6 gap-y-1 text-sm sm:grid-cols-3">
          <div>
            <dt className="text-xs text-muted">App runs in</dt>
            <dd className="font-medium">{health.region === "syd1" ? "Sydney (syd1)" : (health.region ?? "unknown")}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted">Database round trip (from the app)</dt>
            <dd className="font-medium">{db.length ? `${median(db)} ms` : String(health.database_ms?.[0] ?? "unknown")}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted">Sign-in service round trip</dt>
            <dd className="font-medium">{typeof health.signin_service_ms === "number" ? `${health.signin_service_ms} ms` : String(health.signin_service_ms ?? "unknown")}</dd>
          </div>
        </dl>
      ) : null}
      {rows.length ? (
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="text-xs text-muted">
              <th className="py-1 font-medium">Page</th>
              <th className="py-1 font-medium">Time</th>
              <th className="py-1 font-medium">Size</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.name} className="border-t border-line">
                <td className="py-1.5">{r.name}</td>
                <td className="py-1.5 tabular-nums">{r.ms === null ? "–" : `${r.ms} ms`}</td>
                <td className="py-1.5 tabular-nums text-muted">
                  {r.kb === null ? "–" : `${r.kb} KB`}
                  {r.note ? ` · ${r.note}` : ""}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : null}
      {when ? <p className="text-xs text-muted">Measured {when}. Screenshot this to compare later.</p> : null}
    </div>
  );
}

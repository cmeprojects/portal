// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useMemo, useState, useTransition } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveBaselines, type BaselineEntry } from "./baseline-actions";

export type BaselineModule = { id: string; label: string; actions: string[]; sensitive: boolean };
export type BaselineRow = { holder: string; module: string; effect: "allow" | "restrict"; actions: string[]; scope: "all" | "own_teams" };
type Choice = { value: string; label: string };

// cmeprojects (Stage 3, D-047): give a function group, a job title or an access
// level access to modules that have been switched over to the one permission
// check. Precedence: a person's own setting, then job title, then function
// group, then access level.
export function RoleGroupAccess({ modules, rows, groups, titles, levels }: { modules: BaselineModule[]; rows: BaselineRow[]; groups: Choice[]; titles: Choice[]; levels: Choice[] }) {
  const [holder, setHolder] = useState("");
  const [draft, setDraft] = useState<Record<string, BaselineEntry>>({});
  const [msg, setMsg] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const isGroup = holder.startsWith("group:");
  const shown = useMemo(() => modules.filter((m) => !(isGroup && m.sensitive)), [modules, isGroup]);

  const choose = (value: string) => {
    setHolder(value);
    setMsg(null);
    setDraft(Object.fromEntries(rows.filter((r) => r.holder === value).map((r) => [r.module, { module: r.module, effect: r.effect, actions: r.actions, scope: r.scope }])));
  };
  const set = (id: string, v: Partial<BaselineEntry> | null) =>
    setDraft((d) => {
      const next = { ...d };
      if (v === null) delete next[id];
      else next[id] = { ...{ module: id, effect: "allow" as const, actions: [] as string[], scope: "all" as const }, ...d[id], ...v };
      return next;
    });

  if (!modules.length) {
    return (
      <p className="text-sm text-muted">
        No part of the portal uses role or group access yet. Parts are switched over one at a time; each then appears here, starting with what its access level already allows, so nobody&apos;s access changes on the day.
      </p>
    );
  }
  return (
    <div className="flex flex-col gap-3">
      <label htmlFor="rg-holder" className="flex flex-col gap-1 text-sm font-medium">
        Who it&apos;s for
        <select id="rg-holder" value={holder} onChange={(e) => choose(e.target.value)} className={inputClass}>
          <option value="">Choose a function group, role or access level…</option>
          <optgroup label="Function groups">{groups.map((g) => <option key={g.value} value={g.value}>{g.label}</option>)}</optgroup>
          <optgroup label="Roles (job titles)">{titles.map((g) => <option key={g.value} value={g.value}>{g.label}</option>)}</optgroup>
          <optgroup label="Access levels (default for everyone at that level)">{levels.map((g) => <option key={g.value} value={g.value}>{g.label}</option>)}</optgroup>
        </select>
      </label>
      {holder ? (
        <>
          <ul className="divide-y divide-line rounded-lg border border-line">
            {shown.map((m) => {
              const e = draft[m.id];
              const state = e ? e.effect : "off";
              return (
                <li key={m.id} className="flex flex-col gap-2 px-3 py-2 text-sm">
                  <div className="flex flex-wrap items-center gap-3">
                    <span className="min-w-40 flex-1 font-medium">
                      {m.label}
                      {m.sensitive ? <span className="ml-2 text-xs text-muted">sensitive: roles and people only</span> : null}
                    </span>
                    <select aria-label={`${m.label}: access`} value={state} onChange={(ev) => (ev.target.value === "off" ? set(m.id, null) : set(m.id, { effect: ev.target.value as "allow" | "restrict" }))} className={`${inputClass} w-36`}>
                      <option value="off">Not set</option>
                      <option value="allow">Allow</option>
                      <option value="restrict">Block</option>
                    </select>
                    {e ? (
                      <select aria-label={`${m.label}: whose records`} value={e.scope} onChange={(ev) => set(m.id, { scope: ev.target.value as "all" | "own_teams" })} className={`${inputClass} w-40`}>
                        <option value="all">Everyone&apos;s</option>
                        <option value="own_teams">Their own teams&apos;</option>
                      </select>
                    ) : null}
                  </div>
                  {e && e.effect === "allow" && m.actions.length > 1 ? (
                    <div className="flex flex-wrap gap-1.5" role="group" aria-label={`What they can do in ${m.label}`}>
                      {m.actions.map((a) => {
                        const on = !e.actions.length || e.actions.includes(a);
                        return (
                          <button
                            key={a}
                            type="button"
                            aria-pressed={on}
                            onClick={() => {
                              const all = e.actions.length ? e.actions : m.actions;
                              const next = on ? all.filter((x) => x !== a) : [...all, a];
                              set(m.id, { actions: next.length === m.actions.length ? [] : next });
                            }}
                            className={`rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ${on ? "bg-brand text-brand-fg ring-brand" : "bg-surface text-muted ring-line"}`}
                          >
                            {a.replace(/_/g, " ")}
                          </button>
                        );
                      })}
                    </div>
                  ) : null}
                </li>
              );
            })}
          </ul>
          <div className="flex flex-wrap items-center gap-3">
            <Button
              disabled={pending}
              onClick={() =>
                start(async () => {
                  const [kind, id] = holder.split(":");
                  setMsg(await saveBaselines({ kind: kind as "group" | "title" | "level", id }, Object.values(draft)));
                })
              }
            >
              {pending ? "Saving…" : "Save access"}
            </Button>
            {msg?.error ? <Notice tone="error">{msg.error}</Notice> : null}
            {msg?.message ? <Notice tone="success">{msg.message}</Notice> : null}
          </div>
        </>
      ) : null}
    </div>
  );
}

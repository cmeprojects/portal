// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { Fragment, useMemo, useState, useTransition } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { saveBaselines, type BaselineEntry } from "./baseline-actions";

// allowed: actions this person may give; everything: may give "all actions".
export type BaselineModule = { id: string; label: string; actions: string[]; sensitive: boolean; allowed: string[]; everything: boolean };
// mine: false for a grant someone else gave (a Manager Administrator can't change it).
export type BaselineRow = { holder: string; module: string; effect: "allow" | "restrict"; actions: string[]; scope: "all" | "own_teams" | "assigned"; mine: boolean };
type Choice = { value: string; label: string };

// cmeprojects (Stage 3, D-047): give a function group, a job title or an access
// level access to modules that have been switched over to the one permission
// check. Precedence: a person's own setting, then job title, then function
// group, then access level. A Manager Administrator sees groups and roles only,
// and only the parts and actions they may pass on.
export function RoleGroupAccess({ modules, rows, groups, titles, levels, admin, ownParts = {} }: { modules: BaselineModule[]; rows: BaselineRow[]; groups: Choice[]; titles: Choice[]; levels: Choice[]; admin: boolean; ownParts?: Record<string, string[]> }) {
  const [holder, setHolder] = useState("");
  const [draft, setDraft] = useState<Record<string, BaselineEntry>>({});
  const [msg, setMsg] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const isGroup = holder.startsWith("group:");
  // Stage 4: the parts this group (or this role's groups) looks after come first.
  const shown = useMemo(() => {
    const list = modules.filter((m) => !(isGroup && m.sensitive));
    const own = ownParts[holder] ?? [];
    const mine = (id: string) => own.some((p) => id === p || id.startsWith(`${p}.`));
    return [...list.filter((m) => mine(m.id)).map((m) => ({ ...m, own: true })), ...list.filter((m) => !mine(m.id)).map((m) => ({ ...m, own: false }))];
  }, [modules, isGroup, ownParts, holder]);
  const hasOwn = shown.some((m) => m.own);

  const choose = (value: string) => {
    setHolder(value);
    setMsg(null);
    setDraft(Object.fromEntries(rows.filter((r) => r.holder === value && r.mine).map((r) => [r.module, { module: r.module, effect: r.effect, actions: r.actions, scope: r.scope }])));
  };
  const set = (id: string, v: Partial<BaselineEntry> | null) =>
    setDraft((d) => {
      const next = { ...d };
      if (v === null) delete next[id];
      else next[id] = { ...{ module: id, effect: "allow" as const, actions: [] as string[], scope: "all" as const }, ...d[id], ...v };
      return next;
    });

  if (!modules.length && !admin) {
    return <p className="text-sm text-muted">You can&apos;t pass on any part that uses role or group access yet.</p>;
  }
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
          <option value="">{admin ? "Choose a function group, role or access level…" : "Choose a function group or role…"}</option>
          <optgroup label="Function groups">{groups.map((g) => <option key={g.value} value={g.value}>{g.label}</option>)}</optgroup>
          <optgroup label="Roles (job titles)">{titles.map((g) => <option key={g.value} value={g.value}>{g.label}</option>)}</optgroup>
          {levels.length ? <optgroup label="Access levels (default for everyone at that level)">{levels.map((g) => <option key={g.value} value={g.value}>{g.label}</option>)}</optgroup> : null}
        </select>
      </label>
      {holder ? (
        <>
          <ul className="divide-y divide-line rounded-lg border border-line">
            {shown.map((m, idx) => {
              const heading =
                hasOwn && (idx === 0 || shown[idx - 1].own !== m.own) ? (
                  <li key={`h-${m.own}`} className="bg-page px-3 py-1.5 text-[11px] font-semibold tracking-[0.12em] text-muted uppercase">
                    {m.own ? "This group's parts" : "Other parts"}
                  </li>
                ) : null;
              const e = draft[m.id];
              const state = e ? e.effect : "off";
              const other = rows.find((r) => r.holder === holder && r.module === m.id && !r.mine);
              if (other) {
                return (
                  <Fragment key={m.id}>
                  {heading}
                  <li className="flex flex-wrap items-center gap-3 px-3 py-2 text-sm">
                    <span className="min-w-40 flex-1 font-medium">{m.label}</span>
                    <span className="text-muted">
                      {other.effect === "allow" ? "Allowed" : "Blocked"}
                      {other.actions.length ? `: ${other.actions.map((a) => a.replace(/_/g, " ")).join(", ")}` : ""} · set by someone else
                    </span>
                  </li>
                  </Fragment>
                );
              }
              return (
                <Fragment key={m.id}>
                {heading}
                <li className="flex flex-col gap-2 px-3 py-2 text-sm">
                  <div className="flex flex-wrap items-center gap-3">
                    <span className="min-w-40 flex-1 font-medium">
                      {m.label}
                      {m.sensitive ? <span className="ml-2 text-xs text-muted">sensitive: roles and people only</span> : null}
                    </span>
                    <select aria-label={`${m.label}: access`} value={state} onChange={(ev) => (ev.target.value === "off" ? set(m.id, null) : set(m.id, { effect: ev.target.value as "allow" | "restrict", ...(e || m.everything ? {} : { actions: m.allowed }) }))} className={`${inputClass} w-36`}>
                      <option value="off">Not set</option>
                      <option value="allow">Allow</option>
                      <option value="restrict">Block</option>
                    </select>
                    {e ? (
                      <select aria-label={`${m.label}: whose records`} value={e.scope} onChange={(ev) => set(m.id, { scope: ev.target.value as "all" | "own_teams" | "assigned" })} className={`${inputClass} w-44`}>
                        <option value="all">Everyone&apos;s</option>
                        <option value="own_teams">Their own teams&apos;</option>
                        {m.id.startsWith("clients.") && m.id !== "clients.assign" ? <option value="assigned">Their assigned clients</option> : null}
                      </select>
                    ) : null}
                  </div>
                  {e && e.effect === "allow" && (m.actions.length > 1 || !m.everything) ? (
                    <div className="flex flex-wrap gap-1.5" role="group" aria-label={`What they can do in ${m.label}`}>
                      {m.allowed.map((a) => {
                        const on = !e.actions.length || e.actions.includes(a);
                        return (
                          <button
                            key={a}
                            type="button"
                            aria-pressed={on}
                            onClick={() => {
                              const all = e.actions.length ? e.actions : m.actions;
                              const next = on ? all.filter((x) => x !== a) : [...all, a];
                              if (!next.length) return;
                              set(m.id, { actions: next.length === m.actions.length && m.everything ? [] : next });
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
                </Fragment>
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

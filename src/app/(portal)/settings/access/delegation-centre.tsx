// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useMemo, useState, useTransition } from "react";
import { ChevronRight, Lock, ShieldAlert } from "lucide-react";
import { Badge, Button, Field, Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { useAfterSuccess } from "@/components/use-after-success";
import { changeNomination, nominateAdmin, saveModuleAccess, type ModuleEntry } from "./delegation-actions";

type Option = { id: string; name: string };

// ---------------------------------------------------------------------------
// Manager Administrators (system admin only)
// ---------------------------------------------------------------------------

export function NominateForm({ managers }: { managers: Option[] }) {
  const [state, run, pending] = useActionState(nominateAdmin, null);
  const [key, setKey] = useState(0);
  useAfterSuccess(state, () => setKey((k) => k + 1));
  if (!managers.length) return <p className="text-sm text-muted">Every active manager is already a Manager Administrator.</p>;
  return (
    <form key={key} action={run} className="grid gap-3 sm:grid-cols-[1fr_11rem_1fr_auto] sm:items-end">
      <Field label="Manager" htmlFor="na-user">
        <select id="na-user" name="user_id" required defaultValue="" className={inputClass}>
          <option value="" disabled>
            Choose a manager
          </option>
          {managers.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>
      </Field>
      <Field label="Ends (optional)" htmlFor="na-end">
        <input id="na-end" type="date" name="expires" className={inputClass} />
      </Field>
      <Field label="Note (optional)" htmlFor="na-note">
        <input id="na-note" name="note" maxLength={300} placeholder="For example: looks after HR" className={inputClass} />
      </Field>
      <Button disabled={pending}>{pending ? "Nominating…" : "Nominate"}</Button>
      {state?.error ? (
        <div className="sm:col-span-4">
          <Notice tone="error">{state.error}</Notice>
        </div>
      ) : null}
      {state?.message ? (
        <div className="sm:col-span-4">
          <Notice tone="success">{state.message}</Notice>
        </div>
      ) : null}
    </form>
  );
}

export function NominationButtons({ id, name, status }: { id: string; name: string; status: "active" | "suspended" }) {
  const [pending, start] = useTransition();

  const [error, setError] = useState("");
  const go = (next: "active" | "suspended" | "ended", text: string, action: string) => async () => {
    if (next !== "active" && !(await askConfirm(text, { action }))) return;
    start(async () => {
      const form = new FormData();
      form.set("id", id);
      form.set("status", next);
      const r = await changeNomination(null, form);
      if (r?.error) setError(r.error);
      else if (r?.message) toast(r.message);
    });
  };
  return (
    <div className="flex flex-col items-end gap-1">
      <div className="flex flex-wrap justify-end gap-2">
        {status === "active" ? (
          <Button variant="outline" size="sm" disabled={pending} onClick={go("suspended", `Suspend ${name}? Their admin access, and what they passed on, stops straight away until you resume it.`, "Suspend")}>
            Suspend
          </Button>
        ) : (
          <Button variant="outline" size="sm" disabled={pending} onClick={go("active", "", "")}>
            Resume
          </Button>
        )}
        <Button variant="outline" size="sm" disabled={pending} onClick={go("ended", `End ${name}'s nomination? Their admin access and what they passed on is removed (it stays in the history). You can nominate them again later.`, "End nomination")}>
          End
        </Button>
      </div>
      {error ? <span className="text-xs text-danger">{error}</span> : null}
    </div>
  );
}

// ---------------------------------------------------------------------------
// The permission tree
// ---------------------------------------------------------------------------

export type TreeNode = {
  id: string;
  parent: string | null;
  category: string;
  label: string;
  sensitivity: "normal" | "sensitive" | "protected";
  legacy: "settings" | "record" | null;
  actions: string[];
  depth: number; // 0 = category
};
export type Existing = { module: string; effect: "allow" | "restrict"; actions: string[]; scope: "all" | "teams" | "people"; ids: string[]; expires: string; passOn: boolean; note: string };
// Who can be chosen: managers (Manager Administrators or not) and staff admins.
export type Person = { id: string; name: string; role: "manager" | "staff_admin"; ma: boolean };
// A Manager Administrator's own pass-on access: which modules, which actions ([] = all).
export type Limit = { module: string; actions: string[] };

type Draft = Record<string, { effect: "allow" | "restrict"; actions: string[] }>;

const ACTION_WORD: Record<string, string> = {
  view: "View",
  create: "Create",
  edit: "Edit",
  delete: "Delete",
  configure: "Set up",
  export: "Export",
  approve: "Approve",
  sign_for_employer: "Sign for the employer",
  download: "Download",
  reveal_tfn: "Reveal TFN",
};
const word = (a: string) => ACTION_WORD[a] ?? a.replace(/_/g, " ");

// cmeprojects step 4: modules whose pages already follow the Access page.
// The rest can be set now and take effect as each module is connected.
const CONNECTED = /^(hr\.onboarding|ops\.cars|insights\.reports|workflows\.forms|ops\.features|engagement\.enquiries)(\.|$)/;
// Every manager and staff admin can already do these (the only roles that can be given access).
const ALREADY = /^(ops\.tasks|hr\.requests|clients\.list|people\.staff|people\.teams)(\.|$)/;

export function ModuleAccessEditor({
  admin,
  nodes,
  people,
  teams,
  scopePeople,
  existing,
  limits,
  legacyOn,
}: {
  admin: boolean;
  nodes: TreeNode[];
  people: Person[];
  teams: Option[];
  scopePeople: Option[];
  existing: Record<string, Existing[]>;
  limits: Limit[];
  // Settings areas each person looks after today (set under Settings areas).
  legacyOn: Record<string, string[]>;
}) {
  const byId = useMemo(() => new Map(nodes.map((n) => [n.id, n])), [nodes]);
  // The chain that can decide a node: itself, then (normal ones only) its parents and category.
  const chain = useMemo(() => {
    const out = new Map<string, string[]>();
    for (const n of nodes) {
      const c = [n.id];
      if (n.depth > 0 && n.sensitivity === "normal" && !n.legacy) {
        let p = n.parent;
        while (p) {
          c.push(p);
          p = byId.get(p)?.parent ?? null;
        }
        c.push(`cat_${n.category}`);
      }
      out.set(n.id, c);
    }
    return out;
  }, [nodes, byId]);

  // What a Manager Administrator may pass on (nearest of their grants covering it).
  const limitFor = (id: string): Limit | undefined => {
    if (admin) return { module: id, actions: [] };
    for (const c of chain.get(id) ?? []) {
      const l = limits.find((x) => x.module === c);
      if (l) return l;
    }
    return undefined;
  };

  const [person, setPerson] = useState("");
  const [draft, setDraft] = useState<Draft>({});
  const [scope, setScope] = useState<"all" | "teams" | "people">("all");
  const [chosenIds, setChosenIds] = useState<string[]>([]);
  const [expires, setExpires] = useState("");
  const [passOn, setPassOn] = useState(false);
  const [note, setNote] = useState("");
  const [open, setOpen] = useState<string[]>([]);
  const [reviewing, setReviewing] = useState(false);
  const [error, setError] = useState("");
  const [pending, start] = useTransition();

  const who = people.find((p) => p.id === person);
  // What can be changed for the chosen person. Staff records: staff details to
  // managers or staff admins, payroll and identity to managers. Modules: only
  // for a Manager Administrator. Settings areas are set further down.
  const editable = (n: TreeNode) => {
    if (n.sensitivity === "protected" || n.legacy === "settings") return false;
    if (n.legacy === "record") return admin ? !who || n.id === "hr.records.details" || who.role === "manager" : limits.some((l) => l.module === n.id);
    return admin ? !who || who.ma : Boolean(limitFor(n.id));
  };
  const shown = nodes.filter((n) => (n.depth === 0 ? true : admin ? true : editable(n) || nodes.some((d) => d.parent === n.id && editable(d))));
  const categories = shown.filter((n) => n.depth === 0).filter((c) => shown.some((n) => n.category === c.category && n.depth > 0 && editable(n)));

  const choose = (id: string) => {
    setPerson(id);
    setReviewing(false);
    setError("");
    const rows = existing[id] ?? [];
    setDraft(Object.fromEntries(rows.map((r) => [r.module, { effect: r.effect, actions: r.actions }])));
    setScope(rows[0]?.scope ?? "all");
    setChosenIds(rows[0]?.ids ?? []);
    setExpires(rows[0]?.expires ?? "");
    setPassOn(rows[0]?.passOn ?? false);
    setNote(rows[0]?.note ?? "");
  };

  // Mirrors can(): the nearest level with a setting decides.
  const resolve = (id: string) => {
    for (const c of chain.get(id) ?? []) if (draft[c]) return draft[c];
    return undefined;
  };
  const allowed = (n: TreeNode) =>
    n.legacy === "record" ? draft[n.id]?.effect === "allow" : n.legacy === "settings" ? (legacyOn[person] ?? []).includes(n.id) : n.sensitivity !== "protected" && resolve(n.id)?.effect === "allow";
  const inside = (n: TreeNode) => nodes.filter((d) => d.id !== n.id && !d.legacy && d.sensitivity !== "protected" && (n.depth === 0 ? d.category === n.category : (chain.get(d.id) ?? []).includes(n.id) || isUnder(d, n)));
  const isUnder = (d: TreeNode, n: TreeNode) => {
    let p = d.parent;
    while (p) {
      if (p === n.id) return true;
      p = byId.get(p)?.parent ?? null;
    }
    return false;
  };
  const status = (n: TreeNode): "on" | "partial" | "off" => {
    const kids = inside(n);
    if (n.depth > 0 && allowed(n)) {
      const r = resolve(n.id);
      const limited = Boolean(r && r.actions.length && r.actions.length < n.actions.length);
      return limited || kids.some((k) => !allowed(k)) ? "partial" : "on";
    }
    if (n.depth === 0) {
      const any = kids.filter(allowed).length;
      return any === 0 ? "off" : any === kids.length ? "on" : "partial";
    }
    return kids.some(allowed) ? "partial" : "off";
  };

  const set = (id: string, v: "none" | "allow" | "restrict") =>
    setDraft((d) => {
      const next = { ...d };
      if (v === "none") delete next[id];
      else next[id] = { effect: v, actions: v === "allow" ? (d[id]?.actions ?? []) : [] };
      return next;
    });
  const toggleAction = (n: TreeNode, a: string) =>
    setDraft((d) => {
      const cur = d[n.id];
      if (!cur) return d;
      const all = limitFor(n.id)?.actions.length ? (limitFor(n.id)?.actions as string[]) : n.actions;
      const has = cur.actions.length ? cur.actions : all;
      let next = has.includes(a) ? has.filter((x) => x !== a) : [...has, a];
      if (!next.length) return d;
      if (next.length === n.actions.length) next = [];
      return { ...d, [n.id]: { ...cur, actions: next } };
    });

  const entries: ModuleEntry[] = Object.entries(draft).map(([module, v]) => ({ module, effect: v.effect, actions: v.actions }));
  const personName = people.find((p) => p.id === person)?.name ?? "";

  const save = () =>
    start(async () => {
      const r = await saveModuleAccess({ userId: person, entries, scope, ids: chosenIds, expires, passOn: passOn && who?.role === "manager", note });
      if (r?.error) {
        setError(r.error);
        setReviewing(false);
      } else {
        toast(r?.message ?? "Saved.");
        setReviewing(false);
      }
    });

  if (!people.length) {
    return <p className="text-sm text-muted">{admin ? "There are no active managers or staff admins." : "There are no active staff admins to pass access on to."}</p>;
  }

  // In plain words, for the review.
  // Top-most parts switched on (a category, or a module not already covered by its parent).
  const willDo = nodes
    .filter((n) => n.legacy !== "settings")
    .filter((n) => (n.depth === 0 ? draft[n.id]?.effect === "allow" : allowed(n) && !(n.parent && byId.get(n.parent) && resolve(n.parent)?.effect === "allow" && n.sensitivity === "normal" && !n.legacy)))
    .map((n) => {
      if (n.legacy === "record") return n.id === "hr.records.payroll" ? `${n.label}${draft[n.id]?.actions.length ? ", without revealing TFNs" : ", including revealing TFNs"}` : n.label;
      const r = resolve(n.id);
      const kids = inside(n);
      const blocked = kids.filter((k) => !allowed(k));
      if (n.depth === 0) return `Everything in ${n.label}${blocked.length ? `, except ${blocked.map((b) => b.label).join(", ")}` : ""}`;
      return `${n.label}${r?.actions.length ? ` (${r.actions.map(word).join(", ").toLowerCase()} only)` : ""}${kids.length && !blocked.length ? " and everything in it" : blocked.length ? `, except ${blocked.map((b) => b.label).join(", ")}` : ""}`;
    });
  const rows0 = existing[person] ?? [];
  const mixed = rows0.some((r) => r.scope !== rows0[0].scope || r.ids.join() !== rows0[0].ids.join() || r.expires !== rows0[0].expires);
  const sensitiveSkipped = nodes.filter((n) => n.depth > 0 && n.sensitivity === "sensitive" && !n.legacy && !allowed(n) && entries.some((e) => e.module === `cat_${n.category}` && e.effect === "allow"));

  return (
    <div className="flex flex-col gap-4">
      <Field
        label="Person"
        htmlFor="ma-person"
        hint={admin ? "Managers and staff admins. Admin access to modules only goes to a Manager Administrator." : "Staff admins. You can pass on only what you were allowed to, never wider or longer."}
      >
        <select id="ma-person" value={person} onChange={(e) => choose(e.target.value)} className={inputClass}>
          <option value="">Choose a person</option>
          {people.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
              {admin ? ` · ${p.ma ? "Manager Administrator" : p.role === "manager" ? "Manager" : "Staff admin"}` : ""}
              {existing[p.id]?.length ? " · has access" : ""}
            </option>
          ))}
        </select>
      </Field>

      {person ? (
        <>
          {admin && who && !who.ma ? (
            <Notice tone="info">
              {who.name} isn&apos;t a Manager Administrator, so only staff records access can be given here. Nominate them above (managers only) to give admin access to modules.
            </Notice>
          ) : null}
          <p className="text-sm text-muted">
            Turn a whole category or module <strong>On</strong> and everything inside it follows. {admin ? <>Use <strong>Block</strong> to keep one part out. </> : null}
            Sensitive parts are never included automatically; they need their own On.
          </p>
          <ul className="flex flex-col gap-2">
            {categories.map((c) => {
              const expanded = open.includes(c.id);
              const rows = shown.filter((n) => n.category === c.category && n.depth > 0);
              return (
                <li key={c.id} data-module={c.id} className="rounded-lg border border-line">
                  <div className="flex flex-wrap items-center gap-3 px-3 py-2">
                    <button
                      type="button"
                      aria-expanded={expanded}
                      onClick={() => setOpen((o) => (expanded ? o.filter((x) => x !== c.id) : [...o, c.id]))}
                      className="flex min-w-0 flex-1 basis-52 items-center gap-2 text-left font-semibold"
                    >
                      <ChevronRight aria-hidden="true" className={`size-4 shrink-0 transition-transform ${expanded ? "rotate-90" : ""}`} />
                      {c.label}
                      <StatusPill s={status(c)} />
                    </button>
                    {admin && who?.ma ? <Choice id={c.id} value={draft[c.id]?.effect ?? "none"} onChange={set} admin={admin} /> : null}
                  </div>
                  {expanded ? (
                    <ul className="divide-y divide-line border-t border-line">
                      {rows.map((n) => (
                        <li key={n.id} data-module={n.id} className="flex flex-wrap items-center gap-x-3 gap-y-2 px-3 py-2 text-sm" style={{ paddingLeft: `${0.75 + n.depth * 1.25}rem` }}>
                          <span className="flex min-w-0 flex-1 basis-56 flex-wrap items-center gap-2">
                            {n.label}
                            {n.sensitivity === "sensitive" ? (
                              <Badge tone="warn">
                                <ShieldAlert aria-hidden="true" className="mr-1 inline size-3" />
                                Sensitive
                              </Badge>
                            ) : null}
                            {n.sensitivity === "protected" ? (
                              <Badge tone="grey">
                                <Lock aria-hidden="true" className="mr-1 inline size-3" />
                                System admin only
                              </Badge>
                            ) : n.legacy ? (
                              <StatusPill s={allowed(n) ? "on" : "off"} />
                            ) : (
                              <StatusPill s={status(n)} />
                            )}
                          </span>
                          {n.legacy === "settings" ? (
                            <a href="#settings-areas" className="text-xs font-semibold text-brand underline">
                              Change under Settings areas
                            </a>
                          ) : editable(n) ? (
                            <Choice id={n.id} value={draft[n.id]?.effect ?? "none"} onChange={set} admin={admin && !n.legacy} />
                          ) : n.legacy === "record" ? (
                            <span className="text-xs text-muted">Managers only</span>
                          ) : null}
                          {!n.legacy && n.sensitivity !== "protected" && !CONNECTED.test(n.id) && editable(n) ? (
                            <span className="w-full text-xs text-muted">
                              {ALREADY.test(n.id) ? "Managers and staff admins already have this." : "Can be set now; takes effect in a later update."}
                            </span>
                          ) : null}
                          {draft[n.id]?.effect === "allow" && n.actions.length > 1 ? (
                            <div className="flex w-full flex-wrap gap-1.5" role="group" aria-label={`What they can do in ${n.label}`}>
                              {(limitFor(n.id)?.actions.length ? (limitFor(n.id)?.actions as string[]) : n.actions).map((a) => {
                                const on = !draft[n.id].actions.length || draft[n.id].actions.includes(a);
                                return (
                                  <button
                                    key={a}
                                    type="button"
                                    aria-pressed={on}
                                    onClick={() => toggleAction(n, a)}
                                    className={`rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ${on ? "bg-brand text-white ring-brand" : "bg-surface text-muted ring-line"}`}
                                  >
                                    {word(a)}
                                  </button>
                                );
                              })}
                            </div>
                          ) : null}
                        </li>
                      ))}
                    </ul>
                  ) : null}
                </li>
              );
            })}
          </ul>

          <fieldset className="grid gap-3 rounded-lg border border-line p-3 sm:grid-cols-2">
            <legend className="px-1 text-sm font-semibold">Conditions</legend>
            <Field label="Covers" htmlFor="ma-scope">
              <select id="ma-scope" value={scope} onChange={(e) => (setScope(e.target.value as "all" | "teams" | "people"), setChosenIds([]))} className={inputClass}>
                <option value="all">All staff</option>
                <option value="teams">Only some teams</option>
                <option value="people">Only some people</option>
              </select>
            </Field>
            <Field label="Ends (optional)" htmlFor="ma-end">
              <input id="ma-end" type="date" value={expires} onChange={(e) => setExpires(e.target.value)} className={inputClass} />
            </Field>
            {scope !== "all" ? (
              <div className="flex max-h-56 flex-wrap gap-x-4 gap-y-2 overflow-y-auto text-sm sm:col-span-2">
                {(scope === "teams" ? teams : scopePeople).map((t) => (
                  <label key={t.id} className="flex items-center gap-2">
                    <input type="checkbox" checked={chosenIds.includes(t.id)} onChange={(e) => setChosenIds((c) => (e.target.checked ? [...c, t.id] : c.filter((x) => x !== t.id)))} />
                    {t.name}
                  </label>
                ))}
              </div>
            ) : null}
            {mixed ? <p className="text-xs text-warn sm:col-span-2">Their access had different conditions; saving applies these to everything you give them.</p> : null}
            {admin && who?.role === "manager" ? (
              <label className="flex items-center gap-2 text-sm sm:col-span-2">
                <input type="checkbox" checked={passOn} onChange={(e) => setPassOn(e.target.checked)} />
                May pass this on to staff admins (never wider, never further)
              </label>
            ) : null}
            <Field label="Note (optional)" htmlFor="ma-note">
              <input id="ma-note" value={note} maxLength={300} onChange={(e) => setNote(e.target.value)} className={inputClass} />
            </Field>
          </fieldset>

          {error ? <Notice tone="error">{error}</Notice> : null}

          {reviewing ? (
            <div className="flex flex-col gap-3 rounded-lg border border-brand bg-brand-soft/40 p-4 text-sm">
              <p className="font-semibold">Check before saving: {personName}</p>
              {willDo.length ? (
                <div>
                  <p>Will be able to use:</p>
                  <ul className="ml-5 list-disc">
                    {willDo.map((w) => (
                      <li key={w}>{w}</li>
                    ))}
                  </ul>
                </div>
              ) : (
                <p>Will have no admin access{existing[person]?.length ? " (everything you gave before is removed)" : ""}.</p>
              )}
              {sensitiveSkipped.length ? <p>Won&apos;t get (sensitive, needs its own On): {sensitiveSkipped.map((s) => s.label).join(", ")}.</p> : null}
              <p className="text-muted">
                {scope === "teams" ? `Only for the teams chosen` : "For all staff"}
                {expires ? `, until ${new Date(`${expires}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" })}` : ", no end date"}
                {passOn ? ", may pass it on to staff admins" : ""}. It works straight away and is recorded in the change log.
              </p>
              <div className="flex flex-wrap gap-2">
                <Button type="button" onClick={save} disabled={pending}>
                  {pending ? "Saving…" : "Save access"}
                </Button>
                <Button type="button" variant="outline" onClick={() => setReviewing(false)} disabled={pending}>
                  Back
                </Button>
              </div>
            </div>
          ) : (
            <Button type="button" className="self-start" onClick={() => (setError(""), setReviewing(true))} icon={null}>
              Review changes
            </Button>
          )}
        </>
      ) : null}
    </div>
  );
}

function StatusPill({ s }: { s: "on" | "partial" | "off" }) {
  return s === "on" ? <Badge tone="good">On</Badge> : s === "partial" ? <Badge tone="warn">Partly</Badge> : <Badge tone="grey">Off</Badge>;
}

function Choice({ id, value, onChange, admin }: { id: string; value: "none" | "allow" | "restrict"; onChange: (id: string, v: "none" | "allow" | "restrict") => void; admin: boolean }) {
  const opts: ["none" | "allow" | "restrict", string][] = admin ? [["none", "Not set"], ["allow", "On"], ["restrict", "Block"]] : [["none", "Off"], ["allow", "On"]];
  return (
    <div role="radiogroup" aria-label="Access" className="inline-flex shrink-0 rounded-lg bg-page p-0.5 ring-1 ring-line">
      {opts.map(([v, t]) => (
        <button
          key={v}
          type="button"
          role="radio"
          aria-checked={value === v}
          onClick={() => onChange(id, v)}
          className={`rounded-md px-2.5 py-1 text-xs font-semibold ${value === v ? (v === "restrict" ? "bg-danger text-white" : v === "allow" ? "bg-brand text-white" : "bg-surface text-ink shadow-sm") : "text-muted"}`}
        >
          {t}
        </button>
      ))}
    </div>
  );
}

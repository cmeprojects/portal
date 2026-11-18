// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, useTransition } from "react";
import { ArrowDown, ArrowUp, Bell, Eye, Loader2, NotebookText, Pencil, RefreshCw, Search, SlidersHorizontal, X } from "lucide-react";
import { loadClientNotes, type ClientNotes } from "./notes-actions";
import { inputClass } from "@/components/ui";
import { ClientCareForm } from "./care-forms";
import { ClientRow, ClientStatusChip } from "../../cars/manage/forms";

export type ListBudget = { scheme: string; schemeLabel: string; label: string; total: number; used: number; usedAsOf: string | null; periodStart: string; periodEnd: string; management: string };
export type ListClient = {
  id: string;
  name: string;
  ref: string;
  reference: string;
  preferredName: string;
  status: string;
  active: boolean;
  age: number | null;
  ndisNumber: string;
  email: string;
  phone: string;
  suburb: string;
  schemes: string[];
  services: string[];
  managers: { name: string; as: string }[];
  teams: string[];
  budgets: ListBudget[];
  reviews: { label: string; due: string; overdue: boolean }[];
  agreements: { label: string; status: string; ends: string | null }[];
  alerts: number;
  // Next shifts and recent shift notes (null when this person can't see them).
  shifts: { id: string; when: string; worker: string; draft: boolean; day: string }[] | null;
  notes: { when: string; worker: string; wellbeing: string; concern: boolean; text: string }[] | null;
};
const WELLBEING: Record<string, [string, string]> = {
  settled: ["Settled", "bg-good-soft"],
  some_concerns: ["Some concerns", "bg-warn-soft"],
  unwell_or_distressed: ["Unwell or distressed", "bg-danger-soft text-danger"],
};

type SortKey = "name" | "age" | "manager" | "used" | "review";
const aud = (n: number) => n.toLocaleString("en-AU", { style: "currency", currency: "AUD", maximumFractionDigits: 0 });
const day = (d: string | null) => (d ? new Date(`${d}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");
const usedPct = (c: ListClient) => {
  const total = c.budgets.reduce((s, b) => s + b.total, 0);
  return total > 0 ? Math.round((c.budgets.reduce((s, b) => s + b.used, 0) / total) * 100) : null;
};
const isArchived = (c: ListClient) => !c.active || c.status === "discharged";
const in30 = new Date(Date.parse(`${new Date().toISOString().slice(0, 10)}T12:00:00Z`) + 30 * 86_400_000).toISOString().slice(0, 10);
type NotesTab = "alerts" | "shift" | "practitioner" | "comms" | "log" | "reviews";
const CONTACT_WORDS: Record<string, string> = { phone: "Phone call", sms: "Text message", email: "Email", post: "Post" };

// cmeprojects: one client's notes in a pop-up, loaded when opened. Each part is
// what the database lets this person see; parts they can't see are left out.
function NotesPopup({ client, tab: firstTab, onClose }: { client: ListClient; tab: NotesTab; onClose: () => void }) {
  const [tab, setTab] = useState<NotesTab>(firstTab);
  const [data, setData] = useState<ClientNotes | null>(null);
  const [error, setError] = useState("");
  const [loading, start] = useTransition();
  useEffect(() => {
    start(async () => {
      const r = await loadClientNotes(client.id);
      if ("error" in r) setError(r.error);
      else setData(r);
    });
    const esc = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [client.id, onClose]);
  const tabs: [NotesTab, string, number | null][] = [
    ["alerts", "Safety alerts", data?.alerts?.length ?? null],
    ["shift", "Shift and progress notes", data?.shiftNotes?.length ?? null],
    ["practitioner", "Practitioner notes", data?.practitionerNotes?.length ?? null],
    ["comms", "Communications", null],
    ["log", "Activity log", data?.log?.length ?? null],
    ["reviews", "Reviews", data?.reviews?.filter((r) => r.status === "open").length ?? null],
  ];
  const empty = (t: string) => <p className="text-sm text-muted">{t}</p>;
  const hidden = empty("You don't have access to this part.");
  return (
    <>
      <button type="button" aria-label="Close" onClick={onClose} className="fixed inset-0 z-40 bg-black/30" />
      <div role="dialog" aria-modal="true" aria-label={`${client.name}: notes`} className="fixed inset-x-4 top-[8vh] z-50 mx-auto flex max-h-[84vh] max-w-2xl flex-col overflow-hidden rounded-xl bg-surface shadow-2xl">
        <div className="flex items-start gap-2 border-b border-line p-4">
          <div className="min-w-0 flex-1">
            <h2 className="heading-sm">{client.name}</h2>
            <p className="text-xs text-muted">{client.ref}</p>
          </div>
          <Link href={`/settings/clients/${client.id}`} className="text-xs font-semibold text-brand underline">
            Open profile
          </Link>
          <button type="button" onClick={onClose} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
            <X aria-hidden="true" className="size-5" />
          </button>
        </div>
        <div className="thin-scroll flex gap-1 overflow-x-auto border-b border-line px-3" role="tablist">
          {tabs.map(([k, l, n]) => (
            <button key={k} type="button" role="tab" aria-selected={tab === k} onClick={() => setTab(k)} className={`-mb-px shrink-0 border-b-2 px-2 py-2 text-xs font-semibold ${tab === k ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"}`}>
              {l}
              {n ? <span className="ml-1 rounded-full bg-page px-1.5 text-[10px]">{n}</span> : null}
            </button>
          ))}
        </div>
        <div className="thin-scroll flex-1 overflow-y-auto p-4 text-sm">
          {error ? (
            empty(error)
          ) : loading || !data ? (
            <p className="flex items-center gap-2 text-muted">
              <Loader2 aria-hidden="true" className="size-4 animate-spin" /> Loading…
            </p>
          ) : tab === "alerts" ? (
            data.alerts === null ? hidden : data.alerts.length ? (
              <ul className="flex flex-col gap-2">
                {data.alerts.map((a, i) => (
                  <li key={i} className={`rounded-lg border p-3 ${a.severity === "high" ? "border-danger" : "border-line"}`}>
                    <p className="flex flex-wrap items-center gap-2">
                      <span className="font-semibold">{a.title}</span>
                      <span className="rounded-full bg-page px-2 py-0.5 text-xs">{a.kind}</span>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${a.severity === "high" ? "bg-danger-soft text-danger" : a.severity === "medium" ? "bg-warn-soft" : "bg-good-soft"}`}>{a.severity}</span>
                    </p>
                    {a.instructions ? <p className="mt-1 whitespace-pre-wrap"><span className="text-muted">What workers do: </span>{a.instructions}</p> : null}
                    {a.escalation ? <p className="mt-1 whitespace-pre-wrap"><span className="text-muted">If it happens: </span>{a.escalation}</p> : null}
                  </li>
                ))}
              </ul>
            ) : empty("No active safety alerts.")
          ) : tab === "shift" ? (
            data.shiftNotes === null ? hidden : data.shiftNotes.length ? (
              <ul className="flex flex-col gap-2">
                {data.shiftNotes.map((n, i) => (
                  <li key={i} className={`rounded-lg border p-3 ${n.concern ? "border-danger" : "border-line"}`}>
                    <p className="flex flex-wrap items-center gap-2 text-xs text-muted">
                      <span className="font-semibold text-ink">{n.worker}</span> {n.when}
                      {WELLBEING[n.wellbeing] ? <span className={`rounded-full px-2 py-0.5 font-semibold ${WELLBEING[n.wellbeing][1]}`}>{WELLBEING[n.wellbeing][0]}</span> : null}
                      {n.concern ? <span className="rounded-full bg-danger-soft px-2 py-0.5 font-semibold text-danger">Incident or issue</span> : null}
                    </p>
                    <p className="mt-1 whitespace-pre-wrap">{n.text}</p>
                    {n.concern && n.concernNote ? <p className="mt-1 whitespace-pre-wrap text-danger">{n.concernNote}</p> : null}
                  </li>
                ))}
              </ul>
            ) : empty("No shift notes in the last 90 days.")
          ) : tab === "practitioner" ? (
            data.practitionerNotes === null ? hidden : data.practitionerNotes.length ? (
              <ul className="flex flex-col gap-2">
                {data.practitionerNotes.map((n, i) => (
                  <li key={i} className="rounded-lg border border-line p-3">
                    <p className="text-xs text-muted"><span className="font-semibold text-ink">{n.who}</span> {n.when}</p>
                    <p className="mt-1 whitespace-pre-wrap">{n.text}</p>
                  </li>
                ))}
              </ul>
            ) : empty("No practitioner notes.")
          ) : tab === "comms" ? (
            <div className="flex flex-col gap-3">
              {data.comms ? (
                <dl className="grid grid-cols-[10rem_1fr] gap-y-1">
                  <dt className="text-muted">Preferred contact</dt>
                  <dd>{CONTACT_WORDS[data.comms.contact] ?? (data.comms.contact || "Not set")}</dd>
                  <dt className="text-muted">Language</dt>
                  <dd>{data.comms.language || "Not set"}{data.comms.interpreter ? " (needs an interpreter)" : ""}</dd>
                  {data.comms.needs ? (<><dt className="text-muted">Accessibility needs</dt><dd className="whitespace-pre-wrap">{data.comms.needs}</dd></>) : null}
                  {data.comms.notes ? (<><dt className="text-muted">Notes</dt><dd className="whitespace-pre-wrap">{data.comms.notes}</dd></>) : null}
                </dl>
              ) : empty("No communication preferences recorded, or you don't have access to them.")}
              <p className="rounded-lg bg-page px-3 py-2 text-xs text-muted">A log of calls, emails and meetings with the client isn&apos;t set up yet.</p>
            </div>
          ) : tab === "log" ? (
            data.log === null ? hidden : data.log.length ? (
              <ul className="flex flex-col divide-y divide-line">
                {data.log.map((l, i) => (
                  <li key={i} className="flex flex-wrap gap-x-3 py-1.5">
                    <span className="flex-1">{l.what}</span>
                    <span className="text-xs text-muted">{l.who} · {l.when}</span>
                  </li>
                ))}
              </ul>
            ) : empty("Nothing logged yet.")
          ) : data.reviews === null ? (
            hidden
          ) : data.reviews.length ? (
            <ul className="flex flex-col gap-2">
              {data.reviews.map((r, i) => {
                const overdue = r.status === "open" && r.due < new Date().toISOString().slice(0, 10);
                const soon = r.status === "open" && !overdue && r.due <= in30;
                return (
                  <li key={i} className={`flex flex-wrap items-center gap-2 rounded-lg border p-3 ${overdue ? "border-danger" : soon ? "border-warn" : "border-line"} ${r.status === "open" ? "" : "text-muted"}`}>
                    <span className="min-w-40 flex-1 font-semibold">{r.label}</span>
                    <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${overdue ? "bg-danger-soft text-danger" : soon ? "bg-warn-soft" : r.status === "open" ? "bg-page" : "bg-line"}`}>
                      {r.status === "open" ? (overdue ? `Overdue (due ${day(r.due)})` : `Due ${day(r.due)}`) : r.status === "completed" ? "Completed" : "Cancelled"}
                    </span>
                    {r.reason ? <p className="w-full text-xs text-muted">What changed: {r.reason}</p> : null}
                  </li>
                );
              })}
            </ul>
          ) : (
            empty("No reviews or re-assessments set up.")
          )}
        </div>
      </div>
    </>
  );
}

// cmeprojects (owner's client list concept, 17 Nov 2026): a searchable,
// sortable table with Active and Archived tabs; a client opens in a side
// panel (Overview, Plan budget, Reviews and agreements). Each column only
// holds what this person may already see (the database decides).
export function ClientList({ clients, word, schemes, showNdis, showBudget, showContact }: { clients: ListClient[]; word: string; schemes: [string, string][]; showNdis: boolean; showBudget: boolean; showContact: boolean }) {
  const router = useRouter();
  // The notes pop-up (shift notes, practitioner notes, communications, log, reviews).
  const [notesFor, setNotesFor] = useState<{ client: ListClient; tab: NotesTab } | null>(null);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [tab, setTab] = useState<"active" | "archived">("active");
  const [q, setQ] = useState("");
  const [scheme, setScheme] = useState("");
  const [manager, setManager] = useState("");
  const [status, setStatus] = useState("");
  const [sort, setSort] = useState<{ key: SortKey; up: boolean }>({ key: "name", up: true });
  const [open, setOpen] = useState<string | null>(null);
  const plural = word.endsWith("s") ? word : `${word}s`;

  const managers = useMemo(() => [...new Set(clients.flatMap((c) => c.managers.map((m) => m.name)))].sort(), [clients]);
  const counts = { active: clients.filter((c) => !isArchived(c)).length, archived: clients.filter(isArchived).length };
  const rows = useMemo(() => {
    const term = q.trim().toLowerCase();
    const list = clients.filter(
      (c) =>
        (tab === "archived") === isArchived(c) &&
        (!term || [c.name, c.preferredName, c.ref, c.reference, c.ndisNumber, c.email, c.suburb, ...c.services].some((v) => v.toLowerCase().includes(term))) &&
        (!scheme || c.schemes.includes(scheme)) &&
        (!manager || (manager === "-" ? c.managers.length === 0 : c.managers.some((m) => m.name === manager))) &&
        (!status || c.status === status),
    );
    const val = (c: ListClient): string | number => {
      switch (sort.key) {
        case "age":
          return c.age ?? -1;
        case "manager":
          return c.managers[0]?.name ?? "~";
        case "used":
          return usedPct(c) ?? -1;
        case "review":
          return c.reviews[0]?.due ?? "9999";
        default:
          return c.name.toLowerCase();
      }
    };
    return list.sort((a, b) => {
      const x = val(a);
      const y = val(b);
      return (x < y ? -1 : x > y ? 1 : 0) * (sort.up ? 1 : -1);
    });
  }, [clients, tab, q, scheme, manager, status, sort]);
  const picked = clients.find((c) => c.id === open) ?? null;

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(null);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <div className="shadow-card flex flex-col rounded-xl border border-line bg-surface">
      <div className="flex flex-wrap items-center gap-2 border-b border-line px-3 pt-2">
        {(["active", "archived"] as const).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setTab(t)}
            className={`-mb-px border-b-2 px-3 py-2 text-sm font-semibold ${tab === t ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"}`}
          >
            {t === "active" ? "Active" : "Archived"} <span className="text-xs font-normal text-muted">{counts[t]}</span>
          </button>
        ))}
      </div>
      <div className="flex flex-wrap items-center gap-2 p-3">
        <button type="button" onClick={() => setFiltersOpen((o) => !o)} aria-expanded={filtersOpen} className={`inline-flex h-11 items-center gap-2 rounded-lg border px-3 text-sm font-semibold md:h-10 ${filtersOpen || scheme || manager || status ? "border-brand bg-brand-soft text-ink" : "border-field text-muted hover:text-ink"}`}>
          <SlidersHorizontal aria-hidden="true" className="size-4" /> Filters
        </button>
        <label className="relative min-w-48 flex-1">
          <span className="sr-only">Search</span>
          <Search aria-hidden="true" className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted" />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={`Search name, reference${showNdis ? ", NDIS number" : ""}${showContact ? ", email, suburb" : ""} or service`} className={`${inputClass} pl-8`} />
        </label>
        <button type="button" onClick={() => router.refresh()} title="Refresh" aria-label="Refresh" className="inline-flex size-11 items-center justify-center rounded-lg text-muted hover:bg-page hover:text-ink md:size-10">
          <RefreshCw aria-hidden="true" className="size-4" />
        </button>
      </div>
      <div className={`${filtersOpen ? "flex" : "hidden"} flex-wrap items-center gap-2 px-3 pb-3`}>
        <select aria-label="Scheme" value={scheme} onChange={(e) => setScheme(e.target.value)} className={`${inputClass.replace("w-full", "")} w-full sm:w-44`}>
          <option value="">All schemes</option>
          {schemes.map(([k, l]) => (
            <option key={k} value={k}>
              {l}
            </option>
          ))}
        </select>
        <select aria-label="Assigned manager" value={manager} onChange={(e) => setManager(e.target.value)} className={`${inputClass.replace("w-full", "")} w-full sm:w-44`}>
          <option value="">Any manager</option>
          <option value="-">Nobody assigned</option>
          {managers.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
        {tab === "active" ? (
          <select aria-label="Status" value={status} onChange={(e) => setStatus(e.target.value)} className={`${inputClass.replace("w-full", "")} w-full sm:w-44`}>
            <option value="">Any status</option>
            <option value="active">Active</option>
            <option value="pending">To check</option>
            <option value="suspended">Suspended</option>
          </select>
        ) : null}
      </div>
      {rows.length ? (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[46rem] text-sm">
            <thead className="border-y border-line bg-page/60">
              <tr>
                <HeadCell sort={sort} setSort={setSort} k="name">Name</HeadCell>
                <HeadCell sort={sort} setSort={setSort} k="age" className="w-16">Age</HeadCell>
                {showContact ? <HeadCell sort={sort} setSort={setSort}>Email</HeadCell> : null}
                {showNdis ? <HeadCell sort={sort} setSort={setSort}>NDIS number</HeadCell> : null}
                {showContact ? <HeadCell sort={sort} setSort={setSort}>Suburb</HeadCell> : null}
                <HeadCell sort={sort} setSort={setSort}>Services</HeadCell>
                <HeadCell sort={sort} setSort={setSort} k="manager">Assigned manager</HeadCell>
                {showBudget ? <HeadCell sort={sort} setSort={setSort} k="used" className="w-36">Funds used</HeadCell> : null}
                <HeadCell sort={sort} setSort={setSort} k="review">Next review</HeadCell>
                <HeadCell sort={sort} setSort={setSort} className="w-20 text-right">Actions</HeadCell>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {rows.map((c) => {
                const pct = usedPct(c);
                return (
                  <tr key={c.id} onClick={() => setOpen(c.id)} className={`cursor-pointer hover:bg-page/70 ${open === c.id ? "bg-brand-soft/40" : ""}`}>
                    <td className="px-3 py-2">
                      <button type="button" onClick={() => setOpen(c.id)} className="text-left font-semibold hover:text-brand">
                        {c.name}
                      </button>
                      <span className="flex flex-wrap items-center gap-1.5 text-xs text-muted">
                        {c.ref}
                        {c.status !== "active" ? <ClientStatusChip status={c.status} /> : null}
                        {c.alerts ? (
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setNotesFor({ client: c, tab: "alerts" });
                            }}
                            title="See the safety alerts"
                            className="rounded-full bg-danger px-1.5 font-semibold text-white hover:opacity-90"
                          >
                            {c.alerts} alert{c.alerts === 1 ? "" : "s"}
                          </button>
                        ) : null}
                      </span>
                    </td>
                    <td className="px-3 py-2 text-muted">{c.age ?? ""}</td>
                    {showContact ? <td className="max-w-48 truncate px-3 py-2 text-muted">{c.email}</td> : null}
                    {showNdis ? <td className="px-3 py-2 tabular-nums">{c.ndisNumber}</td> : null}
                    {showContact ? <td className="px-3 py-2 text-muted">{c.suburb}</td> : null}
                    <td className="px-3 py-2">
                      <span className="flex flex-wrap gap-1">
                        {c.schemes.map((s) => (
                          <span key={s} className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">
                            {schemes.find(([k]) => k === s)?.[1] ?? s}
                          </span>
                        ))}
                        {!c.schemes.length ? <span className="text-xs text-muted">None yet</span> : null}
                      </span>
                    </td>
                    <td className="px-3 py-2">{c.managers.length ? c.managers.map((m) => m.name).join(", ") : <span className="text-muted">Nobody</span>}</td>
                    {showBudget ? (
                      <td className="px-3 py-2">
                        {pct === null ? (
                          <span className="text-muted">—</span>
                        ) : (
                          <span className="flex items-center gap-2">
                            <span className="h-1.5 w-16 overflow-hidden rounded-full bg-line" aria-hidden="true">
                              <span className={`block h-full ${pct >= 90 ? "bg-danger" : pct >= 75 ? "bg-warn" : "bg-good"}`} style={{ width: `${Math.min(100, pct)}%` }} />
                            </span>
                            <span className="text-xs tabular-nums">{pct}%</span>
                          </span>
                        )}
                      </td>
                    ) : null}
                    <td className={`px-3 py-2 text-xs ${c.reviews[0]?.overdue ? "font-semibold text-danger" : "text-muted"}`}>
                      {c.reviews[0] ? `${c.reviews[0].label} · ${c.reviews[0].overdue ? "overdue" : day(c.reviews[0].due)}` : "—"}
                    </td>
                    <td className="px-3 py-2" onClick={(e) => e.stopPropagation()}>
                      <span className="flex justify-end gap-1">
                        {(() => {
                          // Reviews and re-assessments: red when overdue, amber when due within 30 days.
                          const soon = c.reviews.filter((r) => !r.overdue && r.due <= in30).length;
                          const late = c.reviews.filter((r) => r.overdue).length;
                          const tone = late ? "bg-danger-soft text-danger" : soon ? "bg-warn-soft text-ink" : "bg-page text-muted";
                          const tip = late ? `${late} overdue` : soon ? `${soon} due within 30 days` : c.reviews.length ? `Next due ${day(c.reviews[0].due)}` : "No open reviews";
                          return (
                            <button type="button" onClick={() => setNotesFor({ client: c, tab: "reviews" })} title={`Reviews and re-assessments: ${tip}`} aria-label={`Reviews for ${c.name}: ${tip}`} className={`relative inline-flex size-8 items-center justify-center rounded-full hover:opacity-80 ${tone}`}>
                              <Bell aria-hidden="true" className="size-4" />
                              {late || soon ? <span className={`absolute -top-0.5 -right-0.5 flex size-4 items-center justify-center rounded-full text-[9px] font-bold text-white ${late ? "bg-danger" : "bg-warn"}`}>{late || soon}</span> : null}
                            </button>
                          );
                        })()}
                        <button type="button" onClick={() => setNotesFor({ client: c, tab: "shift" })} title="Notes, communications and log" aria-label={`Notes for ${c.name}`} className="inline-flex size-8 items-center justify-center rounded-full bg-yellow-soft text-ink hover:opacity-80">
                          <NotebookText aria-hidden="true" className="size-4" />
                        </button>
                        <Link href={`/settings/clients/${c.id}`} title="View" aria-label={`View ${c.name}`} className="inline-flex size-8 items-center justify-center rounded-full bg-brand-soft text-brand hover:opacity-80">
                          <Eye aria-hidden="true" className="size-4" />
                        </Link>
                        <Link href={`/settings/clients/${c.id}?edit=basic`} title="Edit" aria-label={`Edit ${c.name}`} className="inline-flex size-8 items-center justify-center rounded-full bg-good-soft text-ink hover:opacity-80">
                          <Pencil aria-hidden="true" className="size-4" />
                        </Link>
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      ) : (
        <p className="px-4 pb-6 pt-2 text-center text-sm text-muted">
          {clients.length ? `No ${plural.toLowerCase()} match.` : `No ${plural.toLowerCase()} yet. Add one above.`}
        </p>
      )}
      {picked ? <Panel client={picked} onClose={() => setOpen(null)} schemes={schemes} showBudget={showBudget} /> : null}
      {notesFor ? <NotesPopup key={notesFor.client.id} client={notesFor.client} tab={notesFor.tab} onClose={() => setNotesFor(null)} /> : null}
    </div>
  );
}

function HeadCell({ k, children, className = "", sort, setSort }: { k?: SortKey; children: string; className?: string; sort: { key: SortKey; up: boolean }; setSort: (f: (s: { key: SortKey; up: boolean }) => { key: SortKey; up: boolean }) => void }) {
  return (
    <th scope="col" className={`px-3 py-2 text-left text-xs font-semibold text-muted ${className}`}>
      {k ? (
        <button type="button" onClick={() => setSort((s) => ({ key: k, up: s.key === k ? !s.up : true }))} className="inline-flex items-center gap-1 hover:text-ink">
          {children}
          {sort.key === k ? sort.up ? <ArrowUp aria-hidden="true" className="size-3" /> : <ArrowDown aria-hidden="true" className="size-3" /> : null}
        </button>
      ) : (
        children
      )}
    </th>
  );
}

function Panel({ client: c, onClose, schemes, showBudget }: { client: ListClient; onClose: () => void; schemes: [string, string][]; showBudget: boolean }) {
  const [tab, setTab] = useState<"overview" | "budget" | "reviews" | "shifts">("overview");
  const tabs: [typeof tab, string][] = [
    ["overview", "Overview"],
    ...(showBudget ? [["budget", "Plan budget"] as [typeof tab, string]] : []),
    ["reviews", "Reviews and agreements"],
    ...(c.shifts || c.notes ? [["shifts", "Shifts and notes"] as [typeof tab, string]] : []),
  ];
  return (
    <>
      <button type="button" aria-label="Close" onClick={onClose} className="fixed inset-0 z-40 bg-black/20" />
      <aside role="dialog" aria-label={c.name} className="thin-scroll fixed inset-y-0 right-0 z-50 flex w-full max-w-md flex-col overflow-y-auto bg-surface shadow-2xl">
        <div className="flex items-start gap-2 border-b border-line p-4">
          <div className="min-w-0 flex-1">
            <h2 className="heading-sm">{c.name}</h2>
            <p className="text-xs text-muted">
              {c.ref}
              {c.preferredName ? ` · goes by ${c.preferredName}` : ""}
              {c.age !== null ? ` · ${c.age} years` : ""}
            </p>
            <div className="mt-1 flex flex-wrap gap-1">
              <ClientStatusChip status={c.status} />
              {c.schemes.map((s) => (
                <span key={s} className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">
                  {schemes.find(([k]) => k === s)?.[1] ?? s}
                </span>
              ))}
            </div>
          </div>
          <button type="button" onClick={onClose} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
            <X aria-hidden="true" className="size-5" />
          </button>
        </div>
        <div className="flex gap-1 border-b border-line px-3">
          {tabs.map(([k, l]) => (
            <button key={k} type="button" onClick={() => setTab(k)} className={`-mb-px border-b-2 px-2 py-2 text-xs font-semibold ${tab === k ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"}`}>
              {l}
            </button>
          ))}
        </div>
        <div className="flex flex-col gap-4 p-4 text-sm">
          {tab === "overview" ? (
            <>
              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5">
                {c.ndisNumber ? (
                  <>
                    <dt className="text-muted">NDIS number</dt>
                    <dd className="tabular-nums">{c.ndisNumber}</dd>
                  </>
                ) : null}
                <dt className="text-muted">Services</dt>
                <dd>{c.services.length ? c.services.join(", ") : "None yet"}</dd>
                <dt className="text-muted">Managed by</dt>
                <dd>{c.managers.length ? c.managers.map((m) => `${m.name} (${m.as})`).join(", ") : "Nobody assigned"}</dd>
                <dt className="text-muted">Teams</dt>
                <dd>{c.teams.length ? c.teams.join(", ") : "None"}</dd>
                <dt className="text-muted">Safety alerts</dt>
                <dd>{c.alerts ? `${c.alerts} active` : "None active"}</dd>
              </dl>
              <Link href={`/settings/clients/${c.id}`} className="inline-flex w-fit rounded-lg bg-brand px-3 py-1.5 text-xs font-semibold text-brand-fg hover:opacity-90">
                View full profile
              </Link>
              <div className="border-t border-line pt-3">
                <h3 className="mb-1 text-xs font-semibold uppercase text-muted">Status and preferred name</h3>
                <ClientCareForm client={{ id: c.id, name: c.name, client_ref: c.ref, status: c.status, preferred_name: c.preferredName }} />
              </div>
              <ul className="border-t border-line pt-1">
                <ClientRow client={{ id: c.id, name: c.name, reference: c.reference, active: c.active, client_ref: c.ref, status: c.status }} />
              </ul>
            </>
          ) : tab === "shifts" ? (
            <>
              {c.shifts ? (
                <div>
                  <h3 className="mb-1 text-xs font-semibold uppercase text-muted">Next two weeks</h3>
                  {c.shifts.length ? (
                    <ul className="flex flex-col gap-1">
                      {c.shifts.map((x) => (
                        <li key={x.id}>
                          <Link href={`/roster?by=client&d=${x.day}&shift=${x.id}`} className="font-semibold hover:text-brand">
                            {x.when}
                          </Link>{" "}
                          · {x.worker || <span className="font-semibold text-danger">not filled</span>}
                          {x.draft ? <span className="ml-1 rounded-full bg-brand-soft px-1.5 text-xs font-semibold">Draft</span> : null}
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <p className="text-muted">No shifts booked.</p>
                  )}
                </div>
              ) : null}
              {c.notes ? (
                <div>
                  <h3 className="mb-1 text-xs font-semibold uppercase text-muted">Recent shift notes</h3>
                  {c.notes.length ? (
                    <ul className="flex flex-col gap-2">
                      {c.notes.map((n, i) => (
                        <li key={i} className={`rounded-lg border p-2 ${n.concern ? "border-danger" : "border-line"}`}>
                          <p className="flex flex-wrap items-center gap-1.5 text-xs text-muted">
                            <span className="font-semibold text-ink">{n.worker}</span> {n.when}
                            {WELLBEING[n.wellbeing] ? <span className={`rounded-full px-1.5 font-semibold ${WELLBEING[n.wellbeing][1]}`}>{WELLBEING[n.wellbeing][0]}</span> : null}
                            {n.concern ? <span className="rounded-full bg-danger-soft px-1.5 font-semibold text-danger">Incident or issue</span> : null}
                          </p>
                          <p className="mt-1 line-clamp-3">{n.text}</p>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <p className="text-muted">No shift notes in the last two weeks.</p>
                  )}
                </div>
              ) : null}
              <Link href={`/settings/clients/${c.id}?tab=shifts`} className="text-xs font-semibold text-brand underline">
                See all shifts and notes
              </Link>
            </>
          ) : tab === "budget" ? (
            c.budgets.length ? (
              <ul className="flex flex-col gap-3">
                {c.budgets.map((b, i) => {
                  const pct = b.total > 0 ? Math.round((b.used / b.total) * 100) : 0;
                  return (
                    <li key={i} className="rounded-lg border border-line p-3">
                      <p className="font-semibold">
                        {b.label} · {b.schemeLabel}
                      </p>
                      <p className="text-xs text-muted">
                        {day(b.periodStart)} to {day(b.periodEnd)}
                        {b.management ? ` · ${b.management}` : ""}
                      </p>
                      <div className="mt-2 h-2 overflow-hidden rounded-full bg-line" aria-hidden="true">
                        <div className={`h-full ${pct >= 90 ? "bg-danger" : pct >= 75 ? "bg-warn" : "bg-good"}`} style={{ width: `${Math.min(100, pct)}%` }} />
                      </div>
                      <p className="mt-1 text-xs">
                        {aud(b.used)} of {aud(b.total)} used ({pct}%) · {aud(Math.max(0, b.total - b.used))} left{b.usedAsOf ? ` · as at ${day(b.usedAsOf)}` : ""}
                      </p>
                    </li>
                  );
                })}
              </ul>
            ) : (
              <p className="text-muted">No current budgets.</p>
            )
          ) : (
            <>
              <div>
                <h3 className="mb-1 text-xs font-semibold uppercase text-muted">Open reviews</h3>
                {c.reviews.length ? (
                  <ul className="flex flex-col gap-1">
                    {c.reviews.map((r, i) => (
                      <li key={i} className={r.overdue ? "font-semibold text-danger" : ""}>
                        {r.label} · {r.overdue ? `overdue (due ${day(r.due)})` : `due ${day(r.due)}`}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-muted">None open.</p>
                )}
              </div>
              <div>
                <h3 className="mb-1 text-xs font-semibold uppercase text-muted">Service agreements</h3>
                {c.agreements.length ? (
                  <ul className="flex flex-col gap-1">
                    {c.agreements.map((a, i) => (
                      <li key={i}>
                        {a.label} · {a.status}
                        {a.ends ? ` · ends ${day(a.ends)}` : ""}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-muted">None current.</p>
                )}
              </div>
            </>
          )}
        </div>
      </aside>
    </>
  );
}

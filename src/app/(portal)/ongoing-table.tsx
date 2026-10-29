// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { Fragment, useActionState, useEffect, useRef, useState, useTransition } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button, Field, Notice, buttonClass, inputClass } from "@/components/ui";
import type { FormState } from "@/lib/form";
import { createClient } from "@/lib/supabase/client";
import { describeEvent, eventNote } from "@/lib/task-events";
import { addHelper, reassignTask, type TaskSnapshot } from "./tasks/actions";

export type OngoingRow = {
  id: string;
  description: string;
  ref: string;
  title: string;
  register: string;
  assignedTo: string;
  assignee: string;
  priority: string;
  priorityClass: string;
  status: string;
  due: string;
  dueClass: string;
};

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

// The quick view reads straight from the database in the browser (the
// database's own rules decide what each person can see), so it doesn't wait
// on a round trip through the website server.
type Ctx = { names: Map<string, string>; timeZone: string };

async function loadSnapshot(id: string, ctx: Ctx): Promise<TaskSnapshot | null> {
  const db = createClient();
  const [{ data: task }, { data: helpers }, { data: events }, { data: canEdit }, { count }] = await Promise.all([
    db.from("tasks").select("id, description").eq("id", id).maybeSingle(),
    db.from("task_helpers").select("user_id").eq("task_id", id),
    db.from("task_events").select("type, actor_id, from_value, to_value, comment, created_at").eq("task_id", id).order("created_at").order("id"),
    db.rpc("can_edit_task", { p_task_id: id }),
    db.from("task_attachments").select("id", { count: "exact", head: true }).eq("task_id", id),
  ]);
  if (!task) return null;
  const nameOf = (uid: string | null) => (uid ? ctx.names.get(uid) ?? "Admin" : "System");
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone: ctx.timeZone });
  return {
    description: task.description,
    helpers: (helpers ?? []).map((h) => ({ id: h.user_id, name: nameOf(h.user_id) })),
    history: (events ?? []).map((e) => ({ who: nameOf(e.actor_id), what: describeEvent(e, nameOf), note: eventNote(e), at: when.format(new Date(e.created_at)) })),
    canEdit: Boolean(canEdit),
    files: count ?? 0,
  };
}

// Quick views load once and are kept, starting as soon as you point at a row.
const cache = new Map<string, Promise<TaskSnapshot | null>>();
function prefetch(id: string, ctx: Ctx) {
  if (!cache.has(id)) cache.set(id, loadSnapshot(id, ctx).catch(() => null));
  return cache.get(id)!;
}

// "All ongoing tasks": click a row for a quick view instead of opening it.
export function OngoingTable({
  rows,
  people,
  names,
  timeZone,
}: {
  rows: OngoingRow[];
  people: { id: string; name: string }[];
  // Everyone's names (for the history), and the company's time zone.
  names: [string, string][];
  timeZone: string;
}) {
  const [openId, setOpenId] = useState<string | null>(null);
  const [ctx] = useState<Ctx>(() => ({ names: new Map(names), timeZone }));
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="text-left text-xs tracking-wider text-muted uppercase">
            {["Ref.", "Task", "Register", "Looked after by", "Priority", "Status", "Due"].map((h) => (
              <th key={h} scope="col" className="px-4 py-3 font-medium whitespace-nowrap">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((t) => {
            const open = openId === t.id;
            return (
              <Fragment key={t.id}>
                <tr
                  className={`cursor-pointer border-t border-line hover:bg-page ${open ? "bg-page" : ""}`}
                  onMouseEnter={() => prefetch(t.id, ctx)}
                  onTouchStart={() => prefetch(t.id, ctx)}
                  onClick={() => setOpenId(open ? null : t.id)}
                >
                  <td className="px-4 py-3 whitespace-nowrap text-muted">{t.ref}</td>
                  <td className="min-w-56 px-4 py-3">
                    <button
                      type="button"
                      aria-expanded={open}
                      aria-controls={`snap-${t.id}`}
                      className="text-left font-semibold hover:text-brand"
                      onClick={(e) => {
                        e.stopPropagation();
                        setOpenId(open ? null : t.id);
                      }}
                    >
                      <span aria-hidden="true" className="mr-1.5 inline-block w-3 text-muted">{open ? "▾" : "▸"}</span>
                      {t.title}
                    </button>
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-muted">{t.register}</td>
                  <td className="px-4 py-3 whitespace-nowrap">{t.assignee}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${t.priorityClass}`}>{t.priority}</span>
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap">{t.status}</td>
                  <td className={`px-4 py-3 whitespace-nowrap ${t.dueClass}`}>{t.due}</td>
                </tr>
                {open ? (
                  <tr id={`snap-${t.id}`} className="bg-page">
                    <td colSpan={7} className="px-4 pt-1 pb-5">
                      <Snapshot row={t} people={people} ctx={ctx} />
                    </td>
                  </tr>
                ) : null}
              </Fragment>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

function Snapshot({ row, people, ctx }: { row: OngoingRow; people: { id: string; name: string }[]; ctx: Ctx }) {
  const router = useRouter();
  const [snap, setSnap] = useState<TaskSnapshot | null | "loading">("loading");
  const [panel, setPanel] = useState<"none" | "reassign" | "helper">("none");
  const progress = useRef<HTMLDialogElement>(null);
  const [, startTransition] = useTransition();
  const load = (fresh = false) =>
    startTransition(async () => {
      if (fresh) cache.delete(row.id);
      setSnap(await prefetch(row.id, ctx));
    });
  useEffect(() => load(), [row.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const [reassignState, reassignAction, reassigning] = useActionState(async (prev: FormState, form: FormData) => {
    const result = await reassignTask(prev, form);
    if (result?.message) {
      setPanel("none");
      cache.delete(row.id);
      router.refresh();
    }
    return result;
  }, null);
  const [helperState, helperAction, addingHelper] = useActionState(async (prev: FormState, form: FormData) => {
    const result = await addHelper(prev, form);
    if (result?.message) {
      setPanel("none");
      load(true);
    }
    return result;
  }, null);

  if (snap === null) return <p className="py-3 text-sm text-muted">This task can&apos;t be shown.</p>;
  const loading = snap === "loading";
  const data: TaskSnapshot = loading ? { description: row.description, helpers: [], history: [], canEdit: false, files: 0 } : snap;
  const latest = data.history[data.history.length - 1];
  const helperIds = new Set(data.helpers.map((h) => h.id));
  const choices = people.filter((p) => p.id !== row.assignedTo && !helperIds.has(p.id));

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-line bg-surface p-4">
      <Result state={reassignState ?? helperState} />
      <div className="grid gap-4 md:grid-cols-[2fr_1fr]">
        <div className="flex flex-col gap-3">
          <div>
            <p className="text-xs font-medium tracking-wider text-muted uppercase">About this task</p>
            <p className="text-sm whitespace-pre-line">{data.description || "Nothing written yet."}</p>
          </div>
          {loading ? <p className="text-sm text-muted">Loading the latest update…</p> : null}
          {latest ? (
            <div>
              <p className="text-xs font-medium tracking-wider text-muted uppercase">Latest update</p>
              <p className="text-sm">
                <strong>{latest.who}</strong> {latest.what} · <span className="text-muted">{latest.at}</span>
              </p>
              {latest.note ? <p className="mt-1 rounded-md bg-page px-3 py-2 text-sm whitespace-pre-line">{latest.note}</p> : null}
            </div>
          ) : null}
        </div>
        <dl className="flex flex-col gap-2 text-sm">
          <div>
            <dt className="text-xs font-medium tracking-wider text-muted uppercase">Looked after by</dt>
            <dd className="font-semibold">{row.assignee}</dd>
          </div>
          <div>
            <dt className="text-xs font-medium tracking-wider text-muted uppercase">Helpers</dt>
            <dd>{loading ? "…" : data.helpers.length ? data.helpers.map((h) => h.name).join(", ") : "None"}</dd>
          </div>
          <div>
            <dt className="text-xs font-medium tracking-wider text-muted uppercase">Status · due</dt>
            <dd>
              {row.status} · <span className={row.dueClass}>{row.due}</span>
            </dd>
          </div>
          <div>
            <dt className="text-xs font-medium tracking-wider text-muted uppercase">Updates · files</dt>
            <dd>
              {loading ? "…" : `${data.history.length} · ${data.files}`}
            </dd>
          </div>
        </dl>
      </div>

      <div className="flex flex-wrap gap-2">
        <Link href={`/tasks/${row.id}`} className={buttonClass("primary")}>
          Open task
        </Link>
        {data.canEdit ? (
          <Button type="button" variant="outline" onClick={() => setPanel(panel === "reassign" ? "none" : "reassign")}>
            Reassign
          </Button>
        ) : null}
        <Button type="button" variant="outline" onClick={() => setPanel(panel === "helper" ? "none" : "helper")}>
          Add someone to help
        </Button>
        <Button type="button" variant="outline" aria-haspopup="dialog" disabled={loading} onClick={() => progress.current?.showModal()}>
          See progress
        </Button>
      </div>

      {panel === "reassign" ? (
        <form action={reassignAction} className="grid gap-3 md:grid-cols-[1fr_2fr_auto] md:items-end">
          <input type="hidden" name="task_id" value={row.id} />
          <Field label="Who should look after it?" htmlFor={`ra-${row.id}`}>
            <select id={`ra-${row.id}`} name="to" required defaultValue="" className={inputClass}>
              <option value="" disabled>
                Choose a person
              </option>
              {people
                .filter((p) => p.id !== row.assignedTo)
                .map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
            </select>
          </Field>
          <Field label="Reason" htmlFor={`rr-${row.id}`}>
            <input id={`rr-${row.id}`} name="reason" required className={inputClass} />
          </Field>
          <Button className="h-12" disabled={reassigning}>
            {reassigning ? "Saving…" : "Reassign"}
          </Button>
        </form>
      ) : null}

      {panel === "helper" ? (
        <form action={helperAction} className="flex flex-wrap items-end gap-3">
          <input type="hidden" name="task_id" value={row.id} />
          <div className="min-w-56 flex-1">
            <Field label="Who can help?" htmlFor={`h-${row.id}`}>
              <select id={`h-${row.id}`} name="user_id" required defaultValue="" className={inputClass}>
                <option value="" disabled>
                  Choose a person
                </option>
                {choices.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <Button className="h-12" disabled={addingHelper}>
            {addingHelper ? "Adding…" : "Add helper"}
          </Button>
        </form>
      ) : null}

      {/* The full history, in a pop-up. Esc or the close button shuts it. */}
      <dialog
        ref={progress}
        aria-labelledby={`p-title-${row.id}`}
        onClick={(e) => {
          if (e.target === e.currentTarget) progress.current?.close();
        }}
        className="m-auto w-[min(40rem,calc(100vw-2rem))] rounded-xl border border-line bg-surface p-0 text-ink shadow-xl backdrop:bg-black/50"
      >
        <div className="flex max-h-[80vh] flex-col">
          <div className="flex items-start justify-between gap-3 border-b border-line px-5 py-4">
            <div>
              <p className="text-xs text-muted">{row.ref} · Progress</p>
              <h2 id={`p-title-${row.id}`} className="heading-sm">{row.title}</h2>
            </div>
            <button type="button" onClick={() => progress.current?.close()} className="min-h-11 min-w-11 rounded-full text-xl text-muted hover:bg-page" aria-label="Close">
              ×
            </button>
          </div>
          <ol className="flex flex-col gap-4 overflow-y-auto px-5 py-4">
            {data.history.map((h, i) => (
              <li key={i} className="flex gap-3">
                <span aria-hidden="true" className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-brand" />
                <div className="min-w-0">
                  <p className="text-sm">
                    <strong>{h.who}</strong> {h.what}
                  </p>
                  {h.note ? <p className="mt-1 rounded-md bg-page px-3 py-2 text-sm whitespace-pre-line">{h.note}</p> : null}
                  <p className="text-xs text-muted">{h.at}</p>
                </div>
              </li>
            ))}
          </ol>
          <div className="flex justify-end gap-2 border-t border-line px-5 py-3">
            <Link href={`/tasks/${row.id}`} className={buttonClass("outline")}>
              Open task
            </Link>
            <Button type="button" onClick={() => progress.current?.close()}>
              Close
            </Button>
          </div>
        </div>
      </dialog>
    </div>
  );
}

// A task link with a preview card on hover (or keyboard focus): what it's
// about and the latest update. Clicking still opens the task.
export function TaskPeek({
  id,
  href,
  names,
  timeZone,
  children,
}: {
  id: string;
  href: string;
  names: [string, string][];
  timeZone: string;
  children: React.ReactNode;
}) {
  const [ctx] = useState<Ctx>(() => ({ names: new Map(names), timeZone }));
  const [show, setShow] = useState(false);
  const [snap, setSnap] = useState<TaskSnapshot | null | "loading">("loading");
  const timer = useRef<number | null>(null);

  function enter() {
    void prefetch(id, ctx).then(setSnap);
    timer.current = window.setTimeout(() => setShow(true), 350);
  }
  function leave() {
    if (timer.current) window.clearTimeout(timer.current);
    setShow(false);
  }
  const latest = snap && snap !== "loading" ? snap.history[snap.history.length - 1] : undefined;

  return (
    <div className="relative" onMouseEnter={enter} onMouseLeave={leave} onFocus={enter} onBlur={leave}>
      <Link href={href} className="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-5 py-3 hover:bg-page">
        {children}
      </Link>
      {show ? (
        <div
          role="tooltip"
          className="pointer-events-none absolute top-full left-5 z-40 mt-1 hidden w-[min(26rem,calc(100%-2.5rem))] flex-col gap-2 rounded-lg border border-line bg-surface p-4 text-ink shadow-xl md:flex print:hidden"
        >
          {snap === "loading" ? (
            <p className="text-sm text-muted">Loading…</p>
          ) : snap === null ? (
            <p className="text-sm text-muted">This task can&apos;t be shown.</p>
          ) : (
            <>
              <p className="text-xs font-medium tracking-wider text-muted uppercase">About this task</p>
              <p className="line-clamp-4 text-sm whitespace-pre-line">{snap.description || "Nothing written yet."}</p>
              {latest ? (
                <>
                  <p className="text-xs font-medium tracking-wider text-muted uppercase">Latest update</p>
                  <p className="text-sm">
                    <strong>{latest.who}</strong> {latest.what} · <span className="text-muted">{latest.at}</span>
                  </p>
                  {latest.note ? <p className="line-clamp-3 rounded-md bg-page px-3 py-2 text-sm whitespace-pre-line">{latest.note}</p> : null}
                </>
              ) : null}
              <p className="text-xs text-muted">
                {snap.helpers.length ? `Helpers: ${snap.helpers.map((h) => h.name).join(", ")} · ` : ""}
                {snap.history.length} update{snap.history.length === 1 ? "" : "s"} · {snap.files} file{snap.files === 1 ? "" : "s"} · Click to open
              </p>
            </>
          )}
        </div>
      ) : null}
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useId, useRef, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { addComment, changeStatus, reassignTask } from "./tasks/actions";
import { toast } from "@/components/toast";
import Link from "next/link";
import { AlertTriangle, BadgeCheck, CalendarClock, ListChecks, Siren, Timer, X } from "lucide-react";
import { Panel, Tile } from "@/components/dash";
import { STATUS_CLASS, STATUS_LABELS, PRIORITY_CLASS, PRIORITY_LABELS, type Priority, type Status } from "@/lib/tasks";
import { TaskPeek } from "./ongoing-table";
import { FormPending } from "@/components/form-pending";

// cmeprojects: the manager's dashboard, made to act on. Every tile, bar and
// chart slice opens a side panel with those tasks (hover a title for a quick
// look, click to open it in this tab), plus a "View all" link to Tasks with the
// same filter.
export type BoardTask = {
  id: string;
  ref: string;
  title: string;
  status: Status;
  priority: Priority;
  due: string | null;
  dueLabel: string;
  assignedTo: string;
  assignee: string;
  registryId: string;
  register: string;
};
type Week = { label: string; opened: number; closed: number };
type Drawer = { title: string; tasks: BoardTask[]; viewAll: string; extra?: ReactNode; note?: string };

const COLOURS = { ontrack: "var(--accent)", overdue: "var(--bad)", escalated: "var(--warn)", awaiting: "var(--brand-accent)" };

export function ManagerBoard({
  tasks,
  today,
  weekEnd,
  weeks,
  onTime,
  names,
  handTo,
  timeZone,
}: {
  tasks: BoardTask[];
  today: string;
  weekEnd: string;
  weeks: Week[];
  onTime: { finished: number; onTime: number };
  names: [string, string][];
  // Active staff a task can be handed to (id, name).
  handTo: [string, string][];
  timeZone: string;
}) {
  const [drawer, setDrawer] = useState<Drawer | null>(null);
  const dialog = useRef<HTMLDialogElement>(null);
  const open = (d: Drawer) => setDrawer(d);
  useEffect(() => {
    if (drawer && !dialog.current?.open) dialog.current?.showModal();
  }, [drawer]);

  // One category per task, so nothing is counted twice: escalated first, then
  // waiting for approval, then overdue, otherwise on track.
  const cat = (t: BoardTask) =>
    t.status === "escalated" ? "escalated" : t.status === "awaiting_approval" ? "awaiting" : t.due && t.due < today ? "overdue" : "ontrack";
  const by = (k: string) => tasks.filter((t) => cat(t) === k);
  const late = tasks.filter((t) => t.due && t.due < today);
  const week = tasks.filter((t) => t.due && t.due >= today && t.due <= weekEnd);
  const days = (d: string) => Math.round((Date.parse(today) - Date.parse(d)) / 86_400_000);
  const ages = [
    { label: "1–7 days", test: (n: number) => n <= 7 },
    { label: "8–30 days", test: (n: number) => n > 7 && n <= 30 },
    { label: "Over 30 days", test: (n: number) => n > 30 },
  ].map((a) => ({ label: a.label, tasks: late.filter((t) => a.test(days(t.due!))) }));

  const people = [...new Map(tasks.map((t) => [t.assignedTo, t.assignee])).entries()]
    .map(([id, name]) => ({ id, name, tasks: tasks.filter((t) => t.assignedTo === id) }))
    .sort((a, b) => b.tasks.length - a.tasks.length);
  const average = people.length ? tasks.length / people.length : 0;
  const heavy = people.filter((p) => p.tasks.length >= Math.max(5, average * 1.5));
  const regs = [...new Map(late.map((t) => [t.registryId, t.register])).entries()]
    .map(([id, name]) => ({ id, name, tasks: late.filter((t) => t.registryId === id) }))
    .sort((a, b) => b.tasks.length - a.tasks.length);
  const pct = onTime.finished ? Math.round((onTime.onTime / onTime.finished) * 100) : null;

  const segments = [
    { key: "ontrack", label: "On track", show: "ontrack", tasks: by("ontrack") },
    { key: "overdue", label: "Overdue", show: "overdue", tasks: by("overdue") },
    { key: "escalated", label: "Escalated", show: "escalated", tasks: by("escalated") },
    { key: "awaiting", label: "Waiting for approval", show: "awaiting", tasks: by("awaiting") },
  ] as const;

  return (
    <>
      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        <TileButton onClick={() => open({ title: "Open tasks", tasks, viewAll: "/tasks#all" })}>
          <Tile label="Open tasks" value={tasks.length} note={`${week.length} due this week`} icon={ListChecks} />
        </TileButton>
        <TileButton onClick={() => open({ title: "Past their due date", tasks: late, viewAll: "/tasks?show=late#all" })}>
          <Tile
            label="Overdue"
            value={late.length}
            // cmeprojects: the chart counts escalated ones separately, so say when they're included here.
            note={late.some((t) => t.status === "escalated") ? `Past their due date (including ${late.filter((t) => t.status === "escalated").length} escalated)` : "Past their due date"}
            icon={AlertTriangle}
            tone="danger"
          />
        </TileButton>
        <TileButton onClick={() => open({ title: "Waiting for approval", tasks: by("awaiting"), viewAll: "/tasks?show=awaiting#all" })}>
          <Tile label="Waiting for approval" value={by("awaiting").length} note="Finished, needs a manager" icon={BadgeCheck} tone="warn" />
        </TileButton>
        <TileButton onClick={() => open({ title: "Escalated", tasks: by("escalated"), viewAll: "/tasks?show=escalated#all" })}>
          <Tile label="Escalated" value={by("escalated").length} note="Someone asked for help" icon={Siren} tone="danger" />
        </TileButton>
        <TileButton onClick={() => open({ title: "Due this week", tasks: week, viewAll: "/tasks?show=week#all" })}>
          <Tile label="Due this week" value={week.length} icon={CalendarClock} />
        </TileButton>
        <Tile
          label="Finished on time"
          value={pct === null ? "–" : `${pct}%`}
          note={onTime.finished ? `${onTime.onTime} of ${onTime.finished}, last 30 days` : "Nothing finished with a due date yet"}
          icon={Timer}
          tone={pct === null ? undefined : pct >= 80 ? "good" : pct >= 60 ? "warn" : "danger"}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Panel title="Task status">
          <div className="flex flex-wrap items-center gap-6">
            <Donut
              total={tasks.length}
              slices={segments.map((s) => ({ value: s.tasks.length, colour: COLOURS[s.key], label: s.label, onClick: () => open({ title: s.label, tasks: s.tasks, viewAll: `/tasks?show=${s.show}#all` }) }))}
            />
            <ul className="flex min-w-48 flex-1 flex-col gap-2 text-sm">
              {segments.map((s) => (
                <li key={s.key}>
                  <button type="button" onClick={() => open({ title: s.label, tasks: s.tasks, viewAll: `/tasks?show=${s.show}#all` })} className="flex w-full items-center gap-2 rounded-md px-2 py-1 text-left hover:bg-page">
                    <span className="size-3 rounded-sm" style={{ background: COLOURS[s.key] }} />
                    <span className="flex-1">{s.label}</span>
                    <span className="font-semibold tabular-nums">{s.tasks.length}</span>
                  </button>
                </li>
              ))}
            </ul>
          </div>
          <p className="text-xs text-muted">Each task is counted once: escalated first, then waiting for approval, then overdue.</p>
        </Panel>

        <Panel title="Open tasks by person" action={heavy.length ? <span className="text-xs font-semibold text-warn">{heavy.length} carrying a lot</span> : undefined}>
          {people.length ? (
            <ClickBars
              rows={people.slice(0, 8).map((p) => ({
                label: p.name || "Not assigned",
                value: p.tasks.length,
                flag: heavy.includes(p),
                onClick: () =>
                  open({
                    title: p.name || "Not assigned",
                    tasks: p.tasks,
                    viewAll: `/tasks?person=${p.id}#all`,
                    note: `${p.tasks.filter((t) => t.due && t.due < today).length} overdue · ${p.tasks.filter((t) => t.due && t.due >= today && t.due <= weekEnd).length} due this week`,
                  }),
              }))}
            />
          ) : (
            <p className="text-sm text-muted">No open tasks.</p>
          )}
        </Panel>

        <Panel title="Overdue by register">
          {regs.length ? (
            <ClickBars
              colour="var(--bad)"
              rows={regs.slice(0, 8).map((r) => ({
                label: r.name,
                value: r.tasks.length,
                onClick: () =>
                  open({
                    title: `${r.name}: overdue`,
                    tasks: r.tasks,
                    viewAll: `/tasks?register=${r.id}&show=late#all`,
                    extra: (
                      <Link href={`/registers/${r.id}`} className="text-sm font-semibold text-brand underline">
                        Open the register
                      </Link>
                    ),
                  }),
              }))}
            />
          ) : (
            <p className="text-sm text-muted">Nothing is overdue. Well done.</p>
          )}
        </Panel>

        <Panel title="How late are overdue tasks">
          {late.length ? (
            <ClickBars
              colour="var(--bad)"
              rows={ages.map((a) => ({ label: a.label, value: a.tasks.length, onClick: () => open({ title: `Overdue ${a.label}`, tasks: a.tasks, viewAll: "/tasks?show=late#all" }) }))}
            />
          ) : (
            <p className="text-sm text-muted">Nothing is overdue.</p>
          )}
        </Panel>

        <Panel title="Opened and closed, last 8 weeks" className="lg:col-span-2">
          <WeekBars weeks={weeks} />
        </Panel>
      </div>

      <dialog
        ref={dialog}
        aria-label={drawer?.title ?? "Tasks"}
        onClose={() => setDrawer(null)}
        onClick={(e) => e.target === e.currentTarget && e.currentTarget.close()}
        className="m-0 ml-auto h-full max-h-none w-[min(30rem,100vw)] max-w-none border-l border-line bg-surface p-0 text-ink shadow-xl backdrop:bg-black/30"
      >
        {drawer ? (
          <div className="flex h-full flex-col">
            <header className="flex items-start gap-3 border-b border-line px-5 py-4">
              <div className="min-w-0 flex-1">
                <h2 className="heading-sm">{drawer.title}</h2>
                <p className="text-sm text-muted">
                  {drawer.tasks.length} task{drawer.tasks.length === 1 ? "" : "s"}
                  {drawer.note ? ` · ${drawer.note}` : ""}
                </p>
              </div>
              <button type="button" onClick={(e) => e.currentTarget.closest("dialog")?.close()} aria-label="Close" className="rounded-md p-1.5 text-muted hover:bg-page hover:text-ink">
                <X className="size-5" />
              </button>
            </header>
            <ul className="flex-1 divide-y divide-line overflow-y-auto">
              {drawer.tasks.length === 0 ? <li className="px-5 py-8 text-center text-sm text-muted">Nothing here.</li> : null}
              {drawer.tasks.slice(0, 60).map((t) => (
                <li key={t.id} className="px-5 py-3">
                  <p className="text-xs text-muted">
                    {t.ref} · {t.register}
                  </p>
                  <TaskPeek id={t.id} href={`/tasks/${t.id}`} names={names} timeZone={timeZone}>
                    <span className="font-semibold">{t.title}</span>
                  </TaskPeek>
                  <p className="mt-1.5 flex flex-wrap items-center gap-2 text-xs">
                    <span className={`rounded-full px-2.5 py-0.5 font-semibold ${STATUS_CLASS[t.status]}`}>{STATUS_LABELS[t.status]}</span>
                    <span className={`rounded-full px-2.5 py-0.5 font-semibold ${PRIORITY_CLASS[t.priority]}`}>{PRIORITY_LABELS[t.priority]}</span>
                    <span className={t.due && t.due < today ? "font-semibold text-danger" : "text-muted"}>{t.dueLabel}</span>
                    <span className="text-muted">· {t.assignee}</span>
                  </p>
                  <QuickActions task={t} people={handTo} onDone={() => setDrawer((d) => (d ? { ...d, tasks: d.tasks.filter((x) => x.id !== t.id) } : d))} />
                </li>
              ))}
            </ul>
            <footer className="flex flex-wrap items-center justify-between gap-3 border-t border-line px-5 py-3">
              {drawer.extra ?? <span />}
              <Link href={drawer.viewAll} className="inline-flex min-h-10 items-center rounded-lg bg-brand px-4 text-sm font-semibold text-brand-fg hover:brightness-110">
                View all in Tasks
              </Link>
            </footer>
          </div>
        ) : null}
      </dialog>
    </>
  );
}

function TileButton({ onClick, children }: { onClick: () => void; children: ReactNode }) {
  return (
    <button type="button" onClick={onClick} className="block h-full rounded-lg text-left focus-visible:outline-2 focus-visible:outline-brand">
      {children}
    </button>
  );
}

// Bars you can click; flagged rows (carrying a lot) are marked.
function ClickBars({ rows, colour = "var(--accent)" }: { rows: { label: string; value: number; flag?: boolean; onClick: () => void }[]; colour?: string }) {
  const max = Math.max(1, ...rows.map((r) => r.value));
  return (
    <ul className="flex flex-col gap-1">
      {rows.map((r) => (
        <li key={r.label}>
          <button type="button" onClick={r.onClick} title={`${r.label}: ${r.value}. Click to see them.`} className="grid w-full grid-cols-[8rem_1fr_2rem] items-center gap-3 rounded-md px-1 py-1.5 text-left text-sm hover:bg-page">
            <span className={`truncate ${r.flag ? "font-semibold text-warn" : "text-muted"}`}>{r.label}</span>
            <span className="h-2.5 overflow-hidden rounded-full bg-page" aria-hidden="true">
              <span className="chart-grow-x block h-full rounded-full transition-[width]" style={{ width: `${(r.value / max) * 100}%`, background: r.flag ? "var(--warn)" : colour }} />
            </span>
            <span className="text-right font-medium tabular-nums">{r.value}</span>
          </button>
        </li>
      ))}
    </ul>
  );
}

// A doughnut with clickable slices.
function Donut({ total, slices }: { total: number; slices: { value: number; colour: string; label: string; onClick: () => void }[] }) {
  const r = 52;
  const c = 2 * Math.PI * r;
  let offset = 0;
  const mask = useId();
  return (
    <svg viewBox="0 0 140 140" className="size-40 shrink-0" role="img" aria-label={`Task status: ${slices.map((s) => `${s.label} ${s.value}`).join(", ")}`}>
      {/* cmeprojects: the slices sweep round once on first show. */}
      <defs>
        <mask id={mask}>
          <circle cx="70" cy="70" r={r} fill="none" stroke="white" strokeWidth="20" pathLength={1} transform="rotate(-90 70 70)" className="chart-sweep" />
        </mask>
      </defs>
      <circle cx="70" cy="70" r={r} fill="none" stroke="var(--line)" strokeWidth="18" />
      <g mask={`url(#${mask})`}>
        {total
        ? slices.map((s) => {
            const len = (s.value / total) * c;
            const el = s.value ? (
              <circle
                key={s.label}
                cx="70"
                cy="70"
                r={r}
                fill="none"
                stroke={s.colour}
                strokeWidth="18"
                strokeDasharray={`${len} ${c - len}`}
                strokeDashoffset={-offset}
                transform="rotate(-90 70 70)"
                className="cursor-pointer transition-opacity hover:opacity-80"
                onClick={s.onClick}
              >
                <title>{`${s.label}: ${s.value}`}</title>
              </circle>
            ) : null;
            offset += len;
            return el;
          })
        : null}
      </g>
      <text x="70" y="68" textAnchor="middle" fontSize="26" fontWeight="600" fill="var(--fg)">
        {total}
      </text>
      <text x="70" y="88" textAnchor="middle" fontSize="11" fill="var(--muted)">
        open
      </text>
    </svg>
  );
}

// Opened (brand) and closed (green) side by side each week; hover for numbers.
function WeekBars({ weeks }: { weeks: Week[] }) {
  const max = Math.max(4, ...weeks.flatMap((w) => [w.opened, w.closed]));
  const h = 160;
  return (
    <div className="flex flex-col gap-3">
      <div className="flex h-44 items-end gap-2 sm:gap-4" role="img" aria-label="Tasks opened and closed each week, last 8 weeks">
        {weeks.map((w) => (
          <div key={w.label} className="group flex flex-1 flex-col items-center gap-1" title={`Week of ${w.label}: ${w.opened} opened, ${w.closed} closed`}>
            <div className="flex w-full items-end justify-center gap-1" style={{ height: h }}>
              <span className="chart-grow-y w-1/2 max-w-6 rounded-t-md bg-brand transition-opacity group-hover:opacity-80" style={{ height: `${(w.opened / max) * 100}%`, minHeight: w.opened ? 4 : 0 }} />
              <span className="chart-grow-y w-1/2 max-w-6 rounded-t-md bg-good transition-opacity group-hover:opacity-80" style={{ height: `${(w.closed / max) * 100}%`, minHeight: w.closed ? 4 : 0 }} />
            </div>
            <span className="text-[11px] text-muted">{w.label}</span>
          </div>
        ))}
      </div>
      <p className="flex flex-wrap gap-4 text-xs text-muted">
        <span className="flex items-center gap-1.5">
          <span className="size-3 rounded-sm bg-brand" /> Opened
        </span>
        <span className="flex items-center gap-1.5">
          <span className="size-3 rounded-sm bg-good" /> Closed
        </span>
        <span>
          Last 8 weeks: {weeks.reduce((a, w) => a + w.opened, 0)} opened, {weeks.reduce((a, w) => a + w.closed, 0)} closed
        </span>
      </p>
    </div>
  );
}

// cmeprojects: act on a task straight from the side panel, whatever tile it
// came from. Waiting for approval: Approve or Send back. Escalated: Dealt with.
// Every open task: Remind (a comment the person is told about), Reassign,
// Take over, and Open. The database still checks the person may do each one.
type Op = "approve" | "back" | "dealt" | "remind" | "reassign" | "takeover";
const OP_NEEDS_TEXT: Partial<Record<Op, string>> = { back: "Why is it being sent back?", reassign: "Reason for the change", takeover: "Reason for taking it over", remind: "Message to them" };

function QuickActions({ task, people, onDone }: { task: BoardTask; people: [string, string][]; onDone: () => void }) {
  const router = useRouter();
  const [op, setOp] = useState<Op | null>(null);
  const [text, setText] = useState("");
  const [to, setTo] = useState("");
  const [state, run, pending] = useActionState(async (prev: Awaited<ReturnType<typeof changeStatus>>, form: FormData) => {
    const chosen = String(form.get("op")) as Op;
    const f = new FormData();
    f.set("task_id", task.id);
    let r: Awaited<ReturnType<typeof changeStatus>>;
    if (chosen === "approve" || chosen === "back" || chosen === "dealt") {
      f.set("status", chosen === "approve" ? "completed" : "in_progress");
      f.set("note", text);
      r = await changeStatus(prev, f);
    } else if (chosen === "remind") {
      f.set("body", text);
      r = await addComment(prev, f);
      if (r?.message && !r.error) r = { message: `Reminder sent to ${task.assignee}.` };
    } else {
      f.set("reason", text);
      if (chosen === "takeover") f.set("take_over", "1");
      else f.set("to", to);
      r = await reassignTask(prev, f);
    }
    if (r?.message && !r.error) {
      toast(r.message);
      setOp(null);
      // A reminder leaves the task where it is; everything else moves it on.
      if (chosen !== "remind") onDone();
      router.refresh();
    }
    return r;
  }, null);
  const btn = "inline-flex min-h-8 items-center rounded-md border px-2.5 text-xs font-semibold disabled:opacity-50";
  const start = (o: Op) => {
    setOp(o);
    setText(o === "remind" ? `Reminder: this is ${task.due ? "past its due date" : "still open"}. Please update it, or ask for help if you're stuck.` : "");
    setTo("");
  };
  const others = people.filter(([id]) => id !== task.assignedTo);
  return (
    <form action={run} className="mt-2 flex flex-col gap-2">
      {op && OP_NEEDS_TEXT[op] ? (
        <>
          <input type="hidden" name="op" value={op} />
          {op === "reassign" ? (
            <select required value={to} onChange={(e) => setTo(e.target.value)} aria-label="Reassign to" className="w-full rounded-md border border-field bg-surface px-2 py-1.5 text-sm">
              <option value="">Choose who looks after it…</option>
              {others.map(([id, name]) => (
                <option key={id} value={id}>
                  {name}
                </option>
              ))}
            </select>
          ) : null}
          <textarea required rows={2} value={text} onChange={(e) => setText(e.target.value)} placeholder={OP_NEEDS_TEXT[op]} aria-label={OP_NEEDS_TEXT[op]} className="w-full rounded-md border border-field bg-surface px-2 py-1.5 text-sm" />
          <span className="flex gap-2">
            <button className={`${btn} border-brand bg-brand text-brand-fg`} disabled={pending || !text.trim() || (op === "reassign" && !to)}>
              {pending ? "Saving…" : { back: "Send back", remind: "Send reminder", reassign: "Reassign", takeover: "Take it over" }[op as "back"]}
            <FormPending /></button>
            <button type="button" onClick={() => setOp(null)} className={`${btn} border-line`}>
              Cancel
            </button>
          </span>
        </>
      ) : (
        <span className="flex flex-wrap gap-2">
          {task.status === "awaiting_approval" ? (
            <>
              <button name="op" value="approve" className={`${btn} border-good bg-good text-white`} disabled={pending}>
                {pending ? "Saving…" : "Approve"}
              <FormPending /></button>
              <button type="button" onClick={() => start("back")} className={`${btn} border-line`} disabled={pending}>
                Send back
              </button>
            </>
          ) : (
            <>
              {task.status === "escalated" ? (
                <button name="op" value="dealt" className={`${btn} border-brand bg-brand text-brand-fg`} disabled={pending}>
                  {pending ? "Saving…" : "Escalation dealt with"}
                <FormPending /></button>
              ) : null}
              {task.assignedTo ? (
                <button type="button" onClick={() => start("remind")} className={`${btn} border-line`} disabled={pending}>
                  Remind
                </button>
              ) : null}
              <button type="button" onClick={() => start("reassign")} className={`${btn} border-line`} disabled={pending}>
                Reassign
              </button>
              <button type="button" onClick={() => start("takeover")} className={`${btn} border-line`} disabled={pending}>
                Take over
              </button>
            </>
          )}
          <Link href={`/tasks/${task.id}`} className={`${btn} border-line`}>
            Open task
          </Link>
        </span>
      )}
      {state?.error ? <p role="alert" className="text-xs text-danger">{state.error}</p> : null}
    </form>
  );
}

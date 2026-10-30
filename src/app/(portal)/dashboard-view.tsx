// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { getPeople, getRegistries } from "@/lib/register-data";
import { refLabel } from "@/lib/registers";
import {
  DONE,
  PRIORITY_CLASS,
  PRIORITY_LABELS,
  STATUS_LABELS,
  dueState,
  endOfWeek,
  formatDue,
  todayIn,
  type Priority,
  type Status,
} from "@/lib/tasks";
import { Card, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { AttentionList, OngoingTable, TaskPeek, type OngoingRow } from "./ongoing-table";

type Row = {
  id: string;
  ref_number: number;
  title: string;
  status: Status;
  priority: Priority;
  due_date: string | null;
  assigned_to: string;
  registry_id: string;
  created_at: string;
  description: string;
  escalated_to: "team_leader" | "manager" | null;
};

const PRIORITY_ORDER: Record<Priority, number> = { urgent: 0, high: 1, medium: 2, low: 3 };

function one(v: string | string[] | undefined): string {
  return typeof v === "string" ? v.trim().slice(0, 100) : "";
}

// The dashboard for team leaders, managers and system admins: every ongoing
// task they're allowed to see (their team's, their registers', or all).
export async function DashboardView({ params }: { params: Record<string, string | string[] | undefined> }) {
  const { profile, features } = await requireSession();
  const supabase = await createClient();
  const [timeZone, registries, people] = await Promise.all([getTimeZone(), getRegistries(), getPeople()]);
  const today = todayIn(timeZone);
  const weekEnd = endOfWeek(today);

  const load = (columns: string) =>
    supabase.from("tasks").select(columns).not("status", "in", `(${DONE.join(",")})`).order("created_at", { ascending: false }).limit(3000).returns<Row[]>();
  const base = "id, ref_number, title, description, status, priority, due_date, assigned_to, registry_id, created_at";
  // Who an escalation went to comes with live update 31; without it, treat escalations as for managers.
  const first = await load(`${base}, escalated_to`);
  const data = first.error ? (await load(base)).data : first.data;
  const open = (data ?? []).map((t) => ({ ...t, escalated_to: t.escalated_to ?? null }));
  const { data: helping } = await supabase.from("task_helpers").select("task_id").eq("user_id", profile.id);
  const helpingIds = new Set((helping ?? []).map((h) => h.task_id));
  const mine = open
    .filter((t) => t.assigned_to === profile.id || helpingIds.has(t.id))
    .sort((a, b) => (a.due_date ?? "9999").localeCompare(b.due_date ?? "9999") || PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority]);

  const register = one(params.register);
  const person = one(params.person);
  const q = one(params.q).toLowerCase();
  const filtered = open.filter(
    (t) =>
      (!register || t.registry_id === register) &&
      (!person || t.assigned_to === person) &&
      (!q || t.title.toLowerCase().includes(q)),
  );

  const regOf = new Map(registries.map((r) => [r.id, r]));
  const peekNames = people.filter((p) => p.role !== "system_admin").map((p) => [p.id, p.name] as [string, string]);
  const nameOf = new Map(people.map((p) => [p.id, p.name]));
  const ref = (t: Row) => refLabel(regOf.get(t.registry_id)?.prefix, t.ref_number);
  const overdue = (t: Row) => Boolean(t.due_date && t.due_date < today);

  // Escalations sent to them (team leaders: from their team; managers: the
  // rest), approvals for those who approve, then overdue and urgent ones not started.
  const approves = profile.role === "manager" || profile.role === "system_admin";
  const escalatedToMe = (t: Row) =>
    t.status === "escalated" && (profile.role === "team_leader" ? t.escalated_to === "team_leader" : approves && t.escalated_to !== "team_leader");
  const counts = [
    { label: "Open", n: open.length, tone: "text-brand" },
    { label: "Overdue", n: open.filter(overdue).length, tone: "text-danger" },
    { label: "Due this week", n: open.filter((t) => t.due_date && t.due_date >= today && t.due_date <= weekEnd).length, tone: "text-brand" },
    { label: "Escalated to you", n: open.filter(escalatedToMe).length, tone: "text-warn" },
    approves
      ? { label: "Awaiting approval", n: open.filter((t) => t.status === "awaiting_approval").length, tone: "text-brand" }
      : { label: "Escalated by your team", n: open.filter((t) => t.status === "escalated").length, tone: "text-warn" },
  ];

  const attention = open
    .filter(
      (t) =>
        escalatedToMe(t) ||
        (approves && t.status === "awaiting_approval") ||
        (t.status !== "escalated" && t.status !== "awaiting_approval" && (overdue(t) || (t.priority === "urgent" && t.status === "assigned"))),
    )
    .sort((a, b) => {
      const rank = (t: Row) => (escalatedToMe(t) ? 0 : t.status === "awaiting_approval" ? 1 : overdue(t) ? 2 : 3);
      return rank(a) - rank(b) || (a.due_date ?? "9999") .localeCompare(b.due_date ?? "9999");
    })
    .slice(0, 8);

  const byRegister = registries
    .filter((r) => r.kind === "tasks")
    .map((r) => ({ r, n: open.filter((t) => t.registry_id === r.id).length }))
    .filter((x) => x.n > 0)
    .sort((a, b) => b.n - a.n);
  const most = Math.max(1, ...byRegister.map((x) => x.n));

  // One shape for both quick-view lists.
  const toRow = (t: Row): OngoingRow => {
    const due = dueState(t.due_date, today, t.status);
    return {
      id: t.id,
      description: t.description.length > 600 ? `${t.description.slice(0, 600)}…` : t.description,
      ref: ref(t),
      title: t.title,
      register: regOf.get(t.registry_id)?.name ?? "",
      assignedTo: t.assigned_to,
      assignee: nameOf.get(t.assigned_to) ?? "",
      priority: PRIORITY_LABELS[t.priority],
      priorityClass: PRIORITY_CLASS[t.priority],
      status: STATUS_LABELS[t.status],
      statusKey: t.status,
      due: formatDue(t.due_date, today, t.status),
      dueClass: due === "overdue" ? "font-semibold text-danger" : due === "today" ? "text-warn" : "text-muted",
    };
  };
  const pickable = people.filter((p) => p.active && p.role !== "system_admin" && p.role !== "new_starter").map((p) => ({ id: p.id, name: p.name }));

  const sorted = [...filtered].sort((a, b) => {
    const ad = a.due_date ?? "9999-12-31";
    const bd = b.due_date ?? "9999-12-31";
    return ad === bd ? PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority] : ad < bd ? -1 : 1;
  });
  const assignees = people.filter((p) => open.some((t) => t.assigned_to === p.id));
  const scope =
    profile.role === "system_admin"
      ? "Every open task in the portal."
      : profile.role === "manager"
        ? "Open tasks in the registers you manage, plus your own."
        : "Open tasks of the people in your team, plus your own.";
  const firstName = profile.full_name.split(" ")[0];

  return (
    <>
      <PageHeader
        title="Dashboard"
        intro={`${firstName ? `Hi ${firstName}. ` : ""}${scope}`}
        action={
          features.tasks !== false ? (
            <Link href="/tasks/new" className={buttonClass("primary")}>
              + New task
            </Link>
          ) : null
        }
      />

      <div className="grid grid-cols-2 gap-3 md:grid-cols-5">
        {counts.map((c) => (
          <Card key={c.label} className="px-5 py-4">
            <p className={`text-3xl font-semibold ${c.n > 0 ? c.tone : "text-muted"}`}>{c.n}</p>
            <p className="text-sm font-medium text-muted">{c.label}</p>
          </Card>
        ))}
      </div>

      {/* Not overflow-hidden, so the hover preview can show over what's below. */}
      <Card>
        <div className="flex items-center justify-between gap-2 border-b border-line px-5 py-3">
          <h2 className="heading-sm">My tasks · {mine.length}</h2>
          <Link href="/my-tasks" className="text-sm font-medium text-brand underline">
            See all
          </Link>
        </div>
        {mine.length === 0 ? (
          <p className="px-5 py-4 text-sm text-muted">Nothing for you to look after or help with right now.</p>
        ) : (
          <ul className="divide-y divide-line">
            {mine.slice(0, 6).map((t) => {
              const due = dueState(t.due_date, today, t.status);
              return (
                <li key={t.id}>
                  <TaskPeek id={t.id} href={`/tasks/${t.id}`} names={peekNames} timeZone={timeZone}>
                    <span className="min-w-48 flex-1">
                      <span className="block text-sm font-semibold">{t.title}</span>
                      <span className="block text-xs text-muted">
                        {ref(t)} · {t.assigned_to === profile.id ? "you're looking after it" : "you are asked to help"}
                      </span>
                    </span>
                    <span className="flex items-center gap-2 text-xs font-semibold">
                      <span className={`rounded-full px-2.5 py-0.5 ${PRIORITY_CLASS[t.priority]}`}>{PRIORITY_LABELS[t.priority]}</span>
                      <span className={due === "overdue" ? "text-danger" : due === "today" ? "text-warn" : "text-muted"}>
                        {formatDue(t.due_date, today, t.status)}
                      </span>
                    </span>
                  </TaskPeek>
                </li>
              );
            })}
          </ul>
        )}
      </Card>

      <div className="grid items-start gap-4 lg:grid-cols-[1fr_320px]">
        <Card className="overflow-hidden">
          <h2 className="heading-sm border-b border-line px-5 py-3">Needs your attention</h2>
          {attention.length === 0 ? (
            <p className="px-5 py-4 text-sm text-muted">Nothing overdue, escalated or waiting on you.</p>
          ) : (
            <AttentionList
              rows={attention.map((t) => ({
                ...toRow(t),
                flag:
                  t.status === "escalated"
                    ? t.escalated_to === "team_leader"
                      ? "Escalated to team leader"
                      : "Escalated to managers"
                    : t.status === "awaiting_approval"
                      ? STATUS_LABELS[t.status]
                      : null,
              }))}
              people={pickable}
              names={peekNames}
              timeZone={timeZone}
            />
          )}
        </Card>

        <Card className="p-5">
          <h2 className="heading-sm mb-3">Open tasks by register</h2>
          {byRegister.length === 0 ? (
            <p className="text-sm text-muted">No open tasks.</p>
          ) : (
            <ul className="flex flex-col gap-3">
              {byRegister.map(({ r, n }) => (
                <li key={r.id}>
                  <Link
                    href={`/registers/${r.id}`}
                    className="group -mx-2 block rounded-md px-2 py-1.5 hover:bg-page"
                    aria-label={`${r.name}: ${n} open. Open the register`}
                  >
                    <span className="flex items-center justify-between gap-2 text-sm">
                      <span className="truncate font-medium text-brand group-hover:underline">{r.name}</span>
                      <span className="flex items-center gap-1 font-semibold tabular-nums">
                        {n}
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true" className="text-muted group-hover:text-brand">
                          <path d="M9 6l6 6-6 6" />
                        </svg>
                      </span>
                    </span>
                    <span className="mt-1 block h-2 rounded-full bg-page" aria-hidden="true">
                      <span className="block h-2 rounded-full bg-brand" style={{ width: `${(n / most) * 100}%` }} />
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>

      <Card id="all" className="overflow-hidden">
        <div className="flex flex-col gap-3 border-b border-line px-5 py-3">
          <h2 className="heading-sm">All ongoing tasks · {filtered.length}</h2>
          <form className="grid gap-2 sm:grid-cols-[1fr_1fr_1.5fr_auto_auto] sm:items-center" role="search" action="/#all">
            <label className="sr-only" htmlFor="d-register">Register</label>
            <select id="d-register" name="register" defaultValue={register} className={inputClass}>
              <option value="">All registers</option>
              {registries
                .filter((r) => r.kind === "tasks")
                .map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.name}
                  </option>
                ))}
            </select>
            <label className="sr-only" htmlFor="d-person">Looked after by</label>
            <select id="d-person" name="person" defaultValue={person} className={inputClass}>
              <option value="">Everyone</option>
              {assignees.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
            <label className="sr-only" htmlFor="d-q">Search by title</label>
            <input id="d-q" name="q" type="search" defaultValue={one(params.q)} placeholder="Search by title" className={inputClass} />
            <button className={buttonClass("outline")}>Show</button>
            {register || person || q ? (
              <Link href="/#all" className="min-h-11 content-center px-2 text-sm text-muted underline">
                Clear
              </Link>
            ) : null}
          </form>
        </div>
        {sorted.length === 0 ? (
          <p className="px-5 py-5 text-sm text-muted">No ongoing tasks match.</p>
        ) : (
          <OngoingTable
            rows={sorted.map(toRow)}
            people={pickable}
            names={peekNames}
            timeZone={timeZone}
          />
        )}
      </Card>
    </>
  );
}

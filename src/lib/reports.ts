// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import { getPeople, getRegistries } from "@/lib/register-data";
import { formatDate } from "@/lib/registers";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import type { Table } from "@/lib/register-rows";
import { PRIORITIES, PRIORITY_LABELS, STATUS_LABELS, type Priority, type Status } from "@/lib/tasks";

export type Period = { key: string; from: string; to: string; label: string };

const ISO = /^\d{4}-\d{2}-\d{2}$/;

function shift(day: string, months: number): string {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCMonth(d.getUTCMonth() + months);
  return d.toISOString().slice(0, 10);
}

// This month, the last 3 or 12 months, or chosen dates.
export function parsePeriod(params: Record<string, string | string[] | undefined>, today: string): Period {
  const get = (k: string) => (typeof params[k] === "string" ? (params[k] as string) : "");
  const from = get("from");
  const to = get("to");
  if (ISO.test(from) && ISO.test(to) && from <= to) {
    return { key: "custom", from, to, label: `${formatDate(from)} to ${formatDate(to)}` };
  }
  const range = get("range");
  if (range === "3m") return { key: "3m", from: shift(today, -3), to: today, label: "Last 3 months" };
  if (range === "12m") return { key: "12m", from: shift(today, -12), to: today, label: "Last 12 months" };
  return { key: "month", from: `${today.slice(0, 8)}01`, to: today, label: "This month" };
}

// Narrowing the report (managers choose these on the Reports page).
export type TaskFilter = { registry: string; person: string; status: "all" | "open" | "overdue" | "completed"; priority: string };
const STATUSES: TaskFilter["status"][] = ["all", "open", "overdue", "completed"];

export function parseTaskFilter(params: Record<string, string | string[] | undefined>): TaskFilter {
  const get = (k: string) => (typeof params[k] === "string" ? (params[k] as string) : "");
  const uuid = (v: string) => (/^[0-9a-f-]{36}$/.test(v) ? v : "");
  const status = get("status") as TaskFilter["status"];
  return {
    registry: uuid(get("registry")),
    person: uuid(get("person")),
    status: STATUSES.includes(status) ? status : "all",
    priority: (PRIORITIES as readonly string[]).includes(get("priority")) ? get("priority") : "",
  };
}

export const taskFilterQuery = (f: TaskFilter) =>
  Object.entries(f)
    .filter(([k, v]) => v && !(k === "status" && v === "all"))
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");

type TaskRow = {
  id: string;
  title: string;
  priority: string;
  registry_id: string;
  assigned_to: string;
  status: string;
  due_date: string | null;
  created_at: string;
  completed_at: string | null;
};

const pct = (a: number, b: number) => (b ? `${Math.round((a / b) * 100)}%` : "—");

export type Summary = { opened: number; completed: number; onTime: string; open: number; overdue: number; escalated: number };
export type MonthBar = { label: string; opened: number; completed: number };

export type Reports = {
  summary: Summary;
  months: MonthBar[];
  tables: { key: string; title: string; intro: string; table: Table }[];
  options: { registries: { id: string; name: string }[]; people: { id: string; name: string }[] };
};

// Everything on the Reports page, from the tasks the signed-in person can see.
export async function buildReports(period: Period, today: string, timeZone: string, filter?: TaskFilter): Promise<Reports> {
  const supabase = await createClient();
  const [{ data }, registries, people] = await Promise.all([
    supabase
      .from("tasks")
      .select("id, title, priority, registry_id, assigned_to, status, due_date, created_at, completed_at")
      .is("parent_task_id", null)
      .limit(20000)
      .returns<TaskRow[]>(),
    getRegistries(),
    getPeople(),
  ]);
  const day = new Intl.DateTimeFormat("en-CA", { timeZone });
  const local = (iso: string | null) => (iso ? day.format(new Date(iso)) : "");
  const inPeriod = (iso: string | null) => {
    const d = local(iso);
    return Boolean(d) && d >= period.from && d <= period.to;
  };
  const open = (t: TaskRow) => t.status !== "completed" && t.status !== "closed";
  const overdue = (t: TaskRow) => open(t) && Boolean(t.due_date) && t.due_date! < today;
  const doneIn = (t: TaskRow) => inPeriod(t.completed_at);
  const onTime = (t: TaskRow) => Boolean(t.due_date) && local(t.completed_at) <= t.due_date!;
  const f = filter ?? { registry: "", person: "", status: "all", priority: "" };
  const tasks = (data ?? []).filter(
    (t) =>
      (!f.registry || t.registry_id === f.registry) &&
      (!f.person || t.assigned_to === f.person) &&
      (!f.priority || t.priority === f.priority) &&
      (f.status === "all" || (f.status === "open" ? open(t) : f.status === "overdue" ? overdue(t) : !open(t))),
  );

  const opened = tasks.filter((t) => inPeriod(t.created_at));
  const completed = tasks.filter(doneIn);
  const completedWithDue = completed.filter((t) => t.due_date);
  const summary: Summary = {
    opened: opened.length,
    completed: completed.length,
    onTime: pct(completedWithDue.filter(onTime).length, completedWithDue.length),
    open: tasks.filter(open).length,
    overdue: tasks.filter(overdue).length,
    escalated: tasks.filter((t) => t.status === "escalated").length,
  };

  // Month by month across the period.
  const months: MonthBar[] = [];
  for (let m = period.from.slice(0, 7); m <= period.to.slice(0, 7); m = shift(`${m}-01`, 1).slice(0, 7)) {
    months.push({
      label: new Intl.DateTimeFormat("en-AU", { month: "short", year: "2-digit", timeZone: "UTC" }).format(new Date(`${m}-01T00:00:00Z`)),
      opened: opened.filter((t) => local(t.created_at).startsWith(m)).length,
      completed: completed.filter((t) => local(t.completed_at).startsWith(m)).length,
    });
    if (months.length > 36) break;
  }

  const cell = (v: string | number, tone?: "danger" | "muted") => ({ text: String(v), tone });
  const row = (id: string, cells: Record<string, ReturnType<typeof cell>>) => ({ id, href: "", cells });

  const byRegister: Table = {
    columns: [
      { key: "name", label: "Register", wide: true },
      { key: "opened", label: "Opened" },
      { key: "completed", label: "Completed" },
      { key: "ontime", label: "On time" },
      { key: "open", label: "Open now" },
      { key: "overdue", label: "Overdue now" },
    ],
    rows: registries
      .filter((r) => r.kind === "tasks")
      .map((r) => {
        const mine = tasks.filter((t) => t.registry_id === r.id);
        const done = mine.filter(doneIn);
        const withDue = done.filter((t) => t.due_date);
        const od = mine.filter(overdue).length;
        return row(r.id, {
          name: cell(r.name),
          opened: cell(mine.filter((t) => inPeriod(t.created_at)).length),
          completed: cell(done.length),
          ontime: cell(pct(withDue.filter(onTime).length, withDue.length)),
          open: cell(mine.filter(open).length),
          overdue: cell(od, od ? "danger" : undefined),
        });
      }),
  };

  const byPerson: Table = {
    columns: [
      { key: "name", label: "Person", wide: true },
      { key: "role", label: "Role" },
      { key: "open", label: "Open now" },
      { key: "overdue", label: "Overdue now" },
      { key: "completed", label: "Completed" },
      { key: "ontime", label: "On time" },
    ],
    rows: people
      .filter((p) => p.active && p.role !== "system_admin" && p.role !== "new_starter")
      .map((p) => {
        const mine = tasks.filter((t) => t.assigned_to === p.id);
        const done = mine.filter(doneIn);
        const withDue = done.filter((t) => t.due_date);
        const od = mine.filter(overdue).length;
        return { p, mine, cells: {
          name: cell(p.name),
          role: cell(ROLE_LABELS[p.role as Role] ?? ""),
          open: cell(mine.filter(open).length),
          overdue: cell(od, od ? "danger" : undefined),
          completed: cell(done.length),
          ontime: cell(pct(withDue.filter(onTime).length, withDue.length)),
        } };
      })
      .filter((x) => x.mine.length)
      .map((x) => row(x.p.id, x.cells)),
  };

  // Every task opened or completed in the period (or still open), one per line.
  const nameOf = new Map(people.map((p) => [p.id, p.name]));
  const regName = new Map(registries.map((r) => [r.id, r.name]));
  const listed = tasks
    .filter((t) => inPeriod(t.created_at) || doneIn(t) || open(t))
    .sort((a, b) => b.created_at.localeCompare(a.created_at))
    .slice(0, 2000);
  const short = (d: string) => (d ? formatDate(d) : "");
  const list: Table = {
    columns: [
      { key: "title", label: "Task", wide: true },
      { key: "register", label: "Register" },
      { key: "person", label: "Looking after" },
      { key: "priority", label: "Priority" },
      { key: "status", label: "Status" },
      { key: "opened", label: "Opened" },
      { key: "due", label: "Due" },
      { key: "done", label: "Completed" },
      { key: "days", label: "Days taken" },
    ],
    rows: listed.map((t) => {
      const days = t.completed_at ? Math.max(0, Math.round((new Date(t.completed_at).getTime() - new Date(t.created_at).getTime()) / 86_400_000)) : null;
      return {
        id: t.id,
        href: `/tasks/${t.id}`,
        cells: {
          title: cell(t.title),
          register: cell(regName.get(t.registry_id) ?? ""),
          person: cell(nameOf.get(t.assigned_to) ?? ""),
          priority: cell(PRIORITY_LABELS[t.priority as Priority] ?? t.priority),
          status: cell(overdue(t) ? "Overdue" : STATUS_LABELS[t.status as Status] ?? t.status, overdue(t) ? "danger" : undefined),
          opened: cell(short(local(t.created_at))),
          due: cell(short(t.due_date ?? "")),
          done: cell(short(local(t.completed_at))),
          days: cell(days === null ? "" : days),
        },
      };
    }),
  };

  const tables: Reports["tables"] = [
    { key: "registers", title: "By register", intro: "Opened and completed in the period; open and overdue right now.", table: byRegister },
    { key: "people", title: "By person", intro: "Tasks each person looks after.", table: byPerson },
    { key: "list", title: "Task list", intro: "Each task opened or completed in the period, or still open (up to 2,000). Click one to open it.", table: list },
  ];

  return {
    summary,
    months,
    tables,
    options: {
      registries: registries.filter((r) => r.kind === "tasks").map((r) => ({ id: r.id, name: r.name })),
      people: people.filter((p) => p.active && p.role !== "system_admin").map((p) => ({ id: p.id, name: p.name })),
    },
  };
}

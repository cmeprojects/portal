// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
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
import { Card, PageHeader, Tabs, buttonClass } from "@/components/ui";
import { refLabel } from "@/lib/registers";

export const metadata: Metadata = { title: "My tasks" };

type Row = {
  id: string;
  ref_number: number;
  title: string;
  priority: Priority;
  status: Status;
  due_date: string | null;
  assigned_to: string;
  created_by: string;
  registries: { name: string; prefix: string } | null;
};

const TABS = [
  { key: "assigned", label: "Assigned to me" },
  { key: "helping", label: "Helping on" },
  { key: "created", label: "Created by me" },
  { key: "completed", label: "Completed" },
] as const;
type Tab = (typeof TABS)[number]["key"];

const PRIORITY_ORDER: Record<Priority, number> = { urgent: 0, high: 1, medium: 2, low: 3 };

export default async function HomePage({ searchParams }: PageProps<"/">) {
  const { profile, features } = await requireSession();
  const params = await searchParams;
  const tab: Tab = TABS.some((t) => t.key === params.tab) ? (params.tab as Tab) : "assigned";
  const supabase = await createClient();
  const timeZone = await getTimeZone();
  const today = todayIn(timeZone);
  const weekEnd = endOfWeek(today);
  const me = profile.id;

  const { data: helping } = await supabase.from("task_helpers").select("task_id").eq("user_id", me);
  const helpingIds = (helping ?? []).map((h) => h.task_id);
  const filters = [`assigned_to.eq.${me}`, `created_by.eq.${me}`];
  if (helpingIds.length) filters.push(`id.in.(${helpingIds.join(",")})`);
  const { data } = await supabase
    .from("tasks")
    .select("id, ref_number, title, priority, status, due_date, assigned_to, created_by, registries(name, prefix)")
    .or(filters.join(","))
    .order("created_at", { ascending: false })
    .limit(500)
    .returns<Row[]>();
  const tasks = data ?? [];
  const open = (t: Row) => !DONE.includes(t.status);
  const mine = (t: Row) => t.assigned_to === me || helpingIds.includes(t.id);

  const lists: Record<Tab, Row[]> = {
    assigned: tasks.filter((t) => t.assigned_to === me && open(t)),
    helping: tasks.filter((t) => helpingIds.includes(t.id) && open(t)),
    created: tasks.filter((t) => t.created_by === me && open(t)),
    completed: tasks.filter((t) => !open(t)),
  };
  const counts = [
    { label: "Assigned to me", n: lists.assigned.length, alert: false },
    { label: "Helping on", n: lists.helping.length, alert: false },
    {
      label: "Due this week",
      n: tasks.filter((t) => mine(t) && open(t) && t.due_date && t.due_date >= today && t.due_date <= weekEnd).length,
      alert: false,
    },
    { label: "Overdue", n: tasks.filter((t) => mine(t) && open(t) && t.due_date && t.due_date < today).length, alert: true },
  ];

  // Overdue first, then by due date, then by priority.
  const shown = [...lists[tab]].sort((a, b) => {
    if (tab === "completed") return 0;
    const ad = a.due_date ?? "9999-12-31";
    const bd = b.due_date ?? "9999-12-31";
    return ad === bd ? PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority] : ad < bd ? -1 : 1;
  });
  const firstName = profile.full_name.split(" ")[0];

  return (
    <>
      <PageHeader
        title="My tasks"
        intro={firstName ? `Hi ${firstName}. Everything you're looking after or helping with.` : undefined}
        action={
          features.tasks !== false ? (
            <Link href="/tasks/new" className={buttonClass("primary")}>
              + New task
            </Link>
          ) : null
        }
      />

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {counts.map((c) => (
          <Card key={c.label} className="px-5 py-4">
            <p className={`text-[32px] font-semibold ${c.alert && c.n > 0 ? "text-danger" : "text-brand"}`}>{c.n}</p>
            <p className="text-sm font-semibold text-muted">{c.label}</p>
          </Card>
        ))}
      </div>

      <Card className="overflow-hidden">
        <div className="px-4 pt-2">
          <Tabs
            label="Task lists"
            items={TABS.map((t) => ({
              href: t.key === "assigned" ? "/" : `/?tab=${t.key}`,
              text: t.key !== "completed" ? `${t.label} · ${lists[t.key].length}` : t.label,
              current: t.key === tab,
            }))}
          />
        </div>

        {shown.length === 0 ? (
          <p className="p-6 text-sm text-muted">
            {tab === "assigned"
              ? "Nothing assigned to you right now."
              : tab === "helping"
                ? "You're not helping on any open tasks."
                : tab === "created"
                  ? "You haven't created any open tasks."
                  : "No completed tasks yet."}
          </p>
        ) : (
          <ul>
            {shown.map((t) => {
              const due = dueState(t.due_date, today, t.status);
              return (
                <li key={t.id} className="border-t border-line first:border-t-0">
                  <Link href={`/tasks/${t.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-2 px-5 py-4 hover:bg-page">
                    <span className="min-w-56 flex-1">
                      <span className="block text-base font-semibold">{t.title}</span>
                      <span className="block text-sm text-muted">
                        {refLabel(t.registries?.prefix, t.ref_number)} · {t.registries?.name}
                      </span>
                    </span>
                    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${PRIORITY_CLASS[t.priority]}`}>
                      {PRIORITY_LABELS[t.priority]}
                    </span>
                    <span className="inline-flex rounded-full bg-brand-soft px-3 py-1 text-xs font-semibold text-brand">
                      {STATUS_LABELS[t.status]}
                    </span>
                    <span
                      className={`w-40 text-sm font-semibold ${
                        due === "overdue" ? "text-danger" : due === "today" ? "text-warn" : "text-muted"
                      }`}
                    >
                      {formatDue(t.due_date, today, t.status)}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </Card>
    </>
  );
}

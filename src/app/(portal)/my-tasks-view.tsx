// Staff Portal · © cmeproject. All rights reserved.
import { EmptyState } from "@/components/ui";
import { CheckCircle2, Plus } from "lucide-react";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { QuestionPanel } from "./question-panel";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import {
  DONE,
  PRIORITY_CLASS,
  PRIORITY_LABELS,
  STATUS_CLASS, STATUS_LABELS,
  dueState,
  endOfWeek,
  formatDue,
  todayIn,
  type Priority,
  type Status,
} from "@/lib/tasks";
import { Card, PageHeader, Tabs, buttonClass } from "@/components/ui";
import { refLabel } from "@/lib/registers";

type Row = {
  id: string;
  ref_number: number;
  title: string;
  priority: Priority;
  status: Status;
  due_date: string | null;
  assigned_to: string;
  created_by: string;
  description: string;
  created_at: string;
  updated_at: string;
  registries: { name: string; prefix: string } | null;
};

const TABS = [
  { key: "assigned", label: "Assigned to me" },
  { key: "helping", label: "Asked to help" },
  { key: "created", label: "My requests and questions" },
  { key: "completed", label: "Completed" },
] as const;
type Tab = (typeof TABS)[number]["key"];

const PRIORITY_ORDER: Record<Priority, number> = { urgent: 0, high: 1, medium: 2, low: 3 };

// "My tasks": what the signed-in person is looking after, helping on or created.
// Shown at "/" for support workers, and at "/my-tasks" for everyone.
export async function MyTasksView({ basePath, params }: { basePath: string; params: Record<string, string | string[] | undefined> }) {
  const { profile, features } = await requireSession();
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
    .select("id, ref_number, title, description, priority, status, due_date, assigned_to, created_by, created_at, updated_at, registries(name, prefix)")
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
  // Staff, team leaders and staff admins open their own questions and requests
  // in place: they follow them up or escalate them (the person looking after
  // it completes it).
  const inline = (t: Row) => ["support_worker", "team_leader", "staff_admin"].includes(profile.role) && t.created_by === me && t.assigned_to !== me;
  const inlineIds = shown.filter(inline).map((t) => t.id);
  const [{ data: events }, { data: names }] = inlineIds.length
    ? await Promise.all([
        supabase.from("task_events").select("task_id, actor_id, type, to_value, comment, created_at").in("task_id", inlineIds).order("created_at", { ascending: false }).limit(200),
        supabase.from("profiles").select("id, full_name"),
      ])
    : [{ data: [] }, { data: [] }];
  const nameOf = new Map((names ?? []).map((n) => [n.id, n.full_name]));
  const firstName = profile.full_name.split(" ")[0];
  const snap = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone: "Australia/Sydney" });

  return (
    <>
      <PageHeader
        title="My tasks"
        intro={firstName ? `Hi ${firstName}. Everything you're looking after or helping with.` : undefined}
        action={
          features.tasks !== false ? (
            <Link href="/tasks/new" className={buttonClass("primary")}>
              <Plus aria-hidden="true" className="size-4" />New task
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
              href: t.key === "assigned" ? basePath : `${basePath}?tab=${t.key}`,
              text: t.key !== "completed" ? `${t.label} · ${lists[t.key].length}` : t.label,
              current: t.key === tab,
            }))}
          />
        </div>

        {shown.length === 0 ? (
          <EmptyState
            icon={CheckCircle2}
            title={
              tab === "assigned"
                ? "You're all caught up"
                : tab === "helping"
                  ? "You're not helping on any open tasks"
                  : tab === "created"
                    ? "Nothing open that you asked"
                    : "No completed tasks yet"
            }
            text={
              tab === "assigned"
                ? "Nothing is assigned to you right now."
                : tab === "created"
                  ? "Questions and tasks you raise show here until they're answered."
                  : undefined
            }
            action={tab === "assigned" || tab === "created" ? { href: "/tasks/new", label: "+ New task" } : undefined}
          />
        ) : (
          <ul>
            {shown.map((t) => {
              const due = dueState(t.due_date, today, t.status);
              return (
                inline(t) ? (
                  <li key={t.id} className="border-t border-line first:border-t-0">
                    <details name="my-task" className="group">
                      <summary className="flex cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-2 px-5 py-4 hover:bg-page [&::-webkit-details-marker]:hidden">
                        <span className="min-w-56 flex-1">
                          <span className="block text-base font-semibold">{t.title}</span>
                          <span className="block text-sm text-muted">
                            {refLabel(t.registries?.prefix, t.ref_number)} · With {nameOf.get(t.assigned_to) ?? "someone"}
                          </span>
                        </span>
                        {t.title.startsWith("Staff question") ? <span className="inline-flex rounded-full bg-page px-3 py-1 text-xs font-semibold">Staff question</span> : null}
                        <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${STATUS_CLASS[t.status]}`}>{STATUS_LABELS[t.status]}</span>
                        <span className="text-sm font-semibold text-brand group-open:hidden">Open</span>
                        <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                      </summary>
                      <div className="flex flex-col gap-3 border-t border-brand/30 bg-brand-soft px-5 py-4 text-ink">
                        {t.description?.trim() ? <p className="text-sm whitespace-pre-line">{t.description}</p> : null}
                        <div className="flex flex-col gap-1">
                          <p className="text-xs font-semibold tracking-wide text-muted uppercase">Latest</p>
                          {(events ?? []).filter((e) => e.task_id === t.id).slice(0, 5).length === 0 ? (
                            <p className="text-sm">No updates yet.</p>
                          ) : (
                            <ul className="flex flex-col gap-1">
                              {(events ?? [])
                                .filter((e) => e.task_id === t.id)
                                .slice(0, 5)
                                .map((e, i) => (
                                  <li key={i} className="rounded-md border border-line bg-surface px-3 py-2 text-sm">
                                    <span className="font-semibold">{e.actor_id === me ? "You" : nameOf.get(e.actor_id ?? "") ?? "Someone"}</span>{" "}
                                    {e.type === "comment" ? `: ${e.comment}` : e.type === "status_changed" ? `changed it to ${STATUS_LABELS[e.to_value as Status] ?? e.to_value}` : e.type === "reassigned" ? "passed it to someone else" : e.type === "escalated" ? "escalated it" : "updated it"}
                                    <span className="block text-xs text-muted">{snap.format(new Date(e.created_at))}</span>
                                  </li>
                                ))}
                            </ul>
                          )}
                        </div>
                        <QuestionPanel taskId={t.id} canEscalate={t.status !== "escalated"} />
                      </div>
                    </details>
                  </li>
                ) : (
                <li key={t.id} className="group relative border-t border-line first:border-t-0">
                  {/* A quick look on hover (or keyboard focus): what it's about and when it last moved. */}
                  <div
                    role="tooltip"
                    className="pointer-events-none invisible absolute top-full left-5 z-20 mt-1 w-[min(28rem,calc(100%-2.5rem))] shadow-card rounded-xl border border-line bg-surface p-4 text-sm opacity-0 shadow-lg transition-opacity delay-300 group-focus-within:visible group-focus-within:opacity-100 group-hover:visible group-hover:opacity-100 print:hidden"
                  >
                    <p className="font-semibold">{t.title}</p>
                    <p className="mt-1 line-clamp-4 whitespace-pre-line text-muted">{t.description?.trim() || "No details added."}</p>
                    <p className="mt-2 text-xs text-muted">
                      Opened {snap.format(new Date(t.created_at))} · Last updated {snap.format(new Date(t.updated_at))}
                    </p>
                  </div>
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
                    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${STATUS_CLASS[t.status]}`}>
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
                )
              );
            })}
          </ul>
        )}
      </Card>
    </>
  );
}

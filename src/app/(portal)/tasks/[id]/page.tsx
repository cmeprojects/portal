// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import {
  PRIORITY_CLASS,
  PRIORITY_LABELS,
  STATUS_LABELS,
  dueState,
  formatDue,
  taskNumber,
  todayIn,
  type Priority,
  type Status,
} from "@/lib/tasks";
import { Badge, Card, Notice } from "@/components/ui";
import { AddHelperForm } from "./add-helper";

export const metadata: Metadata = { title: "Task" };

const UUID = /^[0-9a-f-]{36}$/i;

export default async function TaskPage({ params, searchParams }: PageProps<"/tasks/[id]">) {
  const { id } = await params;
  const { created } = await searchParams;
  if (!UUID.test(id)) notFound();
  const { features } = await requireSession();
  const supabase = await createClient();

  const { data: task } = await supabase
    .from("tasks")
    .select("id, number, title, description, priority, status, due_date, created_at, registry_id, assigned_to, created_by, registries(name, requires_approval)")
    .eq("id", id)
    .maybeSingle();
  // Not found and not allowed look the same, so nobody can probe for tasks.
  if (!task) notFound();

  const [{ data: helpers }, { data: events }, { data: managers }, { data: people }, timeZone] = await Promise.all([
    supabase.from("task_helpers").select("user_id").eq("task_id", id),
    supabase.from("task_events").select("id, actor_id, type, to_value, comment, created_at").eq("task_id", id).order("created_at").order("id"),
    supabase.from("registry_managers").select("user_id").eq("registry_id", task.registry_id),
    supabase.from("profiles").select("id, full_name, email, active"),
    getTimeZone(),
  ]);

  const names = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const nameOf = (uid: string | null) => (uid ? names.get(uid) ?? "Former staff member" : "System");
  const helperIds = (helpers ?? []).map((h) => h.user_id);
  const registry = task.registries as unknown as { name: string; requires_approval: boolean } | null;
  const status = task.status as Status;
  const priority = task.priority as Priority;
  const today = todayIn(timeZone);
  const due = dueState(task.due_date, today, status);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone });
  const canAddHelpers = features.tasks !== false && status !== "closed";
  const helperChoices = (people ?? [])
    .filter((p) => p.active && p.id !== task.assigned_to && !helperIds.includes(p.id))
    .map((p) => ({ id: p.id, name: p.full_name || p.email }))
    .sort((a, b) => a.name.localeCompare(b.name));

  function describe(e: { type: string; actor_id: string | null; to_value: string | null }) {
    switch (e.type) {
      case "created":
        return `created the task and asked ${nameOf(e.to_value)} to look after it`;
      case "helper_added":
        return `added ${nameOf(e.to_value)} as a helper`;
      default:
        return e.type.replace(/_/g, " ");
    }
  }

  return (
    <>
      {created ? <Notice tone="success">Task created. We&apos;ve emailed the people involved.</Notice> : null}
      <div className="flex flex-col gap-2">
        <Link href="/" className="text-[15px] font-semibold text-brand">
          ← My tasks
        </Link>
        <p className="text-sm font-semibold text-muted">
          {taskNumber(task.number)} · {registry?.name}
        </p>
        <h1 className="text-[28px] font-extrabold leading-tight">{task.title}</h1>
        <div className="flex flex-wrap items-center gap-2">
          <Badge>{STATUS_LABELS[status]}</Badge>
          <span className={`inline-flex rounded-full px-3 py-1 text-[13px] font-bold ${PRIORITY_CLASS[priority]}`}>
            {PRIORITY_LABELS[priority]} priority
          </span>
          <span className={`text-[15px] font-semibold ${due === "overdue" ? "text-danger" : due === "today" ? "text-warn" : "text-muted"}`}>
            {formatDue(task.due_date, today, status)}
          </span>
        </div>
      </div>

      <div className="grid items-start gap-4 lg:grid-cols-[1fr_340px]">
        <div className="flex flex-col gap-4">
          <Card className="p-5">
            <h2 className="mb-2 text-lg font-bold">Description</h2>
            <p className="whitespace-pre-line text-[15px] leading-relaxed">
              {task.description || <span className="text-muted">No description.</span>}
            </p>
          </Card>

          <Card className="p-5">
            <h2 className="mb-3 text-lg font-bold">Activity</h2>
            <ol className="flex flex-col gap-4">
              {(events ?? []).map((e) => (
                <li key={e.id} className="flex gap-3">
                  <span aria-hidden="true" className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-brand" />
                  <div>
                    <p className="text-[15px]">
                      <strong>{nameOf(e.actor_id)}</strong> {describe(e)}
                    </p>
                    <time dateTime={e.created_at} className="text-sm text-muted">
                      {when.format(new Date(e.created_at))}
                    </time>
                  </div>
                </li>
              ))}
            </ol>
            <p className="mt-4 text-sm text-muted">Comments, status changes and attachments are coming in the next update.</p>
          </Card>
        </div>

        <Card className="flex flex-col gap-4 p-5">
          <h2 className="text-lg font-bold">Details</h2>
          <dl className="flex flex-col gap-3 text-[15px]">
            <div>
              <dt className="text-[13px] font-bold uppercase tracking-wide text-muted">Looked after by</dt>
              <dd className="font-semibold">{nameOf(task.assigned_to)}</dd>
            </div>
            <div>
              <dt className="text-[13px] font-bold uppercase tracking-wide text-muted">Helpers</dt>
              <dd>{helperIds.length ? helperIds.map(nameOf).join(", ") : "No helpers yet"}</dd>
            </div>
            <div>
              <dt className="text-[13px] font-bold uppercase tracking-wide text-muted">Registry managers</dt>
              <dd>{(managers ?? []).length ? (managers ?? []).map((m) => nameOf(m.user_id)).join(", ") : "None yet"}</dd>
            </div>
            <div>
              <dt className="text-[13px] font-bold uppercase tracking-wide text-muted">Created</dt>
              <dd>
                {when.format(new Date(task.created_at))} by {nameOf(task.created_by)}
              </dd>
            </div>
            <div>
              <dt className="text-[13px] font-bold uppercase tracking-wide text-muted">Manager approval needed to close</dt>
              <dd>{registry?.requires_approval ? "Yes" : "No"}</dd>
            </div>
          </dl>
          {canAddHelpers ? (
            <div className="border-t border-line pt-4">
              <AddHelperForm taskId={task.id} people={helperChoices} />
            </div>
          ) : null}
        </Card>
      </div>
    </>
  );
}

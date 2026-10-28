// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { CHOICE_COLOUR_CLASS, choiceColour, formatDate, formatValue, refLabel, type Details } from "@/lib/registers";
import {
  DONE,
  PRIORITY_CLASS,
  PRIORITY_LABELS,
  STATUS_LABELS,
  dueState,
  formatDue,
  todayIn,
  type Priority,
  type Status,
} from "@/lib/tasks";
import { Badge, Card, Notice } from "@/components/ui";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";
import { getBranding } from "@/lib/branding";
import { AddHelperForm } from "./add-helper";
import { EditDetailsForm } from "./edit-details";
import { FollowUpForm } from "./follow-up";

export const metadata: Metadata = { title: "Task" };

const UUID = /^[0-9a-f-]{36}$/i;

type TaskRow = {
  id: string;
  ref_number: number;
  title: string;
  description: string;
  priority: Priority;
  status: Status;
  due_date: string | null;
  date_reported: string;
  review_date: string | null;
  outcome: string;
  details: Details;
  created_at: string;
  registry_id: string;
  assigned_to: string;
  created_by: string;
  parent_task_id: string | null;
};

function Label({ children }: { children: React.ReactNode }) {
  return <dt className="text-xs font-medium tracking-wider text-muted uppercase">{children}</dt>;
}

export default async function TaskPage({ params, searchParams }: PageProps<"/tasks/[id]">) {
  const { id } = await params;
  const { created } = await searchParams;
  if (!UUID.test(id)) notFound();
  const { features } = await requireTaskAccess();
  const supabase = await createClient();

  const { data: task } = await supabase
    .from("tasks")
    .select(
      "id, ref_number, title, description, priority, status, due_date, date_reported, review_date, outcome, details, created_at, registry_id, assigned_to, created_by, parent_task_id",
    )
    .eq("id", id)
    .maybeSingle<TaskRow>();
  // Not found and not allowed look the same, so nobody can probe for tasks.
  if (!task) notFound();
  // Opening a task clears it from your bell.
  await supabase.rpc("mark_task_seen", { p_task_id: id });

  const [
    { data: helpers },
    { data: events },
    { data: managers },
    { data: actions },
    { data: parent },
    { data: canEdit },
    registries,
    allFields,
    people,
    assets,
    timeZone,
  ] = await Promise.all([
    supabase.from("task_helpers").select("user_id").eq("task_id", id),
    supabase.from("task_events").select("id, actor_id, type, to_value, comment, created_at").eq("task_id", id).order("created_at").order("id"),
    supabase.from("registry_managers").select("user_id").eq("registry_id", task.registry_id),
    supabase.from("tasks").select("id, ref_number, title, status, due_date, assigned_to").eq("parent_task_id", id).order("created_at"),
    task.parent_task_id
      ? supabase.from("tasks").select("id, ref_number, title").eq("id", task.parent_task_id).maybeSingle()
      : Promise.resolve({ data: null }),
    supabase.rpc("can_edit_task", { p_task_id: id }),
    getRegistries(),
    getFields(),
    getPeople(),
    getAssets(),
    getTimeZone(),
  ]);
  const brand = await getBranding();

  const registry = registries.find((r) => r.id === task.registry_id);
  if (!registry) notFound();
  const fields = allFields.filter((f) => f.registry_id === registry.id);
  const names = new Map(people.map((p) => [p.id, p.name]));
  const assetNames = new Map(assets.map((a) => [a.id, a.label]));
  const nameOf = (uid: string | null) => (uid ? names.get(uid) ?? "Admin" : "System");
  const helperIds = (helpers ?? []).map((h) => h.user_id);
  const today = todayIn(timeZone);
  const due = dueState(task.due_date, today, task.status);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone });
  const open = task.status !== "closed" && features.tasks !== false;
  const isAction = Boolean(task.parent_task_id);
  const ref = refLabel(registry.prefix, task.ref_number);
  // System admins look after the portal, so they're never given tasks.
  const activePeople = people.filter((p) => p.active && p.role !== "system_admin").map((p) => ({ id: p.id, label: p.name }));
  const helperChoices = activePeople.filter((p) => p.id !== task.assigned_to && !helperIds.includes(p.id));
  const shownFields = fields.filter((f) => f.active || task.details[f.key] !== undefined);
  const display = (f: (typeof fields)[number]) =>
    formatValue(f, task.details[f.key], { person: (pid) => nameOf(pid), asset: (aid) => assetNames.get(aid) ?? "Unknown item" });

  function describe(e: { type: string; actor_id: string | null; to_value: string | null; comment: string | null }) {
    switch (e.type) {
      case "created":
        return `created the task and asked ${nameOf(e.to_value)} to look after it`;
      case "helper_added":
        return `added ${nameOf(e.to_value)} as a helper`;
      case "details_changed":
        return `updated ${e.comment}`;
      case "action_added": {
        const a = (actions ?? []).find((x) => x.id === e.to_value);
        return a ? `added a follow-up action: ${a.title}` : "added a follow-up action";
      }
      default:
        return e.type.replace(/_/g, " ");
    }
  }

  return (
    <>
      <PrintHeader
        brand={brand}
        title={`${registry.name} · ${refLabel(registry.prefix, task.ref_number)}`}
        subtitle={task.title}
        printedAt={when.format(new Date())}
      />
      {created ? (
        <div className="print:hidden">
          <Notice tone="success">Task created. We&apos;ve emailed the people involved.</Notice>
        </div>
      ) : null}
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-3 print:hidden">
          <Link href={`/registers/${registry.id}`} className="text-sm font-semibold text-brand">
            ← {registry.name}
          </Link>
          <PrintButton />
        </div>
        {parent ? (
          <p className="text-sm">
            Follow-up action for{" "}
            <Link href={`/tasks/${parent.id}`} className="font-semibold text-brand">
              {refLabel(registry.prefix, parent.ref_number)} · {parent.title}
            </Link>
          </p>
        ) : null}
        <p className="text-sm font-semibold text-muted">{ref}</p>
        <h1 className="heading">{task.title}</h1>
        <div className="flex flex-wrap items-center gap-2">
          <Badge>{STATUS_LABELS[task.status]}</Badge>
          <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${PRIORITY_CLASS[task.priority]}`}>
            {PRIORITY_LABELS[task.priority]} priority
          </span>
          <span className={`text-sm font-semibold ${due === "overdue" ? "text-danger" : due === "today" ? "text-warn" : "text-muted"}`}>
            {formatDue(task.due_date, today, task.status)}
          </span>
        </div>
      </div>

      <div className="grid items-start gap-4 lg:grid-cols-[1fr_340px] print:grid-cols-[1fr_240px]">
        <div className="flex min-w-0 flex-col gap-4">
          <Card className="p-5">
            <h2 className="mb-2 heading-sm">{registry.description_label}</h2>
            <p className="whitespace-pre-line text-sm leading-relaxed">
              {task.description || <span className="text-muted">Nothing written yet.</span>}
            </p>
          </Card>

          {!isAction && (shownFields.length || registry.show_outcome) ? (
            <Card className="p-5">
              <h2 className="mb-3 heading-sm">{registry.name} details</h2>
              <dl className="grid gap-x-6 gap-y-4 sm:grid-cols-2">
                {shownFields.map((f) => (
                  <div key={f.id} className={f.type === "long_text" ? "sm:col-span-2" : ""}>
                    <Label>{f.label}</Label>
                    <dd className="whitespace-pre-line text-sm">
                      {(() => {
                        const text = display(f);
                        const colour = choiceColour(f, task.details[f.key]);
                        if (!text) return <span className="text-muted">Not filled in</span>;
                        return colour ? (
                          <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${CHOICE_COLOUR_CLASS[colour]}`}>{text}</span>
                        ) : (
                          text
                        );
                      })()}
                    </dd>
                  </div>
                ))}
                {registry.show_outcome ? (
                  <div className="sm:col-span-2">
                    <Label>{registry.outcome_label}</Label>
                    <dd className="whitespace-pre-line text-sm">{task.outcome || <span className="text-muted">Not filled in yet</span>}</dd>
                  </div>
                ) : null}
              </dl>
            </Card>
          ) : null}

          {canEdit && open ? (
            <details className="rounded-lg border border-line bg-surface print:hidden">
              <summary className="flex min-h-14 cursor-pointer list-none items-center px-5 font-semibold text-brand">Edit details</summary>
              <div className="px-5 pb-5">
                <EditDetailsForm
                  task={{ ...task, isAction }}
                  registry={registry}
                  fields={fields.filter((f) => f.active)}
                  people={activePeople}
                  assets={assets.filter((a) => !a.archived)}
                />
              </div>
            </details>
          ) : null}

          {!isAction ? (
            <Card className="flex flex-col gap-4 p-5">
              <div>
                <h2 className="heading-sm">Follow-up actions</h2>
                <p className="text-sm text-muted">Smaller jobs that need doing for this task, each with its own person and due date.</p>
              </div>
              {(actions ?? []).length ? (
                <ul className="flex flex-col divide-y divide-line rounded-md border border-line">
                  {(actions ?? []).map((a) => (
                    <li key={a.id}>
                      <Link href={`/tasks/${a.id}`} className="flex flex-wrap items-center justify-between gap-2 px-4 py-3 hover:bg-page">
                        <span>
                          <span className={`block font-semibold ${DONE.includes(a.status as Status) ? "text-muted line-through" : ""}`}>{a.title}</span>
                          <span className="block text-sm text-muted">
                            {refLabel(registry.prefix, a.ref_number)} · {nameOf(a.assigned_to)}
                          </span>
                        </span>
                        <span className="text-sm font-semibold text-muted">
                          {STATUS_LABELS[a.status as Status]} · {formatDue(a.due_date, today, a.status as Status)}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted">No actions yet.</p>
              )}
              {canEdit && open ? (
                <details className="print:hidden">
                  <summary className="flex min-h-11 cursor-pointer list-none items-center font-semibold text-brand">+ Add a follow-up action</summary>
                  <div className="pt-2">
                    <FollowUpForm parentId={task.id} people={activePeople} today={today} />
                  </div>
                </details>
              ) : null}
            </Card>
          ) : null}

          <Card className="p-5">
            <h2 className="mb-3 heading-sm">Activity</h2>
            <ol className="flex flex-col gap-4">
              {(events ?? []).map((e) => (
                <li key={e.id} className="flex gap-3">
                  <span aria-hidden="true" className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-brand" />
                  <div>
                    <p className="text-sm">
                      <strong>{nameOf(e.actor_id)}</strong> {describe(e)}
                    </p>
                    <time dateTime={e.created_at} className="text-sm text-muted">
                      {when.format(new Date(e.created_at))}
                    </time>
                  </div>
                </li>
              ))}
            </ol>
            <p className="mt-4 text-sm text-muted print:hidden">Comments, status changes and attachments are coming in the next update.</p>
          </Card>
        </div>

        <Card className="flex flex-col gap-4 p-5">
          <h2 className="heading-sm">Details</h2>
          <dl className="flex flex-col gap-3 text-sm">
            <div>
              <Label>Looked after by</Label>
              <dd className="font-semibold">{nameOf(task.assigned_to)}</dd>
            </div>
            <div>
              <Label>Helpers</Label>
              <dd>{helperIds.length ? helperIds.map(nameOf).join(", ") : "No helpers yet"}</dd>
            </div>
            <div>
              <Label>Register managers</Label>
              <dd>
                {/* System admins are hidden from staff, so only people you can see are listed. */}
                {(managers ?? []).filter((m) => names.has(m.user_id)).map((m) => nameOf(m.user_id)).join(", ") || "None yet"}
              </dd>
            </div>
            <div>
              <Label>Date reported</Label>
              <dd>{formatDate(task.date_reported)}</dd>
            </div>
            {registry.show_review_date && !isAction ? (
              <div>
                <Label>{registry.review_label}</Label>
                <dd>{task.review_date ? formatDate(task.review_date) : "Not set"}</dd>
              </div>
            ) : null}
            <div>
              <Label>Created</Label>
              <dd>
                {when.format(new Date(task.created_at))} by {nameOf(task.created_by)}
              </dd>
            </div>
            <div>
              <Label>Manager approval needed to close</Label>
              <dd>{registry.requires_approval ? "Yes" : "No"}</dd>
            </div>
          </dl>
          {open ? (
            <div className="border-t border-line pt-4 print:hidden">
              <AddHelperForm taskId={task.id} people={helperChoices.map((p) => ({ id: p.id, name: p.label }))} />
            </div>
          ) : null}
        </Card>
      </div>
    </>
  );
}

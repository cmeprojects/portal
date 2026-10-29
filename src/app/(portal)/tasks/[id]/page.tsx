// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getRequiredWhen, getTimeZone } from "@/lib/settings";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { CHOICE_COLOUR_CLASS, choiceColour, fieldsForTaskForm, formatDate, formatValue, refLabel, type Details } from "@/lib/registers";
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
import { AttachmentForm, CommentForm, TaskActions, type Can } from "./workflow";
import { describeEvent, type TaskEvent } from "@/lib/task-events";

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
  const { features, profile: me } = await requireTaskAccess();
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
    { data: canApprove },
    { data: files },
    { data: missingFields },
    requiredWhen,
    registries,
    allFields,
    people,
    assets,
    timeZone,
  ] = await Promise.all([
    supabase.from("task_helpers").select("user_id").eq("task_id", id),
    supabase.from("task_events").select("id, actor_id, type, from_value, to_value, comment, created_at").eq("task_id", id).order("created_at").order("id"),
    supabase.from("registry_managers").select("user_id").eq("registry_id", task.registry_id),
    supabase.from("tasks").select("id, ref_number, title, status, due_date, assigned_to").eq("parent_task_id", id).order("created_at"),
    task.parent_task_id
      ? supabase.from("tasks").select("id, ref_number, title").eq("id", task.parent_task_id).maybeSingle()
      : Promise.resolve({ data: null }),
    supabase.rpc("can_edit_task", { p_task_id: id }),
    supabase.rpc("can_approve_task", { p_task_id: id }),
    supabase.from("task_attachments").select("id, file_path, file_name, uploaded_by, created_at").eq("task_id", id).order("created_at"),
    supabase.rpc("task_missing_fields", { p_task_id: id }),
    getRequiredWhen(),
    getRegistries(),
    getFields(),
    getPeople(),
    getAssets(),
    getTimeZone(),
  ]);
  const brand = await getBranding();
  // Files open through short-lived private links.
  const fileLinks = new Map<number, string>();
  await Promise.all(
    (files ?? []).map(async (f) => {
      const { data } = await supabase.storage.from("task-files").createSignedUrl(f.file_path, 3600);
      if (data?.signedUrl) fileLinks.set(f.id, data.signedUrl);
    }),
  );

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

  const mine = task.assigned_to === me.id;
  const isHelper = helperIds.includes(me.id);
  const working = ["assigned", "in_progress", "escalated"].includes(task.status);
  const finished = task.status === "completed" || task.status === "closed";
  const live = features.tasks !== false;
  const can: Can = {
    start: live && Boolean(canEdit) && task.status === "assigned",
    complete: live && Boolean(canEdit) && working,
    completeNeedsApproval: registry.requires_approval && !canApprove && !(mine && me.role === "manager"),
    managerOwn: registry.requires_approval && mine && me.role === "manager",
    approve: live && task.status === "awaiting_approval" && Boolean(canApprove),
    close: live && Boolean(canEdit) && task.status === "completed" && (!mine || task.created_by === me.id),
    reopen: live && Boolean(canEdit) && finished && !mine,
    resolveEscalation: live && Boolean(canEdit) && task.status === "escalated" && !mine,
    escalate: live && (Boolean(canEdit) || isHelper) && (task.status === "assigned" || task.status === "in_progress"),
    reassign: live && Boolean(canEdit) && !finished,
    takeOver: live && Boolean(canEdit) && !mine && !finished && (me.role === "team_leader" || me.role === "manager"),
  };
  const reassignTo = activePeople.filter((p) => p.id !== task.assigned_to).map((p) => ({ id: p.id, name: p.label }));

  const describe = (e: TaskEvent) => describeEvent(e, nameOf, (aid) => (actions ?? []).find((x) => x.id === aid)?.title);


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

      <div className="grid items-start gap-4 lg:grid-cols-[1fr_340px] print:flex print:flex-col print:gap-3">
        <div className="flex min-w-0 flex-col gap-4 print:gap-3">
          <Card className="p-5">
            <h2 className="mb-2 heading-sm">{registry.description_label}</h2>
            <p className="whitespace-pre-line text-sm leading-relaxed">
              {task.description || <span className="text-muted">Nothing written yet.</span>}
            </p>
          </Card>

          {!isAction && (shownFields.length || registry.show_outcome) ? (
            <Card className="p-5">
              <h2 className="mb-3 heading-sm">{registry.name} details</h2>
              <dl className="grid gap-x-6 gap-y-4 sm:grid-cols-2 print:grid-cols-3 print:gap-y-2">
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
                  fields={fieldsForTaskForm(fields.filter((f) => f.active), requiredWhen)}
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
            <ol className="flex flex-col gap-4 print:gap-2">
              {(events ?? []).map((e) => (
                <li key={e.id} className="flex gap-3">
                  <span aria-hidden="true" className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-brand" />
                  <div>
                    <p className="text-sm">
                      <strong>{nameOf(e.actor_id)}</strong> {describe(e)}
                    </p>
                    {e.comment && e.type !== "details_changed" && e.type !== "attachment_added" ? (
                      <p className={`mt-1 whitespace-pre-line text-sm ${e.type === "comment" ? "rounded-md bg-page px-3 py-2" : "text-muted"}`}>
                        {e.type === "comment" ? e.comment : `“${e.comment}”`}
                      </p>
                    ) : null}
                    <time dateTime={e.created_at} className="text-sm text-muted">
                      {when.format(new Date(e.created_at))}
                    </time>
                  </div>
                </li>
              ))}
            </ol>
            {open ? (
              <div className="mt-5 border-t border-line pt-4 print:hidden">
                <CommentForm taskId={task.id} />
              </div>
            ) : null}
          </Card>

          {features.attachments !== false || (files ?? []).length ? (
          <Card className="flex flex-col gap-3 p-5">
            <h2 className="heading-sm">Files · {(files ?? []).length}</h2>
            {(files ?? []).length ? (
              <ul className="flex flex-col divide-y divide-line rounded-md border border-line">
                {(files ?? []).map((f) => (
                  <li key={f.id} className="flex flex-wrap items-center justify-between gap-2 px-4 py-3 text-sm">
                    {fileLinks.has(f.id) ? (
                      <a href={fileLinks.get(f.id)} target="_blank" rel="noopener noreferrer" className="font-semibold text-brand underline">
                        {f.file_name}
                      </a>
                    ) : (
                      <span className="font-semibold">{f.file_name}</span>
                    )}
                    <span className="text-muted">
                      {nameOf(f.uploaded_by)} · {when.format(new Date(f.created_at))}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted">No files yet.</p>
            )}
            {open && features.attachments !== false ? (
              <div className="print:hidden">
                <AttachmentForm taskId={task.id} />
              </div>
            ) : null}
          </Card>
          ) : null}
        </div>

        <div className="flex flex-col gap-4 print:order-first print:gap-3">
        {Object.entries(can).some(([k, v]) => k !== "completeNeedsApproval" && k !== "managerOwn" && v) ? (
          <Card className="flex flex-col gap-3 p-5 print:hidden">
            <h2 className="heading-sm">What&apos;s next</h2>
            {(can.complete || can.approve) && (missingFields ?? []).length ? (
              <div className="rounded-md border border-warn/40 bg-warn-soft/40 p-3 text-sm">
                <p className="font-semibold">Before {can.completeNeedsApproval ? "sending it for approval" : "completing"}, fill in:</p>
                <ul className="mt-1 list-disc pl-5">
                  {(missingFields as string[]).map((m) => (
                    <li key={m}>{m}</li>
                  ))}
                </ul>
                {canEdit ? <p className="mt-1 text-muted">Use Edit details on this page.</p> : null}
              </div>
            ) : null}
            <TaskActions taskId={task.id} can={can} people={reassignTo} />
          </Card>
        ) : null}
        <Card className="flex flex-col gap-4 p-5 print:gap-2">
          <h2 className="heading-sm">Details</h2>
          <dl className="flex flex-col gap-3 text-sm print:grid print:grid-cols-4 print:gap-x-4 print:gap-y-2">
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
      </div>
    </>
  );
}

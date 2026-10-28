// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { getBranding } from "@/lib/branding";
import { env } from "@/lib/env";
import { sendEmail } from "./send";
import { render, renderSummary, type SummaryTask, type TaskInfo } from "./templates";
import { refLabel } from "@/lib/registers";

const MAX_ATTEMPTS = 5;

type Row = {
  id: number;
  to_user: string;
  cc_users: string[];
  template: string;
  task_id: string | null;
  data: Record<string, unknown> | null;
  attempts: number;
  created_at: string;
};

// Sends the emails waiting in the queue (for one task, or all of them).
// Failures are kept with the error so they can be retried later.
export async function flushOutbox(taskId?: string): Promise<void> {
  let admin;
  try {
    admin = createAdminClient();
  } catch {
    return; // Not connected yet.
  }

  let query = admin
    .from("email_outbox")
    .select("id, to_user, cc_users, template, task_id, data, attempts, created_at")
    .is("sent_at", null)
    .lt("attempts", MAX_ATTEMPTS)
    .order("id")
    .limit(50);
  if (taskId) query = query.eq("task_id", taskId);
  const { data: rows } = await query.returns<Row[]>();
  if (!rows?.length) return;

  const brand = await getBranding();
  const peopleIds = [...new Set(rows.flatMap((r) => [r.to_user, ...r.cc_users]))];
  const taskIds = [...new Set(rows.map((r) => r.task_id).filter((x): x is string => Boolean(x)))];

  const [{ data: people }, { data: tasks }, { data: events }] = await Promise.all([
    admin.from("profiles").select("id, full_name, email, active, role").in("id", peopleIds),
    admin
      .from("tasks")
      .select("id, ref_number, title, description, priority, due_date, registry_id, assigned_to, created_by, registries(name, prefix)")
      .in("id", taskIds),
    admin.from("task_events").select("task_id, actor_id, type, created_at").in("task_id", taskIds),
  ]);

  const extraIds = (tasks ?? []).flatMap((t) => [t.assigned_to, t.created_by]).concat((events ?? []).map((e) => e.actor_id));
  const missing = [...new Set(extraIds)].filter((id) => id && !people?.some((p) => p.id === id));
  const { data: more } = missing.length
    ? await admin.from("profiles").select("id, full_name, email, active, role").in("id", missing)
    : { data: [] };
  const everyone = new Map([...(people ?? []), ...(more ?? [])].map((p) => [p.id, p]));
  // System admins are hidden from staff, so their actions show as "Admin".
  const nameOf = (id: string | null | undefined) => {
    const p = id ? everyone.get(id) : undefined;
    if (!p) return "Someone";
    return p.role === "system_admin" ? "Admin" : p.full_name || p.email;
  };

  for (const row of rows) {
    const to = everyone.get(row.to_user);
    const task = (tasks ?? []).find((t) => t.id === row.task_id);
    try {
      // The managers' morning summary isn't about one task.
      if (row.template === "overdue_summary") {
        if (!to?.active) {
          await admin.from("email_outbox").update({ sent_at: new Date().toISOString(), last_error: "skipped" }).eq("id", row.id);
          continue;
        }
        const msg = renderSummary({
          tasks: ((row.data?.tasks as SummaryTask[] | undefined) ?? []),
          recipientName: (to.full_name || to.email).split(" ")[0],
          companyName: brand.companyName,
          siteUrl: env.siteUrl,
          brand: brand.colorPrimary,
        });
        await sendEmail({ to: { email: to.email, name: to.full_name }, cc: [], ...msg });
        await admin.from("email_outbox").update({ sent_at: new Date().toISOString(), attempts: row.attempts + 1, last_error: null }).eq("id", row.id);
        continue;
      }
      if (!to?.active || !task) {
        await admin.from("email_outbox").update({ sent_at: new Date().toISOString(), last_error: "skipped" }).eq("id", row.id);
        continue;
      }
      // The person who did the thing that caused this email.
      const cause = (events ?? [])
        .filter((e) => e.task_id === row.task_id && e.created_at <= row.created_at)
        .sort((a, b) => (a.created_at < b.created_at ? 1 : -1))[0];
      const registry = task.registries as unknown as { name: string; prefix: string } | null;
      const info: TaskInfo = {
        id: task.id,
        ref: refLabel(registry?.prefix, task.ref_number),
        title: task.title,
        description: task.description,
        priority: task.priority,
        due_date: task.due_date,
        registry: registry?.name ?? "",
        assignee: nameOf(task.assigned_to),
        createdBy: nameOf(task.created_by),
      };
      const msg = render(row.template, {
        task: info,
        recipientName: (to.full_name || to.email).split(" ")[0],
        actorName: nameOf(cause?.actor_id),
        companyName: brand.companyName,
        link: `${env.siteUrl}/tasks/${task.id}`,
        brand: brand.colorPrimary,
      });
      const cc = row.cc_users
        .map((id) => everyone.get(id))
        .filter((p): p is NonNullable<typeof p> => Boolean(p?.active))
        .map((p) => ({ email: p.email, name: p.full_name }));
      await sendEmail({ to: { email: to.email, name: to.full_name }, cc, ...msg });
      await admin.from("email_outbox").update({ sent_at: new Date().toISOString(), attempts: row.attempts + 1, last_error: null }).eq("id", row.id);
    } catch (e) {
      await admin
        .from("email_outbox")
        .update({ attempts: row.attempts + 1, last_error: String(e instanceof Error ? e.message : e).slice(0, 500) })
        .eq("id", row.id);
    }
  }
}

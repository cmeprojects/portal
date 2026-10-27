// Staff Portal · © cmeproject. All rights reserved.
import { PRIORITY_LABELS, type Priority } from "@/lib/tasks";

export type TaskInfo = {
  id: string;
  ref: string;
  title: string;
  description: string;
  priority: Priority;
  due_date: string | null;
  registry: string;
  assignee: string;
  createdBy: string;
};

export type Rendered = { subject: string; html: string; text: string };

type Ctx = { task: TaskInfo; recipientName: string; actorName: string; companyName: string; link: string; brand: string };

function esc(s: string) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function dueText(due: string | null) {
  if (!due) return "No due date";
  return new Intl.DateTimeFormat("en-AU", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" }).format(
    new Date(`${due}T00:00:00Z`),
  );
}

function layout(ctx: Ctx, heading: string, intro: string): Rendered & { subjectSuffix?: never } {
  const t = ctx.task;
  const rows: [string, string][] = [
    ["Task", `${t.ref} · ${t.title}`],
    ["Registry", t.registry],
    ["Priority", PRIORITY_LABELS[t.priority]],
    ["Due", dueText(t.due_date)],
    ["Looked after by", t.assignee],
  ];
  const desc = t.description.length > 600 ? `${t.description.slice(0, 600)}…` : t.description;

  const html = `<!-- Staff Portal · © cmeproject -->
<div style="font-family:Figtree,Arial,sans-serif;color:#1B2333;max-width:560px">
  <p style="margin:0 0 4px;color:#5A6478;font-size:14px">${esc(ctx.companyName)}</p>
  <h2 style="margin:0 0 12px;font-size:22px">${esc(heading)}</h2>
  <p style="margin:0 0 16px;font-size:16px;line-height:1.5">Hi ${esc(ctx.recipientName)}, ${esc(intro)}</p>
  <table style="border-collapse:collapse;font-size:15px;margin:0 0 16px">
    ${rows.map(([k, v]) => `<tr><td style="padding:4px 16px 4px 0;color:#5A6478">${esc(k)}</td><td style="padding:4px 0;font-weight:600">${esc(v)}</td></tr>`).join("")}
  </table>
  ${desc ? `<p style="margin:0 0 16px;padding:12px 14px;background:#F6F8FB;border-radius:12px;font-size:15px;line-height:1.5;white-space:pre-line">${esc(desc)}</p>` : ""}
  <p style="margin:0 0 24px"><a href="${esc(ctx.link)}" style="display:inline-block;padding:12px 22px;border-radius:999px;background:${esc(ctx.brand)};color:#ffffff;font-weight:bold;text-decoration:none">Open the task</a></p>
  <p style="margin:0;color:#5A6478;font-size:13px">You're getting this because of your role on this task in the ${esc(ctx.companyName)} staff portal.</p>
</div>`;

  const text = [
    `Hi ${ctx.recipientName}, ${intro}`,
    "",
    ...rows.map(([k, v]) => `${k}: ${v}`),
    ...(desc ? ["", desc] : []),
    "",
    `Open the task: ${ctx.link}`,
  ].join("\n");

  return { subject: "", html, text };
}

export function render(template: string, ctx: Ctx): Rendered {
  const t = ctx.task;
  const tag = `${t.ref}: ${t.title}`;
  switch (template) {
    case "task_assigned": {
      const r = layout(ctx, "You have a new task", `${ctx.actorName} has asked you to look after this task.`);
      return { ...r, subject: `New task for you · ${tag}` };
    }
    case "helper_added": {
      const r = layout(ctx, "Can you help out?", `${ctx.actorName} has tagged you to help with this task.`);
      return { ...r, subject: `You're helping on ${tag}` };
    }
    case "task_created_manager": {
      const r = layout(ctx, `New task in ${t.registry}`, `${ctx.actorName} created a task in a registry you manage.`);
      return { ...r, subject: `New task in ${t.registry} · ${tag}` };
    }
    default:
      throw new Error(`Unknown email template ${template}`);
  }
}

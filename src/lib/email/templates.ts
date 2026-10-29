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
    case "task_reminder": {
      const r = layout(ctx, "Coming up soon", `this task you're looking after is due ${dueText(t.due_date)}.`);
      return { ...r, subject: `Due soon · ${tag}` };
    }
    case "task_due_today": {
      const r = layout(ctx, "Due today", "this task is due today.");
      return { ...r, subject: `Due today · ${tag}` };
    }
    case "task_overdue": {
      const r = layout(ctx, "This task is overdue", `this task was due ${dueText(t.due_date)} and isn't finished yet.`);
      return { ...r, subject: `Overdue · ${tag}` };
    }
    case "task_escalated": {
      const r = layout(ctx, "Escalated: still overdue", `this task was due ${dueText(t.due_date)} and is still not finished, so it has been escalated to you.`);
      return { ...r, subject: `Escalated · ${tag}` };
    }
    default:
      throw new Error(`Unknown email template ${template}`);
  }
}

export type SummaryTask = {
  id: string;
  ref: string;
  title: string;
  registry: string;
  assignee: string;
  due_date: string;
  days_late: number;
  escalated: boolean;
};

// The managers' morning email: everything overdue, most overdue first.
export function renderSummary(ctx: {
  tasks: SummaryTask[];
  recipientName: string;
  companyName: string;
  siteUrl: string;
  brand: string;
}): Rendered {
  const n = ctx.tasks.length;
  const intro = `${n} task${n === 1 ? " is" : "s are"} overdue this morning.`;
  const late = (t: SummaryTask) => `${t.days_late} day${t.days_late === 1 ? "" : "s"} late${t.escalated ? " · escalated" : ""}`;
  const rows = ctx.tasks
    .map(
      (t) => `<tr>
      <td style="padding:8px 12px 8px 0;border-top:1px solid #E3E8EF;vertical-align:top"><a href="${esc(`${ctx.siteUrl}/tasks/${t.id}`)}" style="color:${esc(ctx.brand)};font-weight:600;text-decoration:none">${esc(t.ref)}</a></td>
      <td style="padding:8px 12px 8px 0;border-top:1px solid #E3E8EF;vertical-align:top">${esc(t.title)}<br><span style="color:#5A6478;font-size:13px">${esc(t.registry)} · ${esc(t.assignee)}</span></td>
      <td style="padding:8px 0;border-top:1px solid #E3E8EF;vertical-align:top;white-space:nowrap;color:${t.escalated ? "#B42318" : "#9A5B00"};font-weight:600">${esc(late(t))}</td>
    </tr>`,
    )
    .join("");
  const html = `<!-- Staff Portal · © cmeproject -->
<div style="font-family:Figtree,Arial,sans-serif;color:#1B2333;max-width:640px">
  <p style="margin:0 0 4px;color:#5A6478;font-size:14px">${esc(ctx.companyName)}</p>
  <h2 style="margin:0 0 12px;font-size:22px">Overdue tasks</h2>
  <p style="margin:0 0 16px;font-size:16px;line-height:1.5">Good morning ${esc(ctx.recipientName)}, ${esc(intro)}</p>
  <table style="border-collapse:collapse;font-size:15px;margin:0 0 20px;width:100%">${rows}</table>
  <p style="margin:0 0 24px"><a href="${esc(ctx.siteUrl)}/" style="display:inline-block;padding:12px 22px;border-radius:999px;background:${esc(ctx.brand)};color:#ffffff;font-weight:bold;text-decoration:none">Open the dashboard</a></p>
  <p style="margin:0;color:#5A6478;font-size:13px">You're getting this each weekday morning as a manager in the ${esc(ctx.companyName)} staff portal.</p>
</div>`;
  const text = [
    `Good morning ${ctx.recipientName}, ${intro}`,
    "",
    ...ctx.tasks.map((t) => `${t.ref} · ${t.title} (${t.assignee}) · ${late(t)}\n${ctx.siteUrl}/tasks/${t.id}`),
    "",
    `Open the dashboard: ${ctx.siteUrl}/`,
  ].join("\n");
  return { subject: `${n} overdue task${n === 1 ? "" : "s"} · ${ctx.companyName}`, html, text };
}

// The welcome invite, with the company's logo.
export function renderInvite(ctx: {
  // The system admin's extra note (System settings → Messages).
  note?: string;
  recipientName: string;
  invitedBy: string;
  companyName: string;
  logo: string;
  link: string;
  brand: string;
}): Rendered {
  const steps = [
    ["Set up your sign-in", "Choose a password (or sign in with email links)."],
    ["Do your onboarding", "Read and confirm our policies, complete any trainings, and upload documents like your police check."],
    ["Get your role", "Once onboarding is done, we'll set up your role and team, and your tasks will appear."],
  ];
  const hi = ctx.recipientName ? `Hi ${ctx.recipientName},` : "Hi,";
  const html = `<!-- Staff Portal · © cmeproject -->
<div style="background:#F3F5F9;padding:24px 12px;font-family:Figtree,Arial,sans-serif;color:#1B2333">
  <div style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden">
    <div style="padding:28px 28px 0;text-align:center">
      <img src="${esc(ctx.logo)}" alt="${esc(ctx.companyName)}" style="max-height:72px;max-width:260px">
    </div>
    <div style="padding:20px 28px 28px">
      <h1 style="margin:0 0 12px;font-size:24px;text-align:center">Welcome to ${esc(ctx.companyName)}</h1>
      <p style="margin:0 0 20px;font-size:16px;line-height:1.55">${esc(hi)} ${esc(ctx.invitedBy)} has invited you to join the ${esc(ctx.companyName)} staff portal. It's where you'll do your onboarding, keep your documents up to date and see your tasks.</p>
      ${ctx.note ? `<p style="margin:0 0 20px;padding:12px 14px;background:#F6F8FB;border-radius:12px;font-size:15px;line-height:1.5;white-space:pre-line">${esc(ctx.note)}</p>` : ""}
      <p style="margin:0 0 24px;text-align:center"><a href="${esc(ctx.link)}" style="display:inline-block;padding:14px 28px;border-radius:999px;background:${esc(ctx.brand)};color:#ffffff;font-weight:bold;font-size:16px;text-decoration:none">Accept your invite</a></p>
      <table style="border-collapse:collapse;width:100%;font-size:15px;line-height:1.45">
        ${steps
          .map(
            ([title, text], i) => `<tr>
          <td style="width:36px;padding:8px 12px 8px 0;vertical-align:top"><span style="display:inline-block;width:28px;height:28px;border-radius:999px;background:${esc(ctx.brand)};color:#fff;font-weight:bold;text-align:center;line-height:28px">${i + 1}</span></td>
          <td style="padding:8px 0;vertical-align:top"><strong>${esc(title)}</strong><br><span style="color:#5A6478">${esc(text)}</span></td>
        </tr>`,
          )
          .join("")}
      </table>
      <p style="margin:24px 0 0;color:#5A6478;font-size:13px;line-height:1.5">This link works once and expires after 24 hours. If it has expired, ask the person who invited you to send a new one.</p>
    </div>
  </div>
</div>`;
  const text = [
    `${hi} ${ctx.invitedBy} has invited you to join the ${ctx.companyName} staff portal.`,
    "",
    ...(ctx.note ? [ctx.note, ""] : []),
    `Accept your invite: ${ctx.link}`,
    "",
    ...steps.map(([title, t], i) => `${i + 1}. ${title}: ${t}`),
    "",
    "This link works once and expires after 24 hours.",
  ].join("\n");
  return { subject: `Welcome to ${ctx.companyName}: your staff portal invite`, html, text };
}

// A general notice from the bell (joined, approvals, expired documents).
export function renderNotice(ctx: { title: string; body: string; link: string; recipientName: string; companyName: string; brand: string }): Rendered {
  const html = `<!-- Staff Portal · © cmeproject -->
<div style="font-family:Figtree,Arial,sans-serif;color:#1B2333;max-width:560px">
  <p style="margin:0 0 4px;color:#5A6478;font-size:14px">${esc(ctx.companyName)}</p>
  <h2 style="margin:0 0 12px;font-size:22px">${esc(ctx.title)}</h2>
  <p style="margin:0 0 16px;font-size:16px;line-height:1.5">Hi ${esc(ctx.recipientName)},${ctx.body ? ` ${esc(ctx.body)}` : ""}</p>
  <p style="margin:0 0 24px"><a href="${esc(ctx.link)}" style="display:inline-block;padding:12px 22px;border-radius:999px;background:${esc(ctx.brand)};color:#ffffff;font-weight:bold;text-decoration:none">Open the portal</a></p>
  <p style="margin:0;color:#5A6478;font-size:13px">From the ${esc(ctx.companyName)} staff portal.</p>
</div>`;
  return { subject: ctx.title, html, text: `Hi ${ctx.recipientName},${ctx.body ? ` ${ctx.body}` : ""}\n\n${ctx.link}` };
}

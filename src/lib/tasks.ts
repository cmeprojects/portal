// Staff Portal · © cmeproject. All rights reserved.

export const PRIORITIES = ["low", "medium", "high", "urgent"] as const;
export type Priority = (typeof PRIORITIES)[number];

export const STATUSES = ["assigned", "in_progress", "escalated", "awaiting_approval", "completed", "closed"] as const;
export type Status = (typeof STATUSES)[number];

export const PRIORITY_LABELS: Record<Priority, string> = {
  low: "Low",
  medium: "Medium",
  high: "High",
  urgent: "Urgent",
};

export const STATUS_LABELS: Record<Status, string> = {
  assigned: "Assigned",
  in_progress: "In progress",
  escalated: "Escalated",
  awaiting_approval: "Awaiting approval",
  completed: "Completed",
  closed: "Closed",
};

// Badge colours: priority is told apart by lightness as well as hue.
export const PRIORITY_CLASS: Record<Priority, string> = {
  low: "bg-page text-muted ring-1 ring-line ring-inset",
  medium: "bg-brand-soft text-brand",
  high: "bg-warn-soft text-warn",
  urgent: "bg-danger-soft text-danger",
};

export const DONE: Status[] = ["completed", "closed"];

// Days to finish a task, by priority. Missing priorities have no default.
export type Sla = Partial<Record<Priority, number>>;

export function parseSla(value: unknown): Sla {
  const out: Sla = {};
  if (value && typeof value === "object") {
    for (const p of PRIORITIES) {
      const n = (value as Record<string, unknown>)[p];
      if (typeof n === "number" && Number.isInteger(n) && n >= 0 && n <= 365) out[p] = n;
    }
  }
  return out;
}

// Days per priority from form inputs named <prefix><priority>; blanks are left out.
export function slaFromForm(form: FormData, prefix: string): Record<string, number> {
  const out: Record<string, number> = {};
  for (const p of PRIORITIES) {
    const v = form.get(`${prefix}${p}`);
    const raw = typeof v === "string" ? v.trim() : "";
    const n = Number(raw);
    if (raw !== "" && Number.isInteger(n) && n >= 0 && n <= 365) out[p] = n;
  }
  return out;
}

// The SLA due date: start + days, optionally skipping weekends.
export function slaDueDate(start: string, days: number, weekdaysOnly: boolean): string {
  const d = new Date(`${start}T00:00:00Z`);
  if (!weekdaysOnly) {
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
  }
  let left = days;
  while (left > 0) {
    d.setUTCDate(d.getUTCDate() + 1);
    const wd = d.getUTCDay();
    if (wd !== 0 && wd !== 6) left--;
  }
  // A task reported at the weekend with 0 days is still due on a weekday.
  while (d.getUTCDay() === 0 || d.getUTCDay() === 6) d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

export function isPriority(v: unknown): v is Priority {
  return typeof v === "string" && (PRIORITIES as readonly string[]).includes(v);
}

// Today's date (YYYY-MM-DD) in the company's time zone.
export function todayIn(timeZone: string): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone }).format(new Date());
}

function addDays(isoDate: string, days: number): string {
  const d = new Date(`${isoDate}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

// Last day of this week (Sunday), weeks running Monday to Sunday.
export function endOfWeek(today: string): string {
  const day = new Date(`${today}T00:00:00Z`).getUTCDay(); // 0 = Sunday
  return addDays(today, (7 - day) % 7);
}

export type DueState = "overdue" | "today" | "soon" | "later" | "none";

export function dueState(due: string | null, today: string, status: Status): DueState {
  if (!due || DONE.includes(status)) return "none";
  if (due < today) return "overdue";
  if (due === today) return "today";
  if (due <= addDays(today, 3)) return "soon";
  return "later";
}

const DUE_FORMAT = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });

export function formatDue(due: string | null, today: string, status: Status): string {
  if (!due) return "No due date";
  const label = DUE_FORMAT.format(new Date(`${due}T00:00:00Z`));
  switch (dueState(due, today, status)) {
    case "overdue":
      return `Overdue · ${label}`;
    case "today":
      return "Due today";
    default:
      return `Due ${label}`;
  }
}

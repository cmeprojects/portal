// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import { choiceColour, formatDate, formatValue, refLabel, type ChoiceColour, type Details, type Registry, type RegistryField } from "@/lib/registers";
import { DONE, PRIORITY_LABELS, STATUS_LABELS, type Priority, type Status } from "@/lib/tasks";
import type { AssetOption, PersonOption } from "@/lib/register-data";

export type Column = { key: string; label: string; wide?: boolean };
export type Cell = { text: string; href?: string; tone?: "danger" | "muted"; badge?: ChoiceColour };
export type Table = { columns: Column[]; rows: { id: string; href: string; cells: Record<string, Cell> }[] };

// from / to: dates (YYYY-MM-DD) on the date reported (tasks) or date added (lists).
export type Filter = { status: "open" | "done" | "all"; q: string; from: string; to: string };

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export function parseFilter(params: Record<string, string | string[] | undefined>): Filter {
  const status = params.status === "done" || params.status === "all" ? params.status : "open";
  const q = typeof params.q === "string" ? params.q.trim().slice(0, 100) : "";
  const date = (v: unknown) => (typeof v === "string" && ISO_DATE.test(v) ? v : "");
  return { status, q, from: date(params.from), to: date(params.to) };
}

// The filter as a query string (for links and downloads).
export function filterQuery(f: Filter, status = f.status): string {
  const p = new URLSearchParams();
  if (status !== "open") p.set("status", status);
  if (f.q) p.set("q", f.q);
  if (f.from) p.set("from", f.from);
  if (f.to) p.set("to", f.to);
  const s = p.toString();
  return s ? `?${s}` : "";
}

function nextDay(iso: string): string {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

// Rows of a register, as the signed-in person is allowed to see them.
export async function registerTable(
  registry: Registry,
  fields: RegistryField[],
  people: PersonOption[],
  assets: AssetOption[],
  filter: Filter,
  today: string,
): Promise<Table> {
  const supabase = await createClient();
  const names = new Map(people.map((p) => [p.id, p.name]));
  const assetNames = new Map(assets.map((a) => [a.id, a.label]));
  const lookup = { person: (id: string) => names.get(id) ?? "Former staff member", asset: (id: string) => assetNames.get(id) ?? "Unknown item" };
  const shown = fields.filter((f) => f.registry_id === registry.id && f.active);
  const q = filter.q.replace(/[%_,()]/g, " ");

  if (registry.kind === "records") {
    let query = supabase.from("records").select("id, ref_number, title, details, archived").eq("registry_id", registry.id).order("ref_number");
    if (filter.status === "open") query = query.eq("archived", false);
    if (filter.status === "done") query = query.eq("archived", true);
    if (q) query = query.ilike("title", `%${q}%`);
    if (filter.from) query = query.gte("created_at", filter.from);
    if (filter.to) query = query.lt("created_at", nextDay(filter.to));
    const { data } = await query.limit(5000);
    const columns: Column[] = [
      { key: "ref", label: "Ref." },
      { key: "title", label: registry.title_label, wide: true },
      ...shown.map((f) => ({ key: f.key, label: f.label, wide: f.type === "long_text" })),
    ];
    return {
      columns,
      rows: (data ?? []).map((r) => {
        const details = (r.details ?? {}) as Details;
        const cells: Record<string, Cell> = {
          ref: { text: refLabel(registry.prefix, r.ref_number) },
          title: { text: r.archived ? `${r.title} (archived)` : r.title, tone: r.archived ? "muted" : undefined },
        };
        for (const f of shown) cells[f.key] = { text: formatValue(f, details[f.key], lookup), badge: choiceColour(f, details[f.key]) };
        return { id: r.id, href: `/records/${r.id}`, cells };
      }),
    };
  }

  let query = supabase
    .from("tasks")
    .select("id, ref_number, title, status, priority, assigned_to, date_reported, due_date, review_date, outcome, details, created_by")
    .eq("registry_id", registry.id)
    .is("parent_task_id", null)
    .order("ref_number", { ascending: false });
  if (filter.status === "open") query = query.not("status", "in", `(${DONE.join(",")})`);
  if (filter.status === "done") query = query.in("status", DONE);
  if (q) query = query.ilike("title", `%${q}%`);
  if (filter.from) query = query.gte("date_reported", filter.from);
  if (filter.to) query = query.lte("date_reported", filter.to);
  const { data } = await query.limit(5000);

  const columns: Column[] = [
    { key: "ref", label: "Ref." },
    { key: "title", label: registry.title_label, wide: true },
    { key: "status", label: "Status" },
    { key: "priority", label: "Priority" },
    { key: "assigned_to", label: "Looked after by" },
    { key: "date_reported", label: "Date reported" },
    ...(registry.show_due_date ? [{ key: "due_date", label: "Due" }] : []),
    ...shown.map((f) => ({ key: f.key, label: f.label, wide: f.type === "long_text" })),
    ...(registry.show_outcome ? [{ key: "outcome", label: registry.outcome_label, wide: true }] : []),
    ...(registry.show_review_date ? [{ key: "review_date", label: registry.review_label }] : []),
  ];

  return {
    columns,
    rows: (data ?? []).map((t) => {
      const details = (t.details ?? {}) as Details;
      const status = t.status as Status;
      const overdue = t.due_date && t.due_date < today && !DONE.includes(status);
      const cells: Record<string, Cell> = {
        ref: { text: refLabel(registry.prefix, t.ref_number) },
        title: { text: t.title },
        status: { text: STATUS_LABELS[status] },
        priority: { text: PRIORITY_LABELS[t.priority as Priority] },
        assigned_to: { text: names.get(t.assigned_to) ?? "" },
        date_reported: { text: formatDate(t.date_reported) },
        due_date: { text: formatDate(t.due_date), tone: overdue ? "danger" : undefined },
        review_date: { text: formatDate(t.review_date) },
        outcome: { text: t.outcome },
      };
      for (const f of shown) cells[f.key] = { text: formatValue(f, details[f.key], lookup), badge: choiceColour(f, details[f.key]) };
      return { id: t.id, href: `/tasks/${t.id}`, cells };
    }),
  };
}

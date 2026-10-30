// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Cell, Table } from "@/lib/register-rows";
import { PERIODS as CAR_PERIODS, periodFor, type CarPeriod } from "@/lib/car-reports";
import type { Feature, FeatureField } from "@/lib/feature-types";

// Reports for features built in the Feature builder (cmeprojects): every
// entry, or each client's daily total against their target, over a period,
// for one client or staff member or everyone. People see the entries they're
// allowed to (team leaders: their own team).

export type FeatureReportKind = "entries" | "daily";
export type FeatureFilter = { kind: FeatureReportKind; period: CarPeriod; client: string; staff: string };

export const FEATURE_KIND_LABELS: Record<FeatureReportKind, string> = { entries: "Every entry", daily: "Daily totals" };
export const FEATURE_KIND_HINTS: Record<FeatureReportKind, string> = {
  entries: "Each entry with its date, time, answers and who entered it.",
  daily: "Each client's total for each day, against their target.",
};
export const FEATURE_PERIODS = [
  { key: "today", label: "Today" },
  { key: "yesterday", label: "Yesterday" },
  { key: "7-days", label: "Last 7 days" },
  ...CAR_PERIODS,
] as const;

const ISO = /^\d{4}-\d{2}-\d{2}$/;
const UUID = /^[0-9a-f-]{36}$/;

function addDays(iso: string, days: number) {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}
const nice = (iso: string) =>
  new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

function featurePeriod(key: string, today: string, from: string, to: string): CarPeriod {
  if (ISO.test(from) && ISO.test(to) && from <= to) return periodFor("", today, from, to);
  if (key === "today") return { key, from: today, to: today, label: `Today: ${nice(today)}` };
  if (key === "yesterday") return { key, from: addDays(today, -1), to: addDays(today, -1), label: `Yesterday: ${nice(addDays(today, -1))}` };
  if (key === "7-days" || !key) return { key: "7-days", from: addDays(today, -6), to: today, label: `Last 7 days: ${nice(addDays(today, -6))} to ${nice(today)}` };
  return periodFor(key, today);
}

export function parseFeatureFilter(params: Record<string, string | string[] | undefined>, today: string, hasTotals: boolean): FeatureFilter {
  const one = (k: string) => (typeof params[k] === "string" ? (params[k] as string).trim().slice(0, 100) : "");
  return {
    kind: one("report") === "daily" && hasTotals ? "daily" : "entries",
    period: featurePeriod(one("range"), today, one("from"), one("to")),
    client: UUID.test(one("client")) ? one("client") : "",
    staff: UUID.test(one("staff")) ? one("staff") : "",
  };
}

export function featureFilterQuery(f: FeatureFilter): string {
  const q = new URLSearchParams({ report: f.kind });
  if (f.period.key === "custom") {
    q.set("from", f.period.from);
    q.set("to", f.period.to);
  } else q.set("range", f.period.key);
  if (f.client) q.set("client", f.client);
  if (f.staff) q.set("staff", f.staff);
  return q.toString();
}

type Entry = {
  id: number;
  data: Record<string, unknown>;
  client_id: string | null;
  client_name: string;
  team_names: string;
  created_by: string;
  created_at: string;
  corrected_at: string | null;
  correction_reason: string;
};

export type FeatureReport = {
  table: Table;
  totals: { entries: number; clients: number; staff: number; underTarget: number };
  options: { clients: { id: string; label: string }[]; staff: { id: string; label: string }[] };
  filterText: string;
};

export async function buildFeatureReport(feature: Feature, allFields: FeatureField[], f: FeatureFilter, timeZone: string): Promise<FeatureReport> {
  const supabase = await createClient();
  let query = supabase
    .from("custom_entries")
    .select("id, data, client_id, client_name, team_names, created_by, created_at, corrected_at, correction_reason")
    .eq("feature_id", feature.id)
    .gte("created_at", `${addDays(f.period.from, -1)}T00:00:00Z`)
    .lt("created_at", `${addDays(f.period.to, 2)}T00:00:00Z`)
    .order("created_at");
  if (f.client) query = query.eq("client_id", f.client);
  if (f.staff) query = query.eq("created_by", f.staff);
  const [{ data }, { data: people }, { data: clientRows }, { data: targetRows }] = await Promise.all([
    query.limit(20000),
    supabase.from("profiles").select("id, full_name, email").order("full_name"),
    supabase.rpc("client_options"),
    supabase.from("custom_client_targets").select("client_id, target").eq("feature_id", feature.id),
  ]);
  const localDate = new Intl.DateTimeFormat("en-CA", { timeZone });
  const entries = ((data ?? []) as Entry[]).filter((e) => {
    const d = localDate.format(new Date(e.created_at));
    return d >= f.period.from && d <= f.period.to;
  });
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const day = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", year: "numeric", timeZone });
  const time = new Intl.DateTimeFormat("en-AU", { hour: "numeric", minute: "2-digit", timeZone });
  const n = (v: number) => v.toLocaleString("en-AU");
  const fields = allFields.filter((x) => !x.archived || entries.some((e) => e.data[x.id] != null));
  const total = allFields.find((x) => x.id === feature.total_field);
  const targets = new Map(((targetRows ?? []) as { client_id: string; target: number }[]).map((t) => [t.client_id, Number(t.target)]));
  const targetFor = (client: string | null) => (client ? targets.get(client) ?? feature.default_target : feature.default_target);

  const show = (x: FeatureField, e: Entry): string => {
    const v = e.data[x.id];
    if (v == null || v === "") return "";
    if (Array.isArray(v)) return v.join(", ");
    if (x.type === "client") return e.client_name || "";
    if (x.type === "staff") return nameOf.get(String(v)) ?? "";
    if (x.type === "number") return `${n(Number(v))}${x.unit ? ` ${x.unit}` : ""}`;
    if (x.type === "photo") return "Photo";
    return String(v);
  };

  let table: Table;
  let underTarget = 0;
  if (f.kind === "daily" && total) {
    const groups = new Map<string, { date: string; client: string | null; name: string; sum: number; count: number }>();
    for (const e of entries) {
      const d = localDate.format(new Date(e.created_at));
      const key = `${d}|${e.client_id ?? ""}`;
      const g = groups.get(key) ?? { date: d, client: e.client_id, name: e.client_name || "No client", sum: 0, count: 0 };
      const v = Number(e.data[total.id]);
      if (Number.isFinite(v)) g.sum += v;
      g.count += 1;
      groups.set(key, g);
    }
    const rows = [...groups.values()].sort((a, b) => b.date.localeCompare(a.date) || a.name.localeCompare(b.name));
    table = {
      columns: [
        { key: "date", label: "Date" },
        { key: "client", label: "Client" },
        { key: "total", label: `Total${total.unit ? ` (${total.unit})` : ""}` },
        { key: "target", label: "Target" },
        { key: "pct", label: "Of target" },
        { key: "count", label: "Entries" },
      ],
      rows: rows.map((g) => {
        const target = targetFor(g.client);
        const pct = target ? Math.round((g.sum / target) * 100) : null;
        if (pct != null && pct < 100) underTarget += 1;
        return {
          id: `${g.date}-${g.client}`,
          href: "",
          cells: {
            date: { text: day.format(new Date(`${g.date}T12:00:00Z`)).replace(",", "") },
            client: { text: g.name },
            total: { text: n(g.sum), num: g.sum },
            target: { text: target ? n(target) : "—", num: target ?? undefined },
            pct: { text: pct == null ? "" : `${pct}%`, num: pct ?? undefined, tone: pct != null && pct < 100 ? "danger" : undefined },
            count: { text: String(g.count), num: g.count },
          } as Record<string, Cell>,
        };
      }),
    };
  } else {
    const sum = total ? entries.reduce((s, e) => s + (Number(e.data[total.id]) || 0), 0) : 0;
    table = {
      columns: [
        { key: "date", label: "Date" },
        { key: "time", label: "Time" },
        ...fields.map((x) => ({ key: x.id, label: `${x.label}${x.unit ? ` (${x.unit})` : ""}`, wide: x.type === "long" })),
        { key: "staff", label: "Staff" },
        ...(feature.record_team ? [{ key: "team", label: "Team" }] : []),
        { key: "note", label: "Notes", wide: true },
      ],
      rows: [
        ...entries.map((e) => ({
          id: String(e.id),
          href: "",
          cells: {
            date: { text: day.format(new Date(e.created_at)).replace(",", "") },
            time: { text: time.format(new Date(e.created_at)).toLowerCase() },
            ...Object.fromEntries(
              fields.map((x) => [x.id, { text: show(x, e), num: x.type === "number" && e.data[x.id] != null ? Number(e.data[x.id]) : undefined } as Cell]),
            ),
            staff: { text: nameOf.get(e.created_by) ?? "Someone" },
            team: { text: e.team_names },
            note: { text: e.corrected_at ? `Fixed by a manager: ${e.correction_reason}` : "", tone: e.corrected_at ? "muted" : undefined },
          } as Record<string, Cell>,
        })),
        ...(entries.length && total
          ? [{ id: "total", href: "", cells: { date: { text: "Total" }, time: { text: `${entries.length} entries` }, [total.id]: { text: `${n(sum)}${total.unit ? ` ${total.unit}` : ""}`, num: sum } } as Record<string, Cell> }]
          : []),
      ],
    };
  }

  const clients = ((clientRows ?? []) as { id: string; name: string }[]).map((c) => ({ id: c.id, label: c.name }));
  const filterText = [
    f.period.label,
    f.client ? `Client: ${clients.find((c) => c.id === f.client)?.label ?? entries[0]?.client_name ?? ""}` : "All clients",
    f.staff ? `Staff: ${nameOf.get(f.staff) ?? ""}` : "",
  ]
    .filter(Boolean)
    .join(" · ");

  return {
    table,
    totals: {
      entries: entries.length,
      clients: new Set(entries.map((e) => e.client_id).filter(Boolean)).size,
      staff: new Set(entries.map((e) => e.created_by)).size,
      underTarget,
    },
    options: {
      clients,
      staff: [...new Set(entries.map((e) => e.created_by)), ...(f.staff ? [f.staff] : [])]
        .filter((v, i, a) => a.indexOf(v) === i)
        .map((id) => ({ id, label: nameOf.get(id) ?? "Someone" }))
        .sort((a, b) => a.label.localeCompare(b.label)),
    },
    filterText,
  };
}

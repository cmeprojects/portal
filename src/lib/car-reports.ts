// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Cell, Table } from "@/lib/register-rows";

// Car reports (cmeprojects): one report at a time, chosen by the manager, for
// one car or all of them, over a period they pick (a week, a month, three
// months, a financial year or their own dates), with optional filters for
// staff, client and purpose.

export type CarReportKind = "mileage" | "log" | "by-car" | "by-staff" | "by-client" | "by-purpose";
export type CarPeriod = { key: string; from: string; to: string; label: string };
export type CarFilter = { kind: CarReportKind; period: CarPeriod; car: string; staff: string; client: string; purpose: string };

export const KIND_LABELS: Record<CarReportKind, string> = {
  mileage: "Mileage tracker",
  log: "Car use log",
  "by-car": "Summary by car",
  "by-staff": "Summary by staff",
  "by-client": "Summary by client",
  "by-purpose": "Summary by purpose",
};
export const KIND_HINTS: Record<CarReportKind, string> = {
  mileage: "Every trip: date, times, staff, start and end odometer, distance, client and purpose.",
  log: "Who took which car, when they took it and returned it, how long it was out, purpose and client.",
  "by-car": "Trips and kilometres for each car, with today's odometer.",
  "by-staff": "Trips and kilometres for each staff member.",
  "by-client": "Trips and kilometres for each client.",
  "by-purpose": "Trips and kilometres for each purpose of use.",
};
export const PERIODS = [
  { key: "this-week", label: "This week" },
  { key: "last-week", label: "Last week" },
  { key: "this-month", label: "This month" },
  { key: "last-month", label: "Last month" },
  { key: "3-months", label: "Last 3 months" },
  { key: "this-fy", label: "This financial year" },
  { key: "last-fy", label: "Last financial year" },
] as const;

// Each person's saved choices (Save as my default).
export const CAR_REPORT_COOKIE = "car_report_view";

const ISO = /^\d{4}-\d{2}-\d{2}$/;
const UUID = /^[0-9a-f-]{36}$/;

function addDays(iso: string, days: number) {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}
function addMonths(iso: string, months: number) {
  const d = new Date(`${iso.slice(0, 8)}01T00:00:00Z`);
  d.setUTCMonth(d.getUTCMonth() + months);
  return d.toISOString().slice(0, 10);
}

// The day after the same date three months ago (30 Oct → 31 Jul), so it's three whole months.
function threeMonthsBack(today: string) {
  const d = new Date(`${today}T00:00:00Z`);
  const day = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() - 3);
  const last = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(day, last));
  return addDays(d.toISOString().slice(0, 10), 1);
}

const nice = (iso: string) =>
  new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

export function periodFor(key: string, today: string, from = "", to = ""): CarPeriod {
  if (ISO.test(from) && ISO.test(to) && from <= to) return { key: "custom", from, to, label: `${nice(from)} to ${nice(to)}` };
  const monday = addDays(today, -((new Date(`${today}T00:00:00Z`).getUTCDay() + 6) % 7));
  const month = `${today.slice(0, 8)}01`;
  // Australian financial year: 1 July to 30 June.
  const year = Number(today.slice(0, 4));
  const fyStart = Number(today.slice(5, 7)) >= 7 ? year : year - 1;
  const ranges: Record<string, [string, string, string]> = {
    "this-week": [monday, today, "This week"],
    "last-week": [addDays(monday, -7), addDays(monday, -1), "Last week"],
    "this-month": [month, today, "This month"],
    "last-month": [addMonths(today, -1), addDays(month, -1), "Last month"],
    "3-months": [threeMonthsBack(today), today, "Last 3 months"],
    "this-fy": [`${fyStart}-07-01`, today, `This financial year (${fyStart}–${String(fyStart + 1).slice(2)})`],
    "last-fy": [`${fyStart - 1}-07-01`, `${fyStart}-06-30`, `Last financial year (${fyStart - 1}–${String(fyStart).slice(2)})`],
  };
  const [f, t, label] = ranges[key] ?? ranges["last-week"];
  return { key: ranges[key] ? key : "last-week", from: f, to: t, label: `${label}: ${nice(f)} to ${nice(t)}` };
}

export function parseCarFilter(params: Record<string, string | string[] | undefined>, today: string): CarFilter {
  const one = (k: string) => (typeof params[k] === "string" ? (params[k] as string).trim().slice(0, 100) : "");
  const kind = one("report") as CarReportKind;
  return {
    kind: kind in KIND_LABELS ? kind : "mileage",
    period: periodFor(one("range"), today, one("from"), one("to")),
    car: UUID.test(one("car")) ? one("car") : "",
    staff: UUID.test(one("staff")) ? one("staff") : "",
    client: one("client"),
    purpose: one("purpose"),
  };
}

// The choices as a link (for Excel, bookmarks and the saved default).
export function carFilterQuery(f: CarFilter, extra: Partial<Record<string, string>> = {}): string {
  const q = new URLSearchParams({ report: f.kind });
  if (f.period.key === "custom") {
    q.set("from", f.period.from);
    q.set("to", f.period.to);
  } else q.set("range", f.period.key);
  if (f.car) q.set("car", f.car);
  if (f.staff) q.set("staff", f.staff);
  if (f.client) q.set("client", f.client);
  if (f.purpose) q.set("purpose", f.purpose);
  for (const [k, v] of Object.entries(extra)) if (v !== undefined) q.set(k, v);
  return q.toString();
}

type Trip = {
  id: number;
  car_id: string;
  driver_id: string;
  purpose: string;
  details: string;
  client_name: string;
  started_at: string;
  start_odo: number;
  gap_km: number;
  returned_at: string | null;
  end_odo: number | null;
  km: number | null;
  returned_by: string | null;
  return_note: string;
  went_to: string;
  corrected_at: string | null;
};

export type CarReport = {
  table: Table;
  totals: { trips: number; km: number; cars: number; gaps: number; out: number };
  options: { cars: { id: string; label: string }[]; staff: { id: string; label: string }[]; clients: string[]; purposes: string[] };
  // In words, for headings, print and Excel.
  filterText: string;
  carDetails: string;
};

export async function buildCarReport(f: CarFilter, timeZone: string): Promise<CarReport> {
  const supabase = await createClient();
  const { period } = f;
  // A day either side, then exact local dates below (the database stores UTC).
  let query = supabase
    .from("car_trips")
    .select("id, car_id, driver_id, purpose, details, client_name, started_at, start_odo, gap_km, returned_at, end_odo, km, returned_by, return_note, went_to, corrected_at")
    .gte("started_at", `${addDays(period.from, -1)}T00:00:00Z`)
    .lt("started_at", `${addDays(period.to, 2)}T00:00:00Z`)
    .order("started_at");
  if (f.car) query = query.eq("car_id", f.car);
  if (f.staff) query = query.eq("driver_id", f.staff);
  if (f.client) query = query.eq("client_name", f.client === "No client" ? "" : f.client);
  if (f.purpose) query = query.eq("purpose", f.purpose);
  const [{ data }, { data: carRows }, { data: people }, { data: purposeRows }, { data: clientRows }] = await Promise.all([
    query.limit(10000),
    supabase.from("cars").select("id, name, rego, car_type, colour, odometer, active").order("name"),
    supabase.from("profiles").select("id, full_name, email, role").neq("role", "system_admin").order("full_name"),
    supabase.from("car_purposes").select("name").order("sort_order"),
    supabase.from("car_trips").select("client_name").neq("client_name", "").limit(5000),
  ]);
  const localDate = new Intl.DateTimeFormat("en-CA", { timeZone });
  const trips = ((data ?? []) as Trip[]).filter((t) => {
    const d = localDate.format(new Date(t.started_at));
    return d >= period.from && d <= period.to;
  });
  const carOf = new Map((carRows ?? []).map((c) => [c.id, c]));
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const day = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", year: "numeric", timeZone });
  const time = new Intl.DateTimeFormat("en-AU", { hour: "numeric", minute: "2-digit", timeZone });
  const dayOf = (iso: string) => day.format(new Date(iso)).replace(",", "");
  const timeOf = (iso: string) => time.format(new Date(iso)).toLowerCase();
  const at = (iso: string | null) => (iso ? `${dayOf(iso)}, ${timeOf(iso)}` : "Still out");
  const n = (v: number | null) => (v == null ? "" : v.toLocaleString("en-AU"));
  const duration = (t: Trip) => {
    if (!t.returned_at) return "";
    const mins = Math.round((new Date(t.returned_at).getTime() - new Date(t.started_at).getTime()) / 60000);
    return `${Math.floor(mins / 60)}h ${String(mins % 60).padStart(2, "0")}m`;
  };
  const car = (id: string) => carOf.get(id)?.name ?? "A car";
  const rego = (id: string) => carOf.get(id)?.rego ?? "";
  const purpose = (t: Trip) => (t.details ? `${t.purpose}: ${t.details}` : t.purpose);
  const staff = (t: Trip) => nameOf.get(t.driver_id) ?? "Someone";
  const totalKm = trips.reduce((s, t) => s + (t.km ?? 0), 0);
  const totalRow = (cells: Record<string, Cell>) => ({ id: "total", href: "", cells });

  let table: Table;
  if (f.kind === "mileage") {
    table = {
      columns: [
        { key: "date", label: "Date" },
        { key: "time", label: "Time" },
        { key: "car", label: "Car" },
        { key: "rego", label: "Rego" },
        { key: "staff", label: "Staff" },
        { key: "start", label: "Start odo" },
        { key: "end", label: "End odo" },
        { key: "km", label: "Distance (km)" },
        { key: "client", label: "Client" },
        { key: "purpose", label: "Purpose", wide: true },
        { key: "where", label: "Where to", wide: true },
        { key: "note", label: "Notes", wide: true },
      ],
      rows: [
        ...trips.map((t) => ({
          id: String(t.id),
          href: "",
          cells: {
            date: { text: dayOf(t.started_at) },
            time: { text: `${timeOf(t.started_at)} – ${t.returned_at ? timeOf(t.returned_at) : "still out"}` },
            car: { text: car(t.car_id) },
            rego: { text: rego(t.car_id) },
            staff: { text: staff(t) },
            start: { text: n(t.start_odo), num: t.start_odo },
            end: { text: t.end_odo == null ? "Still out" : n(t.end_odo), num: t.end_odo ?? undefined, tone: t.end_odo == null ? ("danger" as const) : undefined },
            km: { text: n(t.km), num: t.km ?? undefined },
            client: { text: t.client_name },
            purpose: { text: purpose(t) },
            where: { text: t.went_to },
            note: {
              text: [
                t.gap_km > 0 ? `${n(t.gap_km)} km not logged before this trip` : "",
                t.returned_by && t.returned_by !== t.driver_id ? `Returned by ${nameOf.get(t.returned_by) ?? "a car manager"}: ${t.return_note}` : "",
                t.corrected_at ? "Fixed by a car manager" : "",
              ]
                .filter(Boolean)
                .join(" · "),
              tone: t.gap_km > 0 ? ("danger" as const) : undefined,
            },
          },
        })),
        ...(trips.length ? [totalRow({ date: { text: "Total" }, staff: { text: `${trips.length} trips` }, km: { text: n(totalKm), num: totalKm } })] : []),
      ],
    };
  } else if (f.kind === "log") {
    table = {
      columns: [
        { key: "car", label: "Car" },
        { key: "rego", label: "Rego" },
        { key: "staff", label: "Staff" },
        { key: "out", label: "Taken" },
        { key: "back", label: "Returned" },
        { key: "time", label: "Time out" },
        { key: "purpose", label: "Purpose", wide: true },
        { key: "where", label: "Where to", wide: true },
        { key: "client", label: "Client" },
      ],
      rows: trips.map((t) => ({
        id: String(t.id),
        href: "",
        cells: {
          car: { text: car(t.car_id) },
          rego: { text: rego(t.car_id) },
          staff: { text: staff(t) },
          out: { text: at(t.started_at) },
          back: { text: at(t.returned_at), tone: t.returned_at ? undefined : "danger" },
          time: { text: duration(t) },
          purpose: { text: purpose(t) },
          where: { text: t.went_to },
          client: { text: t.client_name },
        },
      })),
    };
  } else {
    const keyOf: Record<string, (t: Trip) => string> = {
      "by-car": (t) => t.car_id,
      "by-staff": (t) => t.driver_id,
      "by-client": (t) => t.client_name || "No client",
      "by-purpose": (t) => t.purpose,
    };
    const groups = new Map<string, { trips: number; km: number; cars: Set<string>; staff: Set<string> }>();
    for (const t of trips) {
      const k = keyOf[f.kind](t);
      const g = groups.get(k) ?? { trips: 0, km: 0, cars: new Set<string>(), staff: new Set<string>() };
      g.trips += 1;
      g.km += t.km ?? 0;
      g.cars.add(t.car_id);
      g.staff.add(t.driver_id);
      groups.set(k, g);
    }
    const rows = [...groups.entries()].sort((a, b) => b[1].km - a[1].km);
    const label = f.kind === "by-car" ? "Car" : f.kind === "by-staff" ? "Staff" : f.kind === "by-client" ? "Client" : "Purpose";
    table = {
      columns: [
        { key: "name", label },
        ...(f.kind === "by-car"
          ? [
              { key: "rego", label: "Rego" },
              { key: "type", label: "Type" },
            ]
          : []),
        { key: "trips", label: "Trips" },
        { key: "km", label: "Distance (km)" },
        f.kind === "by-car" ? { key: "odo", label: "Odometer now" } : { key: "cars", label: "Cars used" },
        ...(f.kind === "by-client" || f.kind === "by-purpose" ? [{ key: "staff", label: "Staff" }] : []),
      ],
      rows: [
        ...rows.map(([k, g]) => {
          const c = carOf.get(k);
          return {
            id: k,
            href: "",
            cells: {
              name: { text: f.kind === "by-car" ? c?.name ?? "A car" : f.kind === "by-staff" ? nameOf.get(k) ?? "Someone" : k },
              rego: { text: c?.rego ?? "" },
              type: { text: c?.car_type ?? "" },
              trips: { text: String(g.trips), num: g.trips },
              km: { text: n(g.km), num: g.km },
              odo: { text: n(c?.odometer ?? null), num: c?.odometer },
              cars: { text: String(g.cars.size), num: g.cars.size },
              staff: { text: String(g.staff.size), num: g.staff.size },
            } as Record<string, Cell>,
          };
        }),
        ...(rows.length ? [totalRow({ name: { text: "Total" }, trips: { text: String(trips.length), num: trips.length }, km: { text: n(totalKm), num: totalKm } })] : []),
      ],
    };
  }

  const chosenCar = f.car ? carOf.get(f.car) : null;
  const filterText = [
    period.label,
    chosenCar ? `${chosenCar.name} (${chosenCar.rego})` : "All cars",
    f.staff ? nameOf.get(f.staff) ?? "" : "",
    f.client ? `Client: ${f.client}` : "",
    f.purpose ? `Purpose: ${f.purpose}` : "",
  ]
    .filter(Boolean)
    .join(" · ");
  const carDetails = chosenCar
    ? [chosenCar.name, chosenCar.rego, chosenCar.car_type, chosenCar.colour, `odometer now ${n(chosenCar.odometer)} km`].filter(Boolean).join(" · ")
    : "";

  return {
    table,
    totals: {
      trips: trips.length,
      km: totalKm,
      cars: new Set(trips.map((t) => t.car_id)).size,
      gaps: trips.filter((t) => t.gap_km > 0).length,
      out: trips.filter((t) => !t.returned_at).length,
    },
    options: {
      cars: (carRows ?? []).map((c) => ({ id: c.id, label: `${c.name} · ${c.rego}${c.active ? "" : " (retired)"}` })),
      staff: (people ?? []).map((p) => ({ id: p.id, label: p.full_name || p.email })),
      clients: [...new Set(((clientRows ?? []) as { client_name: string }[]).map((c) => c.client_name))].sort((a, b) => a.localeCompare(b)),
      purposes: [...new Set((purposeRows ?? []).map((p) => p.name))],
    },
    filterText,
    carDetails,
  };
}

// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Table } from "@/lib/register-rows";

// Car reports (cmeprojects): the car use log and mileage for a date range,
// with summaries by car, by staff member and by client.

export type CarPeriod = { key: string; from: string; to: string; label: string };

const ISO = /^\d{4}-\d{2}-\d{2}$/;

function addDays(iso: string, days: number) {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

const nice = (iso: string) =>
  new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

// Default: last week, Monday to Sunday (what the Monday report covers).
export function parseCarPeriod(params: Record<string, string | string[] | undefined>, today: string): CarPeriod {
  const monday = addDays(today, -((new Date(`${today}T00:00:00Z`).getUTCDay() + 6) % 7));
  const from = typeof params.from === "string" && ISO.test(params.from) ? params.from : "";
  const to = typeof params.to === "string" && ISO.test(params.to) ? params.to : "";
  if (from && to && from <= to) return { key: "custom", from, to, label: `${nice(from)} to ${nice(to)}` };
  if (params.range === "this-week") return { key: "this-week", from: monday, to: today, label: `This week (${nice(monday)} to ${nice(today)})` };
  if (params.range === "month") {
    const first = `${today.slice(0, 8)}01`;
    return { key: "month", from: first, to: today, label: `This month (${nice(first)} to ${nice(today)})` };
  }
  const lastMon = addDays(monday, -7);
  const lastSun = addDays(monday, -1);
  return { key: "last-week", from: lastMon, to: lastSun, label: `Last week (${nice(lastMon)} to ${nice(lastSun)})` };
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
  corrected_at: string | null;
};

export type CarReport = {
  totals: { trips: number; km: number; cars: number; gaps: number; out: number };
  cars: { id: string; name: string; rego: string; car_type: string; colour: string; odometer: number; trips: number; km: number }[];
  mileage: Table;
  log: Table;
  byCar: Table;
  byDriver: Table;
  byClient: Table;
};

export async function buildCarReport(period: CarPeriod, timeZone: string, carId = ""): Promise<CarReport> {
  const supabase = await createClient();
  // A day either side, then exact local dates below (the database stores UTC).
  let query = supabase
    .from("car_trips")
    .select("id, car_id, driver_id, purpose, details, client_name, started_at, start_odo, gap_km, returned_at, end_odo, km, returned_by, return_note, corrected_at")
    .gte("started_at", `${addDays(period.from, -1)}T00:00:00Z`)
    .lt("started_at", `${addDays(period.to, 2)}T00:00:00Z`)
    .order("started_at");
  if (carId) query = query.eq("car_id", carId);
  const [{ data }, { data: carRows }, { data: people }] = await Promise.all([
    query.limit(5000),
    supabase.from("cars").select("id, name, rego, car_type, colour, odometer").order("name"),
    supabase.from("profiles").select("id, full_name, email"),
  ]);
  const localDate = new Intl.DateTimeFormat("en-CA", { timeZone });
  const trips = ((data ?? []) as Trip[]).filter((t) => {
    const d = localDate.format(new Date(t.started_at));
    return d >= period.from && d <= period.to;
  });
  const carOf = new Map((carRows ?? []).map((c) => [c.id, c]));
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const day = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", timeZone });
  const time = new Intl.DateTimeFormat("en-AU", { hour: "numeric", minute: "2-digit", timeZone });
  const at = (iso: string | null) => (iso ? `${day.format(new Date(iso)).replace(",", "")} ${time.format(new Date(iso)).toLowerCase()}` : "Still out");
  const n = (v: number | null) => (v == null ? "" : v.toLocaleString("en-AU"));
  const duration = (t: Trip) => {
    if (!t.returned_at) return "";
    const mins = Math.round((new Date(t.returned_at).getTime() - new Date(t.started_at).getTime()) / 60000);
    return `${Math.floor(mins / 60)}h ${String(mins % 60).padStart(2, "0")}m`;
  };
  const carLabel = (id: string) => carOf.get(id)?.name ?? "A car";
  const rego = (id: string) => carOf.get(id)?.rego ?? "";
  const purpose = (t: Trip) => (t.details ? `${t.purpose}: ${t.details}` : t.purpose);

  const mileage: Table = {
    columns: [
      { key: "date", label: "Date" },
      { key: "car", label: "Car" },
      { key: "rego", label: "Rego" },
      { key: "driver", label: "Staff" },
      { key: "purpose", label: "Purpose", wide: true },
      { key: "client", label: "Client" },
      { key: "start", label: "Start odo" },
      { key: "end", label: "End odo" },
      { key: "km", label: "km" },
      { key: "note", label: "Notes", wide: true },
    ],
    rows: trips.map((t) => ({
      id: String(t.id),
      href: "",
      cells: {
        date: { text: day.format(new Date(t.started_at)).replace(",", "") },
        car: { text: carLabel(t.car_id) },
        rego: { text: rego(t.car_id) },
        driver: { text: nameOf.get(t.driver_id) ?? "" },
        purpose: { text: purpose(t) },
        client: { text: t.client_name },
        start: { text: n(t.start_odo), num: t.start_odo },
        end: { text: t.end_odo == null ? "Still out" : n(t.end_odo), num: t.end_odo ?? undefined, tone: t.end_odo == null ? "danger" : undefined },
        km: { text: n(t.km), num: t.km ?? undefined },
        note: {
          text: [
            t.gap_km > 0 ? `${n(t.gap_km)} km not logged before this trip` : "",
            t.returned_by && t.returned_by !== t.driver_id ? `Returned by ${nameOf.get(t.returned_by) ?? "a car manager"}: ${t.return_note}` : "",
            t.corrected_at ? "Fixed by a car manager" : "",
          ]
            .filter(Boolean)
            .join(" · "),
          tone: t.gap_km > 0 ? "danger" : undefined,
        },
      },
    })),
  };

  const log: Table = {
    columns: [
      { key: "car", label: "Car" },
      { key: "rego", label: "Rego" },
      { key: "driver", label: "Staff" },
      { key: "purpose", label: "Purpose", wide: true },
      { key: "client", label: "Client" },
      { key: "out", label: "Taken" },
      { key: "back", label: "Returned" },
      { key: "time", label: "Time out" },
    ],
    rows: trips.map((t) => ({
      id: String(t.id),
      href: "",
      cells: {
        car: { text: carLabel(t.car_id) },
        rego: { text: rego(t.car_id) },
        driver: { text: nameOf.get(t.driver_id) ?? "" },
        purpose: { text: purpose(t) },
        client: { text: t.client_name },
        out: { text: at(t.started_at) },
        back: { text: at(t.returned_at), tone: t.returned_at ? undefined : "danger" },
        time: { text: duration(t) },
      },
    })),
  };

  const group = (key: (t: Trip) => string) => {
    const m = new Map<string, { trips: number; km: number }>();
    for (const t of trips) {
      const k = key(t);
      const g = m.get(k) ?? { trips: 0, km: 0 };
      g.trips += 1;
      g.km += t.km ?? 0;
      m.set(k, g);
    }
    return [...m.entries()].sort((a, b) => b[1].km - a[1].km);
  };
  const summary = (label: string, rows: [string, { trips: number; km: number }][]): Table => ({
    columns: [
      { key: "name", label },
      { key: "trips", label: "Trips" },
      { key: "km", label: "km" },
    ],
    rows: rows.map(([name, g]) => ({
      id: name,
      href: "",
      cells: { name: { text: name }, trips: { text: String(g.trips), num: g.trips }, km: { text: n(g.km), num: g.km } },
    })),
  });

  const usedCars = group((t) => t.car_id);
  const cars = usedCars.map(([id, g]) => {
    const c = carOf.get(id);
    return { id, name: c?.name ?? "A car", rego: c?.rego ?? "", car_type: c?.car_type ?? "", colour: c?.colour ?? "", odometer: c?.odometer ?? 0, ...g };
  });
  const byCar: Table = {
    columns: [
      { key: "name", label: "Car" },
      { key: "rego", label: "Rego" },
      { key: "type", label: "Type" },
      { key: "trips", label: "Trips" },
      { key: "km", label: "km" },
      { key: "odo", label: "Odometer now" },
    ],
    rows: cars.map((c) => ({
      id: c.id,
      href: "",
      cells: {
        name: { text: c.name },
        rego: { text: c.rego },
        type: { text: c.car_type },
        trips: { text: String(c.trips), num: c.trips },
        km: { text: n(c.km), num: c.km },
        odo: { text: n(c.odometer), num: c.odometer },
      },
    })),
  };

  return {
    totals: {
      trips: trips.length,
      km: trips.reduce((s, t) => s + (t.km ?? 0), 0),
      cars: usedCars.length,
      gaps: trips.filter((t) => t.gap_km > 0).length,
      out: trips.filter((t) => !t.returned_at).length,
    },
    cars,
    mileage,
    log,
    byCar,
    byDriver: summary("Staff", group((t) => nameOf.get(t.driver_id) ?? "Someone")),
    byClient: summary("Client", group((t) => t.client_name || "No client")),
  };
}

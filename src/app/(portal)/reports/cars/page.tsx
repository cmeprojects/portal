// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canSeeCarReports, canUseCars, getCarRules } from "@/lib/cars";
import { buildCarReport, parseCarPeriod } from "@/lib/car-reports";
import { getTimeZone } from "@/lib/settings";
import { getBranding } from "@/lib/branding";
import { todayIn } from "@/lib/tasks";
import { createClient } from "@/lib/supabase/server";
import { km } from "@/lib/car-types";
import { Card, PageHeader, Tabs, buttonClass, inputClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";

export const metadata: Metadata = { title: "Car reports" };

const RANGES = [
  { key: "last-week", label: "Last week" },
  { key: "this-week", label: "This week" },
  { key: "month", label: "This month" },
];

export default async function CarReportsPage({ searchParams }: PageProps<"/reports/cars">) {
  const { profile, features } = await requireSession();
  if (!canUseCars(profile.role, features) || !canSeeCarReports(profile.role, await getCarRules())) redirect("/cars");
  const [timeZone, brand, params] = await Promise.all([getTimeZone(), getBranding(), searchParams]);
  const period = parseCarPeriod(params, todayIn(timeZone));
  const view = params.view === "log" ? "log" : "mileage";
  const carId = typeof params.car === "string" ? params.car : "";
  const supabase = await createClient();
  const [{ data: allCars }, report] = await Promise.all([
    supabase.from("cars").select("id, name, rego").order("name"),
    buildCarReport(period, timeZone, carId),
  ]);
  const qs = new URLSearchParams({ ...(period.key === "custom" ? { from: period.from, to: period.to } : { range: period.key }), ...(carId ? { car: carId } : {}) });
  const link = (extra: Record<string, string>) => `/reports/cars?${new URLSearchParams({ ...Object.fromEntries(qs), ...extra })}`;
  const printedAt = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());

  return (
    <>
      <PrintHeader brand={brand} title={view === "log" ? "Car use log" : "Mileage report"} subtitle={period.label} printedAt={printedAt} />
      <PageHeader
        eyebrow="Reports"
        title="Car reports"
        intro={`${period.label}. Car managers get last week's report every Monday morning.`}
        action={
          <div className="flex flex-wrap gap-2 print:hidden">
            <a href={`/reports/cars/export?${qs}`} className={buttonClass("primary")}>
              Download Excel
            </a>
            <PrintButton label="Print or save as PDF" />
          </div>
        }
      />

      <div className="flex flex-col gap-3 print:hidden">
        <Tabs label="Period" items={RANGES.map((r) => ({ href: `/reports/cars?range=${r.key}${carId ? `&car=${carId}` : ""}&view=${view}`, text: r.label, current: period.key === r.key }))} />
        <form className="flex flex-wrap items-end gap-2">
          <input type="hidden" name="view" value={view} />
          <label className="flex flex-col gap-1 text-sm">
            <span className="font-semibold">From</span>
            <input type="date" name="from" defaultValue={period.from} required className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-sm">
            <span className="font-semibold">To</span>
            <input type="date" name="to" defaultValue={period.to} required className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-sm">
            <span className="font-semibold">Car</span>
            <select name="car" defaultValue={carId} className={inputClass}>
              <option value="">All cars</option>
              {(allCars ?? []).map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} · {c.rego}
                </option>
              ))}
            </select>
          </label>
          <button className={buttonClass("outline", "h-11")}>Show</button>
        </form>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[
          { label: "Trips", n: String(report.totals.trips), tone: "text-brand" },
          { label: "Total distance", n: km(report.totals.km), tone: "text-brand" },
          { label: "Cars used", n: String(report.totals.cars), tone: "text-brand" },
          { label: "Gaps in the readings", n: String(report.totals.gaps), tone: report.totals.gaps ? "text-danger" : "text-muted" },
        ].map((s) => (
          <Card key={s.label} className="p-4">
            <p className={`heading ${s.tone} tabular-nums`}>{s.n}</p>
            <p className="text-sm text-muted">{s.label}</p>
          </Card>
        ))}
      </div>

      <Tabs
        label="Report"
        items={[
          { href: link({ view: "mileage" }), text: "Mileage", current: view === "mileage" },
          { href: link({ view: "log" }), text: "Car use log", current: view === "log" },
        ]}
      />

      {view === "mileage" ? (
        <>
          <Card className="overflow-hidden">
            <div className="border-b border-line px-5 py-3">
              <h2 className="heading-sm">Summary by car</h2>
            </div>
            <DataTable table={report.byCar} empty="No trips in these dates." />
          </Card>
          <div className="grid items-start gap-4 md:grid-cols-2">
            <Card className="overflow-hidden">
              <h2 className="heading-sm border-b border-line px-5 py-3">By staff member</h2>
              <DataTable table={report.byDriver} empty="No trips." />
            </Card>
            <Card className="overflow-hidden">
              <h2 className="heading-sm border-b border-line px-5 py-3">By client</h2>
              <DataTable table={report.byClient} empty="No trips." />
            </Card>
          </div>
          <Card className="overflow-hidden">
            <div className="border-b border-line px-5 py-3">
              <h2 className="heading-sm">Every trip</h2>
              <p className="text-sm text-muted">Start and end readings, with any gap since the car&apos;s last return flagged.</p>
            </div>
            <DataTable table={report.mileage} empty="No trips in these dates." />
          </Card>
        </>
      ) : (
        <Card className="overflow-hidden">
          <div className="border-b border-line px-5 py-3">
            <h2 className="heading-sm">Car use log</h2>
            <p className="text-sm text-muted">Who took which car, when, for what, and when it came back.</p>
          </div>
          <DataTable table={report.log} empty="No trips in these dates." />
        </Card>
      )}
      <p className="text-sm text-muted print:hidden">
        Need to fix a trip? <Link href="/cars/manage?tab=trips" className="font-semibold text-brand underline">Manage cars → Fix a trip</Link>
      </p>
    </>
  );
}

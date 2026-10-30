// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { canSeeCarReports, canUseCars, getCarRules } from "@/lib/cars";
import { CAR_REPORT_COOKIE, KIND_HINTS, KIND_LABELS, PERIODS, buildCarReport, carFilterQuery, parseCarFilter, type CarReportKind } from "@/lib/car-reports";
import { getTimeZone } from "@/lib/settings";
import { getBranding } from "@/lib/branding";
import { todayIn } from "@/lib/tasks";
import { km } from "@/lib/car-types";
import { Card, Notice, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";
import { SectionTabs } from "@/components/section-tabs";
import { PrintLandscape } from "@/components/print-landscape";
import { clearCarReportView, saveCarReportView } from "./actions";

export const metadata: Metadata = { title: "Car reports" };

const KINDS = Object.keys(KIND_LABELS) as CarReportKind[];

export default async function CarReportsPage({ searchParams }: PageProps<"/reports/cars">) {
  const { profile, features } = await requireSession();
  if (!canUseCars(profile.role, features) || !canSeeCarReports(profile.role, await getCarRules())) redirect("/cars");
  const params = await searchParams;
  // No choices in the address: open their saved report, if they have one.
  const saved = (await cookies()).get(CAR_REPORT_COOKIE)?.value;
  if (!Object.keys(params).length && saved) redirect(`/reports/cars?${saved}`);
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const f = parseCarFilter(params, todayIn(timeZone));
  const report = await buildCarReport(f, timeZone);
  const qs = carFilterQuery(f);
  const printedAt = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const field = "flex flex-col gap-1 text-sm";

  return (
    <>
      <PrintLandscape />
      <PrintHeader brand={brand} title={KIND_LABELS[f.kind]} subtitle={report.filterText} printedAt={printedAt} />
      <SectionTabs section="reports" current="/reports/cars" />
      <div className="print:hidden">
      <PageHeader
        title="Car reports"
        intro="Choose a report, a car (or all of them) and the dates, then show it, download it or print it."
        action={
          <div className="flex flex-wrap gap-2 print:hidden">
            <a href={`/reports/cars/export?${qs}`} className={buttonClass("primary")}>
              Download Excel
            </a>
            <PrintButton label="Print or save as PDF" />
          </div>
        }
      />
      </div>
      {params.saved ? <Notice tone="success">Saved. Car reports opens like this for you next time.</Notice> : null}

      <details className="group rounded-lg border border-line bg-surface print:hidden" open={!Object.keys(params).length}>
        <summary className="flex min-h-14 cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1 px-4 py-3">
          <span className="min-w-0 flex-1 text-sm">
            <span className="font-semibold">{KIND_LABELS[f.kind]}</span>
            <span className="text-muted"> · {report.filterText}</span>
          </span>
          <span className="group-open:hidden">
            <span className={buttonClass("outline")}>Change report ▾</span>
          </span>
          <span className="hidden group-open:inline">
            <span className={buttonClass("outline")}>Close ▴</span>
          </span>
        </summary>
        <div className="border-t border-line p-4">
        <form className="flex flex-col gap-4">
          <fieldset className="flex flex-col gap-2">
            <legend className="mb-1 text-sm font-semibold">Report</legend>
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              {KINDS.map((k) => (
                <label key={k} className="flex cursor-pointer items-start gap-3 rounded-md border border-line px-3 py-2 has-[:checked]:border-brand has-[:checked]:bg-brand-soft">
                  <input type="radio" name="report" value={k} defaultChecked={f.kind === k} className="mt-1 h-4 w-4 shrink-0 accent-[var(--brand-primary)]" />
                  <span>
                    <span className="block text-sm font-semibold">{KIND_LABELS[k]}</span>
                    <span className="block text-xs text-muted">{KIND_HINTS[k]}</span>
                  </span>
                </label>
              ))}
            </div>
          </fieldset>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <label className={field}>
              <span className="font-semibold">Period</span>
              <select name="range" defaultValue={f.period.key === "custom" ? "" : f.period.key} className={inputClass}>
                {PERIODS.map((p) => (
                  <option key={p.key} value={p.key}>
                    {p.label}
                  </option>
                ))}
                <option value="">Choose dates below</option>
              </select>
            </label>
            <label className={field}>
              <span className="font-semibold">Car</span>
              <select name="car" defaultValue={f.car} className={inputClass}>
                <option value="">All cars</option>
                {report.options.cars.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.label}
                  </option>
                ))}
              </select>
            </label>
            <label className={field}>
              <span className="font-semibold">Staff</span>
              <select name="staff" defaultValue={f.staff} className={inputClass}>
                <option value="">All staff</option>
                {report.options.staff.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.label}
                  </option>
                ))}
              </select>
            </label>
            <label className={field}>
              <span className="font-semibold">Client</span>
              <select name="client" defaultValue={f.client} className={inputClass}>
                <option value="">All clients</option>
                <option value="No client">No client</option>
                {report.options.clients.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </label>
            <label className={field}>
              <span className="font-semibold">Purpose</span>
              <select name="purpose" defaultValue={f.purpose} className={inputClass}>
                <option value="">All purposes</option>
                {report.options.purposes.map((p) => (
                  <option key={p} value={p}>
                    {p}
                  </option>
                ))}
              </select>
            </label>
            <label className={field}>
              <span className="font-semibold">From (your own dates)</span>
              <input type="date" name="from" defaultValue={f.period.key === "custom" ? f.period.from : ""} className={inputClass} />
            </label>
            <label className={field}>
              <span className="font-semibold">To</span>
              <input type="date" name="to" defaultValue={f.period.key === "custom" ? f.period.to : ""} className={inputClass} />
            </label>
            <div className="flex items-end">
              <button className={buttonClass("primary", "h-11 w-full")}>Show report</button>
            </div>
          </div>
          <p className="text-xs text-muted">Fill in both dates to use your own dates instead of the period.</p>
        </form>
        <div className="mt-3 flex flex-wrap items-center gap-3 border-t border-line pt-3 text-sm">
          <form action={saveCarReportView}>
            <input type="hidden" name="query" value={qs} />
            <button className="font-semibold text-brand underline">Save as my default</button>
          </form>
          {saved ? (
            <form action={clearCarReportView}>
              <button className="text-muted underline">Forget my default</button>
            </form>
          ) : null}
        </div>
        </div>
      </details>

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

      <Card className="overflow-hidden">
        <div className="border-b border-line px-5 py-3">
          <h2 className="heading-sm">{KIND_LABELS[f.kind]}</h2>
          <p className="text-sm text-muted">{report.filterText}</p>
          {report.carDetails ? <p className="text-sm">{report.carDetails}</p> : null}
        </div>
        <DataTable table={report.table} empty="No trips match these choices." />
      </Card>
      <p className="text-sm text-muted print:hidden">
        Need to fix a trip?{" "}
        <Link href="/cars/manage?tab=trips" className="font-semibold text-brand underline">
          Manage cars → Fix a trip
        </Link>
      </p>
    </>
  );
}

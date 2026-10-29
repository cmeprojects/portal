// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { canManageCompliance, canSeeReports, getPeopleRules, getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { buildReports, parsePeriod } from "@/lib/reports";
import { Card, PageHeader, Tabs, buttonClass, inputClass } from "@/components/ui";
import Link from "next/link";
import { canSeeCarReports, canUseCars, getCarRules } from "@/lib/cars";
import { DataTable } from "@/components/data-table";

export const metadata: Metadata = { title: "Reports" };

const RANGES = [
  { key: "month", label: "This month" },
  { key: "3m", label: "Last 3 months" },
  { key: "12m", label: "Last 12 months" },
];

export default async function ReportsPage({ searchParams }: PageProps<"/reports">) {
  const { profile, features } = await requireTaskAccess();
  const rules = await getPeopleRules();
  if (!canSeeReports(profile.role, rules) || features.reports === false) redirect("/");
  const timeZone = await getTimeZone();
  const today = todayIn(timeZone);
  const params = await searchParams;
  const period = parsePeriod(params, today);
  const withCompliance = canManageCompliance(profile.role, rules) || profile.role === "manager";
  const { summary, months, tables } = await buildReports(period, today, timeZone, withCompliance);
  const qs = period.key === "custom" ? `from=${period.from}&to=${period.to}` : `range=${period.key}`;
  const max = Math.max(1, ...months.flatMap((m) => [m.opened, m.completed]));
  const carReports = canUseCars(profile.role, features) && canSeeCarReports(profile.role, await getCarRules());

  return (
    <>
      <PageHeader
        title="Reports"
        intro={`${period.label}${profile.role === "team_leader" ? " · your team's tasks" : ""}. Download any table as an Excel file.`}
        action={
          carReports ? (
            <Link href="/reports/cars" className={buttonClass("outline", "print:hidden")}>
              Car reports
            </Link>
          ) : undefined
        }
      />
      <div className="flex flex-col gap-3 print:hidden">
        <Tabs label="Period" items={RANGES.map((r) => ({ href: `/reports?range=${r.key}`, text: r.label, current: period.key === r.key }))} />
        <form className="flex flex-wrap items-end gap-2">
          <label className="flex flex-col gap-1 text-sm">
            <span className="font-semibold">From</span>
            <input type="date" name="from" defaultValue={period.key === "custom" ? period.from : ""} required className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-sm">
            <span className="font-semibold">To</span>
            <input type="date" name="to" defaultValue={period.key === "custom" ? period.to : ""} required className={inputClass} />
          </label>
          <button className={buttonClass("outline", "h-12")}>Show these dates</button>
        </form>
      </div>

      <div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
        {[
          { label: "Opened", n: summary.opened, tone: "text-brand" },
          { label: "Completed", n: summary.completed, tone: "text-good" },
          { label: "Completed on time", n: summary.onTime, tone: "text-good" },
          { label: "Open now", n: summary.open, tone: "text-brand" },
          { label: "Overdue now", n: summary.overdue, tone: "text-danger" },
          { label: "Escalated now", n: summary.escalated, tone: "text-danger" },
        ].map((s) => (
          <Card key={s.label} className="p-4">
            <p className={`heading ${s.tone}`}>{s.n}</p>
            <p className="text-sm text-muted">{s.label}</p>
          </Card>
        ))}
      </div>

      <Card className="flex flex-col gap-4 p-5">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="heading-sm">Opened and completed by month</h2>
          <p className="flex gap-4 text-xs text-muted">
            <span className="flex items-center gap-1.5"><span className="h-3 w-3 rounded-sm bg-brand" aria-hidden="true" /> Opened</span>
            <span className="flex items-center gap-1.5"><span className="h-3 w-3 rounded-sm bg-good" aria-hidden="true" /> Completed</span>
          </p>
        </div>
        <div className="flex h-48 items-end gap-3 overflow-x-auto pb-1" role="img" aria-label={months.map((m) => `${m.label}: ${m.opened} opened, ${m.completed} completed`).join("; ")}>
          {months.map((m) => (
            <div key={m.label} className="flex min-w-12 flex-1 flex-col items-center gap-1">
              <div className="flex h-40 w-full items-end justify-center gap-1">
                <div className="flex w-1/2 max-w-6 flex-col items-center justify-end gap-0.5">
                  <span className="text-[11px] tabular-nums text-muted">{m.opened || ""}</span>
                  <div className="w-full rounded-t-sm bg-brand" style={{ height: `${(m.opened / max) * 128}px` }} />
                </div>
                <div className="flex w-1/2 max-w-6 flex-col items-center justify-end gap-0.5">
                  <span className="text-[11px] tabular-nums text-muted">{m.completed || ""}</span>
                  <div className="w-full rounded-t-sm bg-good" style={{ height: `${(m.completed / max) * 128}px` }} />
                </div>
              </div>
              <span className="text-xs text-muted">{m.label}</span>
            </div>
          ))}
        </div>
      </Card>

      {tables.map((t) => (
        <Card key={t.key} className="overflow-hidden">
          <div className="flex flex-wrap items-center justify-between gap-2 border-b border-line px-5 py-3">
            <div>
              <h2 className="heading-sm">{t.title}</h2>
              <p className="text-sm text-muted">{t.intro}</p>
            </div>
            <a href={`/reports/export?section=${t.key}&${qs}`} className={buttonClass("outline", "print:hidden")}>
              Download Excel
            </a>
          </div>
          <DataTable table={t.table} empty="Nothing to show for this period." />
        </Card>
      ))}
    </>
  );
}

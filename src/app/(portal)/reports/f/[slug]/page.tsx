// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { loadFeature } from "@/lib/custom-features";
import { FEATURE_KIND_HINTS, FEATURE_KIND_LABELS, FEATURE_PERIODS, buildFeatureReport, featureFilterQuery, parseFeatureFilter, type FeatureReportKind } from "@/lib/feature-reports";
import { getTimeZone } from "@/lib/settings";
import { getBranding } from "@/lib/branding";
import { todayIn } from "@/lib/tasks";
import { Card, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";
import { PrintLandscape } from "@/components/print-landscape";
import { SectionTabs } from "@/components/section-tabs";
import { LiveRefresh } from "@/components/live-refresh";

export async function generateMetadata({ params }: PageProps<"/reports/f/[slug]">): Promise<Metadata> {
  const def = await loadFeature({ slug: (await params).slug });
  return { title: def ? `${def.feature.name} report` : "Not found" };
}

// cmeprojects: the report for a feature built in the Feature builder, for
// whoever the system admin ticked under "Who sees every entry".
export default async function FeatureReportPage({ params, searchParams }: PageProps<"/reports/f/[slug]">) {
  await requireSession();
  const def = await loadFeature({ slug: (await params).slug });
  if (!def || def.feature.status !== "published" || !def.feature.enabled) notFound();
  const { feature, fields } = def;
  const supabase = await createClient();
  const { data: allowed } = await supabase.rpc("can_see_feature", { p_feature: feature.id });
  if (!allowed) notFound();
  const query = await searchParams;
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const hasTotals = Boolean(feature.total_field && feature.group_field);
  const f = parseFeatureFilter(query, todayIn(timeZone), hasTotals);
  const report = await buildFeatureReport(feature, fields, f, timeZone);
  const qs = featureFilterQuery(f);
  const kinds: FeatureReportKind[] = hasTotals ? ["entries", "daily"] : ["entries"];
  const printedAt = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const title = `${feature.name}: ${FEATURE_KIND_LABELS[f.kind]}`;
  const field = "flex flex-col gap-1 text-sm";

  return (
    <>
      <LiveRefresh tables={["custom_entries"]} />
      <PrintLandscape />
      <PrintHeader brand={brand} title={title} subtitle={report.filterText} printedAt={printedAt} />
      <SectionTabs section="reports" current={`/reports/f/${feature.slug}`} />
      <div className="print:hidden">
        <PageHeader
          title={`${feature.name} report`}
          intro="Choose the report, the dates and a client or staff member, then show it, download it or print it."
          action={
            <div className="flex flex-wrap gap-2">
              <a href={`/reports/f/${feature.slug}/export?${qs}`} className={buttonClass("primary")}>
                Download Excel
              </a>
              <PrintButton label="Print or save as PDF" />
            </div>
          }
        />
      </div>

      <details className="group rounded-lg border border-line bg-surface print:hidden">
        <summary className="flex min-h-14 cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1 px-4 py-3">
          <span className="min-w-0 flex-1 text-sm">
            <span className="font-semibold">{FEATURE_KIND_LABELS[f.kind]}</span>
            <span className="text-muted"> · {report.filterText}</span>
          </span>
          <span className="group-open:hidden">
            <span className={buttonClass("outline")}>Change report ▾</span>
          </span>
          <span className="hidden group-open:inline">
            <span className={buttonClass("outline")}>Close ▴</span>
          </span>
        </summary>
        <form className="flex flex-col gap-4 border-t border-line p-4">
          {kinds.length > 1 ? (
            <fieldset className="grid gap-2 sm:grid-cols-2">
              <legend className="mb-1 text-sm font-semibold">Report</legend>
              {kinds.map((k) => (
                <label key={k} className="flex cursor-pointer items-start gap-3 rounded-md border border-line px-3 py-2 has-[:checked]:border-brand has-[:checked]:bg-brand-soft">
                  <input type="radio" name="report" value={k} defaultChecked={f.kind === k} className="mt-1 h-4 w-4 shrink-0 accent-[var(--brand-primary)]" />
                  <span>
                    <span className="block text-sm font-semibold">{FEATURE_KIND_LABELS[k]}</span>
                    <span className="block text-xs text-muted">{FEATURE_KIND_HINTS[k]}</span>
                  </span>
                </label>
              ))}
            </fieldset>
          ) : null}
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <label className={field}>
              <span className="font-semibold">Period</span>
              <select name="range" defaultValue={f.period.key === "custom" ? "" : f.period.key} className={inputClass}>
                {FEATURE_PERIODS.map((p) => (
                  <option key={p.key} value={p.key}>
                    {p.label}
                  </option>
                ))}
                <option value="">Choose dates below</option>
              </select>
            </label>
            <label className={field}>
              <span className="font-semibold">Client</span>
              <select name="client" defaultValue={f.client} className={inputClass}>
                <option value="">All clients</option>
                {report.options.clients.map((c) => (
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
            <div className="flex items-end">
              <button className={buttonClass("primary", "h-11 w-full")}>Show report</button>
            </div>
            <label className={field}>
              <span className="font-semibold">From (your own dates)</span>
              <input type="date" name="from" defaultValue={f.period.key === "custom" ? f.period.from : ""} className={inputClass} />
            </label>
            <label className={field}>
              <span className="font-semibold">To</span>
              <input type="date" name="to" defaultValue={f.period.key === "custom" ? f.period.to : ""} className={inputClass} />
            </label>
          </div>
          <p className="text-xs text-muted">Fill in both dates to use your own dates instead of the period.</p>
        </form>
      </details>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[
          { label: "Entries", n: String(report.totals.entries), tone: "text-brand" },
          { label: "Clients", n: String(report.totals.clients), tone: "text-brand" },
          { label: "Staff who entered", n: String(report.totals.staff), tone: "text-brand" },
          ...(f.kind === "daily" ? [{ label: "Days under target", n: String(report.totals.underTarget), tone: report.totals.underTarget ? "text-danger" : "text-muted" }] : []),
        ].map((s) => (
          <Card key={s.label} className="p-4">
            <p className={`heading ${s.tone} tabular-nums`}>{s.n}</p>
            <p className="text-sm text-muted">{s.label}</p>
          </Card>
        ))}
      </div>

      <Card className="overflow-hidden">
        <div className="border-b border-line px-5 py-3">
          <h2 className="heading-sm">{title}</h2>
          <p className="text-sm text-muted">{report.filterText}</p>
        </div>
        <DataTable table={report.table} empty="No entries match these choices." />
      </Card>
      <p className="text-sm text-muted print:hidden">
        Need to fix an entry?{" "}
        <Link href={`/f/${feature.slug}/manage`} className="font-semibold text-brand underline">
          {feature.name} → Manage
        </Link>{" "}
        (if the system admin allows it).
      </p>
    </>
  );
}

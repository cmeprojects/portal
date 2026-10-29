// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canSeeComplianceReport, getPeopleRules, getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { getBranding } from "@/lib/branding";
import { ROLES, ROLE_LABELS } from "@/lib/roles";
import { KIND_TAB, type ItemKind } from "@/lib/compliance";
import { DEFAULT_COOKIE, SHOW_LABELS, VIEW_LABELS, buildComplianceReport, filterQuery, parseComplianceFilter, type ComplianceView } from "@/lib/compliance-report";
import { Card, Notice, PageHeader, Tabs, buttonClass, inputClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";
import { SectionTabs } from "@/components/section-tabs";
import { clearDefaultView, saveDefaultView } from "./actions";

export const metadata: Metadata = { title: "Compliance report" };

export default async function ComplianceReportPage({ searchParams }: PageProps<"/reports/compliance">) {
  const { profile, features } = await requireSession();
  if (!canSeeComplianceReport(profile.role, await getPeopleRules()) || features.reports === false) redirect("/");
  const params = await searchParams;
  // No choices in the address: open their saved view, if they have one.
  const saved = (await cookies()).get(DEFAULT_COOKIE)?.value;
  if (!Object.keys(params).length && saved) redirect(`/reports/compliance?${saved}`);
  const f = parseComplianceFilter(params);
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const today = todayIn(timeZone);
  const report = await buildComplianceReport(f, today);
  const qs = filterQuery(f);
  const viewLink = (view: ComplianceView) => `/reports/compliance?${filterQuery({ ...f, view })}`;
  const printedAt = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const filterText = [
    SHOW_LABELS[f.show],
    f.role ? ROLE_LABELS[f.role] : "",
    f.team ? report.teams.find((t) => t.id === f.team)?.name ?? "" : "",
    f.items.length ? `${f.items.length} item${f.items.length === 1 ? "" : "s"}` : "All items",
  ]
    .filter(Boolean)
    .join(" · ");

  return (
    <>
      <PrintHeader brand={brand} title={`Compliance: ${VIEW_LABELS[f.view]}`} subtitle={filterText} printedAt={printedAt} />
      <SectionTabs section="reports" current="/reports/compliance" />
      <PageHeader
        title="Compliance report"
        intro="Where everyone is up to with documents to read, trainings and uploads. Choose what to show, then download it or print it."
        action={
          <div className="flex flex-wrap gap-2 print:hidden">
            <a href={`/reports/compliance/export?${qs}`} className={buttonClass("primary")}>
              Download Excel
            </a>
            <PrintButton label="Print or save as PDF" />
          </div>
        }
      />
      {params.saved ? <Notice tone="success">Saved. The report opens like this for you next time.</Notice> : null}

      <div className="grid grid-cols-2 gap-3 md:grid-cols-5">
        {[
          { label: "People", n: report.totals.people, tone: "text-brand" },
          { label: "All done", n: report.totals.finished, tone: "text-good" },
          { label: "Something expired", n: report.totals.expired, tone: report.totals.expired ? "text-danger" : "text-muted" },
          { label: "Expiring soon", n: report.totals.expiring, tone: report.totals.expiring ? "text-warn" : "text-muted" },
          { label: "Uploads to check", n: report.totals.check, tone: report.totals.check ? "text-brand" : "text-muted" },
        ].map((s) => (
          <Card key={s.label} className="p-4">
            <p className={`heading tabular-nums ${s.tone}`}>{s.n}</p>
            <p className="text-sm text-muted">{s.label}</p>
          </Card>
        ))}
      </div>

      <Tabs label="Report view" items={(Object.keys(VIEW_LABELS) as ComplianceView[]).map((v) => ({ href: viewLink(v), text: VIEW_LABELS[v], current: v === f.view }))} />

      <Card className="p-4 print:hidden">
        <form className="flex flex-col gap-3">
          <input type="hidden" name="view" value={f.view} />
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <label className="flex flex-col gap-1 text-sm">
              <span className="font-semibold">Show</span>
              <select name="show" defaultValue={f.show} className={inputClass}>
                {Object.entries(SHOW_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex flex-col gap-1 text-sm">
              <span className="font-semibold">Role</span>
              <select name="role" defaultValue={f.role} className={inputClass}>
                <option value="">All roles</option>
                {ROLES.filter((r) => r !== "system_admin").map((r) => (
                  <option key={r} value={r}>
                    {ROLE_LABELS[r]}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex flex-col gap-1 text-sm">
              <span className="font-semibold">Team</span>
              <select name="team" defaultValue={f.team} className={inputClass}>
                <option value="">All teams</option>
                {report.teams.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name}
                  </option>
                ))}
              </select>
            </label>
            {f.view === "expiry" ? (
              <label className="flex flex-col gap-1 text-sm">
                <span className="font-semibold">Expiring within</span>
                <select name="within" defaultValue={String(f.within)} className={inputClass}>
                  <option value="0">Any date</option>
                  <option value="30">30 days</option>
                  <option value="60">60 days</option>
                  <option value="90">90 days</option>
                </select>
              </label>
            ) : null}
          </div>
          <details open={f.items.length > 0}>
            <summary className="cursor-pointer text-sm font-semibold text-brand">
              Items to include ({f.items.length ? `${f.items.length} chosen` : "all"})
            </summary>
            <div className="mt-2 grid gap-x-6 gap-y-1 sm:grid-cols-2 lg:grid-cols-3">
              {(["read", "training", "upload"] as ItemKind[]).map((kind) => {
                const list = report.items.filter((i) => i.kind === kind);
                return list.length ? (
                  <fieldset key={kind} className="flex flex-col gap-1">
                    <legend className="mb-1 text-xs font-semibold tracking-wider text-muted uppercase">{KIND_TAB[kind]}</legend>
                    {list.map((i) => (
                      <label key={i.id} className="flex min-h-9 items-center gap-2 text-sm">
                        <input type="checkbox" name="item" value={i.id} defaultChecked={f.items.includes(i.id)} className="h-4 w-4 accent-[var(--brand-primary)]" />
                        {i.title}
                      </label>
                    ))}
                  </fieldset>
                ) : null;
              })}
            </div>
            <p className="mt-1 text-xs text-muted">Tick none to include every item.</p>
          </details>
          <div className="flex flex-wrap items-center gap-2">
            <button className={buttonClass("outline")}>Show</button>
          </div>
        </form>
        <div className="mt-3 flex flex-wrap items-center gap-3 border-t border-line pt-3 text-sm">
          <form action={saveDefaultView}>
            <input type="hidden" name="query" value={qs} />
            <button className="font-semibold text-brand underline">Save as my default view</button>
          </form>
          {saved ? (
            <form action={clearDefaultView}>
              <button className="text-muted underline">Forget my default</button>
            </form>
          ) : null}
        </div>
      </Card>

      <Card className="overflow-hidden">
        <div className="border-b border-line px-5 py-3">
          <h2 className="heading-sm">{VIEW_LABELS[f.view]}</h2>
          <p className="text-sm text-muted">{filterText}</p>
        </div>
        <DataTable table={report.table} empty="No one matches these choices." />
      </Card>
    </>
  );
}

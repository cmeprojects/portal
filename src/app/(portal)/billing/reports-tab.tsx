// Staff Portal · © cmeproject. All rights reserved.
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card, buttonClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { addDays, sydneyToday } from "@/lib/sydney-time";
import { billingReports } from "@/lib/billing-reports";

// cmeprojects (update 166): consolidated financial reports for a period, with a CSV for each
// section (Billing export right; recorded in the download trail).
type SP = Record<string, string | string[] | undefined>;
const ymd = (v: unknown) => (typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : "");
const aud = (n: number) => Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" });
const dmyIf = (v: string | number) => (typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v.split("-").reverse().join("/") : v);

export async function ReportsTab({ sp }: { sp: SP }) {
  const today = sydneyToday();
  const from = ymd(sp.from) || `${addDays(`${today.slice(0, 7)}-01`, -1).slice(0, 7)}-01`;
  const to = ymd(sp.to) || addDays(`${today.slice(0, 7)}-01`, -1);
  const supabase = await createClient();
  const { error } = await supabase.from("billing_revenue").select("id").limit(1);
  if (error) return <Card className="p-5 text-sm text-muted">Financial reports aren&apos;t set up yet (update 166).</Card>;
  const [sections, canExport] = await Promise.all([billingReports(supabase, from, to, today), canBill("export")]);
  return (
    <div className="flex flex-col gap-4">
      <Card className="flex flex-col gap-2 p-4">
        <form method="get" action="/billing" className="flex flex-wrap items-end gap-2">
          <input type="hidden" name="tab" value="reports" />
          <label className="flex flex-col gap-1 text-xs font-medium">From<DateInput name="from" defaultValue={from} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
          <label className="flex flex-col gap-1 text-xs font-medium">To<DateInput name="to" defaultValue={to} className="rounded-lg border border-field bg-surface px-3 py-2 text-sm" /></label>
          <button className={buttonClass("outline")}>Show</button>
          {canExport ? <a href={`/billing/reports/export?section=all&from=${from}&to=${to}`} className="text-sm font-semibold text-brand underline">Download all (CSV)</a> : null}
        </form>
        <p className="text-xs text-muted">Everything here is worked out from the approved billing lines, charges, claims, invoices, payments and budgets you can see. Amounts in AUD.</p>
      </Card>
      {sections.map((s) => (
        <Card key={s.key} className="flex flex-col gap-2 p-4">
          <div className="flex flex-wrap items-start gap-2">
            <div className="min-w-48 flex-1">
              <h2 className="heading-sm">{s.title}</h2>
              <p className="text-sm text-muted">{s.note}</p>
            </div>
            {canExport ? <a href={`/billing/reports/export?section=${s.key}&from=${from}&to=${to}`} className="text-xs font-semibold text-brand underline">CSV</a> : null}
          </div>
          {s.rows.length ? (
            <div className="relative overflow-x-auto">
              <table className="w-full min-w-[640px] text-sm">
                <thead className="text-left text-xs text-muted"><tr>{s.head.map((h, i) => <th key={h} className={`py-1 ${s.money.includes(i) || typeof s.rows[0][i] === "number" ? "text-right" : ""}`}>{h}</th>)}</tr></thead>
                <tbody className="divide-y divide-line">
                  {s.rows.map((r, j) => (
                    <tr key={j} className={s.key === "checks" && r[1] === "error" && Number(r[2]) > 0 ? "font-semibold text-danger" : ""}>
                      {r.map((v, i) => <td key={i} className={`py-1.5 ${typeof v === "number" ? "text-right" : ""}`}>{s.money.includes(i) ? aud(Number(v)) : dmyIf(v)}</td>)}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : <p className="text-sm text-muted">Nothing in this period.</p>}
        </Card>
      ))}
    </div>
  );
}

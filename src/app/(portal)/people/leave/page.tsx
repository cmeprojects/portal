// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ChevronLeft, ChevronRight, Download } from "lucide-react";
import { requireSession } from "@/lib/session";
import { seesAllRequestsFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { LEAVE_LABEL } from "@/lib/requests-shared";

export const metadata: Metadata = { title: "Leave calendar" };

const COLOURS: Record<string, string> = { annual: "bg-brand", personal: "bg-warn", long_service: "bg-good", unpaid: "bg-muted", compassionate: "bg-danger", other: "bg-brand-accent" };

// cmeprojects (HR block step 3): who is on approved leave, by month. People
// who see everyone's requests see everyone; team leaders see their teams (the
// database decides). Payroll export of the month for people who see all.
export default async function LeaveCalendarPage({ searchParams }: PageProps<"/people/leave">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false) notFound();
  const all = await seesAllRequestsFor();
  if (!all && profile.role !== "team_leader") notFound();
  const sp = await searchParams;
  const now = new Date();
  const m = typeof sp.m === "string" && /^\d{4}-\d{2}$/.test(sp.m) ? sp.m : `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  const [y, mo] = m.split("-").map(Number);
  const days = new Date(y, mo, 0).getDate();
  const first = `${m}-01`;
  const last = `${m}-${String(days).padStart(2, "0")}`;
  const shift = (n: number) => {
    const d = new Date(y, mo - 1 + n, 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
  };
  const supabase = await createClient();
  const team = typeof sp.team === "string" && /^[0-9a-f-]{36}$/.test(sp.team) ? sp.team : "";
  const [{ data: periods }, { data: teams }, { data: members }] = await Promise.all([
    supabase.from("leave_periods").select("user_id, leave_type, start_date, end_date").lte("start_date", last).gte("end_date", first),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("team_members").select("team_id, user_id"),
  ]);
  const rows = ((periods ?? []) as { user_id: string; leave_type: string; start_date: string; end_date: string }[]).filter(
    (p) => !team || ((members ?? []) as { team_id: string; user_id: string }[]).some((t) => t.team_id === team && t.user_id === p.user_id),
  );
  const ids = [...new Set(rows.map((r) => r.user_id))];
  const { data: people } = ids.length ? await supabase.from("profiles").select("id, full_name, email").in("id", ids) : { data: [] };
  const names = new Map(((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const sorted = ids.sort((a, b) => (names.get(a) ?? "").localeCompare(names.get(b) ?? ""));
  const dayList = Array.from({ length: days }, (_, i) => `${m}-${String(i + 1).padStart(2, "0")}`);
  const weekend = (d: string) => [0, 6].includes(new Date(`${d}T00:00:00`).getDay());
  const today = new Date().toISOString().slice(0, 10);
  const monthName = new Date(y, mo - 1, 1).toLocaleDateString("en-AU", { month: "long", year: "numeric" });
  const q = (extra: Record<string, string>) => `?${new URLSearchParams({ m, ...(team ? { team } : {}), ...extra }).toString()}`;

  return (
    <>
      <PageHeader
        title="Leave calendar"
        intro={all ? "Approved leave for everyone, by month." : "Approved leave for your teams, by month."}
        action={
          all ? (
            <a href={`/people/leave/export${q({})}`} className={buttonClass("outline")}>
              <Download aria-hidden="true" className="size-4" /> Payroll export (CSV)
            </a>
          ) : undefined
        }
      />
      <div className="flex flex-wrap items-center gap-2">
        <Link href={q({ m: shift(-1) })} aria-label="Previous month" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Link>
        <span className="min-w-36 text-center font-semibold">{monthName}</span>
        <Link href={q({ m: shift(1) })} aria-label="Next month" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronRight aria-hidden="true" className="size-4" />
        </Link>
        <form className="ml-auto flex items-center gap-2">
          <input type="hidden" name="m" value={m} />
          <select name="team" defaultValue={team} aria-label="Team" className="h-10 rounded-lg border border-field bg-surface px-2 text-sm">
            <option value="">All teams</option>
            {((teams ?? []) as { id: string; name: string }[]).map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
          <button className={buttonClass("outline")}>Show</button>
        </form>
      </div>
      <Card className="overflow-x-auto p-0">
        {sorted.length ? (
          <table className="w-full border-collapse text-xs">
            <thead>
              <tr>
                <th scope="col" className="sticky left-0 z-10 min-w-40 bg-surface px-3 py-2 text-left font-semibold">
                  Staff
                </th>
                {dayList.map((d) => (
                  <th key={d} scope="col" className={`w-7 px-0.5 py-2 text-center font-semibold ${weekend(d) ? "text-muted" : ""} ${d === today ? "text-brand" : ""}`}>
                    {Number(d.slice(8))}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.map((id) => (
                <tr key={id} className="border-t border-line">
                  <th scope="row" className="sticky left-0 bg-surface px-3 py-1.5 text-left font-medium">
                    {names.get(id) ?? "Staff member"}
                  </th>
                  {dayList.map((d) => {
                    const on = rows.find((r) => r.user_id === id && r.start_date <= d && r.end_date >= d);
                    return (
                      <td key={d} className={`px-0.5 py-1 ${weekend(d) ? "bg-page/60" : ""}`}>
                        {on ? <span title={`${LEAVE_LABEL[on.leave_type] ?? "Leave"}`} className={`block h-5 rounded ${COLOURS[on.leave_type] ?? "bg-brand"} ${weekend(d) ? "opacity-40" : ""}`} /> : null}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="p-6 text-center text-sm text-muted">Nobody is on approved leave in {monthName}.</p>
        )}
      </Card>
      <p className="flex flex-wrap gap-3 text-xs text-muted">
        {Object.entries(COLOURS).map(([k, c]) => (
          <span key={k} className="inline-flex items-center gap-1.5">
            <span className={`inline-block size-3 rounded ${c}`} />
            {LEAVE_LABEL[k] ?? k}
          </span>
        ))}
      </p>
    </>
  );
}

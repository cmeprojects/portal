// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { canSeeScoreboard, getPeopleRules } from "@/lib/settings";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { formatDate } from "@/lib/registers";
import { Badge, Card, PageHeader, Tabs } from "@/components/ui";

export const metadata: Metadata = { title: "Scoreboard" };

type Row = {
  user_id: string;
  full_name: string;
  role: Role;
  open_tasks: number;
  overdue: number;
  escalated: number;
  stuck: number;
  completed: number;
  completed_on_time: number;
  completed_with_due: number;
  avg_days_late: number | null;
  oldest_overdue: string | null;
  onboarding_missing: number;
};

const PERIODS = [30, 90] as const;

// What needs attention, worst first: overdue, escalated and stuck tasks,
// then a low on-time rate.
function attention(r: Row): number {
  const onTime = r.completed_with_due ? r.completed_on_time / r.completed_with_due : 1;
  return r.overdue * 3 + r.escalated * 4 + r.stuck * 2 + (onTime < 0.7 ? 3 : 0) + (r.onboarding_missing ? 1 : 0);
}

export default async function ScoreboardPage({ searchParams }: PageProps<"/scoreboard">) {
  const { profile: me } = await requireSession();
  if (!canSeeScoreboard(me.role, await getPeopleRules())) redirect("/");
  const params = await searchParams;
  const days = PERIODS.find((d) => String(d) === params.days) ?? 30;
  const supabase = await createClient();
  const [{ data }, { data: stuckSetting }] = await Promise.all([
    supabase.rpc("staff_scoreboard", { p_days: days }),
    supabase.from("app_settings").select("value").eq("key", "people.stuck_days").maybeSingle(),
  ]);
  const stuckDays = Number(stuckSetting?.value ?? 7);
  const rows = ((data ?? []) as Row[]).map((r) => ({ ...r, score: attention(r) })).sort((a, b) => b.score - a.score || a.full_name.localeCompare(b.full_name));
  const flagged = rows.filter((r) => r.score > 0);
  const totals = rows.reduce(
    (t, r) => ({ overdue: t.overdue + r.overdue, stuck: t.stuck + r.stuck, escalated: t.escalated + r.escalated, completed: t.completed + r.completed }),
    { overdue: 0, stuck: 0, escalated: 0, completed: 0 },
  );

  return (
    <>
      <PageHeader
        title="Scoreboard"
        intro={`How everyone is going with their tasks, so you can see who might need support. "Stuck" means open with nothing done on it for ${stuckDays} days.${me.role === "team_leader" ? " Showing the team you lead." : ""}`}
      />
      <Tabs label="Period" items={PERIODS.map((d) => ({ href: `/scoreboard?days=${d}`, text: `Last ${d} days`, current: d === days }))} />

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: "Need attention", n: flagged.length, tone: "text-danger" },
          { label: "Overdue tasks", n: totals.overdue, tone: "text-danger" },
          { label: "Stuck tasks", n: totals.stuck, tone: "text-warn" },
          { label: `Completed (${days} days)`, n: totals.completed, tone: "text-good" },
        ].map((s) => (
          <Card key={s.label} className="p-4">
            <p className={`heading ${s.tone}`}>{s.n}</p>
            <p className="text-sm text-muted">{s.label}</p>
          </Card>
        ))}
      </div>

      <Card className="overflow-hidden">
        {rows.length === 0 ? (
          <p className="px-5 py-4 text-sm text-muted">No one to show yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[52rem] text-sm">
              <thead className="bg-page text-left text-xs tracking-wider text-muted uppercase">
                <tr>
                  <th scope="col" className="px-4 py-3 font-medium">Person</th>
                  <th scope="col" className="px-3 py-3 text-right font-medium">Open</th>
                  <th scope="col" className="px-3 py-3 text-right font-medium">Overdue</th>
                  <th scope="col" className="px-3 py-3 text-right font-medium">Escalated</th>
                  <th scope="col" className="px-3 py-3 text-right font-medium">Stuck</th>
                  <th scope="col" className="px-3 py-3 text-right font-medium">Done</th>
                  <th scope="col" className="px-3 py-3 text-right font-medium">On time</th>
                  <th scope="col" className="px-4 py-3 font-medium">Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {rows.map((r) => {
                  const onTime = r.completed_with_due ? Math.round((r.completed_on_time / r.completed_with_due) * 100) : null;
                  const notes = [
                    r.oldest_overdue ? `Overdue since ${formatDate(r.oldest_overdue)}` : "",
                    r.avg_days_late ? `Late by ${r.avg_days_late} days on average` : "",
                    r.onboarding_missing ? `Onboarding: ${r.onboarding_missing} to do` : "",
                  ].filter(Boolean);
                  const cell = (n: number, tone: string) => (
                    <td className={`px-3 py-3 text-right tabular-nums ${n ? `font-semibold ${tone}` : "text-muted"}`}>{n}</td>
                  );
                  return (
                    <tr key={r.user_id} className={r.score >= 6 ? "bg-danger-soft/40" : r.score > 0 ? "bg-warn-soft/30" : ""}>
                      <td className="px-4 py-3">
                        <span className="flex flex-wrap items-center gap-2">
                          <span className="font-semibold">{r.full_name}</span>
                          {r.score >= 6 ? <Badge tone="warn">Needs attention</Badge> : null}
                        </span>
                        <span className="text-xs text-muted">{ROLE_LABELS[r.role]}</span>
                      </td>
                      <td className="px-3 py-3 text-right tabular-nums">{r.open_tasks}</td>
                      {cell(r.overdue, "text-danger")}
                      {cell(r.escalated, "text-danger")}
                      {cell(r.stuck, "text-warn")}
                      <td className="px-3 py-3 text-right tabular-nums">{r.completed}</td>
                      <td className={`px-3 py-3 text-right tabular-nums ${onTime !== null && onTime < 70 ? "font-semibold text-danger" : ""}`}>
                        {onTime === null ? "—" : `${onTime}%`}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted">{notes.join(" · ") || "—"}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      <p className="text-sm text-muted">
        Use it to start a supportive conversation, not as the whole story: some tasks wait on other people.{" "}
        {me.role === "system_admin" ? (
          <>
            Choose who can see this in <Link href="/system" className="text-brand underline">System settings</Link>.
          </>
        ) : null}
      </p>
    </>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import { Cake, PartyPopper } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";

type Event = { key: string; name: string; kind: "birthday" | "anniversary"; years?: number; inDays: number; label: string };

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const leap = (y: number) => (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;

// cmeprojects Phase 5: birthdays (day and month, only when shared) and work
// anniversaries (from the commencement date, for people who can already see
// it), today and in the next 7 days. Active staff only. Nothing shows when
// there's nothing to celebrate.
export async function Celebrations({ me }: { me: string }) {
  const supabase = await createClient();
  const [timeZone, { data: bdays, error }, { data: starts }, { data: people }] = await Promise.all([
    getTimeZone(),
    supabase.from("staff_birthdays").select("user_id, month, day, show"),
    supabase.from("staff_private").select("user_id, start_date").not("start_date", "is", null),
    supabase.from("profiles").select("id, full_name, email, active, role").eq("active", true),
  ]);
  if (error) return null; // before the database update
  const today = todayIn(timeZone);
  const [ty, tm, td] = today.split("-").map(Number);
  const base = Date.UTC(ty, tm - 1, td);
  const who = new Map((people ?? []).filter((p) => p.role !== "system_admin" && p.role !== "new_starter").map((p) => [p.id, (p.full_name || p.email).split(" ")[0]]));
  // Days until the next time this month/day comes round (29 Feb is 28 Feb in other years).
  const until = (m: number, d: number) => {
    for (const y of [ty, ty + 1]) {
      const day = m === 2 && d === 29 && !leap(y) ? 28 : d;
      const diff = Math.round((Date.UTC(y, m - 1, day) - base) / 86_400_000);
      if (diff >= 0) return { diff, year: y };
    }
    return { diff: 999, year: ty };
  };
  const events: Event[] = [];
  for (const b of bdays ?? []) {
    if (!who.has(b.user_id) || (b.user_id !== me && !b.show)) continue;
    const { diff } = until(b.month, b.day);
    if (diff <= 7) events.push({ key: `b${b.user_id}`, name: b.user_id === me ? "You" : who.get(b.user_id)!, kind: "birthday", inDays: diff, label: `${b.day} ${MONTHS[b.month - 1]}` });
  }
  for (const s of starts ?? []) {
    if (!who.has(s.user_id)) continue;
    const [sy, sm, sd] = (s.start_date as string).split("-").map(Number);
    const { diff, year } = until(sm, sd);
    const years = year - sy;
    if (diff <= 7 && years >= 1) events.push({ key: `a${s.user_id}`, name: s.user_id === me ? "You" : who.get(s.user_id)!, kind: "anniversary", years, inDays: diff, label: `${sd} ${MONTHS[sm - 1]}` });
  }
  if (!events.length) return null;
  events.sort((a, b) => a.inDays - b.inDays || a.name.localeCompare(b.name));
  const todays = events.filter((e) => e.inDays === 0);
  const soon = events.filter((e) => e.inDays > 0);
  const greet = (e: Event) =>
    e.kind === "birthday"
      ? e.name === "You"
        ? "Happy birthday to you!"
        : `Happy birthday, ${e.name}!`
      : e.name === "You"
        ? `Happy ${e.years}-year work anniversary to you!`
        : `${e.name}: ${e.years} year${e.years === 1 ? "" : "s"} with us today`;
  return (
    <section aria-label="Celebrations" className="flex flex-col gap-3 rounded-xl border border-line bg-surface p-4 shadow-card sm:flex-row sm:items-start sm:gap-6">
      {todays.length ? (
        <div className="flex flex-1 flex-col gap-2">
          {todays.map((e) => (
            <p key={e.key} className="flex items-center gap-2 font-semibold">
              {e.kind === "birthday" ? <Cake aria-hidden="true" className="size-5 text-brand" /> : <PartyPopper aria-hidden="true" className="size-5 text-brand" />}
              {greet(e)}
            </p>
          ))}
        </div>
      ) : null}
      {soon.length ? (
        <div className="flex flex-1 flex-col gap-1">
          <p className="text-xs font-semibold tracking-wide text-muted uppercase">Coming up this week</p>
          <ul className="flex flex-col gap-1 text-sm">
            {soon.map((e) => (
              <li key={e.key} className="flex items-center gap-2">
                {e.kind === "birthday" ? <Cake aria-hidden="true" className="size-4 text-muted" /> : <PartyPopper aria-hidden="true" className="size-4 text-muted" />}
                <span>
                  <strong>{e.name}</strong> · {e.kind === "birthday" ? "birthday" : `${e.years} year${e.years === 1 ? "" : "s"} with us`} · {e.label}
                  <span className="text-muted"> ({e.inDays === 1 ? "tomorrow" : `in ${e.inDays} days`})</span>
                </span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </section>
  );
}

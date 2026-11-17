// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { AlertTriangle, ChevronLeft, ChevronRight, Hand } from "lucide-react";
import { requireSession } from "@/lib/session";
import { canDo, seesComplianceFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { addDays, mondayOf, shiftHours, sydneyInstant, sydneyParts, sydneyToday } from "@/lib/sydney-time";
import { cancelShift, giveOpenShift, publishWeek } from "./actions";
import { CopyWeekForm, ShiftForm, type ShiftDraft } from "./shift-form";

export const metadata: Metadata = { title: "Roster" };

type Shift = { id: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string; status: string };
const DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const AVAIL_DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
// Day 6am–6pm, evening 6pm–10pm, night otherwise (for availability).
const bandOf = (time: string) => {
  const h = Number(time.slice(0, 2));
  return h >= 6 && h < 12 ? "am" : h >= 12 && h < 18 ? "pm" : "night";
};

// cmeprojects (update 122): the week's roster. Add, change, publish and
// cancel shifts; give open shifts to someone who put their hand up. Warnings
// (availability, hours, expired checks) show here; leave and double-booking
// are refused by the database.
export default async function RosterPage({ searchParams }: PageProps<"/roster">) {
  await requireSession();
  if (!(await canDo("ops.roster", "view"))) notFound();
  const canEdit = await canDo("ops.roster", "edit");
  const sp = await searchParams;
  const monday = mondayOf(typeof sp.w === "string" && /^\d{4}-\d{2}-\d{2}$/.test(sp.w) ? sp.w : sydneyToday());
  const days = Array.from({ length: 7 }, (_, i) => addDays(monday, i));
  const from = sydneyInstant(monday);
  const to = sydneyInstant(addDays(monday, 7));
  const supabase = await createClient();
  const [shiftsRes, { data: people }, { data: clients }, { data: locations }, { data: services }, { data: leave }, { data: interest }, { data: availRows }] = await Promise.all([
    supabase.from("shifts").select("id, worker_id, starts_at, ends_at, break_minutes, client_id, service_id, location_id, notes, status").neq("status", "cancelled").gte("starts_at", from).lt("starts_at", to).order("starts_at"),
    supabase.from("profiles").select("id, full_name, email, role, active").eq("active", true).not("role", "in", "(new_starter,system_admin,external)").order("full_name"),
    supabase.from("car_clients").select("id, name, status").neq("status", "discharged").order("name"),
    supabase.from("client_locations").select("id, client_id, label, address").eq("approved", true),
    supabase.from("client_services").select("id, client_id, label").neq("status", "ended"),
    supabase.from("leave_periods").select("user_id, start_date, end_date").lte("start_date", days[6]).gte("end_date", days[0]),
    supabase.from("shift_interest").select("shift_id, user_id"),
    supabase.from("staff_private").select("user_id, availability"),
  ]);
  if (shiftsRes.error) notFound(); // before live update 122
  const shifts = (shiftsRes.data ?? []) as Shift[];
  const workers = ((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => ({ id: p.id, name: p.full_name || p.email }));
  const name = new Map(workers.map((w) => [w.id, w.name]));
  const clientName = new Map(((clients ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const avail = new Map(((availRows ?? []) as { user_id: string; availability: Record<string, string[]> | null }[]).map((a) => [a.user_id, a.availability]));
  // Expired checks (for people who look after onboarding).
  const expiredOf = new Map<string, number>();
  if (await seesComplianceFor()) {
    const today = sydneyToday();
    const { data: exp } = await supabase.from("compliance_records").select("user_id").in("status", ["accepted", "done"]).lt("expires_on", today);
    for (const r of (exp ?? []) as { user_id: string }[]) expiredOf.set(r.user_id, (expiredOf.get(r.user_id) ?? 0) + 1);
  }
  const hoursOf = new Map<string, number>();
  for (const s of shifts) if (s.worker_id) hoursOf.set(s.worker_id, (hoursOf.get(s.worker_id) ?? 0) + shiftHours(s));
  const onLeave = (who: string, day: string) => ((leave ?? []) as { user_id: string; start_date: string; end_date: string }[]).some((l) => l.user_id === who && l.start_date <= day && l.end_date >= day);
  const warningsFor = (s: Shift): string[] => {
    if (!s.worker_id) return [];
    const w: string[] = [];
    const p = sydneyParts(s.starts_at);
    const a = avail.get(s.worker_id);
    if (a && Object.values(a).some((v) => v?.length) && !(a[AVAIL_DAYS[p.dow]] ?? []).includes(bandOf(p.time))) w.push("Outside their availability");
    if ((hoursOf.get(s.worker_id) ?? 0) > 38) w.push(`${(hoursOf.get(s.worker_id) ?? 0).toFixed(1)} hours this week (over 38)`);
    if (expiredOf.get(s.worker_id)) w.push("A check has expired");
    return w;
  };
  const rowIds = [...new Set(shifts.map((s) => s.worker_id).filter((v): v is string => !!v))].sort((a, b) => (name.get(a) ?? "").localeCompare(name.get(b) ?? ""));
  const openShifts = shifts.filter((s) => !s.worker_id);
  const drafts = shifts.filter((s) => s.status === "draft").length;
  const totalHours = shifts.filter((s) => s.worker_id).reduce((n, s) => n + shiftHours(s), 0);
  const editing = typeof sp.shift === "string" ? shifts.find((s) => s.id === sp.shift) : undefined;
  const adding = typeof sp.add === "string" && /^\d{4}-\d{2}-\d{2}$/.test(sp.add) ? sp.add : null;
  const draftOf = (s?: Shift): ShiftDraft =>
    s
      ? {
          id: s.id,
          date: sydneyParts(s.starts_at).date,
          start: sydneyParts(s.starts_at).time,
          end: sydneyParts(s.ends_at).time,
          break_minutes: s.break_minutes,
          worker_id: s.worker_id ?? "",
          client_id: s.client_id ?? "",
          location_id: s.location_id ?? "",
          service_id: s.service_id ?? "",
          notes: s.notes,
          status: s.status,
        }
      : { date: adding ?? days[0], start: "09:00", end: "15:00", break_minutes: 0, worker_id: typeof sp.worker === "string" ? sp.worker : "", client_id: "", location_id: "", service_id: "", notes: "", status: "draft" };
  const weekLabel = `${new Date(`${days[0]}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short" })} – ${new Date(`${days[6]}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" })}`;
  const today = sydneyToday();

  return (
    <>
      <PageHeader title="Roster" intro="Shifts for the week. Drafts are dashed; publish them to tell the workers. Leave and double-booking are refused; other warnings show with a triangle." />
      <div className="flex flex-wrap items-center gap-2">
        <Link href={`/roster?w=${addDays(monday, -7)}`} aria-label="Previous week" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Link>
        <span className="min-w-44 text-center font-semibold">{weekLabel}</span>
        <Link href={`/roster?w=${addDays(monday, 7)}`} aria-label="Next week" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronRight aria-hidden="true" className="size-4" />
        </Link>
        <Link href={`/roster?w=${mondayOf(today)}`} className="text-sm font-semibold text-brand underline">
          This week
        </Link>
        <span className="ml-auto text-sm text-muted">
          {shifts.length} shifts · {totalHours.toFixed(1)} rostered hours · {openShifts.length} open
        </span>
      </div>
      {canEdit ? (
        <div className="flex flex-wrap items-center gap-2">
          <Link href={`/roster?w=${monday}&add=${today >= days[0] && today <= days[6] ? today : days[0]}`} scroll={false} className={buttonClass("primary")}>
            Add shift
          </Link>
          {drafts ? (
            <form action={publishWeek}>
              <input type="hidden" name="from" value={from} />
              <input type="hidden" name="to" value={to} />
              <button className={buttonClass("outline")}>Publish {drafts} draft{drafts === 1 ? "" : "s"}</button>
            </form>
          ) : null}
          <CopyWeekForm from={from} />
        </div>
      ) : null}
      {canEdit && (editing || adding) ? (
        <Card className="flex flex-col gap-3 p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="heading-sm">{editing ? "Change shift" : "Add shift"}</h2>
            <Link href={`/roster?w=${monday}`} scroll={false} className="text-sm font-semibold text-muted hover:text-ink">
              Close
            </Link>
          </div>
          {editing && warningsFor(editing).length ? (
            <ul className="rounded-lg bg-warn-soft px-3 py-2 text-sm">
              {warningsFor(editing).map((w) => (
                <li key={w} className="flex items-center gap-2">
                  <AlertTriangle aria-hidden="true" className="size-4" /> {w}
                </li>
              ))}
            </ul>
          ) : null}
          <ShiftForm
            key={editing?.id ?? adding ?? "new"}
            shift={draftOf(editing)}
            workers={workers.map((w) => ({ ...w, note: `${(hoursOf.get(w.id) ?? 0).toFixed(0)}h this week${expiredOf.get(w.id) ? " · check expired" : ""}` }))}
            clients={((clients ?? []) as { id: string; name: string }[]).map((c) => ({ id: c.id, name: c.name }))}
            locations={((locations ?? []) as { id: string; client_id: string; label: string; address: string }[]).map((l) => ({ id: l.id, client_id: l.client_id, name: `${l.label}: ${l.address}` }))}
            services={((services ?? []) as { id: string; client_id: string; label: string }[]).map((v) => ({ id: v.id, client_id: v.client_id, name: v.label }))}
          />
          {editing && !editing.worker_id ? (
            <div className="border-t border-line pt-3">
              <h3 className="text-sm font-semibold">Put their hand up</h3>
              {((interest ?? []) as { shift_id: string; user_id: string }[]).filter((i) => i.shift_id === editing.id).length ? (
                <ul className="mt-1 flex flex-wrap gap-2">
                  {((interest ?? []) as { shift_id: string; user_id: string }[])
                    .filter((i) => i.shift_id === editing.id)
                    .map((i) => (
                      <li key={i.user_id}>
                        <form action={giveOpenShift} className="flex items-center gap-2 rounded-lg border border-line px-2 py-1 text-sm">
                          <input type="hidden" name="id" value={editing.id} />
                          <input type="hidden" name="worker_id" value={i.user_id} />
                          {name.get(i.user_id) ?? "Staff member"}
                          <button className="text-xs font-semibold text-brand underline">Give it to them</button>
                        </form>
                      </li>
                    ))}
                </ul>
              ) : (
                <p className="text-sm text-muted">Nobody yet.</p>
              )}
            </div>
          ) : null}
          {editing ? (
            <form action={cancelShift} className="border-t border-line pt-3">
              <input type="hidden" name="id" value={editing.id} />
              <button className="text-sm font-semibold text-danger underline">Cancel this shift</button>
            </form>
          ) : null}
        </Card>
      ) : null}
      <Card className="overflow-x-auto p-0">
        <table className="w-full min-w-[56rem] border-collapse text-sm">
          <thead>
            <tr className="border-b border-line">
              <th scope="col" className="sticky left-0 z-10 w-44 bg-surface px-3 py-2 text-left text-xs font-semibold text-muted">
                Worker
              </th>
              {days.map((d, i) => (
                <th key={d} scope="col" className={`px-1 py-2 text-left text-xs font-semibold ${d === today ? "text-brand" : "text-muted"}`}>
                  {DAY_NAMES[i]} {Number(d.slice(8))}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            <tr className="border-b border-line bg-page/40">
              <th scope="row" className="sticky left-0 bg-page px-3 py-2 text-left text-xs font-semibold">
                Open shifts
              </th>
              {days.map((d) => (
                <td key={d} className="px-1 py-1 align-top">
                  <div className="flex flex-col gap-1">
                    {openShifts.filter((s) => sydneyParts(s.starts_at).date === d).map((s) => (
                      <Chip key={s.id} s={s} monday={monday} client={s.client_id ? clientName.get(s.client_id) : undefined} warnings={warningsFor(s)} hands={((interest ?? []) as { shift_id: string }[]).filter((i) => i.shift_id === s.id).length} />
                    ))}
                  </div>
                </td>
              ))}
            </tr>
            {rowIds.map((w) => (
              <tr key={w} className="border-b border-line">
                <th scope="row" className="sticky left-0 bg-surface px-3 py-2 text-left align-top">
                  <span className="block text-sm font-semibold">{name.get(w) ?? "Staff member"}</span>
                  <span className={`text-xs ${(hoursOf.get(w) ?? 0) > 38 ? "font-semibold text-warn" : "text-muted"}`}>{(hoursOf.get(w) ?? 0).toFixed(1)} hours</span>
                </th>
                {days.map((d) => (
                  <td key={d} className={`px-1 py-1 align-top ${onLeave(w, d) ? "bg-line/40" : ""}`}>
                    <div className="flex flex-col gap-1">
                      {onLeave(w, d) ? <span className="text-[11px] font-semibold text-muted">On leave</span> : null}
                      {shifts
                        .filter((s) => s.worker_id === w && sydneyParts(s.starts_at).date === d)
                        .map((s) => (
                          <Chip key={s.id} s={s} monday={monday} client={s.client_id ? clientName.get(s.client_id) : undefined} warnings={warningsFor(s)} hands={((interest ?? []) as { shift_id: string }[]).filter((i) => i.shift_id === s.id).length} />
                        ))}
                      {canEdit && !onLeave(w, d) ? (
                        <Link href={`/roster?w=${monday}&add=${d}&worker=${w}`} scroll={false} aria-label={`Add a shift for ${name.get(w)} on ${d}`} className="rounded-md border border-dashed border-transparent px-1 text-center text-xs text-muted hover:border-line hover:text-brand">
                          +
                        </Link>
                      ) : null}
                    </div>
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
        {!shifts.length ? <p className="p-6 text-center text-sm text-muted">No shifts this week yet.</p> : null}
      </Card>
    </>
  );
}

function Chip({ s, monday, client, warnings, hands }: { s: Shift; monday: string; client?: string; warnings: string[]; hands: number }) {
  const a = sydneyParts(s.starts_at);
  const b = sydneyParts(s.ends_at);
  return (
    <Link
      href={`/roster?w=${monday}&shift=${s.id}`}
      scroll={false}
      title={[client ?? "", s.notes, ...warnings].filter(Boolean).join("\n")}
      className={`block rounded-md px-1.5 py-1 text-[11px] leading-tight hover:ring-2 hover:ring-brand ${s.status === "draft" ? "border border-dashed border-brand/60 bg-surface" : "bg-brand-soft"}`}
    >
      <span className="flex items-center gap-1 font-semibold">
        {a.time}–{b.time}
        {warnings.length ? <AlertTriangle aria-label="Warning" className="size-3 text-warn" /> : null}
        {hands ? (
          <span className="inline-flex items-center text-brand">
            <Hand aria-hidden="true" className="size-3" />
            {hands}
          </span>
        ) : null}
      </span>
      <span className="block truncate text-muted">{client ?? (s.notes || "Shift")}</span>
    </Link>
  );
}

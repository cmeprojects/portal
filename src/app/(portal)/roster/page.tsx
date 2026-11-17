// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { AlertTriangle, ArrowLeftRight, ChevronLeft, ChevronRight, Hand, MoreVertical, Repeat2 } from "lucide-react";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, buttonClass } from "@/components/ui";
import { addDays, mondayOf, shiftHours, sydneyInstant, sydneyParts, sydneyToday } from "@/lib/sydney-time";
import { BANDS, availabilitySlot, bandOf, shortTime } from "@/lib/roster";
import { cancelShift, decideRequest, endRepeat, giveOpenShift, publishWeek } from "./actions";
import { BulkBar, CopyWeekForm, ShiftForm, type ShiftDraft, type WorkerFit } from "./shift-form";

export const metadata: Metadata = { title: "Roster" };

type Shift = { id: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string; status: string; series_id: string | null };
type Req = { id: string; shift_id: string; requested_by: string; kind: string; swap_with: string | null; reason: string; created_at: string };
const DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const AVAIL_DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
const auDate = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", timeZone: "UTC" });

// cmeprojects (rostering round 2, update 123; premium package): the week's
// roster by worker or by client; open (vacant) shifts; a panel to view, add or
// change a shift; change requests behind the ⇄ icon; select mode for bulk work.
export default async function RosterPage({ searchParams }: PageProps<"/roster">) {
  const { features } = await requireSession();
  if (features.rostering === false) notFound();
  if (!(await canDo("ops.roster", "view"))) notFound();
  const canEdit = await canDo("ops.roster", "edit");
  const sp = await searchParams;
  const str = (k: string) => (typeof sp[k] === "string" ? (sp[k] as string) : "");
  const today = sydneyToday();
  const monday = mondayOf(/^\d{4}-\d{2}-\d{2}$/.test(str("w")) ? str("w") : today);
  const days = Array.from({ length: 7 }, (_, i) => addDays(monday, i));
  const from = sydneyInstant(monday);
  const to = sydneyInstant(addDays(monday, 7));
  const byClient = str("by") === "client";
  const selecting = canEdit && str("select") === "1";
  const base = `/roster?w=${monday}${byClient ? "&by=client" : ""}`;
  const supabase = await createClient();
  const [shiftsRes, { data: people }, { data: clients }, { data: locations }, { data: services }, { data: leave }, { data: interest }, { data: availRows }, { data: checks }, reqRes] = await Promise.all([
    supabase.from("shifts").select("id, worker_id, starts_at, ends_at, break_minutes, client_id, service_id, location_id, notes, status, series_id").neq("status", "cancelled").gte("starts_at", from).lt("starts_at", to).order("starts_at"),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).not("role", "in", "(new_starter,system_admin,external)").order("full_name"),
    supabase.from("car_clients").select("id, name, status").neq("status", "discharged").order("name"),
    supabase.from("client_locations").select("id, client_id, label, address").eq("approved", true),
    supabase.from("client_services").select("id, client_id, label").neq("status", "ended"),
    supabase.from("leave_periods").select("user_id, start_date, end_date").lte("start_date", addDays(days[6], 7)).gte("end_date", days[0]),
    supabase.from("shift_interest").select("shift_id, user_id"),
    supabase.from("staff_private").select("user_id, availability"),
    supabase.rpc("roster_check_dates"),
    supabase.from("shift_change_requests").select("id, shift_id, requested_by, kind, swap_with, reason, created_at").eq("status", "pending").order("created_at"),
  ]);
  if (shiftsRes.error) notFound(); // before live update 122
  const shifts = (shiftsRes.data ?? []) as Shift[];
  const requests = reqRes.error ? [] : ((reqRes.data ?? []) as Req[]);
  const name = new Map(((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const clientName = new Map(((clients ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const serviceName = new Map(((services ?? []) as { id: string; label: string }[]).map((v) => [v.id, v.label]));
  const locName = new Map(((locations ?? []) as { id: string; label: string; address: string }[]).map((l) => [l.id, `${l.label}: ${l.address}`]));
  const avail = new Map(((availRows ?? []) as { user_id: string; availability: Record<string, string[]> | null }[]).map((a) => [a.user_id, a.availability]));
  const expired = new Map<string, { before: string[]; other: string[] }>();
  for (const c of (checks ?? []) as { user_id: string; title: string; expires_on: string; before_work: boolean }[]) {
    if (c.expires_on >= today) continue;
    const e = expired.get(c.user_id) ?? { before: [], other: [] };
    (c.before_work ? e.before : e.other).push(c.title);
    expired.set(c.user_id, e);
  }
  const hoursOf = new Map<string, number>();
  for (const s of shifts) if (s.worker_id) hoursOf.set(s.worker_id, (hoursOf.get(s.worker_id) ?? 0) + shiftHours(s));
  const onLeave = (who: string, day: string) => ((leave ?? []) as { user_id: string; start_date: string; end_date: string }[]).some((l) => l.user_id === who && l.start_date <= day && l.end_date >= day);
  const warningsFor = (s: Shift): string[] => {
    if (!s.worker_id) return [];
    const w: string[] = [];
    const p = sydneyParts(s.starts_at);
    const a = avail.get(s.worker_id);
    if (a && Object.values(a).some((v) => v?.length) && !(a[AVAIL_DAYS[p.dow]] ?? []).includes(availabilitySlot(s.starts_at))) w.push("Outside their availability");
    if ((hoursOf.get(s.worker_id) ?? 0) > 38) w.push(`${(hoursOf.get(s.worker_id) ?? 0).toFixed(1)} hours this week (over 38)`);
    if (expired.get(s.worker_id)?.other.length) w.push(`Expired: ${expired.get(s.worker_id)!.other.join(", ")}`);
    return w;
  };
  const hands = (id: string) => ((interest ?? []) as { shift_id: string; user_id: string }[]).filter((i) => i.shift_id === id);
  const vacant = shifts.filter((s) => !s.worker_id);
  const rowIds = byClient
    ? [...new Set(shifts.map((s) => s.client_id ?? "none"))].sort((a, b) => (clientName.get(a) ?? "~").localeCompare(clientName.get(b) ?? "~"))
    : [...new Set(shifts.map((s) => s.worker_id).filter((v): v is string => !!v))].sort((a, b) => (name.get(a) ?? "").localeCompare(name.get(b) ?? ""));
  const drafts = shifts.filter((s) => s.status === "draft").length;
  const totalHours = shifts.filter((s) => s.worker_id).reduce((n, s) => n + shiftHours(s), 0);
  const opened = str("shift") ? shifts.find((s) => s.id === str("shift")) ?? (await supabase.from("shifts").select("id, worker_id, starts_at, ends_at, break_minutes, client_id, service_id, location_id, notes, status, series_id").eq("id", str("shift")).maybeSingle()).data as Shift | null : null;
  const editing = canEdit && (str("add") || (opened && str("edit") === "1"));
  const tab = ["details", "timesheet", "log"].includes(str("tab")) ? str("tab") : "details";
  const weekLabel = `${auDate(days[0])} – ${auDate(days[6])} ${days[6].slice(0, 4)}`;
  const thisMonday = mondayOf(today);
  const weeksAway = Math.round((new Date(`${monday}T12:00:00Z`).getTime() - new Date(`${thisMonday}T12:00:00Z`).getTime()) / (7 * 86_400_000));

  // What Suggest weighs for each worker, around the shift being added or changed.
  const fitDay = opened ? sydneyParts(opened.starts_at).date : /^\d{4}-\d{2}-\d{2}$/.test(str("add")) ? str("add") : today;
  const workerFit: WorkerFit[] = editing
    ? ((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => ({
        id: p.id,
        name: p.full_name || p.email,
        hours: hoursOf.get(p.id) ?? 0,
        leave: Array.from({ length: 14 }, (_, i) => addDays(fitDay, i - 7)).filter((d) => onLeave(p.id, d)),
        busy: shifts.filter((s) => s.worker_id === p.id && s.id !== opened?.id).map((s) => ({ date: sydneyParts(s.starts_at).date, start: sydneyParts(s.starts_at).time, end: sydneyParts(s.ends_at).time })),
        expiredBeforeWork: (expired.get(p.id)?.before ?? []).join(", "),
        expiredOther: (expired.get(p.id)?.other ?? []).join(", "),
        avail: avail.get(p.id) ?? null,
      }))
    : [];
  const draft: ShiftDraft = opened
    ? {
        id: opened.id,
        date: sydneyParts(opened.starts_at).date,
        start: sydneyParts(opened.starts_at).time,
        end: sydneyParts(opened.ends_at).time,
        nextDay: sydneyParts(opened.ends_at).date !== sydneyParts(opened.starts_at).date && sydneyParts(opened.ends_at).time > sydneyParts(opened.starts_at).time,
        break_minutes: opened.break_minutes,
        worker_id: opened.worker_id ?? "",
        client_id: opened.client_id ?? "",
        location_id: opened.location_id ?? "",
        service_id: opened.service_id ?? "",
        notes: opened.notes,
        status: opened.status,
        series: !!opened.series_id,
      }
    : { date: fitDay, start: "09:00", end: "15:00", nextDay: false, break_minutes: 0, worker_id: str("worker"), client_id: str("client"), location_id: "", service_id: "", notes: "", status: "draft", series: false };

  // The opened shift's timesheet and log.
  const [{ data: sheet }, { data: events }] = opened && !editing
    ? await Promise.all([
        supabase.from("shift_timesheets").select("actual_start, actual_end, break_minutes, km, expense, allowances, note, status").eq("shift_id", opened.id).maybeSingle(),
        supabase.from("shift_events").select("id, actor, happened_at, summary").eq("shift_id", opened.id).order("happened_at", { ascending: false }).limit(50),
      ])
    : [{ data: null }, { data: null }];
  const actorIds = [...new Set(((events ?? []) as { actor: string | null }[]).map((e) => e.actor).filter((v): v is string => !!v && !name.has(v)))];
  const { data: actors } = actorIds.length ? await supabase.from("profiles").select("id, full_name, email").in("id", actorIds) : { data: [] };
  for (const a of (actors ?? []) as { id: string; full_name: string | null; email: string }[]) name.set(a.id, a.full_name || a.email);

  const chip = (s: Shift) => {
    const a = sydneyParts(s.starts_at);
    const warn = warningsFor(s);
    const n = hands(s.id).length;
    const asked = requests.some((r) => r.shift_id === s.id);
    const band = bandOf(s.starts_at, s.ends_at);
    const inner = (
      <>
        <span className="flex items-center justify-between gap-1 font-semibold">
          <span className="flex items-center gap-1">
            {a.time.replace(/^0/, "")}–{shortTime(s.ends_at)}
            {s.series_id ? <Repeat2 aria-label="Repeats" className="size-3" /> : null}
          </span>
          <span className="flex items-center gap-1">
            {warn.length ? <AlertTriangle aria-label="Warning" className="size-3 text-warn" /> : null}
            {asked ? <ArrowLeftRight aria-label="Change asked" className="size-3 text-warn" /> : null}
            {n ? (
              <span className="inline-flex items-center text-brand">
                <Hand aria-hidden="true" className="size-3" />
                {n}
              </span>
            ) : null}
          </span>
        </span>
        <span className="block truncate">{byClient ? (s.worker_id ? name.get(s.worker_id) : "No worker yet") : s.client_id ? clientName.get(s.client_id) : s.notes || "Shift"}</span>
        {s.service_id ? <span className="block truncate opacity-75">{serviceName.get(s.service_id)}</span> : null}
      </>
    );
    const cls = `block w-full rounded-md border-l-[3px] px-1.5 py-1 text-left text-[11px] leading-tight ${!s.worker_id ? "border-danger bg-danger-soft" : `border-brand ${BANDS[band][1]}`} ${s.status === "draft" ? "outline-dashed outline-1 -outline-offset-1 outline-brand" : ""}`;
    return selecting ? (
      <label key={s.id} className={`${cls} cursor-pointer has-[:checked]:ring-2 has-[:checked]:ring-brand`}>
        <input type="checkbox" form="pick" name="ids" value={s.id} className="mr-1 size-3 align-middle" />
        {inner}
      </label>
    ) : (
      <Link key={s.id} href={`${base}&shift=${s.id}`} scroll={false} title={[...warn].join("\n")} className={`${cls} hover:ring-2 hover:ring-brand`}>
        {inner}
      </Link>
    );
  };
  const close = base + (selecting ? "&select=1" : "");

  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        <span className="inline-flex overflow-hidden rounded-lg border border-line text-sm font-semibold">
          <Link href={`/roster?w=${monday}`} className={`px-3 py-1.5 ${byClient ? "text-muted hover:bg-page" : "bg-brand-soft text-brand"}`}>
            Staff
          </Link>
          <Link href={`/roster?w=${monday}&by=client`} className={`px-3 py-1.5 ${byClient ? "bg-brand-soft text-brand" : "text-muted hover:bg-page"}`}>
            Client
          </Link>
        </span>
        <Link href={`/roster?w=${thisMonday}${byClient ? "&by=client" : ""}`} className={buttonClass("outline")}>
          Today
        </Link>
        <Link href={`/roster?w=${addDays(monday, -7)}${byClient ? "&by=client" : ""}`} aria-label="Previous week" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Link>
        <Link href={`/roster?w=${addDays(monday, 7)}${byClient ? "&by=client" : ""}`} aria-label="Next week" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronRight aria-hidden="true" className="size-4" />
        </Link>
        <h1 className="heading text-xl">{weekLabel}</h1>
        <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${weeksAway === 0 ? "bg-brand-soft text-brand" : "bg-page ring-1 ring-line"}`}>
          {weeksAway === 0 ? "This week" : weeksAway > 0 ? `${weeksAway} week${weeksAway === 1 ? "" : "s"} ahead` : `${-weeksAway} week${weeksAway === -1 ? "" : "s"} ago`}
        </span>
        <span className="ml-auto flex flex-wrap items-center gap-2">
          {canEdit ? (
            <form action={publishWeek}>
              <input type="hidden" name="from" value={from} />
              <input type="hidden" name="to" value={to} />
              <button className={buttonClass("outline")} disabled={!drafts}>
                Publish shifts{drafts ? ` (${drafts})` : ""}
              </button>
            </form>
          ) : null}
          {canEdit ? (
            <Link href={`${base}&add=${today >= days[0] && today <= days[6] ? today : days[0]}`} scroll={false} className={buttonClass("primary")}>
              + Add shift
            </Link>
          ) : null}
          <Link href={`${base}&requests=1`} scroll={false} title="Shift change requests" aria-label={`Shift change requests${requests.length ? `: ${requests.length} waiting` : ""}`} className="relative rounded-lg border border-line p-2 hover:bg-page">
            <ArrowLeftRight aria-hidden="true" className="size-4" />
            {requests.length ? <span className="absolute -top-1.5 -right-1.5 grid size-5 place-items-center rounded-full bg-danger text-[10px] font-bold text-white">{requests.length}</span> : null}
          </Link>
          {canEdit ? (
            <Link href={selecting ? base : `${base}&select=1`} className={buttonClass(selecting ? "primary" : "outline")}>
              {selecting ? "Done selecting" : "Select shifts"}
            </Link>
          ) : null}
          <details className="relative">
            <summary aria-label="More" className="list-none rounded-lg border border-line p-2 hover:bg-page [&::-webkit-details-marker]:hidden">
              <MoreVertical aria-hidden="true" className="size-4" />
            </summary>
            <div className="absolute right-0 z-30 mt-1 w-64 overflow-hidden rounded-lg border border-line bg-surface shadow-lg">
              {canEdit ? <CopyWeekForm from={from} to={to} /> : null}
              <a href={`/roster/export?w=${monday}`} className="block px-3 py-2 text-sm font-semibold hover:bg-page">
                Export this week (CSV)
              </a>
              <Link href="/roster/timesheets" className="block px-3 py-2 text-sm font-semibold hover:bg-page">
                Timesheets
              </Link>
              <Link href="/settings/staff" className="block px-3 py-2 text-sm font-semibold hover:bg-page">
                Staff availability (on each staff page)
              </Link>
            </div>
          </details>
        </span>
      </div>
      <p className="flex flex-wrap gap-2 text-xs text-muted">
        <span className={`rounded-full px-2 py-0.5 font-semibold ${BANDS.day[1]}`}>Day 6am–6pm</span>
        <span className={`rounded-full px-2 py-0.5 font-semibold ${BANDS.eve[1]}`}>Evening 6–10pm</span>
        <span className={`rounded-full px-2 py-0.5 font-semibold ${BANDS.night[1]}`}>Night 10pm–6am</span>
        <span>Dashed: draft · ↻ repeats · ✋ hands up · ⇄ change asked</span>
        <span className="ml-auto">
          {shifts.length} shifts · {totalHours.toFixed(1)} rostered hours · {vacant.length} vacant
        </span>
      </p>

      <Card className="overflow-x-auto p-0">
        <table className="w-full min-w-[60rem] table-fixed border-collapse text-sm">
          <thead>
            <tr className="border-b border-line">
              <th scope="col" className="sticky left-0 z-10 w-48 border-r-[3px] border-line bg-page px-3 py-2 text-left text-xs font-semibold text-muted">
                {byClient ? "Client" : "Worker"}
              </th>
              {days.map((d, i) => (
                <th key={d} scope="col" className="border-r border-line px-1 py-2 text-center text-xs font-semibold text-muted">
                  {DAY_NAMES[i].toUpperCase()}
                  <span className={`mx-auto mt-0.5 block w-fit rounded-full px-1.5 font-display text-sm ${d === today ? "bg-brand text-brand-fg" : "text-ink"}`}>{Number(d.slice(8))}</span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            <tr className="border-b border-line">
              <th scope="row" className="sticky left-0 border-r-[3px] border-line bg-page px-3 py-2 text-left align-top">
                <span className="block text-sm font-semibold text-danger">Vacant shifts</span>
                <span className="text-xs text-muted">{vacant.reduce((n, s) => n + shiftHours(s), 0).toFixed(1)} hours not filled</span>
              </th>
              {days.map((d) => (
                <td key={d} className="border-r border-line px-1 py-1 align-top">
                  <div className="flex flex-col gap-1">{vacant.filter((s) => sydneyParts(s.starts_at).date === d).map(chip)}</div>
                </td>
              ))}
            </tr>
            {rowIds.map((k) => (
              <tr key={k} className="border-b border-line">
                <th scope="row" className="sticky left-0 border-r-[3px] border-line bg-page px-3 py-2 text-left align-top">
                  {byClient ? (
                    <span className="block text-sm font-semibold">{clientName.get(k) ?? "No client"}</span>
                  ) : (
                    <>
                      <span className="block text-sm font-semibold">{name.get(k) ?? "Staff member"}</span>
                      <span className={`text-xs ${(hoursOf.get(k) ?? 0) > 38 ? "font-semibold text-warn" : "text-muted"}`}>{(hoursOf.get(k) ?? 0).toFixed(1)} hours</span>
                      {expired.get(k)?.before.length ? <span className="mt-0.5 block w-fit rounded-full bg-danger-soft px-1.5 text-[10px] font-semibold text-danger">Check expired</span> : null}
                    </>
                  )}
                </th>
                {days.map((d) => {
                  const off = !byClient && onLeave(k, d);
                  return (
                    <td key={d} className={`border-r border-line px-1 py-1 align-top ${off ? "bg-[repeating-linear-gradient(135deg,transparent_0_6px,var(--line)_6px_7px)]" : ""}`}>
                      <div className="flex flex-col gap-1">
                        {off ? <span className="text-[11px] font-semibold text-muted">On leave</span> : null}
                        {shifts.filter((s) => (byClient ? (s.client_id ?? "none") === k && !!s.worker_id : s.worker_id === k) && sydneyParts(s.starts_at).date === d).map(chip)}
                        {canEdit && !off && !selecting ? (
                          <Link href={`${base}&add=${d}${byClient ? (k !== "none" ? `&client=${k}` : "") : `&worker=${k}`}`} scroll={false} aria-label="Add a shift" className="rounded-md text-center text-xs text-muted hover:bg-page hover:text-brand">
                            +
                          </Link>
                        ) : null}
                      </div>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
        {!shifts.length ? <p className="p-6 text-center text-sm text-muted">No shifts this week yet. Add one, or copy last week from the ⋮ menu.</p> : null}
      </Card>
      {selecting ? (
        <>
          <form id="pick" />
          <BulkBar formId="pick" workers={((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => ({ id: p.id, name: p.full_name || p.email }))} />
        </>
      ) : null}

      {/* Side panels: view, add/edit, change requests. */}
      {editing || opened || str("requests") === "1" ? (
        <>
          <Link href={close} scroll={false} aria-label="Close" className="fixed inset-0 z-40 bg-black/25" />
          <aside className="thin-scroll fixed inset-y-0 right-0 z-50 flex w-full max-w-xl flex-col overflow-y-auto bg-surface shadow-2xl">
            {str("requests") === "1" ? (
              <div className="flex flex-col gap-3 p-5">
                <div className="flex items-center justify-between">
                  <h2 className="heading-sm">Shift change requests</h2>
                  <Link href={close} scroll={false} className={buttonClass("outline")}>
                    Close
                  </Link>
                </div>
                {requests.length ? (
                  requests.map((r) => {
                    const s = shifts.find((x) => x.id === r.shift_id);
                    return (
                      <div key={r.id} className="flex flex-col gap-2 rounded-lg border border-line p-3 text-sm">
                        <p>
                          <b>{name.get(r.requested_by) ?? "A worker"}</b> {r.kind === "swap" ? <>wants to swap with <b>{name.get(r.swap_with ?? "") ?? "someone"}</b></> : "can't work this shift"}
                        </p>
                        {s ? (
                          <p className="text-muted">
                            {auDate(sydneyParts(s.starts_at).date)} · {shortTime(s.starts_at)}–{shortTime(s.ends_at)} · {s.client_id ? clientName.get(s.client_id) : "No client"}
                          </p>
                        ) : null}
                        <p>“{r.reason}”</p>
                        {r.kind === "swap" && r.swap_with && expired.get(r.swap_with)?.before.length ? <p className="rounded-md bg-danger-soft px-2 py-1 text-danger">Can&apos;t approve: {name.get(r.swap_with)} has an expired check ({expired.get(r.swap_with)!.before.join(", ")}).</p> : null}
                        {canEdit ? (
                          <div className="flex gap-2">
                            {(["approved", "declined"] as const).map((st) => (
                              <form key={st} action={decideRequest}>
                                <input type="hidden" name="id" value={r.id} />
                                <input type="hidden" name="status" value={st} />
                                <button className={buttonClass(st === "approved" ? "primary" : "outline")}>{st === "approved" ? (r.kind === "swap" ? "Approve (moves the shift)" : "Approve (opens the shift)") : "Decline"}</button>
                              </form>
                            ))}
                          </div>
                        ) : null}
                      </div>
                    );
                  })
                ) : (
                  <p className="text-sm text-muted">No requests waiting.</p>
                )}
              </div>
            ) : editing ? (
              <div className="flex flex-col gap-3 p-5">
                <div className="flex items-center justify-between gap-2">
                  <h2 className="heading-sm">{opened ? "Change shift" : "Add shift"}</h2>
                  <span className="flex gap-2">
                    {opened ? (
                      <Link href={`${base}&shift=${opened.id}`} scroll={false} className={buttonClass("outline")}>
                        Back
                      </Link>
                    ) : null}
                    <Link href={close} scroll={false} className={buttonClass("outline")}>
                      Close
                    </Link>
                  </span>
                </div>
                <ShiftForm
                  key={opened?.id ?? str("add")}
                  shift={draft}
                  workers={workerFit}
                  clients={((clients ?? []) as { id: string; name: string }[]).map((c) => ({ id: c.id, name: c.name }))}
                  locations={((locations ?? []) as { id: string; client_id: string; label: string; address: string }[]).map((l) => ({ id: l.id, client_id: l.client_id, name: `${l.label}: ${l.address}` }))}
                  services={((services ?? []) as { id: string; client_id: string; label: string }[]).map((v) => ({ id: v.id, client_id: v.client_id, name: v.label }))}
                />
              </div>
            ) : opened ? (
              <div className="flex flex-col">
                <div className="sticky top-0 z-10 flex flex-col gap-1 border-b border-line bg-surface p-5 pb-0">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-semibold">
                        {auDate(sydneyParts(opened.starts_at).date)} · {shortTime(opened.starts_at)} – {shortTime(opened.ends_at)}{" "}
                        <span className="font-normal text-muted">({shiftHours(opened).toFixed(1)} h)</span>
                      </p>
                      <p className="text-sm text-muted">
                        {opened.client_id ? clientName.get(opened.client_id) : "No client"} · {opened.worker_id ? name.get(opened.worker_id) : "Vacant"}
                        {opened.status === "draft" ? " · draft" : ""}
                        {opened.series_id ? " · repeats" : ""}
                      </p>
                    </div>
                    <span className="flex gap-2">
                      {canEdit ? (
                        <Link href={`${base}&shift=${opened.id}&edit=1`} scroll={false} className={buttonClass("primary")}>
                          Edit
                        </Link>
                      ) : null}
                      <Link href={close} scroll={false} className={buttonClass("outline")}>
                        Close
                      </Link>
                    </span>
                  </div>
                  <nav className="mt-2 flex gap-1">
                    {(["details", "timesheet", "log"] as const).map((t) => (
                      <Link key={t} href={`${base}&shift=${opened.id}${t === "details" ? "" : `&tab=${t}`}`} scroll={false} className={`-mb-px border-b-2 px-3 py-2 text-sm font-semibold ${tab === t ? "border-brand" : "border-transparent text-muted"}`}>
                        {t === "details" ? "Details" : t === "timesheet" ? "Timesheet" : "Log"}
                      </Link>
                    ))}
                  </nav>
                </div>
                <div className="flex flex-col gap-3 p-5 text-sm">
                  {tab === "details" ? (
                    <>
                      <dl className="grid grid-cols-[8rem_1fr] gap-x-4 gap-y-1.5">
                        <dt className="text-muted">Client</dt>
                        <dd>{opened.client_id ? clientName.get(opened.client_id) : "No client"}</dd>
                        <dt className="text-muted">Service</dt>
                        <dd>{opened.service_id ? serviceName.get(opened.service_id) : "Not set"}</dd>
                        <dt className="text-muted">Location</dt>
                        <dd>{opened.location_id ? locName.get(opened.location_id) : "Not set"}</dd>
                        <dt className="text-muted">Band</dt>
                        <dd>
                          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${BANDS[bandOf(opened.starts_at, opened.ends_at)][1]}`}>{BANDS[bandOf(opened.starts_at, opened.ends_at)][0]}</span>
                        </dd>
                        <dt className="text-muted">Paid hours</dt>
                        <dd>
                          {shiftHours(opened).toFixed(2)} (break {opened.break_minutes} min)
                        </dd>
                        <dt className="text-muted">Worker</dt>
                        <dd>{opened.worker_id ? `${name.get(opened.worker_id)} · ${(hoursOf.get(opened.worker_id) ?? 0).toFixed(1)} of 38 h this week` : "Vacant"}</dd>
                        <dt className="text-muted">Instructions</dt>
                        <dd className="whitespace-pre-line">{opened.notes || "None"}</dd>
                      </dl>
                      {warningsFor(opened).map((w) => (
                        <p key={w} className="rounded-md bg-warn-soft px-2 py-1">
                          {w}
                        </p>
                      ))}
                      {!opened.worker_id && hands(opened.id).length ? (
                        <div className="flex flex-col gap-1">
                          <h3 className="font-semibold">Put their hand up</h3>
                          {hands(opened.id).map((h) => (
                            <form key={h.user_id} action={giveOpenShift} className="flex items-center gap-2">
                              <input type="hidden" name="id" value={opened.id} />
                              <input type="hidden" name="worker_id" value={h.user_id} />
                              <span className="flex-1">{name.get(h.user_id) ?? "Staff member"}</span>
                              {canEdit ? <button className={buttonClass("outline")}>Give it to them</button> : null}
                            </form>
                          ))}
                        </div>
                      ) : null}
                      {canEdit ? (
                        <div className="flex flex-wrap gap-2 border-t border-line pt-3">
                          <form action={cancelShift}>
                            <input type="hidden" name="id" value={opened.id} />
                            <button className="text-sm font-semibold text-danger underline">Cancel this shift</button>
                          </form>
                          {opened.series_id ? (
                            <form action={endRepeat}>
                              <input type="hidden" name="id" value={opened.id} />
                              <button className="text-sm font-semibold text-brand underline">End the repeat after this shift</button>
                            </form>
                          ) : null}
                          <span className="text-xs text-muted">Shifts are never deleted: cancelled ones stay in the log.</span>
                        </div>
                      ) : null}
                    </>
                  ) : tab === "timesheet" ? (
                    sheet ? (
                      <dl className="grid grid-cols-[8rem_1fr] gap-x-4 gap-y-1.5">
                        <dt className="text-muted">Rostered</dt>
                        <dd>
                          {shortTime(opened.starts_at)}–{shortTime(opened.ends_at)} · {shiftHours(opened).toFixed(2)} h
                        </dd>
                        <dt className="text-muted">Worked</dt>
                        <dd>
                          {shortTime(sheet.actual_start)}–{shortTime(sheet.actual_end)} · {shiftHours({ starts_at: sheet.actual_start, ends_at: sheet.actual_end, break_minutes: sheet.break_minutes }).toFixed(2)} h
                        </dd>
                        <dt className="text-muted">Extras</dt>
                        <dd>{[(sheet.allowances ?? []).join(", "), Number(sheet.km) ? `${sheet.km} km` : "", Number(sheet.expense) ? `$${Number(sheet.expense).toFixed(2)}` : ""].filter(Boolean).join(" · ") || "None"}</dd>
                        <dt className="text-muted">Note</dt>
                        <dd>{sheet.note || "None"}</dd>
                        <dt className="text-muted">Status</dt>
                        <dd>{sheet.status === "approved" ? "Approved" : sheet.status === "queried" ? "Queried" : "Waiting for approval"}</dd>
                        <dd className="col-span-2">
                          <Link href={`/roster/timesheets?w=${monday}&edit=${opened.id}`} className="font-semibold text-brand underline">
                            Open in Timesheets
                          </Link>
                        </dd>
                      </dl>
                    ) : (
                      <p className="text-muted">The worker sends their actual times after the shift. Nothing yet.</p>
                    )
                  ) : (events ?? []).length ? (
                    <ol className="flex flex-col gap-2 border-l-2 border-line pl-3">
                      {((events ?? []) as { id: number; actor: string | null; happened_at: string; summary: string }[]).map((e) => (
                        <li key={e.id}>
                          <b>{e.actor ? (name.get(e.actor) ?? "Someone") : "The portal"}</b> {e.summary}.
                          <span className="block text-xs text-muted">{new Date(e.happened_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}</span>
                        </li>
                      ))}
                    </ol>
                  ) : (
                    <p className="text-muted">No changes recorded yet.</p>
                  )}
                </div>
              </div>
            ) : null}
          </aside>
        </>
      ) : null}
    </>
  );
}

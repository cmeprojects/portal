// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { AlertTriangle, ArrowLeftRight, ChevronLeft, ChevronRight, Hand, MoreVertical, Plus, Repeat2 } from "lucide-react";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { addDays, mondayOf, shiftHours, sydneyInstant, sydneyParts, sydneyToday } from "@/lib/sydney-time";
import { BANDS, availabilitySlot, bandOf, shiftTypeLabel, shortTime } from "@/lib/roster";
import { addShiftNote, cancelShift, decideRequest, endRepeat, giveOpenShift, makeOpenShift, switchOffTemplate, voidSignature } from "./actions";
import { BulkBar, CopyWeekForm, ShiftForm, type ShiftDraft, type WorkerFit } from "./shift-form";
import { PublishControl, type PublishPeriod } from "./publish-control";
import { Spotlight } from "./spotlight";

export const metadata: Metadata = { title: "Roster" };

type Shift = { id: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string; status: string; series_id: string | null;
  // update 128 (absent before it runs)
  ref?: string; shift_type?: string; vehicle_id?: string | null; pay_group?: string; allowances?: string[]; needs_worker_signature?: boolean; needs_client_signature?: boolean;
  created_by?: string | null; created_at?: string; updated_by?: string | null; updated_at?: string; notified_at?: string | null };
type Req = { id: string; shift_id: string; requested_by: string; kind: string; swap_with: string | null; reason: string; created_at: string };
const DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
// cmeprojects: shift colours by status (label, chip style).
const STATUS_STYLE = {
  vacant: ["Vacant", "border-danger bg-danger-soft"],
  draft: ["Draft", "border-muted bg-page outline-dashed outline-1 -outline-offset-1 outline-muted"],
  waiting: ["Published, waiting for answer", "border-warn bg-warn-soft"],
  accepted: ["Accepted", "border-good bg-good-soft"],
  declined: ["Declined", "border-danger bg-surface ring-1 ring-danger"],
  done: ["Finished", "border-line bg-page opacity-75"],
} as const;
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
  // cmeprojects (update 129): Day, Week or Month, around one date.
  const view: "day" | "week" | "fortnight" | "month" = str("v") === "day" ? "day" : str("v") === "fortnight" ? "fortnight" : str("v") === "month" ? "month" : "week";
  const isDate = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v);
  const anchor = isDate(str("d")) ? str("d") : isDate(str("w")) ? str("w") : today;
  const monday = mondayOf(anchor);
  const monthStart = `${anchor.slice(0, 7)}-01`;
  const nextMonthStart = (() => {
    const [y, m] = anchor.slice(0, 7).split("-").map(Number);
    return m === 12 ? `${y + 1}-01-01` : `${y}-${String(m + 1).padStart(2, "0")}-01`;
  })();
  const prevMonthStart = (() => {
    const [y, m] = anchor.slice(0, 7).split("-").map(Number);
    return m === 1 ? `${y - 1}-12-01` : `${y}-${String(m - 1).padStart(2, "0")}-01`;
  })();
  const gridStart = view === "day" ? anchor : view === "month" ? monthStart : monday;
  const gridEnd = view === "day" ? addDays(anchor, 1) : view === "month" ? nextMonthStart : addDays(monday, view === "fortnight" ? 14 : 7);
  // Every day shown, as columns (workers or clients stay on the left in every view).
  const days = Array.from({ length: Math.round((Date.parse(`${gridEnd}T12:00:00Z`) - Date.parse(`${gridStart}T12:00:00Z`)) / 86_400_000) }, (_, i) => addDays(gridStart, i));
  const compact = days.length > 7;
  const from = sydneyInstant(gridStart);
  const to = sydneyInstant(gridEnd);
  const byClient = str("by") === "client";
  const selecting = canEdit && str("select") === "1";
  const viewQ = `${view === "week" ? "" : `v=${view}&`}d=${anchor}`;
  const base = `/roster?${viewQ}${byClient ? "&by=client" : ""}`;
  const go = (d: string, v: string = view) => `/roster?${v === "week" ? "" : `v=${v}&`}d=${d}${byClient ? "&by=client" : ""}`;
  const supabase = await createClient();
  type Tpl = { id: string; name: string; shift_type: string; start_time: string; end_time: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string; allowances: string[]; pay_group: string; needs_worker_signature: boolean; needs_client_signature: boolean };
  const [shiftsRes, { data: people }, { data: clients }, { data: locations }, { data: services }, { data: leave }, { data: interest }, { data: availRows }, { data: checks }, reqRes, { data: cars }] = await Promise.all([
    supabase.from("shifts").select("*").neq("status", "cancelled").gte("starts_at", from).lt("starts_at", to).order("starts_at"),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).not("role", "in", "(new_starter,system_admin,external)").order("full_name"),
    supabase.from("car_clients").select("id, name, status").neq("status", "discharged").order("name"),
    supabase.from("client_locations").select("id, client_id, label, address").eq("approved", true),
    supabase.from("client_services").select("id, client_id, label").neq("status", "ended"),
    supabase.from("leave_periods").select("user_id, start_date, end_date").lte("start_date", addDays(gridEnd, 6)).gte("end_date", gridStart),
    supabase.from("shift_interest").select("shift_id, user_id"),
    supabase.from("staff_private").select("user_id, availability"),
    supabase.rpc("roster_check_dates"),
    supabase.from("shift_change_requests").select("id, shift_id, requested_by, kind, swap_with, reason, created_at").eq("status", "pending").order("created_at"),
    // cmeprojects (update 128): company cars from the Cars module (only those this person may see).
    supabase.from("cars").select("id, name, rego").eq("active", true).order("name"),
  ]);
  // cmeprojects (update 129): shift templates (people who roster; empty before it runs).
  const templates = canEdit ? (((await supabase.from("shift_templates").select("*").eq("active", true).order("name")).data ?? []) as Tpl[]) : [];
  const tpl = templates.find((t) => t.id === str("tpl"));
  // cmeprojects: periods that can be published (the view on screen first), with their drafts and workers told.
  const span = (a: string, b: string) => `${auDate(a)} – ${auDate(addDays(b, -1))} ${addDays(b, -1).slice(0, 4)}`;
  const periodDefs: [string, string, string, string][] = [
    ["current", view === "day" ? "This day" : view === "month" ? "This month" : view === "fortnight" ? "This fortnight" : "This week", gridStart, gridEnd],
    ["next_week", "Next week", addDays(monday, 7), addDays(monday, 14)],
    ["next_fortnight", "Next fortnight", addDays(monday, 7), addDays(monday, 21)],
    ["this_month", "This month", monthStart, nextMonthStart],
    ["next_month", "Next month", nextMonthStart, (() => { const [y, m] = nextMonthStart.split("-").map(Number); return m === 12 ? `${y + 1}-01-01` : `${y}-${String(m + 1).padStart(2, "0")}-01`; })()],
  ];
  const rangeFrom = periodDefs.map((d) => d[2]).sort()[0];
  const rangeTo = periodDefs.map((d) => d[3]).sort().slice(-1)[0];
  const { data: draftRows } = canEdit
    ? await supabase.from("shifts").select("starts_at, worker_id").eq("status", "draft").gte("starts_at", sydneyInstant(rangeFrom)).lt("starts_at", sydneyInstant(rangeTo))
    : { data: [] };
  const draftList = (draftRows ?? []) as { starts_at: string; worker_id: string | null }[];
  const publishPeriods: PublishPeriod[] = periodDefs
    .filter(([k, , a, b], i) => k === "current" || !(a === gridStart && b === gridEnd) || i === 0)
    .map(([key, label, a, b]) => {
      const inside = draftList.filter((x) => { const d = sydneyParts(x.starts_at).date; return d >= a && d < b; });
      return { key, label, dates: span(a, b), from: sydneyInstant(a), to: sydneyInstant(b), drafts: inside.length, workers: new Set(inside.map((x) => x.worker_id).filter(Boolean)).size };
    });
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
  // cmeprojects (update 128): which published shifts the worker has answered (empty before it runs).
  const { data: answerRows } = shifts.length ? await supabase.from("shift_responses").select("shift_id, response").in("shift_id", shifts.map((x) => x.id)) : { data: [] };
  const answerOf = new Map(((answerRows ?? []) as { shift_id: string; response: string }[]).map((r) => [r.shift_id, r.response]));
  const answered = new Set(answerOf.keys());
  // cmeprojects: one status per shift, for its colour.
  const nowAt = Date.parse(new Date().toISOString());
  const statusOf = (x: Shift): keyof typeof STATUS_STYLE =>
    !x.worker_id ? "vacant" : x.status === "draft" ? "draft" : Date.parse(x.ends_at) < nowAt ? "done" : answerOf.get(x.id) === "declined" ? "declined" : answerOf.get(x.id) === "accepted" ? "accepted" : "waiting";
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
  // cmeprojects: every rosterable staff member (or every active client) gets a row, shifts or not.
  const rowIds = byClient
    ? [
        ...new Set([
          ...((clients ?? []) as { id: string; status: string }[]).filter((c) => c.status === "active").map((c) => c.id),
          ...shifts.filter((s) => !!s.worker_id).map((s) => s.client_id ?? "none"),
        ]),
      ].sort((a, b) => (clientName.get(a) ?? "~").localeCompare(clientName.get(b) ?? "~"))
    : [
        ...new Set([
          ...((people ?? []) as { id: string }[]).map((p) => p.id),
          ...shifts.map((s) => s.worker_id).filter((v): v is string => !!v),
        ]),
      ].sort((a, b) => (name.get(a) ?? "").localeCompare(name.get(b) ?? ""));
  const totalHours = shifts.filter((s) => s.worker_id).reduce((n, s) => n + shiftHours(s), 0);
  const opened = str("shift") ? shifts.find((s) => s.id === str("shift")) ?? (await supabase.from("shifts").select("*").eq("id", str("shift")).maybeSingle()).data as Shift | null : null;
  const editing = canEdit && (str("add") || (opened && str("edit") === "1"));
  const tab = str("tab") === "log" ? "logs" : ["details", "events", "signatures", "trips", "timesheet", "logs"].includes(str("tab")) ? str("tab") : "details";
  const weekLabel =
    view === "day"
      ? new Date(`${anchor}T12:00:00Z`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short", year: "numeric", timeZone: "UTC" })
      : view === "month"
        ? new Date(`${monthStart}T12:00:00Z`).toLocaleDateString("en-AU", { month: "long", year: "numeric", timeZone: "UTC" })
        : `${auDate(days[0])} – ${auDate(days[days.length - 1])} ${days[days.length - 1].slice(0, 4)}`;
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
        shift_type: opened.shift_type ?? "standard",
        vehicle_id: opened.vehicle_id ?? "",
        pay_group: opened.pay_group ?? "",
        allowances: opened.allowances ?? [],
        needs_worker_signature: !!opened.needs_worker_signature,
        needs_client_signature: !!opened.needs_client_signature,
      }
    : tpl
      ? { date: fitDay, start: tpl.start_time.slice(0, 5), end: tpl.end_time.slice(0, 5), nextDay: tpl.end_time <= tpl.start_time, break_minutes: tpl.break_minutes, worker_id: str("worker"), client_id: tpl.client_id ?? str("client"), location_id: tpl.location_id ?? "", service_id: tpl.service_id ?? "", notes: tpl.notes, status: "draft", series: false, shift_type: tpl.shift_type, vehicle_id: "", pay_group: tpl.pay_group, allowances: tpl.allowances, needs_worker_signature: tpl.needs_worker_signature, needs_client_signature: tpl.needs_client_signature }
      : { date: fitDay, start: "09:00", end: "15:00", nextDay: false, break_minutes: 0, worker_id: str("worker"), client_id: str("client"), location_id: "", service_id: "", notes: "", status: "draft", series: false, shift_type: "standard", vehicle_id: "", pay_group: "", allowances: [], needs_worker_signature: false, needs_client_signature: false };

  // The opened shift's timesheet and log.
  const [{ data: sheet }, { data: events }, { data: sigRows }, { data: tripRows }, { data: noteRows }, { data: response }] = opened && !editing
    ? await Promise.all([
        supabase.from("shift_timesheets").select("actual_start, actual_end, break_minutes, km, expense, allowances, note, status").eq("shift_id", opened.id).maybeSingle(),
        supabase.from("shift_events").select("*").eq("shift_id", opened.id).order("happened_at", { ascending: false }).limit(200),
        // cmeprojects (update 128): signatures, Cars trips, internal notes and the worker's answer (empty before it runs).
        supabase.from("shift_signatures").select("id, kind, signer_name, signer_role, signature, captured_by, signed_at, voided_at, voided_by, void_reason").eq("shift_id", opened.id).order("signed_at"),
        supabase.from("car_trips").select("id, car_id, driver_id, started_at, returned_at, km, went_to, purpose").eq("shift_id", opened.id).order("started_at"),
        supabase.from("shift_notes").select("id, author_id, body, created_at").eq("shift_id", opened.id).order("created_at"),
        supabase.from("shift_responses").select("response, note, responded_at").eq("shift_id", opened.id).maybeSingle(),
      ])
    : [{ data: null }, { data: null }, { data: null }, { data: null }, { data: null }, { data: null }];
  type Ev = { id: number; actor: string | null; happened_at: string; summary: string; kind?: string; field?: string | null; old_value?: string | null; new_value?: string | null; source?: string; reason?: string | null };
  const evs = (events ?? []) as Ev[];
  const sigs = (sigRows ?? []) as { id: string; kind: string; signer_name: string; signer_role: string; signature: string; captured_by: string | null; signed_at: string; voided_at: string | null; voided_by: string | null; void_reason: string | null }[];
  const trips = (tripRows ?? []) as { id: number; car_id: string; driver_id: string | null; started_at: string; returned_at: string | null; km: number | null; went_to: string | null; purpose: string | null }[];
  const shiftNotes = (noteRows ?? []) as { id: string; author_id: string | null; body: string; created_at: string }[];
  const answer = response as { response: string; note: string; responded_at: string } | null;
  const carName = new Map(((cars ?? []) as { id: string; name: string; rego: string }[]).map((c) => [c.id, `${c.name} (${c.rego})`]));
  // cmeprojects: the opened shift's client: address, alerts and how to support them (only what this person may see).
  type ClientCard = {
    ref: string | null;
    status: string | null;
    address: string | null;
    access: string | null;
    alerts: { id: string; title: string; severity: string; worker_instructions: string | null }[];
    instructions: { id: string; title: string; instructions: string }[];
  };
  let clientCard: ClientCard | null = null;
  if (opened?.client_id && !editing && tab === "details") {
    const [{ data: c }, { data: loc }, { data: det }, { data: al }, { data: wi }] = await Promise.all([
      supabase.from("car_clients").select("client_ref, status").eq("id", opened.client_id).maybeSingle(),
      opened.location_id ? supabase.from("client_locations").select("address, suburb, access_notes").eq("id", opened.location_id).maybeSingle() : Promise.resolve({ data: null }),
      supabase.from("client_details").select("home_address").eq("client_id", opened.client_id).maybeSingle(),
      supabase.from("client_alerts").select("id, title, severity, worker_instructions").eq("client_id", opened.client_id).eq("active", true),
      supabase.from("client_worker_instructions").select("id, title, instructions").eq("client_id", opened.client_id).eq("active", true).order("sort_order"),
    ]);
    const l = loc as { address: string; suburb: string | null; access_notes: string | null } | null;
    clientCard = {
      ref: (c as { client_ref: string | null } | null)?.client_ref ?? null,
      status: (c as { status: string | null } | null)?.status ?? null,
      address: l ? `${l.address}${l.suburb ? `, ${l.suburb}` : ""}` : ((det as { home_address: string | null } | null)?.home_address ?? null),
      access: l?.access_notes ?? null,
      alerts: (al ?? []) as ClientCard["alerts"],
      instructions: (wi ?? []) as ClientCard["instructions"],
    };
  }
  const actorIds = [...new Set([...evs.map((e) => e.actor), ...sigs.map((x) => x.captured_by), ...shiftNotes.map((x) => x.author_id), ...trips.map((t) => t.driver_id), opened?.created_by ?? null, opened?.updated_by ?? null].filter((v): v is string => !!v && !name.has(v)))];
  const { data: actors } = actorIds.length ? await supabase.from("profiles").select("id, full_name, email").in("id", actorIds) : { data: [] };
  for (const a of (actors ?? []) as { id: string; full_name: string | null; email: string }[]) name.set(a.id, a.full_name || a.email);

  const chip = (s: Shift) => {
    const warn = warningsFor(s);
    const n = hands(s.id).length;
    const asked = requests.some((r) => r.shift_id === s.id);
    const band = bandOf(s.starts_at, s.ends_at);
    const inner = (
      <>
        <span className="flex items-center justify-between gap-1 font-semibold">
          <span className="flex items-center gap-1">
            {compact ? shortTime(s.starts_at) : `${shortTime(s.starts_at)}–${shortTime(s.ends_at)}`}
            {band !== "day" ? <span className="rounded bg-ink/10 px-1 text-[9px] font-semibold">{band === "night" ? "Night" : "Eve"}</span> : null}
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
        {s.service_id && !compact ? <span className="block truncate opacity-75">{serviceName.get(s.service_id)}</span> : null}
      </>
    );
    const cls = `block w-full rounded-md border-l-[3px] px-1.5 py-1 text-left ${compact ? "text-[10px]" : "text-[11px]"} leading-tight ${STATUS_STYLE[statusOf(s)][1]}`;
    return selecting ? (
      <label key={s.id} data-shift-id={s.id} className={`${cls} cursor-pointer has-[:checked]:ring-2 has-[:checked]:ring-brand`}>
        <input type="checkbox" form="pick" name="ids" value={s.id} className="mr-1 size-3 align-middle" />
        {inner}
      </label>
    ) : (
      <Link key={s.id} data-shift-id={s.id} href={`${base}&shift=${s.id}`} scroll={false} title={[...warn].join("\n")} className={`${cls} hover:ring-2 hover:ring-brand`}>
        {inner}
      </Link>
    );
  };
  const close = base + (selecting ? "&select=1" : "");
  // Closing a shift's panel spotlights that shift so you can see where it is.
  const closePanel = opened && !editing ? `${close}&spot=${opened.id}&spotlabel=seen` : close;

  return (
    <>
      <span data-wide hidden />
      <PageHeader title="Rostering" intro="Plan, publish and track shifts. Click a shift to see its details, events, signatures and log." />
      {/^[0-9a-f-]{36}$/.test(str("spot")) ? <Spotlight id={str("spot")} label={str("spotlabel") === "added" ? "Just added" : str("spotlabel") === "changed" ? "Just changed" : "You were here"} /> : null}
      {str("saved") ? <p role="status" className="rounded-lg bg-good-soft px-3 py-2 text-sm font-semibold">{str("saved")}</p> : null}
      {/* cmeprojects (update 128): the week in numbers, from the shifts shown. */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 xl:grid-cols-8">
        {(
          [
            ["Shifts", String(shifts.length), ""],
            ["Rostered hours", totalHours.toFixed(1), ""],
            ["Filled", String(shifts.filter((x) => x.worker_id).length), ""],
            ["Vacant", String(vacant.length), vacant.length ? "text-danger" : ""],
            ["Drafts", String(shifts.filter((x) => x.status === "draft").length), ""],
            ["Published", String(shifts.filter((x) => x.status === "published").length), ""],
            ["Waiting for answer", String(shifts.filter((x) => x.status === "published" && x.worker_id && !answered.has(x.id)).length), ""],
            ["Warnings", String(shifts.filter((x) => warningsFor(x).length).length), shifts.some((x) => warningsFor(x).length) ? "text-warn" : ""],
          ] as [string, string, string][]
        ).map(([l, v, c]) => (
          <div key={l} className="rounded-lg border border-line bg-surface px-3 py-2">
            <p className="text-xs text-muted">{l}</p>
            <p className={`text-lg font-semibold ${c}`}>{v}</p>
          </div>
        ))}
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <span className="inline-flex overflow-hidden rounded-lg border border-line text-sm font-semibold">
          <Link href={`/roster?${viewQ}`} className={`px-3 py-1.5 ${byClient ? "text-muted hover:bg-page" : "bg-brand-soft text-brand"}`}>
            Staff
          </Link>
          <Link href={`/roster?${viewQ}&by=client`} className={`px-3 py-1.5 ${byClient ? "bg-brand-soft text-brand" : "text-muted hover:bg-page"}`}>
            Client
          </Link>
        </span>
        <span className="inline-flex overflow-hidden rounded-lg border border-line text-sm font-semibold">
          {(["day", "week", "fortnight", "month"] as const).map((v) => (
            <Link key={v} href={go(anchor, v)} className={`px-3 py-1.5 ${view === v ? "bg-brand-soft text-brand" : "text-muted hover:bg-page"}`}>
              {v[0].toUpperCase() + v.slice(1)}
            </Link>
          ))}
        </span>
        <Link href={go(today)} className={buttonClass("outline")}>
          Today
        </Link>
        {/* The week shown, between its arrows, in one box the height of the buttons. */}
        <span className="inline-flex min-h-11 items-stretch overflow-hidden rounded-lg border border-line bg-surface md:min-h-10">
          <Link href={go(view === "day" ? addDays(anchor, -1) : view === "month" ? prevMonthStart : addDays(monday, view === "fortnight" ? -14 : -7))} aria-label={`Previous ${view}`} className="flex items-center border-r border-line px-2.5 hover:bg-page">
            <ChevronLeft aria-hidden="true" className="size-4" />
          </Link>
          <span className="flex min-w-60 items-center justify-center gap-2 px-3">
            <span className="text-sm font-semibold">{weekLabel}</span>
            {view === "week" ? (
              <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${weeksAway === 0 ? "bg-brand-soft text-brand" : "bg-page ring-1 ring-line"}`}>
                {weeksAway === 0 ? "This week" : weeksAway > 0 ? `${weeksAway} week${weeksAway === 1 ? "" : "s"} ahead` : `${-weeksAway} week${weeksAway === -1 ? "" : "s"} ago`}
              </span>
            ) : (view === "day" ? anchor === today : monthStart === `${today.slice(0, 7)}-01`) ? (
              <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">{view === "day" ? "Today" : "This month"}</span>
            ) : null}
          </span>
          <Link href={go(view === "day" ? addDays(anchor, 1) : view === "month" ? nextMonthStart : addDays(monday, view === "fortnight" ? 14 : 7))} aria-label={`Next ${view}`} className="flex items-center border-l border-line px-2.5 hover:bg-page">
            <ChevronRight aria-hidden="true" className="size-4" />
          </Link>
        </span>
        <span className="ml-auto flex flex-wrap items-center gap-2">
          {canEdit ? (
            <PublishControl periods={publishPeriods} />
          ) : null}
          {canEdit ? (
            <Link href={`${base}&add=${today >= gridStart && today < gridEnd ? today : view === "month" ? monthStart : days[0]}`} scroll={false} className={buttonClass("primary")}>
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
              {canEdit ? (
                <Link href={`${base}&templates=1`} scroll={false} className="block px-3 py-2 text-sm font-semibold hover:bg-page">
                  Shift templates
                </Link>
              ) : null}
              <Link href="/settings/staff" className="block px-3 py-2 text-sm font-semibold hover:bg-page">
                Staff availability (on each staff page)
              </Link>
            </div>
          </details>
        </span>
      </div>
      <p className="flex flex-wrap gap-2 text-xs text-muted">
        {(Object.keys(STATUS_STYLE) as (keyof typeof STATUS_STYLE)[]).map((k) => (
          <span key={k} className={`rounded-md border-l-[3px] px-2 py-0.5 font-semibold text-ink ${STATUS_STYLE[k][1]}`}>
            {STATUS_STYLE[k][0]}
          </span>
        ))}
        <span>Eve 6–10pm · Night 10pm–6am · ↻ repeats · ✋ hands up · ⇄ change asked</span>
        <span className="ml-auto">{shifts.length ? "" : "No shifts this week"}</span>
      </p>

      <Card className="roster-grid overflow-x-auto p-0">
        <table className="w-full table-fixed border-collapse text-sm" style={{ minWidth: `${12 + days.length * (view === "day" ? 18 : compact ? 6.5 : 7.5)}rem` }}>
          <thead>
            <tr className="border-b border-line">
              <th scope="col" className="sticky left-0 z-10 w-48 border-r-[3px] border-line bg-page px-3 py-2 text-left text-xs font-semibold text-muted">
                {byClient ? "Client" : "Worker"}
              </th>
              {days.map((d) => (
                <th key={d} scope="col" className={`border-r border-line px-1 py-2 text-center text-xs font-semibold text-muted ${compact && (new Date(`${d}T12:00:00Z`).getUTCDay() % 6 === 0) ? "bg-page" : ""}`}>
                  {compact ? DAY_NAMES[(new Date(`${d}T12:00:00Z`).getUTCDay() + 6) % 7].slice(0, 2) : DAY_NAMES[(new Date(`${d}T12:00:00Z`).getUTCDay() + 6) % 7].toUpperCase()}
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
                <td key={d} className="group border-r border-line px-1 py-1 align-top hover:bg-page/60">
                  <div className="flex flex-col gap-1">
                    {vacant.filter((s) => sydneyParts(s.starts_at).date === d).map(chip)}
                    {canEdit && !selecting && !byClient ? (
                      <Link
                        href={`${base}&add=${d}`}
                        scroll={false}
                        aria-label={`Add an open shift on ${auDate(d)}`}
                        title="Add an open shift (no worker yet)"
                        className="flex min-h-7 items-center justify-center gap-1 rounded-md border border-dashed border-transparent text-xs font-semibold text-muted transition group-hover:border-danger group-hover:bg-danger-soft group-hover:text-danger focus-visible:border-danger [@media(hover:none)]:border-line"
                      >
                        <Plus aria-hidden="true" className="size-3.5" />
                        <span className="hidden group-hover:inline">{compact ? "" : "Open shift"}</span>
                      </Link>
                    ) : null}
                  </div>
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
                    <td key={d} className={`group border-r border-line px-1 py-1 align-top hover:bg-page/60 ${off ? "bg-[repeating-linear-gradient(135deg,transparent_0_6px,var(--line)_6px_7px)]" : ""}`}>
                      <div className="flex flex-col gap-1">
                        {off ? <span className="text-[11px] font-semibold text-muted">On leave</span> : null}
                        {shifts.filter((s) => (byClient ? (s.client_id ?? "none") === k && !!s.worker_id : s.worker_id === k) && sydneyParts(s.starts_at).date === d).map(chip)}
                        {canEdit && !off && !selecting ? (
                          <Link
                            href={`${base}&add=${d}${byClient ? (k !== "none" ? `&client=${k}` : "") : `&worker=${k}`}`}
                            scroll={false}
                            aria-label={`Add a shift for ${byClient ? (clientName.get(k) ?? "this client") : (name.get(k) ?? "this worker")} on ${auDate(d)}`}
                            title="Add a shift"
                            className="flex min-h-7 items-center justify-center gap-1 rounded-md border border-dashed border-transparent text-xs font-semibold text-muted transition group-hover:border-brand group-hover:bg-brand-soft group-hover:text-brand focus-visible:border-brand [@media(hover:none)]:border-line"
                          >
                            <Plus aria-hidden="true" className="size-3.5" />
                            <span className="hidden group-hover:inline">{compact ? "" : "Add shift"}</span>
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
      {editing || opened || str("requests") === "1" || (canEdit && str("templates") === "1") ? (
        <>
          <Link href={closePanel} scroll={false} aria-label="Close" className="fixed inset-0 z-40 bg-black/25" />
          <aside className="thin-scroll fixed inset-y-0 right-0 z-50 flex w-full max-w-xl flex-col overflow-y-auto bg-surface shadow-2xl">
            {canEdit && str("templates") === "1" && !editing && !opened ? (
              <div className="flex flex-col gap-3 p-5">
                <div className="flex items-center justify-between">
                  <h2 className="heading-sm">Shift templates</h2>
                  <Link href={closePanel} scroll={false} className={buttonClass("outline")}>
                    Close
                  </Link>
                </div>
                <p className="text-sm text-muted">Save a template from the Add shift panel (&ldquo;Also save as a template&rdquo;), then start new shifts from it.</p>
                {templates.length ? (
                  <ul className="divide-y divide-line rounded-md border border-line text-sm">
                    {templates.map((t) => (
                      <li key={t.id} className="flex flex-wrap items-center gap-2 px-3 py-2">
                        <span className="flex-1">
                          <span className="font-semibold">{t.name}</span>
                          <span className="block text-xs text-muted">
                            {shiftTypeLabel(t.shift_type)} · {t.start_time.slice(0, 5)}–{t.end_time.slice(0, 5)}
                            {t.client_id ? ` · ${clientName.get(t.client_id) ?? "a client"}` : ""}
                          </span>
                        </span>
                        <Link href={`${base}&add=${anchor}&tpl=${t.id}`} scroll={false} className="text-xs font-semibold text-brand underline">
                          Use
                        </Link>
                        <form action={switchOffTemplate}>
                          <input type="hidden" name="id" value={t.id} />
                          <button className="text-xs font-semibold text-danger underline">Switch off</button>
                        </form>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-muted">No templates yet.</p>
                )}
              </div>
            ) : str("requests") === "1" ? (
              <div className="flex flex-col gap-3 p-5">
                <div className="flex items-center justify-between">
                  <h2 className="heading-sm">Shift change requests</h2>
                  <Link href={closePanel} scroll={false} className={buttonClass("outline")}>
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
                    <Link href={closePanel} scroll={false} className={buttonClass("outline")}>
                      Close
                    </Link>
                  </span>
                </div>
                {!opened && templates.length ? (
                  <form method="get" action="/roster" className="flex flex-wrap items-end gap-2 rounded-lg border border-line bg-page p-3">
                    {view !== "week" ? <input type="hidden" name="v" value={view} /> : null}
                    <input type="hidden" name="d" value={anchor} />
                    {byClient ? <input type="hidden" name="by" value="client" /> : null}
                    <input type="hidden" name="add" value={str("add")} />
                    {str("worker") ? <input type="hidden" name="worker" value={str("worker")} /> : null}
                    <label className="flex flex-1 flex-col gap-1 text-xs font-medium">
                      Start from a template
                      <select name="tpl" defaultValue={str("tpl")} className={inputClass}>
                        <option value="">No template</option>
                        {templates.map((t) => (
                          <option key={t.id} value={t.id}>
                            {t.name} ({t.start_time.slice(0, 5)}–{t.end_time.slice(0, 5)})
                          </option>
                        ))}
                      </select>
                    </label>
                    <button className={buttonClass("outline")}>Use</button>
                  </form>
                ) : null}
                <ShiftForm
                  key={`${opened?.id ?? str("add")}-${str("tpl")}`}
                  closeHref={close}
                  shift={draft}
                  workers={workerFit}
                  clients={((clients ?? []) as { id: string; name: string; status: string }[])
                    .filter((c) => c.status === "active" || c.id === opened?.client_id)
                    .map((c) => ({ id: c.id, name: c.status === "active" ? c.name : `${c.name} (not active)` }))}
                  cars={((cars ?? []) as { id: string; name: string; rego: string }[]).map((c) => ({ id: c.id, name: `${c.name} (${c.rego})` }))}
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
                      <Link href={closePanel} scroll={false} className={buttonClass("outline")}>
                        Close
                      </Link>
                    </span>
                  </div>
                  <nav className="mt-2 flex gap-1">
                    {(["details", "events", "signatures", "trips", "timesheet", "logs"] as const).map((t) => (
                      <Link key={t} href={`${base}&shift=${opened.id}${t === "details" ? "" : `&tab=${t}`}`} scroll={false} className={`-mb-px border-b-2 px-3 py-2 text-sm font-semibold ${tab === t ? "border-brand" : "border-transparent text-muted"}`}>
                        {t[0].toUpperCase() + t.slice(1)}
                        {t === "signatures" && sigs.length ? ` (${sigs.filter((x) => !x.voided_at).length})` : ""}
                        {t === "trips" && trips.length ? ` (${trips.length})` : ""}
                      </Link>
                    ))}
                  </nav>
                </div>
                <div className="flex flex-col gap-3 p-5 text-sm">
                  {tab === "details" ? (
                    <>
                      <dl className="grid grid-cols-[8rem_1fr] gap-x-4 gap-y-1.5">
                        {opened.ref ? (
                          <>
                            <dt className="text-muted">Reference</dt>
                            <dd className="font-mono text-xs">{opened.ref}</dd>
                            <dt className="text-muted">Shift type</dt>
                            <dd>{shiftTypeLabel(opened.shift_type ?? "standard")}</dd>
                          </>
                        ) : null}
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
                        <dt className="text-muted">Worker instructions</dt>
                        <dd className="whitespace-pre-line">{opened.notes || "None"}</dd>
                        {opened.ref ? (
                          <>
                            <dt className="text-muted">Worker&apos;s answer</dt>
                            <dd>
                              {!opened.worker_id || opened.status !== "published" ? "Not asked yet" : answer ? (
                                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${answer.response === "accepted" ? "bg-good-soft" : "bg-danger-soft"}`}>
                                  {answer.response === "accepted" ? "Accepted" : "Declined"} {new Date(answer.responded_at).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short" })}
                                </span>
                              ) : (
                                <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold">Waiting</span>
                              )}
                              {answer?.note ? <span className="block text-xs text-muted">{answer.note}</span> : null}
                              {answer?.response === "declined" && canEdit ? (
                                <span className="mt-1 flex flex-wrap gap-2">
                                  <form action={makeOpenShift}>
                                    <input type="hidden" name="id" value={opened.id} />
                                    <button className={buttonClass("outline")}>Make it an open shift</button>
                                  </form>
                                  <Link href={`${base}&shift=${opened.id}&edit=1`} scroll={false} className={buttonClass("primary")}>
                                    Give to someone else
                                  </Link>
                                </span>
                              ) : null}
                            </dd>
                            <dt className="text-muted">Company car</dt>
                            <dd>{opened.vehicle_id ? (carName.get(opened.vehicle_id) ?? "Booked car") : "None"}</dd>
                            <dt className="text-muted">Pay group</dt>
                            <dd>{opened.pay_group || "Their usual"}</dd>
                            <dt className="text-muted">Allowances</dt>
                            <dd>{(opened.allowances ?? []).join(", ") || "None"}</dd>
                            <dt className="text-muted">Signatures</dt>
                            <dd>{[opened.needs_worker_signature ? "worker at clock in and out" : "", opened.needs_client_signature ? "client at clock out" : ""].filter(Boolean).join("; ") || "Not needed"}</dd>
                            <dt className="text-muted">Added</dt>
                            <dd className="text-xs">{opened.created_at ? `${new Date(opened.created_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })} by ${opened.created_by ? (name.get(opened.created_by) ?? "someone") : "the portal"}` : ""}</dd>
                            <dt className="text-muted">Last changed</dt>
                            <dd className="text-xs">{opened.updated_at ? `${new Date(opened.updated_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}${opened.updated_by ? ` by ${name.get(opened.updated_by) ?? "someone"}` : ""}` : ""}</dd>
                          </>
                        ) : null}
                      </dl>
                      {canEdit && opened.ref ? (
                        <section className="flex flex-col gap-2 rounded-lg border border-line p-3">
                          <h3 className="font-semibold">Internal notes <span className="text-xs font-normal text-muted">(people who roster only)</span></h3>
                          {shiftNotes.map((n) => (
                            <p key={n.id} className="whitespace-pre-line">
                              {n.body}
                              <span className="block text-xs text-muted">{n.author_id ? (name.get(n.author_id) ?? "Someone") : "Someone"} · {new Date(n.created_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}</span>
                            </p>
                          ))}
                          <form action={addShiftNote} className="flex gap-2">
                            <input type="hidden" name="id" value={opened.id} />
                            <input name="body" required maxLength={2000} placeholder="Add a note" className={inputClass} />
                            <button className={buttonClass("outline")}>Add</button>
                          </form>
                        </section>
                      ) : null}
                      {opened.client_id && clientCard ? (
                        <section className="flex flex-col gap-2 rounded-lg border border-line p-3">
                          <div className="flex flex-wrap items-center justify-between gap-2">
                            <h3 className="font-semibold">
                              {clientName.get(opened.client_id)}
                              {clientCard.ref ? <span className="font-normal text-muted"> · {clientCard.ref}</span> : null}
                            </h3>
                            <Link href={`/settings/clients/${opened.client_id}`} className="text-xs font-semibold text-brand underline">
                              Open client
                            </Link>
                          </div>
                          <p>
                            <span className="block text-xs text-muted">{opened.location_id ? "Shift address" : "Home address"}</span>
                            {clientCard.address || "No address recorded"}
                          </p>
                          {clientCard.access ? (
                            <p>
                              <span className="block text-xs text-muted">Getting in</span>
                              {clientCard.access}
                            </p>
                          ) : null}
                          {clientCard.alerts.length ? (
                            <div className="flex flex-col gap-1">
                              <span className="text-xs text-muted">Alerts</span>
                              {clientCard.alerts.map((a) => (
                                <p key={a.id} className="rounded-md bg-danger-soft px-2 py-1">
                                  <span className="font-semibold">{a.title}</span>
                                  {a.worker_instructions ? <span className="block whitespace-pre-line">{a.worker_instructions}</span> : null}
                                </p>
                              ))}
                            </div>
                          ) : null}
                          {clientCard.instructions.length ? (
                            <div className="flex flex-col gap-1">
                              <span className="text-xs text-muted">How to support them</span>
                              {clientCard.instructions.map((i) => (
                                <p key={i.id} className="whitespace-pre-line">
                                  <span className="font-semibold">{i.title}: </span>
                                  {i.instructions}
                                </p>
                              ))}
                            </div>
                          ) : null}
                          {!clientCard.alerts.length && !clientCard.instructions.length ? <p className="text-xs text-muted">No alerts or support instructions recorded.</p> : null}
                        </section>
                      ) : null}
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
                  ) : tab === "events" ? (
                    evs.filter((e) => (e.kind ?? "event") === "event").length ? (
                      <ol className="flex flex-col gap-2 border-l-2 border-line pl-3">
                        {evs.filter((e) => (e.kind ?? "event") === "event").map((e) => (
                          <li key={e.id}>
                            <b>{e.actor ? (name.get(e.actor) ?? "Someone") : "The portal"}</b> {e.summary}.
                            {e.reason ? <span className="block text-xs">“{e.reason}”</span> : null}
                            <span className="block text-xs text-muted">{new Date(e.happened_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}{e.source && e.source !== "portal" ? ` · ${e.source === "worker" ? "worker" : "automatic"}` : ""}</span>
                          </li>
                        ))}
                      </ol>
                    ) : (
                      <p className="text-muted">No events yet.</p>
                    )
                  ) : tab === "signatures" ? (
                    <div className="flex flex-col gap-3">
                      {opened.needs_worker_signature && !sigs.some((x) => !x.voided_at && x.kind === "worker_in") ? <p className="rounded-md bg-warn-soft px-2 py-1">Worker clock-in signature still needed.</p> : null}
                      {opened.needs_worker_signature && !sigs.some((x) => !x.voided_at && x.kind === "worker_out") ? <p className="rounded-md bg-warn-soft px-2 py-1">Worker clock-out signature still needed.</p> : null}
                      {opened.needs_client_signature && !sigs.some((x) => !x.voided_at && (x.kind === "client" || x.kind === "representative")) ? <p className="rounded-md bg-warn-soft px-2 py-1">Client (or representative) signature still needed.</p> : null}
                      {sigs.length ? (
                        sigs.map((x) => (
                          <div key={x.id} className={`flex flex-col gap-1 rounded-lg border border-line p-3 ${x.voided_at ? "opacity-60" : ""}`}>
                            <p className="font-semibold">
                              {{ worker_in: "Worker, clock in", worker_out: "Worker, clock out", client: "Client", representative: "Client representative" }[x.kind] ?? x.kind}: {x.signer_name}
                              {x.signer_role ? <span className="font-normal text-muted"> ({x.signer_role})</span> : null}
                            </p>
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img src={x.signature} alt={`Signature of ${x.signer_name}`} className="h-20 max-w-64 rounded border border-line bg-white object-contain" />
                            <p className="text-xs text-muted">Signed {new Date(x.signed_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}{x.captured_by ? ` · recorded by ${name.get(x.captured_by) ?? "someone"}` : ""}</p>
                            {x.voided_at ? (
                              <p className="text-xs text-danger">Voided {new Date(x.voided_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}: {x.void_reason}</p>
                            ) : canEdit ? (
                              <form action={voidSignature} className="flex gap-2">
                                <input type="hidden" name="id" value={x.id} />
                                <input name="reason" required maxLength={500} placeholder="Reason to void (it stays on record)" className={inputClass} />
                                <button className={buttonClass("outline")}>Void</button>
                              </form>
                            ) : null}
                          </div>
                        ))
                      ) : (
                        <p className="text-muted">No signatures yet. The worker records them on My shifts.</p>
                      )}
                    </div>
                  ) : tab === "trips" ? (
                    trips.length ? (
                      <ul className="divide-y divide-line rounded-md border border-line">
                        {trips.map((t) => (
                          <li key={t.id} className="px-3 py-2">
                            <p className="font-semibold">
                              {carName.get(t.car_id) ?? "Company car"} · {t.km != null ? `${t.km} km` : "not returned yet"}
                            </p>
                            <p className="text-xs text-muted">
                              {new Date(t.started_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}
                              {t.returned_at ? ` – ${new Date(t.returned_at).toLocaleTimeString("en-AU", { timeZone: "Australia/Sydney", hour: "numeric", minute: "2-digit" })}` : ""}
                              {t.went_to ? ` · to ${t.went_to}` : ""}
                              {t.driver_id ? ` · ${name.get(t.driver_id) ?? "driver"}` : ""}
                            </p>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-muted">No trips linked. Trips are recorded in the Cars app; they show here when linked to this shift.</p>
                    )
                  ) : evs.length ? (
                    <table className="w-full text-left text-xs">
                      <thead className="text-muted">
                        <tr className="border-b border-line">
                          <th className="py-1 pr-2 font-medium">When</th>
                          <th className="py-1 pr-2 font-medium">Who</th>
                          <th className="py-1 pr-2 font-medium">Field</th>
                          <th className="py-1 pr-2 font-medium">Previous</th>
                          <th className="py-1 pr-2 font-medium">New</th>
                        </tr>
                      </thead>
                      <tbody>
                        {evs.map((e) => (
                          <tr key={e.id} className="border-b border-line align-top">
                            <td className="py-1.5 pr-2 whitespace-nowrap">{new Date(e.happened_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}</td>
                            <td className="py-1.5 pr-2">
                              {e.actor ? (name.get(e.actor) ?? "Someone") : "The portal"}
                              {e.source && e.source !== "portal" ? <span className="block text-muted">{e.source === "worker" ? "worker app" : "automatic"}</span> : null}
                            </td>
                            <td className="py-1.5 pr-2">{e.field ?? <span className="text-muted">{e.summary}</span>}</td>
                            <td className="py-1.5 pr-2 whitespace-pre-line">{e.old_value ?? ""}</td>
                            <td className="py-1.5 pr-2 whitespace-pre-line">
                              {e.new_value ?? ""}
                              {e.reason ? <span className="block text-muted">Reason: {e.reason}</span> : null}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
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

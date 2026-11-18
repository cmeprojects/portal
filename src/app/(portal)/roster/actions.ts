// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { SHIFT_ALLOWANCES, SHIFT_TYPES } from "@/lib/roster";
import { revalidatePath } from "next/cache";
import { after } from "next/server";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { addDays, mondayOf, sydneyInstant, sydneyParts } from "@/lib/sydney-time";

// cmeprojects (update 122): rostering. The database checks who may
// (Rostering, change), refuses leave and double-booking, and never deletes.
async function requireRoster() {
  await requireSession();
  if (!(await canDo("ops.roster", "edit"))) throw new Error("You can't change the roster.");
}
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const sydney = (date: string, time: string) => (/^\d{4}-\d{2}-\d{2}$/.test(date) && /^\d{2}:\d{2}$/.test(time) ? sydneyInstant(date, time) : null);
// Tell workers straight away (the same server-only job the hourly timer runs).
async function tellWorkers() {
  const { error } = await createAdminClient().rpc("run_roster_alerts");
  if (error && error.code !== "PGRST202") console.error("roster alerts", error.message);
}

export async function saveShift(_: FormState, form: FormData): Promise<FormState> {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const date = String(form.get("date") ?? "");
  const startT = String(form.get("start") ?? "");
  const endT = String(form.get("end") ?? "");
  if (!sydney(date, startT) || !sydney(date, endT)) return { error: "Choose the date, start and finish." };
  const worker = String(form.get("worker_id") ?? "");
  const client = String(form.get("client_id") ?? "");
  const location = String(form.get("location_id") ?? "");
  const service = String(form.get("service_id") ?? "");
  const status = String(form.get("status") ?? "draft");
  const base = {
    worker_id: isId(worker) ? worker : null,
    client_id: isId(client) ? client : null,
    location_id: isId(client) && isId(location) ? location : null,
    service_id: isId(client) && isId(service) ? service : null,
    break_minutes: Math.max(0, Math.min(240, Number(form.get("break_minutes") ?? 0) || 0)),
    notes: String(form.get("notes") ?? "").trim().slice(0, 500),
    status: ["draft", "published"].includes(status) ? status : "draft",
    // cmeprojects (update 128): shift type, car, pay group, allowances and signatures needed.
    shift_type: SHIFT_TYPES.some(([k]) => k === form.get("shift_type")) ? String(form.get("shift_type")) : "standard",
    vehicle_id: isId(String(form.get("vehicle_id") ?? "")) ? String(form.get("vehicle_id")) : null,
    pay_group: String(form.get("pay_group") ?? "").trim().slice(0, 60),
    allowances: form.getAll("allowances").map(String).filter((a) => SHIFT_ALLOWANCES.includes(a)),
    needs_worker_signature: form.get("needs_worker_signature") === "on",
    needs_client_signature: form.get("needs_client_signature") === "on",
  };
  // A client shift needs its service and location (training, meetings and admin shifts have no client).
  if (base.client_id && (!base.service_id || !base.location_id)) return { error: "Choose the client's service and location for this shift." };
  const internalNote = String(form.get("internal_note") ?? "").trim().slice(0, 2000);
  // cmeprojects (update 129): also keep these details as a named template.
  const templateName = String(form.get("save_template") ?? "").trim().slice(0, 80);
  const saveTemplate = async () => {
    if (!templateName) return;
    await (await createClient()).from("shift_templates").insert({
      name: templateName,
      shift_type: base.shift_type,
      start_time: startT,
      end_time: endT,
      break_minutes: base.break_minutes,
      client_id: base.client_id,
      service_id: base.service_id,
      location_id: base.location_id,
      notes: base.notes,
      allowances: base.allowances,
      pay_group: base.pay_group,
      needs_worker_signature: base.needs_worker_signature,
      needs_client_signature: base.needs_client_signature,
    });
  };
  // One date: start and finish (finishing at or before the start, or ticked: the next day).
  const times = (d: string) => {
    const start = sydney(d, startT)!;
    let end = sydney(d, endT)!;
    if (end <= start || form.get("next_day") === "on") end = new Date(new Date(end).getTime() + 86_400_000).toISOString();
    return { starts_at: start, ends_at: end };
  };
  const supabase = await createClient();

  if (id && isId(id)) {
    // Changing a repeating shift: just this one, or this and the later ones in its series.
    const scope = String(form.get("scope") ?? "one");
    const { data: me } = await supabase.from("shifts").select("id, series_id, starts_at").eq("id", id).maybeSingle();
    if (!me) return { error: "That shift isn't there any more. Please reload the page." };
    if (scope === "future" && me.series_id) {
      const { data: later } = await supabase.from("shifts").select("id, starts_at").eq("series_id", me.series_id).neq("status", "cancelled").gte("starts_at", me.starts_at);
      let done = 0;
      const refused: string[] = [];
      for (const s of (later ?? []) as { id: string; starts_at: string }[]) {
        const d = sydneyParts(s.starts_at).date;
        const { error } = await supabase.from("shifts").update({ ...base, ...times(s.id === id ? date : d) }).eq("id", s.id);
        if (error) refused.push(`${d}: ${friendlyError(error)}`);
        else done++;
      }
      if (base.status === "published") after(() => tellWorkers());
      // Success closes the panel by moving to a new address (one refresh); a part-failure stays and refreshes here.
      if (refused.length) revalidatePath("/roster");
      return refused.length ? { error: `${done} changed; not changed: ${refused.join("; ")}` } : { message: `${done} shifts changed.` };
    }
    const { error } = await supabase.from("shifts").update({ ...base, ...times(date) }).eq("id", id);
    if (error) return { error: friendlyError(error) };
    if (internalNote) await supabase.from("shift_notes").insert({ shift_id: id, body: internalNote });
    await saveTemplate();
    if (base.status === "published") after(() => tellWorkers());
    return { message: "Shift saved.", spotlight: id };
  }

  // New: once, or repeating (every day / week / fortnight on chosen days) until a date or a number of shifts, at most 12 weeks.
  const repeat = String(form.get("repeat") ?? "none");
  let dates = [date];
  if (["daily", "weekly", "fortnightly"].includes(repeat)) {
    const days = form.getAll("repeat_days").map(Number).filter((n) => n >= 0 && n <= 6);
    const until = String(form.get("repeat_until") ?? "");
    const count = Math.max(1, Math.min(100, Number(form.get("repeat_count") ?? 0) || 0));
    const byCount = form.get("repeat_end") === "count";
    const last = byCount ? addDays(date, 84) : /^\d{4}-\d{2}-\d{2}$/.test(until) && until <= addDays(date, 84) ? until : addDays(date, 84);
    const monday = mondayOf(date);
    dates = [];
    for (let d = date; d <= last && dates.length < (byCount ? count : 200); d = addDays(d, 1)) {
      const dow = (new Date(`${d}T12:00:00Z`).getUTCDay() + 6) % 7;
      const weekNo = Math.floor((new Date(`${mondayOf(d)}T12:00:00Z`).getTime() - new Date(`${monday}T12:00:00Z`).getTime()) / (7 * 86_400_000));
      if (repeat === "daily" || (days.includes(dow) && (repeat === "weekly" || weekNo % 2 === 0))) dates.push(d);
    }
    if (!dates.length) return { error: "Choose at least one day for it to repeat on." };
  }
  const seriesId = dates.length > 1 ? crypto.randomUUID() : null;
  let made = 0;
  let firstId = "";
  const refused: string[] = [];
  for (const d of dates) {
    const { data: added, error } = await supabase.from("shifts").insert({ ...base, ...times(d), series_id: seriesId }).select("id").single();
    if (error) refused.push(`${d}: ${friendlyError(error)}`);
    else {
      made++;
      if (internalNote && made === 1 && added) await supabase.from("shift_notes").insert({ shift_id: added.id, body: internalNote });
      if (made === 1 && added) firstId = added.id;
    }
  }
  if (made) await saveTemplate();
  if (base.status === "published" && made) after(() => tellWorkers());
  if (!made) return { error: refused[0]?.replace(/^\d{4}-\d{2}-\d{2}: /, "") ?? "That didn't save." };
  return { spotlight: firstId, message: `${made} shift${made === 1 ? "" : "s"} added${refused.length ? `; skipped ${refused.length}: ${refused.slice(0, 3).join("; ")}${refused.length > 3 ? "…" : ""}` : ""}.` };
}

export async function cancelShift(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shifts").update({ status: "cancelled" }).eq("id", id);
  revalidatePath("/roster");
}

export async function giveOpenShift(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const worker = String(form.get("worker_id") ?? "");
  if (!isId(id) || !isId(worker)) return;
  const { error } = await (await createClient()).from("shifts").update({ worker_id: worker }).eq("id", id).is("worker_id", null);
  if (!error) await tellWorkers();
  revalidatePath("/roster");
}

// Publish every draft in the week shown.
export async function publishWeek(form: FormData) {
  await requireRoster();
  const from = String(form.get("from") ?? "");
  const to = String(form.get("to") ?? "");
  if (!from || !to) return;
  await (await createClient()).from("shifts").update({ status: "published" }).eq("status", "draft").gte("starts_at", from).lt("starts_at", to);
  await tellWorkers();
  revalidatePath("/roster");
}

// Copy last week's shifts into this week as drafts (anything that would clash
// or fall on leave is skipped; the database refuses it).
export async function copyLastWeek(_: FormState, form: FormData): Promise<FormState> {
  await requireRoster();
  const from = String(form.get("from") ?? "");
  if (!from) return { error: "Choose a week." };
  const supabase = await createClient();
  const prevFrom = new Date(new Date(from).getTime() - 7 * 86_400_000).toISOString();
  const { data } = await supabase.from("shifts").select("*").neq("status", "cancelled").gte("starts_at", prevFrom).lt("starts_at", from);
  let added = 0;
  let skipped = 0;
  for (const s of (data ?? []) as { worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string }[]) {
    const week = 7 * 86_400_000;
    const { error } = await supabase.from("shifts").insert({ ...copyable(s as unknown as Record<string, unknown>), starts_at: new Date(new Date(s.starts_at).getTime() + week).toISOString(), ends_at: new Date(new Date(s.ends_at).getTime() + week).toISOString(), status: "draft" });
    if (error) skipped++;
    else added++;
  }
  revalidatePath("/roster");
  return { message: `${added} shift${added === 1 ? "" : "s"} copied as drafts${skipped ? `; ${skipped} skipped (leave, a clash or someone no longer active)` : ""}.` };
}

// Staff: put your hand up for an open shift.
export async function putHandUp(form: FormData) {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shift_interest").insert({ shift_id: id });
  revalidatePath("/my-shifts");
}

// End a repeat after this shift: the later shifts in its series are cancelled.
export async function endRepeat(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  const supabase = await createClient();
  const { data: me } = await supabase.from("shifts").select("series_id, starts_at").eq("id", id).maybeSingle();
  if (me?.series_id) await supabase.from("shifts").update({ status: "cancelled" }).eq("series_id", me.series_id).gt("starts_at", me.starts_at).neq("status", "cancelled");
  revalidatePath("/roster");
}

// Copy this week's shifts into next week as drafts.
export async function copyToNextWeek(_: FormState, form: FormData): Promise<FormState> {
  await requireRoster();
  const from = String(form.get("from") ?? "");
  const to = String(form.get("to") ?? "");
  if (!from || !to) return { error: "Choose a week." };
  const supabase = await createClient();
  const { data } = await supabase.from("shifts").select("*").neq("status", "cancelled").gte("starts_at", from).lt("starts_at", to);
  return { message: await copyRows(supabase, (data ?? []) as Row[], "next week") };
}

type Row = { worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string };
// cmeprojects (update 129): what a copy keeps (the update 128 fields too, when present; never the reference, status or car).
const COPY_KEYS = ["worker_id", "break_minutes", "client_id", "service_id", "location_id", "notes", "shift_type", "pay_group", "allowances", "needs_worker_signature", "needs_client_signature"];
const copyable = (r: Record<string, unknown>) => Object.fromEntries(COPY_KEYS.filter((k) => k in r).map((k) => [k, r[k]]));
async function copyRows(supabase: Awaited<ReturnType<typeof createClient>>, rows: Row[], where: string) {
  let added = 0;
  let skipped = 0;
  const week = 7 * 86_400_000;
  for (const s of rows) {
    const { error } = await supabase.from("shifts").insert({ ...copyable(s as unknown as Record<string, unknown>), starts_at: new Date(new Date(s.starts_at).getTime() + week).toISOString(), ends_at: new Date(new Date(s.ends_at).getTime() + week).toISOString(), status: "draft" });
    if (error) skipped++;
    else added++;
  }
  revalidatePath("/roster");
  return `${added} shift${added === 1 ? "" : "s"} copied to ${where} as drafts${skipped ? `; ${skipped} skipped (leave, a clash, an expired check or someone no longer active)` : ""}.`;
}

// Selected shifts: copy to next week, publish, cancel or give to one worker.
export async function bulkShifts(_: FormState, form: FormData): Promise<FormState> {
  await requireRoster();
  const ids = form.getAll("ids").map(String).filter(isId).slice(0, 300);
  const what = String(form.get("bulk") ?? "");
  if (!ids.length) return { error: "Tick at least one shift." };
  const supabase = await createClient();
  if (what === "copy") {
    const { data } = await supabase.from("shifts").select("*").in("id", ids);
    return { message: await copyRows(supabase, (data ?? []) as Row[], "the next week") };
  }
  if (what === "publish") {
    const { error } = await supabase.from("shifts").update({ status: "published" }).in("id", ids).eq("status", "draft");
    if (error) return { error: friendlyError(error) };
    await tellWorkers();
    revalidatePath("/roster");
    return { message: "Published. The workers have been told." };
  }
  if (what === "cancel") {
    const { error } = await supabase.from("shifts").update({ status: "cancelled" }).in("id", ids);
    if (error) return { error: friendlyError(error) };
    revalidatePath("/roster");
    return { message: `${ids.length} shift${ids.length === 1 ? "" : "s"} cancelled.` };
  }
  if (what === "worker") {
    const worker = String(form.get("bulk_worker") ?? "");
    if (!isId(worker)) return { error: "Choose the worker." };
    let done = 0;
    let refused = 0;
    for (const id of ids) {
      const { error } = await supabase.from("shifts").update({ worker_id: worker }).eq("id", id);
      if (error) refused++;
      else done++;
    }
    await tellWorkers();
    revalidatePath("/roster");
    return { message: `${done} given to them${refused ? `; ${refused} refused (leave, a clash or an expired check)` : ""}.` };
  }
  return { error: "Choose what to do." };
}

// Shift change requests: decide (people who roster), ask or withdraw (the worker).
export async function decideRequest(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!isId(id) || !["approved", "declined"].includes(status)) return;
  await (await createClient()).from("shift_change_requests").update({ status }).eq("id", id);
  await tellWorkers();
  revalidatePath("/roster");
}

export async function askChange(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const shift = String(form.get("shift_id") ?? "");
  const kind = String(form.get("kind") ?? "");
  const swap = String(form.get("swap_with") ?? "");
  const reason = String(form.get("reason") ?? "").trim().slice(0, 500);
  if (!isId(shift) || !["swap", "cannot_work"].includes(kind)) return { error: "Choose what you need." };
  if (kind === "swap" && !isId(swap)) return { error: "Choose who you'd swap with." };
  if (!reason) return { error: "Give a short reason." };
  const { error } = await (await createClient()).from("shift_change_requests").insert({ shift_id: shift, kind, swap_with: kind === "swap" ? swap : null, reason });
  if (error) return { error: friendlyError(error) };
  await tellWorkers();
  revalidatePath("/my-shifts");
  return { message: "Sent to the roster team." };
}

export async function withdrawRequest(form: FormData) {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shift_change_requests").update({ status: "withdrawn" }).eq("id", id);
  revalidatePath("/my-shifts");
}

// Timesheets: the worker sends their actual times; people who roster approve,
// query or correct them (a correction needs a reason).
export async function saveTimesheet(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const shift = String(form.get("shift_id") ?? "");
  const date = String(form.get("date") ?? "");
  const start = sydney(date, String(form.get("start") ?? ""));
  let end = sydney(date, String(form.get("end") ?? ""));
  if (!isId(shift) || !start || !end) return { error: "Fill in when you started and finished." };
  if (end <= start) end = new Date(new Date(end).getTime() + 86_400_000).toISOString();
  const allow = form.getAll("allowances").map(String).filter((a) => ["Sleepover", "Broken shift", "First aid", "Higher duties"].includes(a)).slice(0, 5);
  const values = {
    shift_id: shift,
    actual_start: start,
    actual_end: end,
    break_minutes: Math.max(0, Math.min(240, Number(form.get("break_minutes") ?? 0) || 0)),
    km: Math.max(0, Math.min(2000, Number(form.get("km") ?? 0) || 0)),
    expense: Math.max(0, Math.min(10000, Number(form.get("expense") ?? 0) || 0)),
    allowances: allow,
    note: String(form.get("note") ?? "").trim().slice(0, 500),
    change_reason: String(form.get("change_reason") ?? "").trim().slice(0, 500),
  };
  const supabase = await createClient();
  const { data: existing } = await supabase.from("shift_timesheets").select("shift_id").eq("shift_id", shift).maybeSingle();
  const { error } = existing ? await supabase.from("shift_timesheets").update(values).eq("shift_id", shift) : await supabase.from("shift_timesheets").insert(values);
  if (error) return { error: friendlyError(error) };
  revalidatePath("/my-shifts");
  revalidatePath("/roster/timesheets");
  return { message: existing ? "Timesheet saved." : "Times sent for approval." };
}

export async function decideTimesheet(form: FormData) {
  await requireRoster();
  const ids = form.getAll("shift_id").map(String).filter(isId);
  const status = String(form.get("status") ?? "");
  if (!ids.length || !["approved", "queried"].includes(status)) return;
  await (await createClient()).from("shift_timesheets").update({ status }).in("shift_id", ids).neq("status", "approved");
  if (status === "queried") await tellWorkers();
  revalidatePath("/roster/timesheets");
}

// cmeprojects (update 128): an internal rostering note (never shown to the worker).
export async function addShiftNote(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const body = String(form.get("body") ?? "").trim().slice(0, 2000);
  if (!isId(id) || !body) return;
  await (await createClient()).from("shift_notes").insert({ shift_id: id, body });
  revalidatePath("/roster");
}

// cmeprojects (update 128): void a signature with a reason (it's kept, never replaced).
export async function voidSignature(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const reason = String(form.get("reason") ?? "").trim().slice(0, 500);
  if (!isId(id) || !reason) return;
  await (await createClient()).from("shift_signatures").update({ voided_at: new Date().toISOString(), void_reason: reason }).eq("id", id);
  revalidatePath("/roster");
}

// cmeprojects (update 129): switch a shift template off (kept, not deleted).
export async function switchOffTemplate(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shift_templates").update({ active: false }).eq("id", id);
  revalidatePath("/roster");
}

// cmeprojects (update 129): a declined shift becomes an open shift (staff can put their hand up).
export async function makeOpenShift(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shifts").update({ worker_id: null }).eq("id", id);
  revalidatePath("/roster");
}

// cmeprojects: drag and drop. Moves a shift to another day (same times) and,
// in Staff view, to another worker or to Vacant. The database checks leave,
// clashes, checks and hours as for any change; a published shift's worker is told.
export async function moveShift(id: string, date: string, row: string, byClient: boolean): Promise<FormState> {
  await requireRoster();
  if (!isId(id) || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return { error: "That didn't move. Please reload the page." };
  const supabase = await createClient();
  const { data: s } = await supabase.from("shifts").select("id, worker_id, client_id, starts_at, ends_at, status, notified_at").eq("id", id).maybeSingle();
  if (!s) return { error: "That shift isn't there any more. Please reload the page." };
  if (s.status === "cancelled") return { error: "A cancelled shift can't be moved." };
  const fromDate = sydneyParts(s.starts_at).date;
  const days = Math.round((Date.parse(`${date}T12:00:00Z`) - Date.parse(`${fromDate}T12:00:00Z`)) / 86_400_000);
  const shiftBy = (iso: string) => {
    const p = sydneyParts(iso);
    return sydney(addDays(p.date, days), p.time)!;
  };
  const patch: Record<string, unknown> = { starts_at: shiftBy(s.starts_at), ends_at: shiftBy(s.ends_at) };
  if (byClient) {
    if ((s.client_id ?? "none") !== row) return { error: "In Client view a shift can only move to another day for the same client." };
  } else {
    patch.worker_id = row === "vacant" ? null : isId(row) ? row : s.worker_id;
  }
  const reassigned = "worker_id" in patch && patch.worker_id !== s.worker_id;
  if (days === 0 && !reassigned) return { message: "" };
  // Any move of a published shift sends it back to draft, to be checked and published again.
  if (s.status === "published") patch.status = "draft";
  const { error } = await supabase.from("shifts").update(patch).eq("id", id);
  if (error) return { error: friendlyError(error) };
  if (patch.status === "draft" && s.worker_id && s.notified_at) {
    // The worker who had it is told: it's no longer theirs, or it's on a new day.
    const when = new Date(s.starts_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
    const was = s.worker_id;
    const title = reassigned ? `Your shift on ${when} has been re-assigned to someone else` : `Your shift on ${when} is being moved to another day`;
    const body = reassigned ? "See My shifts" : "You'll get the new day once it's published again. See My shifts";
    after(() => createAdminClient().rpc("notify", { p_user: was, p_kind: "shift_changed", p_title: title, p_body: body, p_href: "/my-shifts", p_email: true }));
  }
  if (patch.status === "draft") return { message: reassigned ? "Shift re-assigned and set back to draft. Publish it when ready." : "Shift moved and set back to draft. Publish it when ready.", spotlight: id };
  return { message: reassigned ? "Shift re-assigned." : "Shift moved.", spotlight: id };
}

// cmeprojects: cancel one shift (asked first on screen); a published shift's worker is told.
export async function cancelShiftNow(id: string): Promise<FormState> {
  await requireRoster();
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const { error } = await (await createClient()).from("shifts").update({ status: "cancelled" }).eq("id", id);
  if (error) return { error: friendlyError(error) };
  await tellWorkers();
  revalidatePath("/roster");
  return { message: "Shift cancelled." };
}

// cmeprojects: copy and paste. A copy of a shift on another day (same times)
// and, in Staff view, for another worker or Vacant. Always a draft.
export async function pasteShift(id: string, date: string, row: string, byClient: boolean): Promise<FormState> {
  await requireRoster();
  if (!isId(id) || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return { error: "That didn't paste. Please reload the page." };
  const supabase = await createClient();
  const { data: s } = await supabase.from("shifts").select("*").eq("id", id).maybeSingle();
  if (!s) return { error: "The copied shift isn't there any more." };
  const fromDate = sydneyParts(s.starts_at).date;
  const days = Math.round((Date.parse(`${date}T12:00:00Z`) - Date.parse(`${fromDate}T12:00:00Z`)) / 86_400_000);
  const shiftBy = (iso: string) => {
    const p = sydneyParts(iso);
    return sydney(addDays(p.date, days), p.time)!;
  };
  const copy: Record<string, unknown> = { ...copyable(s as Record<string, unknown>), starts_at: shiftBy(s.starts_at), ends_at: shiftBy(s.ends_at), status: "draft" };
  if (byClient) {
    if ((s.client_id ?? "none") !== row) return { error: "In Client view a shift can only be pasted for the same client." };
  } else {
    copy.worker_id = row === "vacant" ? null : isId(row) ? row : s.worker_id;
  }
  // An older client shift without a service or location: use the client's service (and its location) if there's just one.
  if (copy.client_id && (!copy.service_id || !copy.location_id)) {
    const { data: svc } = await supabase.from("client_services").select("id, location_id").eq("client_id", String(copy.client_id)).neq("status", "ended");
    const list = (svc ?? []) as { id: string; location_id: string }[];
    if (list.length !== 1) return { error: "The copied shift has no service or location. Open it, choose them, then copy it again." };
    copy.service_id = copy.service_id || list[0].id;
    copy.location_id = copy.location_id || list[0].location_id;
  }
  const { data: added, error } = await supabase.from("shifts").insert(copy).select("id").single();
  if (error) return { error: friendlyError(error) };
  return { message: "Shift pasted.", spotlight: added.id };
}

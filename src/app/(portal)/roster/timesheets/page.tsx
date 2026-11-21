// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ChevronLeft, ChevronRight, Download } from "lucide-react";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, buttonClass } from "@/components/ui";
import { addDays, mondayOf, shiftHours, sydneyInstant, sydneyParts, sydneyToday } from "@/lib/sydney-time";
import { PAY_COLUMNS, payColumns, shortTime, type PayKey } from "@/lib/roster";
import { decideTimesheet } from "../actions";
import { TimesheetForm } from "./timesheet-form";
import { CancellationForm, type Cancellation } from "../../settings/clients/[id]/billing-panels";

export const metadata: Metadata = { title: "Timesheets" };

type Shift = { id: string; worker_id: string; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null };
type Sheet = { shift_id: string; actual_start: string; actual_end: string; break_minutes: number; km: number; expense: number; allowances: string[]; note: string; change_reason: string; status: string };
const auDate = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });

// cmeprojects (rostering round 2, update 123; premium package): the week's
// timesheets. Staff (left) are set apart from their hours by pay period
// (right); open a worker to check each rostered shift against their clock in
// and out, then approve, query or edit (a correction needs a reason).
export default async function TimesheetsPage({ searchParams }: PageProps<"/roster/timesheets">) {
  const { features } = await requireSession();
  if (features.rostering === false || !(await canDo("ops.roster", "view"))) notFound();
  const canEdit = await canDo("ops.roster", "edit");
  const sp = await searchParams;
  const str = (k: string) => (typeof sp[k] === "string" ? (sp[k] as string) : "");
  const today = sydneyToday();
  const monday = mondayOf(/^\d{4}-\d{2}-\d{2}$/.test(str("w")) ? str("w") : today);
  const days = Array.from({ length: 7 }, (_, i) => addDays(monday, i));
  const supabase = await createClient();
  const [shiftsRes, sheetsRes, { data: people }, { data: clients }, { data: services }, { data: priv }, { data: holidayRow }] = await Promise.all([
    supabase.from("shifts").select("id, worker_id, starts_at, ends_at, break_minutes, client_id, service_id").eq("status", "published").not("worker_id", "is", null).gte("starts_at", sydneyInstant(monday)).lt("starts_at", sydneyInstant(addDays(monday, 7))).lte("starts_at", new Date().toISOString()).order("starts_at"),
    supabase.from("shift_timesheets").select("shift_id, actual_start, actual_end, break_minutes, km, expense, allowances, note, change_reason, status"),
    supabase.from("profiles").select("id, full_name, email"),
    supabase.from("car_clients").select("id, name"),
    supabase.from("client_services").select("id, label"),
    supabase.from("staff_private").select("user_id, employment_type"),
    supabase.from("app_settings").select("value").eq("key", "tasks.public_holidays").maybeSingle(),
  ]);
  if (shiftsRes.error || sheetsRes.error) notFound(); // before live update 123
  const shifts = (shiftsRes.data ?? []) as Shift[];
  const sheets = new Map(((sheetsRes.data ?? []) as Sheet[]).map((t) => [t.shift_id, t]));
  const name = new Map(((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const clientName = new Map(((clients ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const serviceName = new Map(((services ?? []) as { id: string; label: string }[]).map((v) => [v.id, v.label]));
  const EMP: Record<string, string> = { full_time: "Full time", part_time: "Part time", casual: "Casual", contractor: "Contractor" };
  const emp = new Map(((priv ?? []) as { user_id: string; employment_type: string | null }[]).map((p) => [p.user_id, EMP[p.employment_type ?? ""] ?? "Not set"]));
  const holidays = new Set(((Array.isArray(holidayRow?.value) ? holidayRow.value : []) as string[]).map((h) => String(h).slice(0, 10)));
  const state = (id: string) => sheets.get(id)?.status ?? "missing";
  const count = (st: string) => shifts.filter((s) => state(s.id) === st).length;
  const differs = shifts.filter((s) => {
    const t = sheets.get(s.id);
    return t && (t.actual_start !== s.starts_at || t.actual_end !== s.ends_at || t.break_minutes !== s.break_minutes);
  }).length;
  const byWorker = new Map<string, Shift[]>();
  for (const s of shifts) byWorker.set(s.worker_id, [...(byWorker.get(s.worker_id) ?? []), s]);
  const workers = [...byWorker.keys()].sort((a, b) => (name.get(a) ?? "").localeCompare(name.get(b) ?? ""));
  const editing = str("edit") ? shifts.find((s) => s.id === str("edit")) : undefined;
  const weekLabel = `${new Date(`${days[0]}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", timeZone: "UTC" })} – ${new Date(`${days[6]}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" })}`;
  const base = `/roster/timesheets?w=${monday}`;
  // cmeprojects (update 161): cancelled client shifts this week, with their
  // cancellation details (notice, who, reason, reasonable grounds, charge decision).
  const [cancelledRes, cdRes, canDecide] = await Promise.all([
    supabase.from("shifts").select("id, worker_id, starts_at, ends_at, client_id, service_id").eq("status", "cancelled").not("client_id", "is", null).gte("starts_at", sydneyInstant(monday)).lt("starts_at", sydneyInstant(addDays(monday, 7))).order("starts_at"),
    supabase.from("shift_cancellations").select("shift_id, notified_at, cancelled_by, reason, reasonable_grounds, charge, charge_note, decided_by, decided_at"),
    canDo("clients.billing", "approve"),
  ]);
  const cancelled = cdRes.error ? [] : ((cancelledRes.data ?? []) as (Omit<Shift, "worker_id" | "break_minutes"> & { worker_id: string | null })[]);
  const details = new Map(((cdRes.data ?? []) as (Omit<Cancellation, "decided"> & { shift_id: string; decided_by: string | null; decided_at: string | null })[]).map((c) => [c.shift_id, c]));

  return (
    <>
      <span data-wide hidden />
      <div className="flex flex-wrap items-center gap-2">
        <div className="min-w-56 flex-1">
          <h1 className="heading">Timesheets</h1>
          <p className="text-sm text-muted">Week {weekLabel}. Open a worker to check each shift against their clock in and out.</p>
        </div>
        <Link href={`/roster/timesheets?w=${addDays(monday, -7)}`} aria-label="Previous week" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Link>
        <span className="rounded-full bg-page px-3 py-1 text-sm font-semibold ring-1 ring-line">{weekLabel}</span>
        <Link href={`/roster/timesheets?w=${addDays(monday, 7)}`} aria-label="Next week" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronRight aria-hidden="true" className="size-4" />
        </Link>
        <a href={`/roster/timesheets/export?w=${monday}`} className={buttonClass("outline")}>
          <Download aria-hidden="true" className="size-4" /> Payroll export (CSV)
        </a>
      </div>
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {[
          ["Approved", count("approved"), "border-l-good"],
          ["Waiting for approval", count("submitted") + count("queried"), "border-l-warn"],
          ["Not sent yet", count("missing"), "border-l-line"],
          ["Different from the roster", differs, "border-l-brand"],
        ].map(([l, n, c]) => (
          <Card key={l as string} className={`border-l-4 p-4 ${c}`}>
            <p className="text-xs text-muted">{l}</p>
            <p className="font-display text-2xl font-semibold">{n}</p>
          </Card>
        ))}
      </div>
      <Card className="overflow-x-auto p-0">
        <table className="w-full min-w-[62rem] border-collapse text-sm">
          <thead>
            <tr className="text-[10px] tracking-wider text-muted uppercase">
              <th colSpan={2} className="bg-page px-3 pt-2 text-left">
                Staff
              </th>
              <th colSpan={PAY_COLUMNS.length} className="border-l-[3px] border-line px-3 pt-2 text-center">
                Hours worked by pay period
              </th>
              <th className="px-3 pt-2" />
            </tr>
            <tr className="border-b border-line text-left text-xs text-muted">
              <th className="bg-page px-3 py-2">Name</th>
              <th className="bg-page px-3 py-2">Status</th>
              {PAY_COLUMNS.map(([k, l], i) => (
                <th key={k} className={`px-2 py-2 text-right ${i === 0 ? "border-l-[3px] border-line" : ""}`}>
                  {l}
                </th>
              ))}
              <th className="px-3 py-2" />
            </tr>
          </thead>
          {workers.map((w) => {
            const list = byWorker.get(w)!;
            const tot = Object.fromEntries(PAY_COLUMNS.map(([k]) => [k, 0])) as Record<PayKey, number>;
            for (const s of list) {
              const t = sheets.get(s.id);
              const c = t ? payColumns(t.actual_start, t.actual_end, t.break_minutes, holidays) : payColumns(s.starts_at, s.ends_at, s.break_minutes, holidays);
              for (const [k] of PAY_COLUMNS) tot[k] += c[k];
            }
            const waiting = list.filter((s) => state(s.id) !== "approved");
            const sent = waiting.filter((s) => sheets.has(s.id) && state(s.id) === "submitted");
            return (
              <tbody key={w} className="border-b border-line">
                <tr>
                  <td className="bg-page px-3 py-2">
                    <Link href={`${base}&open=${w}#${w}`} id={w} className="font-semibold hover:text-brand">
                      {str("open") === w ? "▾" : "▸"} {name.get(w)}
                    </Link>
                    <span className="block text-xs text-muted">{emp.get(w) ?? "Not set"}</span>
                  </td>
                  <td className="bg-page px-3 py-2">
                    {waiting.length ? <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold">{waiting.length} to approve</span> : <span className="rounded-full bg-good-soft px-2 py-0.5 text-xs font-semibold">All approved</span>}
                  </td>
                  {PAY_COLUMNS.map(([k], i) => (
                    <td key={k} className={`px-2 py-2 text-right tabular-nums ${i === 0 ? "border-l-[3px] border-line" : ""} ${tot[k] ? "" : "text-muted"}`}>
                      {tot[k] ? tot[k].toFixed(2) : "0"}
                    </td>
                  ))}
                  <td className="px-3 py-2 text-right">
                    {canEdit && sent.length ? (
                      <form action={decideTimesheet}>
                        {sent.map((s) => (
                          <input key={s.id} type="hidden" name="shift_id" value={s.id} />
                        ))}
                        <input type="hidden" name="status" value="approved" />
                        <button className={buttonClass("outline")}>Approve all sent</button>
                      </form>
                    ) : null}
                  </td>
                </tr>
                {str("open") === w ? (
                  <tr>
                    <td colSpan={PAY_COLUMNS.length + 3} className="px-3 pb-4">
                      <div className="ml-6 overflow-x-auto rounded-lg border border-l-4 border-line border-l-brand">
                        <h3 className="border-b border-line bg-page px-3 py-2 text-sm font-semibold">{name.get(w)}: shifts this week, rostered against worked</h3>
                        <table className="w-full min-w-[48rem] text-sm">
                          <thead>
                            <tr className="text-left text-xs text-muted">
                              <th className="px-3 py-2">Date</th>
                              <th className="px-3 py-2">Client and service</th>
                              <th className="px-3 py-2">Start (rostered / worked)</th>
                              <th className="px-3 py-2">Finish (rostered / worked)</th>
                              <th className="px-3 py-2">Break</th>
                              <th className="px-3 py-2">Status</th>
                              <th className="px-3 py-2" />
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-line">
                            {list.map((s) => {
                              const t = sheets.get(s.id);
                              const st = state(s.id);
                              return (
                                <tr key={s.id}>
                                  <td className="px-3 py-2">{auDate(sydneyParts(s.starts_at).date)}</td>
                                  <td className="px-3 py-2">
                                    <Link href={`/roster?w=${monday}&shift=${s.id}`} className="text-brand underline">
                                      {s.client_id ? clientName.get(s.client_id) : "No client"}
                                    </Link>
                                    {s.service_id ? <span className="block text-xs text-muted">{serviceName.get(s.service_id)}</span> : null}
                                  </td>
                                  <td className="px-3 py-2 tabular-nums">
                                    {shortTime(s.starts_at)} / <b className={t && t.actual_start !== s.starts_at ? "text-warn" : ""}>{t ? shortTime(t.actual_start) : "—"}</b>
                                  </td>
                                  <td className="px-3 py-2 tabular-nums">
                                    {shortTime(s.ends_at)} / <b className={t && t.actual_end !== s.ends_at ? "text-warn" : ""}>{t ? shortTime(t.actual_end) : "—"}</b>
                                  </td>
                                  <td className="px-3 py-2">{t ? t.break_minutes : s.break_minutes} min</td>
                                  <td className="px-3 py-2">
                                    <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${st === "approved" ? "bg-good-soft" : st === "queried" ? "bg-danger-soft text-danger" : st === "submitted" ? "bg-warn-soft" : "bg-page ring-1 ring-line"}`}>
                                      {st === "approved" ? "Approved" : st === "queried" ? "Queried" : st === "submitted" ? "To approve" : "Not sent"}
                                    </span>
                                    {t && ((t.allowances ?? []).length || Number(t.km) || Number(t.expense)) ? (
                                      <span className="block text-xs text-muted">{[(t.allowances ?? []).join(", "), Number(t.km) ? `${t.km} km` : "", Number(t.expense) ? `$${Number(t.expense).toFixed(2)}` : ""].filter(Boolean).join(" · ")}</span>
                                    ) : null}
                                  </td>
                                  <td className="px-3 py-2">
                                    {canEdit ? (
                                      <span className="flex justify-end gap-1">
                                        {t && st !== "approved" ? (
                                          <>
                                            <form action={decideTimesheet}>
                                              <input type="hidden" name="shift_id" value={s.id} />
                                              <input type="hidden" name="status" value="approved" />
                                              <button title="Approve" className="rounded-md bg-good-soft px-2 py-1 text-xs font-semibold">
                                                Approve
                                              </button>
                                            </form>
                                            <form action={decideTimesheet}>
                                              <input type="hidden" name="shift_id" value={s.id} />
                                              <input type="hidden" name="status" value="queried" />
                                              <button title="Query" className="rounded-md bg-warn-soft px-2 py-1 text-xs font-semibold">
                                                Query
                                              </button>
                                            </form>
                                          </>
                                        ) : null}
                                        <Link href={`${base}&open=${w}&edit=${s.id}`} scroll={false} className="rounded-md border border-line px-2 py-1 text-xs font-semibold">
                                          Edit
                                        </Link>
                                      </span>
                                    ) : null}
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    </td>
                  </tr>
                ) : null}
              </tbody>
            );
          })}
        </table>
        {!workers.length ? <p className="p-6 text-center text-sm text-muted">No worked shifts in this week yet.</p> : null}
      </Card>
      <p className="text-xs text-muted">Pay periods follow the award time bands; public holidays come from Due dates. Approved hours go into the payroll export.</p>
      {cancelled.length ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Cancelled client shifts this week</h2>
            <p className="text-sm text-muted">Record when and how each was cancelled. Whether the client is charged is decided by someone with the Billing approve right, with a reason. Nothing is billed from here.</p>
          </div>
          <ul className="flex flex-col gap-2">
            {cancelled.map((c) => {
              const d = details.get(c.id);
              return (
                <li key={c.id} className="rounded-md border border-line px-3 py-2 text-sm">
                  <p className="font-semibold">
                    {clientName.get(c.client_id ?? "") ?? "Client"} · {c.service_id ? serviceName.get(c.service_id) : "No service"} · {auDate(sydneyParts(c.starts_at).date)} {shortTime(c.starts_at)}
                    {c.worker_id ? ` · ${name.get(c.worker_id)}` : ""}
                  </p>
                  {canEdit || canDecide ? (
                    <details open={!d} className="mt-1">
                      <summary className="cursor-pointer text-xs font-semibold text-brand">{d ? `Cancelled by ${d.cancelled_by}: ${d.reason} · charge: ${d.charge === "charge" ? "yes" : d.charge === "no_charge" ? "no" : "not decided"}` : "Record cancellation details"}</summary>
                      <div className="mt-2">
                        <CancellationForm shiftId={c.id} canDecide={canDecide}
                          c={d ? { ...d, decided: d.decided_by ? `decided by ${name.get(d.decided_by) ?? "someone"}${d.decided_at ? ` on ${new Date(d.decided_at).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney" })}` : ""}` : "" } : null} />
                      </div>
                    </details>
                  ) : d ? <p className="text-xs text-muted">Cancelled by {d.cancelled_by}: {d.reason}</p> : null}
                </li>
              );
            })}
          </ul>
        </Card>
      ) : null}

      {editing && canEdit ? (
        <>
          <Link href={`${base}&open=${editing.worker_id}`} scroll={false} aria-label="Close" className="fixed inset-0 z-40 bg-black/30" />
          <div role="dialog" aria-label="Edit attendance" className="fixed top-1/2 left-1/2 z-50 max-h-[90vh] w-[min(36rem,calc(100vw-2rem))] -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-xl bg-surface p-5 shadow-2xl">
            <div className="mb-3 flex items-start justify-between gap-2">
              <div>
                <h2 className="heading-sm">Edit attendance</h2>
                <p className="text-sm text-muted">
                  {name.get(editing.worker_id)} · {editing.client_id ? clientName.get(editing.client_id) : "No client"} · {auDate(sydneyParts(editing.starts_at).date)}
                </p>
              </div>
              <Link href={`${base}&open=${editing.worker_id}`} scroll={false} className={buttonClass("outline")}>
                Close
              </Link>
            </div>
            <div className="mb-3 rounded-lg bg-page p-3 text-sm">
              <b>Rostered:</b> {shortTime(editing.starts_at)} – {shortTime(editing.ends_at)} · {shiftHours(editing).toFixed(2)} h
            </div>
            <TimesheetForm
              shiftId={editing.id}
              date={sydneyParts(editing.starts_at).date}
              start={sydneyParts(sheets.get(editing.id)?.actual_start ?? editing.starts_at).time}
              end={sydneyParts(sheets.get(editing.id)?.actual_end ?? editing.ends_at).time}
              breakMinutes={sheets.get(editing.id)?.break_minutes ?? editing.break_minutes}
              km={Number(sheets.get(editing.id)?.km ?? 0)}
              expense={Number(sheets.get(editing.id)?.expense ?? 0)}
              allowances={sheets.get(editing.id)?.allowances ?? []}
              note={sheets.get(editing.id)?.note ?? ""}
              needsReason
            />
          </div>
        </>
      ) : null}
    </>
  );
}

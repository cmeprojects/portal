// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { CalendarClock, Hand, MapPin } from "lucide-react";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader, buttonClass } from "@/components/ui";
import { shiftHours, sydneyParts } from "@/lib/sydney-time";
import { nowMs } from "@/lib/access";
import { putHandUp, withdrawRequest } from "../roster/actions";
import { ChangeRequestForm } from "./change-request-form";
import { answerShift } from "./actions";
import { SignaturePad } from "./signature-pad";
import { TimesheetForm } from "../roster/timesheets/timesheet-form";

export const metadata: Metadata = { title: "My shifts" };

type Shift = { id: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; location_id: string | null; notes: string; ref?: string; shift_type?: string; needs_worker_signature?: boolean; needs_client_signature?: boolean };

// cmeprojects (update 122): my published shifts, and open shifts I can put my
// hand up for. Only what the database lets me see.
export default async function MyShiftsPage() {
  const { profile, features } = await requireSession();
  if (profile.role === "new_starter" || profile.role === "system_admin" || features.rostering === false) notFound();
  const supabase = await createClient();
  const now = new Date().toISOString();
  const res = await supabase.from("shifts").select("*").eq("status", "published").gte("ends_at", now).order("starts_at").limit(60);
  if (res.error) notFound(); // before live update 122
  const all = (res.data ?? []) as Shift[];
  const mine = all.filter((s) => s.worker_id === profile.id);
  const open = all.filter((s) => !s.worker_id);
  const { data: myHands } = await supabase.from("shift_interest").select("shift_id").eq("user_id", profile.id);
  const raised = new Set(((myHands ?? []) as { shift_id: string }[]).map((h) => h.shift_id));
  const clientIds = [...new Set(all.map((s) => s.client_id).filter((v): v is string => !!v))];
  const locIds = [...new Set(all.map((s) => s.location_id).filter((v): v is string => !!v))];
  const [{ data: clients }, { data: locs }] = await Promise.all([
    clientIds.length ? supabase.from("car_clients").select("id, name, preferred_name").in("id", clientIds) : Promise.resolve({ data: [] }),
    locIds.length ? supabase.from("client_locations").select("id, label, address, suburb, access_notes").in("id", locIds) : Promise.resolve({ data: [] }),
  ]);
  // cmeprojects: alerts and how to support each client (only what the worker may see).
  const [{ data: alertRows }, { data: instrRows }] = clientIds.length
    ? await Promise.all([
        supabase.from("client_alerts").select("client_id, title, worker_instructions").in("client_id", clientIds).eq("active", true),
        supabase.from("client_worker_instructions").select("client_id, title, instructions").in("client_id", clientIds).eq("active", true).order("sort_order"),
      ])
    : [{ data: [] }, { data: [] }];
  const careOf = new Map<string, Care>();
  for (const a of (alertRows ?? []) as { client_id: string; title: string; worker_instructions: string | null }[]) {
    const c = careOf.get(a.client_id) ?? { alerts: [], instructions: [] };
    c.alerts.push({ title: a.title, text: a.worker_instructions });
    careOf.set(a.client_id, c);
  }
  for (const i of (instrRows ?? []) as { client_id: string; title: string; instructions: string }[]) {
    const c = careOf.get(i.client_id) ?? { alerts: [], instructions: [] };
    c.instructions.push({ title: i.title, text: i.instructions });
    careOf.set(i.client_id, c);
  }
  const clientName = new Map(((clients ?? []) as { id: string; name: string; preferred_name: string | null }[]).map((c) => [c.id, c.preferred_name || c.name]));
  const loc = new Map(((locs ?? []) as { id: string; label: string; address: string; suburb: string | null; access_notes: string | null }[]).map((l) => [l.id, l]));
  const when = (s: Shift) => {
    const a = sydneyParts(s.starts_at);
    const b = sydneyParts(s.ends_at);
    return `${new Date(`${a.date}T12:00:00`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short" })}, ${a.time}–${b.time}`;
  };
  // cmeprojects (update 123): my shifts in the last 14 days, to send my times; my change requests.
  const [{ data: pastRows }, reqRes, { data: colleagues }] = await Promise.all([
    supabase.from("shifts").select("*").eq("status", "published").eq("worker_id", profile.id).lt("starts_at", now).gte("starts_at", new Date(nowMs() - 14 * 86_400_000).toISOString()).order("starts_at", { ascending: false }),
    supabase.from("shift_change_requests").select("id, shift_id, kind, status, reason").eq("requested_by", profile.id).order("created_at", { ascending: false }).limit(30),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).not("role", "in", "(new_starter,system_admin,external)").neq("id", profile.id).order("full_name"),
  ]);
  const past = ((pastRows ?? []) as Shift[]).filter((x) => !mine.some((m) => m.id === x.id));
  const { data: sheetRows } = [...mine, ...past].length ? await supabase.from("shift_timesheets").select("shift_id, actual_start, actual_end, break_minutes, km, expense, allowances, note, status").in("shift_id", [...mine, ...past].map((x) => x.id)) : { data: [] };
  type Sheet = { shift_id: string; actual_start: string; actual_end: string; break_minutes: number; km: number; expense: number; allowances: string[]; note: string; status: string };
  const sheets = new Map(((sheetRows ?? []) as Sheet[]).map((t) => [t.shift_id, t]));
  const requests = reqRes.error ? [] : ((reqRes.data ?? []) as { id: string; shift_id: string; kind: string; status: string; reason: string }[]);
  const people = ((colleagues ?? []) as { id: string; full_name: string | null; email: string }[]).map((c) => ({ id: c.id, name: c.full_name || c.email }));
  // cmeprojects (update 128): my answers and the signatures recorded (empty before it runs).
  const shownIds = [...mine, ...past].map((x) => x.id);
  const [{ data: ansRows }, { data: sigRows }] = shownIds.length
    ? await Promise.all([
        supabase.from("shift_responses").select("shift_id, response").in("shift_id", shownIds),
        supabase.from("shift_signatures").select("shift_id, kind").in("shift_id", shownIds).is("voided_at", null),
      ])
    : [{ data: [] }, { data: [] }];
  const answerOf = new Map(((ansRows ?? []) as { shift_id: string; response: string }[]).map((a) => [a.shift_id, a.response]));
  const signed = new Set(((sigRows ?? []) as { shift_id: string; kind: string }[]).map((x) => `${x.shift_id}:${x.kind}`));
  const started = (x: Shift) => new Date(x.starts_at).getTime() <= nowMs() + 3_600_000;
  const extra = (x: Shift) => {
    const req = requests.find((r) => r.shift_id === x.id);
    const t = sheets.get(x.id);
    return (
      <div className="flex flex-col gap-2 px-4 pb-3">
        {x.ref && !started(x) ? (
          answerOf.get(x.id) ? (
            <p className="text-sm">
              <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${answerOf.get(x.id) === "accepted" ? "bg-good-soft" : "bg-danger-soft"}`}>
                You {answerOf.get(x.id)} this shift
              </span>
            </p>
          ) : (
            <div className="flex flex-wrap items-center gap-2">
              <form action={answerShift}>
                <input type="hidden" name="id" value={x.id} />
                <input type="hidden" name="response" value="accepted" />
                <button className={buttonClass("primary")}>Accept</button>
              </form>
              <form action={answerShift}>
                <input type="hidden" name="id" value={x.id} />
                <input type="hidden" name="response" value="declined" />
                <button className={buttonClass("outline")}>Decline</button>
              </form>
            </div>
          )
        ) : null}
        {started(x) && (x.needs_worker_signature || x.needs_client_signature)
          ? (
              [
                ...(x.needs_worker_signature ? ["worker_in", "worker_out"] : []),
                ...(x.needs_client_signature ? ["client"] : []),
              ] as string[]
            )
              .filter((k) => !signed.has(`${x.id}:${k}`) && !(k === "client" && signed.has(`${x.id}:representative`)))
              .map((k) => (
                <details key={k}>
                  <summary className="cursor-pointer text-sm font-semibold text-brand">
                    {k === "worker_in" ? "Sign in (clock in)" : k === "worker_out" ? "Sign out (clock out)" : "Client signature"}
                  </summary>
                  <div className="mt-2 flex flex-col gap-3">
                    <SignaturePad shiftId={x.id} kind={k} defaultName={k.startsWith("worker") ? (profile.full_name ?? "") : ""} />
                    {k === "client" ? (
                      <details>
                        <summary className="cursor-pointer text-xs font-semibold text-brand">A representative is signing instead</summary>
                        <div className="mt-2">
                          <SignaturePad shiftId={x.id} kind="representative" />
                        </div>
                      </details>
                    ) : null}
                  </div>
                </details>
              ))
          : null}
        {req ? (
          <p className="text-sm">
            <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${req.status === "pending" ? "bg-warn-soft" : req.status === "approved" ? "bg-good-soft" : "bg-page ring-1 ring-line"}`}>
              {req.kind === "swap" ? "Swap" : "Can't work"}: {req.status === "pending" ? "waiting for the roster team" : req.status}
            </span>
            {req.status === "pending" ? (
              <form action={withdrawRequest} className="ml-2 inline">
                <input type="hidden" name="id" value={req.id} />
                <button className="text-xs font-semibold text-brand underline">Withdraw</button>
              </form>
            ) : null}
          </p>
        ) : null}
        {started(x) ? (
          t?.status === "approved" ? (
            <p className="text-xs text-good">Times approved.</p>
          ) : (
            <details open={t?.status === "queried"}>
              <summary className="cursor-pointer text-sm font-semibold text-brand">{t ? (t.status === "queried" ? "Your times were queried: check them" : "Change the times I sent") : "Confirm my times"}</summary>
              <div className="mt-2">
                <TimesheetForm shiftId={x.id} date={sydneyParts(x.starts_at).date} start={sydneyParts(t?.actual_start ?? x.starts_at).time} end={sydneyParts(t?.actual_end ?? x.ends_at).time} breakMinutes={t?.break_minutes ?? x.break_minutes} km={Number(t?.km ?? 0)} expense={Number(t?.expense ?? 0)} allowances={t?.allowances ?? []} note={t?.note ?? ""} />
              </div>
            </details>
          )
        ) : !req || req.status !== "pending" ? (
          <details>
            <summary className="cursor-pointer text-sm font-semibold text-brand">Ask to swap, or say I can&apos;t work it</summary>
            <div className="mt-2">
              <ChangeRequestForm shiftId={x.id} people={people} />
            </div>
          </details>
        ) : null}
      </div>
    );
  };
  const weekHours = mine.filter((s) => new Date(s.starts_at).getTime() < nowMs() + 7 * 86_400_000).reduce((n, s) => n + shiftHours(s), 0);

  return (
    <>
      <PageHeader title="My shifts" intro={`Your upcoming shifts${mine.length ? ` · ${weekHours.toFixed(1)} hours in the next 7 days` : ""}. You're told when a shift is published or changes, and the day before.`} />
      {mine.length ? (
        <Card className="p-0">
          <ul className="divide-y divide-line">
            {mine.map((s) => (
              <div key={s.id}>
                <ShiftCard s={s} when={when(s)} client={s.client_id ? clientName.get(s.client_id) : undefined} loc={s.location_id ? loc.get(s.location_id) : undefined} care={s.client_id ? careOf.get(s.client_id) : undefined} />
                {extra(s)}
              </div>
            ))}
          </ul>
        </Card>
      ) : (
        <EmptyState icon={CalendarClock} title="No shifts coming up" text="Published shifts for you show here." />
      )}
      {open.length ? (
        <Card className="p-0">
          <h2 className="heading-sm border-b border-line px-4 py-3">Open shifts</h2>
          <ul className="divide-y divide-line">
            {open.map((s) => (
              <ShiftCard key={s.id} s={s} when={when(s)} client={s.client_id ? clientName.get(s.client_id) : undefined} loc={s.location_id ? loc.get(s.location_id) : undefined} isOpen raised={raised.has(s.id)} />
            ))}
          </ul>
        </Card>
      ) : null}
      {past.length ? (
        <Card className="p-0">
          <h2 className="heading-sm border-b border-line px-4 py-3">Recent shifts: confirm your times</h2>
          <ul className="divide-y divide-line">
            {past.map((s) => (
              <div key={s.id}>
                <ShiftCard s={s} when={when(s)} client={s.client_id ? clientName.get(s.client_id) : undefined} loc={s.location_id ? loc.get(s.location_id) : undefined} care={s.client_id ? careOf.get(s.client_id) : undefined} />
                {extra(s)}
              </div>
            ))}
          </ul>
        </Card>
      ) : null}
    </>
  );
}

type Loc = { id: string; label: string; address: string; suburb: string | null; access_notes: string | null };
type Care = { alerts: { title: string; text: string | null }[]; instructions: { title: string; text: string }[] };
function ShiftCard({ s, when, client, loc: l, isOpen, raised, care }: { s: Shift; when: string; client?: string; loc?: Loc; isOpen?: boolean; raised?: boolean; care?: Care }) {
  return (
    <li className="flex flex-wrap items-start gap-3 px-4 py-3">
      <div className="min-w-48 flex-1">
        <p className="font-semibold">{when}</p>
        <p className="text-sm">
          {client ?? "No client"}
          {s.break_minutes ? <span className="text-muted"> · {s.break_minutes} min break</span> : null}
        </p>
        {l ? (
          <p className="mt-0.5 flex items-start gap-1 text-sm text-muted">
            <MapPin aria-hidden="true" className="mt-0.5 size-4 shrink-0" />
            <span>
              {l.address}
              {l.suburb ? `, ${l.suburb}` : ""}
              {!isOpen && l.access_notes ? <span className="block">{l.access_notes}</span> : null}
            </span>
          </p>
        ) : null}
        {s.notes ? <p className="mt-0.5 whitespace-pre-line text-sm">{s.notes}</p> : null}
        {care?.alerts.length ? (
          <div className="mt-1 flex flex-col gap-1">
            {care.alerts.map((a) => (
              <p key={a.title} className="rounded-md bg-danger-soft px-2 py-1 text-sm">
                <span className="font-semibold">{a.title}</span>
                {a.text ? <span className="block whitespace-pre-line">{a.text}</span> : null}
              </p>
            ))}
          </div>
        ) : null}
        {care?.instructions.length ? (
          <details className="mt-1 text-sm">
            <summary className="cursor-pointer font-semibold text-brand">How to support {client ?? "them"}</summary>
            {care.instructions.map((i) => (
              <p key={i.title} className="mt-1 whitespace-pre-line">
                <span className="font-semibold">{i.title}: </span>
                {i.text}
              </p>
            ))}
          </details>
        ) : null}
      </div>
      {isOpen ? (
        raised ? (
          <span className="rounded-full bg-good-soft px-2 py-1 text-xs font-semibold">Hand up · waiting</span>
        ) : (
          <form action={putHandUp}>
            <input type="hidden" name="id" value={s.id} />
            <button className={buttonClass("outline")}>
              <Hand aria-hidden="true" className="size-4" /> Put my hand up
            </button>
          </form>
        )
      ) : null}
    </li>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { CalendarClock, Hand, MapPin } from "lucide-react";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader, buttonClass } from "@/components/ui";
import { shiftHours, sydneyParts } from "@/lib/sydney-time";
import { nowMs } from "@/lib/access";
import { putHandUp } from "../roster/actions";

export const metadata: Metadata = { title: "My shifts" };

type Shift = { id: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; location_id: string | null; notes: string };

// cmeprojects (update 122): my published shifts, and open shifts I can put my
// hand up for. Only what the database lets me see.
export default async function MyShiftsPage() {
  const { profile } = await requireSession();
  if (profile.role === "new_starter" || profile.role === "system_admin") notFound();
  const supabase = await createClient();
  const now = new Date().toISOString();
  const res = await supabase.from("shifts").select("id, worker_id, starts_at, ends_at, break_minutes, client_id, location_id, notes").eq("status", "published").gte("ends_at", now).order("starts_at").limit(60);
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
  const clientName = new Map(((clients ?? []) as { id: string; name: string; preferred_name: string | null }[]).map((c) => [c.id, c.preferred_name || c.name]));
  const loc = new Map(((locs ?? []) as { id: string; label: string; address: string; suburb: string | null; access_notes: string | null }[]).map((l) => [l.id, l]));
  const when = (s: Shift) => {
    const a = sydneyParts(s.starts_at);
    const b = sydneyParts(s.ends_at);
    return `${new Date(`${a.date}T12:00:00`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short" })}, ${a.time}–${b.time}`;
  };
  const weekHours = mine.filter((s) => new Date(s.starts_at).getTime() < nowMs() + 7 * 86_400_000).reduce((n, s) => n + shiftHours(s), 0);

  return (
    <>
      <PageHeader title="My shifts" intro={`Your upcoming shifts${mine.length ? ` · ${weekHours.toFixed(1)} hours in the next 7 days` : ""}. You're told when a shift is published or changes, and the day before.`} />
      {mine.length ? (
        <Card className="p-0">
          <ul className="divide-y divide-line">
            {mine.map((s) => (
              <ShiftCard key={s.id} s={s} when={when(s)} client={s.client_id ? clientName.get(s.client_id) : undefined} loc={s.location_id ? loc.get(s.location_id) : undefined} />
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
    </>
  );
}

type Loc = { id: string; label: string; address: string; suburb: string | null; access_notes: string | null };
function ShiftCard({ s, when, client, loc: l, isOpen, raised }: { s: Shift; when: string; client?: string; loc?: Loc; isOpen?: boolean; raised?: boolean }) {
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

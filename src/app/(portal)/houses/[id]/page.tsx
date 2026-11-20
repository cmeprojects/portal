// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { houseKind } from "@/lib/houses";
import { HouseActiveForm, HouseForm, MoveInForm, MoveOutForm, RoomForm, type House } from "../forms";
import { PageFloat } from "@/components/page-float";

export const metadata: Metadata = { title: "House" };

const day = (d: string) => new Date(`${d}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });
const when = (iso: string) => new Date(iso).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });

type Resident = { id: string; client_id: string; room: string; moved_in: string; moved_out: string | null; move_reason: string; car_clients: { name: string; preferred_name: string | null; status: string } | null };

// cmeprojects (update 150): one house: residents, history, shifts and details.
export default async function HousePage({ params }: PageProps<"/houses/[id]">) {
  const { live } = await requireSession();
  if (live.sil_houses !== true) notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data } = await supabase.from("sil_houses").select("*").eq("id", id).maybeSingle();
  if (!data) notFound();
  const house = data as House & { created_at: string };
  const [canView, canEdit, canRoster] = await Promise.all([canDo("clients.houses", "view"), canDo("clients.houses", "edit"), canDo("ops.roster", "view")]);
  const now = new Date().toISOString();
  const in14 = new Date(Date.parse(now) + 14 * 86_400_000).toISOString();
  const [resRes, peopleRes, teamsRes, clientsRes, shiftsRes] = await Promise.all([
    supabase.from("sil_house_residents").select("id, client_id, room, moved_in, moved_out, move_reason, car_clients(name, preferred_name, status)").eq("house_id", id).order("moved_in", { ascending: false }),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).not("role", "in", "(new_starter,external)").order("full_name"),
    supabase.from("teams").select("id, name").order("name"),
    canEdit ? supabase.from("car_clients").select("id, name").neq("status", "discharged").order("name") : Promise.resolve({ data: [] }),
    canRoster ? supabase.from("shifts").select("id, starts_at, ends_at, worker_id, status, client_id").eq("house_id", id).neq("status", "cancelled").gte("ends_at", now).lte("starts_at", in14).order("starts_at").limit(40) : Promise.resolve({ data: [] }),
  ]);
  const residents = (resRes.data ?? []) as unknown as Resident[];
  const current = residents.filter((r) => !r.moved_out);
  const past = residents.filter((r) => r.moved_out);
  const staff: [string, string][] = ((peopleRes.data ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]);
  const names = new Map(staff);
  const teams: [string, string][] = ((teamsRes.data ?? []) as { id: string; name: string }[]).map((t) => [t.id, t.name]);
  // Clients who could move in: not archived and not living in a house now (the database checks too).
  const { data: housed } = canEdit ? await supabase.from("sil_house_residents").select("client_id").is("moved_out", null) : { data: [] };
  const taken = new Set(((housed ?? []) as { client_id: string }[]).map((r) => r.client_id));
  const movable: [string, string][] = ((clientsRes.data ?? []) as { id: string; name: string }[]).filter((c) => !taken.has(c.id)).map((c) => [c.id, c.name]);
  const shifts = (shiftsRes.data ?? []) as { id: string; starts_at: string; ends_at: string; worker_id: string | null; status: string; client_id: string | null }[];
  const full = house.beds !== null && current.length >= house.beds;
  const nm = (r: Resident) => r.car_clients?.preferred_name || r.car_clients?.name || "Client";

  return (
    <div className="flex flex-col gap-4">
      {canView ? (
        <Link href="/houses" className="text-sm text-muted hover:text-ink">
          ← All houses
        </Link>
      ) : null}
      <PageHeader eyebrow={houseKind(house.kind)} title={house.name} intro={[house.address, house.phone].filter(Boolean).join(" · ") || undefined} action={canEdit ? <HouseActiveForm id={house.id} active={house.active} /> : undefined} />
      {!house.active ? <p className="rounded-xl bg-line px-4 py-2 text-sm text-muted">This house is closed. Reopen it to move people in or roster shifts there.</p> : null}
      <div className="grid gap-4 lg:grid-cols-[1fr_24rem]">
        <div className="flex flex-col gap-4">
          {canView ? (
            <Card className="flex flex-col gap-3 p-4">
              <div className="flex items-center justify-between gap-2">
                <h2 className="text-sm font-semibold text-ink">Residents</h2>
                <span className="text-xs text-muted">{house.beds !== null ? `${current.length} of ${house.beds} beds` : `${current.length} living here`}</span>
              </div>
              {current.length ? (
                <ul className="flex flex-col divide-y divide-line">
                  {current.map((r) => (
                    <li key={r.id} className="flex flex-wrap items-center gap-2 py-2 text-sm">
                      <Link href={`/settings/clients/${r.client_id}`} className="min-w-0 flex-1 font-semibold text-ink hover:underline">
                        {nm(r)}
                      </Link>
                      {canEdit ? <RoomForm id={r.id} room={r.room} /> : r.room ? <span className="text-muted">{r.room}</span> : null}
                      <span className="text-xs text-muted">Since {day(r.moved_in)}</span>
                      {canEdit ? <MoveOutForm id={r.id} movedIn={r.moved_in} /> : null}
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted">No one lives here at the moment.</p>
              )}
              {canEdit && house.active ? (
                full ? (
                  <p className="text-sm text-muted">The house is full. Change the number of beds under Details to add someone.</p>
                ) : (
                  <div className="border-t border-line pt-3">
                    <MoveInForm houseId={house.id} clients={movable} />
                  </div>
                )
              ) : null}
              {past.length ? (
                <details className="border-t border-line pt-2">
                  <summary className="cursor-pointer text-xs font-semibold text-muted">Past residents ({past.length})</summary>
                  <ul className="mt-2 flex flex-col gap-1 text-sm">
                    {past.map((r) => (
                      <li key={r.id} className="text-muted">
                        <Link href={`/settings/clients/${r.client_id}`} className="text-ink hover:underline">
                          {nm(r)}
                        </Link>{" "}
                        · {day(r.moved_in)} to {day(r.moved_out as string)}
                        {r.move_reason ? ` · ${r.move_reason}` : ""}
                      </li>
                    ))}
                  </ul>
                </details>
              ) : null}
            </Card>
          ) : null}
          {canRoster ? (
            <Card className="flex flex-col gap-2 p-4">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-semibold text-ink">Shifts at this house (next 14 days)</h2>
                <Link href="/roster" className="text-xs font-medium text-brand hover:underline">
                  Open rostering
                </Link>
              </div>
              {shifts.length ? (
                <ul className="flex flex-col divide-y divide-line text-sm">
                  {shifts.map((s) => (
                    <li key={s.id} className="flex flex-wrap gap-2 py-1.5">
                      <span className="w-48 shrink-0">
                        {when(s.starts_at)} – {new Date(s.ends_at).toLocaleTimeString("en-AU", { timeZone: "Australia/Sydney", hour: "numeric", minute: "2-digit" })}
                      </span>
                      <span className={s.worker_id ? "text-ink" : "font-semibold text-danger"}>{s.worker_id ? (names.get(s.worker_id) ?? "Staff member") : "Vacant"}</span>
                      {s.status === "draft" ? <span className="text-xs text-muted">(not published)</span> : null}
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted">No shifts here in the next 14 days. Choose this house on a shift in rostering.</p>
              )}
            </Card>
          ) : null}
        </div>
        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="text-sm font-semibold text-ink">Notes for staff on shift</h2>
            <p className="whitespace-pre-wrap text-sm text-ink">{house.staff_notes || <span className="text-muted">None yet.</span>}</p>
            {house.manager_id ? <p className="text-xs text-muted">House manager: {names.get(house.manager_id) ?? "Staff member"}</p> : null}
          </Card>
          {canEdit ? (
            <Card className="p-4">
              <details>
                <summary className="cursor-pointer text-sm font-semibold text-ink">Details</summary>
                <div className="mt-3">
                  <HouseForm house={house} staff={staff} teams={teams} />
                </div>
              </details>
            </Card>
          ) : null}
        </div>
      </div>
      {/* Floating icons (owner, 20 Nov 2026). */}
      <PageFloat list={{ href: "/houses", label: "Back to houses" }} />
    </div>
  );
}

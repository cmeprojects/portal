// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader } from "@/components/ui";
import { houseKind } from "@/lib/houses";
import { HouseForm } from "./forms";

export const metadata: Metadata = { title: "Houses" };

type Row = { id: string; name: string; kind: string; address: string; beds: number | null; manager_id: string | null; active: boolean };

// cmeprojects (update 150): SIL houses, only while the switch is on.
export default async function HousesPage({ searchParams }: PageProps<"/houses">) {
  const { live } = await requireSession();
  if (live.sil_houses !== true || !(await canDo("clients.houses", "view"))) notFound();
  const sp = await searchParams;
  const showClosed = sp.show === "closed";
  const canEdit = await canDo("clients.houses", "edit");
  const supabase = await createClient();
  const [{ data: houses }, { data: residents }, { data: people }, { data: teams }] = await Promise.all([
    supabase.from("sil_houses").select("id, name, kind, address, beds, manager_id, active").eq("active", !showClosed).order("name"),
    supabase.from("sil_house_residents").select("house_id, client_id, car_clients(name, preferred_name)").is("moved_out", null),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).not("role", "in", "(new_starter,external)").order("full_name"),
    supabase.from("teams").select("id, name").order("name"),
  ]);
  const rows = (houses ?? []) as Row[];
  const res = (residents ?? []) as unknown as { house_id: string; client_id: string; car_clients: { name: string; preferred_name: string | null } | null }[];
  const staff: [string, string][] = ((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]);
  const names = new Map(staff);

  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Clients" title="Houses" intro="Supported Independent Living and other shared houses: who lives where, rooms, and notes for staff on shift." action={<Link href="/settings/clients" className="text-sm font-semibold text-brand underline">Back to clients</Link>} />
      {canEdit && !showClosed ? (
        <details className="rounded-xl border border-line bg-surface p-4">
          <summary className="cursor-pointer text-sm font-semibold text-ink">+ Add a house</summary>
          <div className="mt-3">
            <HouseForm staff={staff} teams={((teams ?? []) as { id: string; name: string }[]).map((t) => [t.id, t.name])} />
          </div>
        </details>
      ) : null}
      <div className="flex gap-2 text-sm">
        <Link href="/houses" className={`rounded-full px-3 py-1 font-medium ${showClosed ? "border border-line" : "bg-ink text-white"}`}>
          Open
        </Link>
        <Link href="/houses?show=closed" className={`rounded-full px-3 py-1 font-medium ${showClosed ? "bg-ink text-white" : "border border-line"}`}>
          Closed
        </Link>
      </div>
      {rows.length ? (
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {rows.map((h) => {
            const here = res.filter((r) => r.house_id === h.id);
            const full = h.beds !== null && here.length >= h.beds;
            return (
              <Link key={h.id} href={`/houses/${h.id}`} className="block">
                <Card className="flex h-full flex-col gap-2 p-4 hover:border-brand">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-semibold text-ink">{h.name}</p>
                      <p className="text-xs text-muted">{houseKind(h.kind)}</p>
                    </div>
                    <span className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold ${full ? "bg-warn-soft text-ink" : "bg-good-soft text-good"}`}>
                      {h.beds !== null ? `${here.length} of ${h.beds} beds` : `${here.length} resident${here.length === 1 ? "" : "s"}`}
                    </span>
                  </div>
                  {h.address ? <p className="text-sm text-muted">{h.address}</p> : null}
                  <p className="text-sm text-ink">{here.length ? here.map((r) => r.car_clients?.preferred_name || r.car_clients?.name || "Client").join(", ") : <span className="text-muted">No residents</span>}</p>
                  {h.manager_id ? <p className="mt-auto text-xs text-muted">House manager: {names.get(h.manager_id) ?? "Staff member"}</p> : null}
                </Card>
              </Link>
            );
          })}
        </div>
      ) : (
        <EmptyState title={showClosed ? "No closed houses" : "No houses yet"} text={showClosed ? undefined : "Add a house, then move its residents in."} />
      )}
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { AlertTriangle, MapPin } from "lucide-react";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Badge, Card, EmptyState, PageHeader } from "@/components/ui";
import { canDoFor } from "@/lib/module-access";
import { getClientWord } from "@/lib/client-word";

export const metadata: Metadata = { title: "My clients" };

type Loc = { id: string; client_id: string; label: string; address: string; suburb: string | null; access_notes?: string | null; from_date: string | null; to_date: string | null };
type Alert = { id: string; client_id: string; title: string; severity: string; worker_instructions: string | null };

// cmeprojects (Care block C1): the clients a staff member works with: their
// teams' clients and the clients assigned to them. Only what they may see:
// approved current locations and active alerts with worker instructions (the
// database decides; nothing here widens access). Details, contacts, notes and
// services stay on the full client page, for people allowed to open it.
export default async function MyClientsPage() {
  const { profile } = await requireSession();
  if (profile.role === "new_starter" || profile.role === "system_admin") notFound();
  const supabase = await createClient();
  const word = await getClientWord();
  const [team, mine] = await Promise.all([
    supabase.rpc("team_clients"),
    supabase.from("client_assignments").select("client_id, assigned_as, starts_on, ends_on").eq("user_id", profile.id).is("ended_at", null),
  ]);
  const today = new Date().toISOString().slice(0, 10);
  const assigned = ((mine.data ?? []) as { client_id: string; assigned_as: string; starts_on: string; ends_on: string | null }[]).filter((a) => a.starts_on <= today && (!a.ends_on || a.ends_on >= today));
  const assignedIds = assigned.map((a) => a.client_id);
  const { data: assignedClients } = assignedIds.length ? await supabase.from("car_clients").select("id, client_ref, name, preferred_name, status").in("id", assignedIds) : { data: [] };
  const byId = new Map<string, { id: string; client_ref: string; name: string; preferred_name: string | null; why: string[] }>();
  for (const c of (team.data ?? []) as { id: string; client_ref: string; name: string; preferred_name: string | null }[]) byId.set(c.id, { ...c, why: ["Your team"] });
  for (const c of (assignedClients ?? []) as { id: string; client_ref: string; name: string; preferred_name: string | null }[]) {
    const as = assigned.find((a) => a.client_id === c.id)?.assigned_as.replace("_", " ") ?? "assigned";
    const prev = byId.get(c.id);
    byId.set(c.id, { ...c, why: [...(prev?.why ?? []), `Assigned: ${as}`] });
  }
  const clients = [...byId.values()].sort((a, b) => a.name.localeCompare(b.name));
  const ids = clients.map((c) => c.id);
  const [locs, alerts] = ids.length
    ? await Promise.all([
        supabase.from("client_locations").select("id, client_id, label, address, suburb, access_notes, from_date, to_date").in("client_id", ids).eq("approved", true),
        supabase.from("client_alerts").select("id, client_id, title, severity, worker_instructions").in("client_id", ids).eq("active", true),
      ])
    : [{ data: [] }, { data: [] }];
  const opens = new Map(await Promise.all(ids.map(async (id) => [id, await canDoFor("clients.list", "view", id)] as const)));
  const plural = word.endsWith("s") ? word : `${word}s`;
  return (
    <>
      <PageHeader title={`My ${plural.toLowerCase()}`} intro={`The ${plural.toLowerCase()} you work with: your teams' and the ones assigned to you. Where to go and what to watch for.`} />
      {clients.length === 0 ? (
        <EmptyState icon={MapPin} title={`No ${plural.toLowerCase()} yet`} text={`You'll see a ${word.toLowerCase()} here once they're linked to your team or assigned to you.`} />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {clients.map((c) => {
            const myLocs = ((locs.data ?? []) as Loc[]).filter((l) => l.client_id === c.id && (!l.from_date || l.from_date <= today) && (!l.to_date || l.to_date >= today));
            const myAlerts = ((alerts.data ?? []) as Alert[]).filter((a) => a.client_id === c.id);
            return (
              <Card key={c.id} className="flex flex-col gap-3 p-4">
                <div className="flex flex-wrap items-start gap-2">
                  <div className="min-w-0 flex-1">
                    <h2 className="heading-sm">
                      {opens.get(c.id) ? (
                        <Link href={`/settings/clients/${c.id}`} className="hover:text-brand hover:underline">
                          {c.name}
                        </Link>
                      ) : (
                        c.name
                      )}
                    </h2>
                    <p className="text-xs text-muted">
                      {c.client_ref}
                      {c.preferred_name ? ` · goes by ${c.preferred_name}` : ""}
                    </p>
                  </div>
                  {c.why.map((w) => (
                    <Badge key={w} tone="soft">
                      {w}
                    </Badge>
                  ))}
                </div>
                {myAlerts.length ? (
                  <ul className="flex flex-col gap-2">
                    {myAlerts.map((a) => (
                      <li key={a.id} className="rounded-lg border border-warn/40 bg-warn-soft px-3 py-2 text-sm">
                        <span className="flex items-center gap-2 font-semibold">
                          <AlertTriangle aria-hidden="true" className="size-4 shrink-0" />
                          {a.title}
                          <span className="text-xs font-normal text-muted">{a.severity}</span>
                        </span>
                        {a.worker_instructions ? <span className="mt-1 block whitespace-pre-line">{a.worker_instructions}</span> : null}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-muted">No active alerts.</p>
                )}
                {myLocs.length ? (
                  <ul className="flex flex-col gap-1 text-sm">
                    {myLocs.map((l) => (
                      <li key={l.id} className="flex gap-2">
                        <MapPin aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-muted" />
                        <span>
                          <span className="font-medium">{l.label || "Location"}</span>: {l.address}
                          {l.suburb ? `, ${l.suburb}` : ""}
                          {l.access_notes ? <span className="block text-xs text-muted">{l.access_notes}</span> : null}
                        </span>
                      </li>
                    ))}
                  </ul>
                ) : null}
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}

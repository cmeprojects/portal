// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { AddClientForm, ClientRow } from "../../cars/manage/forms";
import { ClientTeamsForm } from "./team-form";

export const metadata: Metadata = { title: "Clients" };

// The company's client list, used by Cars and by built features (for example Fluid intake).
export default async function ClientsPage() {
  await requireRole(PEOPLE_MANAGERS);
  const supabase = await createClient();
  const { data } = await supabase.from("car_clients").select("id, name, reference, active").order("active", { ascending: false }).order("name");
  const clients = data ?? [];
  // cmeprojects: which team looks after each client (hidden before live update 54).
  const [{ data: teams }, { data: links, error: linkError }] = await Promise.all([
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("client_teams").select("client_id, team_id"),
  ]);
  return (
    <>
      <PageHeader
        title="Clients"
        intro="The people you support. Staff pick from this list in Cars and features like Fluid intake, and only see the name."
      />
      <Card className="p-4">
        <AddClientForm />
      </Card>
      {clients.length ? (
        <Card className="overflow-hidden">
          <h2 className="border-b border-line px-4 py-2 text-sm font-semibold">
            {clients.filter((c) => c.active).length} shown{clients.some((c) => !c.active) ? ` · ${clients.filter((c) => !c.active).length} hidden` : ""}
          </h2>
          <ul className="grid divide-y divide-line sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-3 [&>li]:border-line sm:[&>li]:border-b">
            {clients.map((c) => (
              <ClientRow key={c.id} client={c} />
            ))}
          </ul>
        </Card>
      ) : null}
      {!linkError && clients.some((c) => c.active) ? (
        <Card className="p-4">
          <h2 className="heading-sm">Which team looks after each client</h2>
          <p className="mb-2 text-sm text-muted">Team leaders see their team&apos;s clients, with their open tasks, on their dashboard.</p>
          {teams?.length ? (
            <div className="divide-y divide-line">
              {clients
                .filter((c) => c.active)
                .map((c) => (
                  <ClientTeamsForm key={c.id} clientId={c.id} name={c.name} teams={teams} chosen={(links ?? []).filter((l) => l.client_id === c.id).map((l) => l.team_id)} />
                ))}
            </div>
          ) : (
            <p className="text-sm text-muted">Add teams on the Teams page first.</p>
          )}
        </Card>
      ) : null}
    </>
  );
}

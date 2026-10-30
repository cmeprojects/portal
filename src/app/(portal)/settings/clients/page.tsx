// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { SectionTabs } from "@/components/section-tabs";
import { AddClientForm, ClientRow } from "../../cars/manage/forms";

export const metadata: Metadata = { title: "Clients" };

// The company's client list, used by Cars and by built features (for example Fluid intake).
export default async function ClientsPage() {
  await requireRole(PEOPLE_MANAGERS);
  const supabase = await createClient();
  const { data } = await supabase.from("car_clients").select("id, name, reference, active").order("active", { ascending: false }).order("name");
  const clients = data ?? [];
  return (
    <>
      <SectionTabs section="people" current="/settings/clients" />
      <PageHeader
        title="Clients"
        intro="The people you support. Staff choose from this list in Cars and in features like Fluid intake. Staff only ever see the name, never the reference."
      />
      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Add a client</h2>
        <AddClientForm />
      </Card>
      {clients.length ? (
        <Card className="overflow-hidden">
          <h2 className="heading-sm border-b border-line px-5 py-3">Clients · {clients.length}</h2>
          <ul className="divide-y divide-line">
            {clients.map((c) => (
              <ClientRow key={c.id} client={c} />
            ))}
          </ul>
        </Card>
      ) : null}
    </>
  );
}

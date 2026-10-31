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
    </>
  );
}

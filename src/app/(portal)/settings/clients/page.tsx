// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";
import { ClientCareForm, ProgramRow, AddProgramForm, SchemeRow, type Scheme } from "./care-forms";
import { getMyAdminAreas } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader } from "@/components/ui";
import { AddClientForm, ClientRow } from "../../cars/manage/forms";
import { ClientTeamsForm } from "./team-form";

export const metadata: Metadata = { title: "Clients" };

// The company's client list, used by Cars and by built features (for example Fluid intake).
export default async function ClientsPage() {
  // Who sees Clients: the Access page (update 107); which clients, the database.
  const { profile } = await requireSession();
  if (!(await seesClientsFor())) notFound();
  const supabase = await createClient();
  // cmeprojects (Clients step 1): reference, status and preferred name (after live update 85).
  const care = await supabase.from("car_clients").select("id, name, reference, active, client_ref, status, preferred_name").order("active", { ascending: false }).order("name");
  const { data } = care.error ? await supabase.from("car_clients").select("id, name, reference, active").order("active", { ascending: false }).order("name") : care;
  const clients = (data ?? []) as { id: string; name: string; reference: string; active: boolean; client_ref?: string; status?: string; preferred_name?: string }[];
  const toCheck = clients.filter((c) => c.status === "pending");
  const { data: programs } = care.error ? { data: null } : await supabase.from("client_programs").select("id, name, needs_dob, active, scheme").order("sort_order").order("name");
  const isAdmin = profile.role === "system_admin";
  // cmeprojects (update 110): programs and schemes live in Care settings.
  const canCare = isAdmin || (await getMyAdminAreas(profile.role)).includes("care");
  const schemeRes = await supabase.from("client_schemes").select("key, label, person_word, review_label, change_review_label, review_lead_days, needs_dob").order("sort_order");
  const schemes = schemeRes.error ? [] : ((schemeRes.data ?? []) as Scheme[]);
  const { data: wordRow } = await supabase.from("app_settings").select("value").eq("key", "wording.client").maybeSingle();
  const orgWord = typeof wordRow?.value === "string" && wordRow.value ? wordRow.value : "Client";
  // cmeprojects: which team looks after each client (hidden before live update 54).
  const [{ data: teams }, { data: links, error: linkError }] = await Promise.all([
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("client_teams").select("client_id, team_id"),
  ]);
  return (
    <>
      <PageHeader
        title="Clients"
        intro="The people you support. Each client has a reference (CL-00001) and a status. Staff pick from this list in Cars and features like Fluid intake, and only see the name."
      />
      <Card className="p-4">
        <AddClientForm />
      </Card>
      {toCheck.length ? (
        <Notice tone="info">
          {toCheck.length === 1 ? "1 client is" : `${toCheck.length} clients are`} <strong>to check</strong>: {toCheck.slice(0, 5).map((c) => c.name).join(", ")}
          {toCheck.length > 5 ? " and more" : ""}. Open a client, check their details and set the status (for example Active).
        </Notice>
      ) : null}
      {clients.length ? (
        <Card className="overflow-hidden">
          <h2 className="border-b border-line px-4 py-2 text-sm font-semibold">
            {clients.filter((c) => c.active).length} shown{clients.some((c) => !c.active) ? ` · ${clients.filter((c) => !c.active).length} hidden` : ""}
          </h2>
          <ul className="grid divide-y divide-line sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-3 [&>li]:border-line sm:[&>li]:border-b">
            {clients.map((c) => (
              <ClientRow key={c.id} client={c}>
                {c.client_ref && c.status ? (
                  <>
                    <ClientCareForm client={{ id: c.id, name: c.name, client_ref: c.client_ref, status: c.status, preferred_name: c.preferred_name ?? "" }} />
                    <Link href={`/settings/clients/${c.id}`} className="mt-2 inline-block text-sm font-semibold text-brand hover:underline">
                      Open full profile (locations, contacts, safety, services)
                    </Link>
                  </>
                ) : null}
              </ClientRow>
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
      {programs ? (
        <Card className="p-4">
          <h2 className="heading-sm">Programs and schemes</h2>
          <p className="mb-2 text-sm text-muted">
            {canCare
              ? "Every program sits under one scheme (NDIS, Support at Home, Private or Other). The scheme decides the wording and rules, so they never mix. Add or rename programs, or untick In use; a program is never deleted, and its scheme can't change once a service uses it."
              : "The programs clients' services come under, each under its scheme. Changed in Care settings."}
          </p>
          <ul className="divide-y divide-line">
            {programs.map((p) => (
              <ProgramRow key={p.id} program={p} canEdit={canCare} schemes={schemes} />
            ))}
          </ul>
          {canCare && schemes.length ? <AddProgramForm schemes={schemes} /> : null}
          {schemes.length ? (
            <div className="mt-4 border-t border-line pt-3">
              <h3 className="text-sm font-semibold">Schemes: wording and rules</h3>
              <ul className="divide-y divide-line">
                {schemes.map((sc) => (
                  <SchemeRow key={sc.key} scheme={sc} canEdit={canCare} orgWord={orgWord} />
                ))}
              </ul>
            </div>
          ) : null}
        </Card>
      ) : null}
    </>
  );
}

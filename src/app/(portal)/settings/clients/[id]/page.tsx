// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { ArrowLeft } from "lucide-react";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { ClientStatusChip } from "../../../cars/manage/forms";
import { ClientCareForm } from "../care-forms";
import { NoAlertsButton, SectionForm } from "./section-form";
import { ALERT_KINDS, PERSON_KINDS, SECTION_FIELDS, SECTION_UPDATE, SERVICE_STATUS, type SectionTable } from "@/lib/client-sections";

export const metadata: Metadata = { title: "Client" };

type Row = Record<string, unknown> & { id: string };
const label = (list: [string, string][], key: unknown) => list.find(([k]) => k === key)?.[1] ?? String(key ?? "");
const day = (d: unknown) => (typeof d === "string" && d ? new Date(`${d}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

// cmeprojects (Clients & Care steps 1 to 5): one client's profile. Core
// sections (details, locations, people, safety, services) and the readiness
// check rostering will use. People managers and the system admin only; each
// section appears once its database update has been run.
export default async function ClientProfilePage({ params }: PageProps<"/settings/clients/[id]">) {
  await requireRole(PEOPLE_MANAGERS);
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: client } = await supabase.from("car_clients").select("id, name, client_ref, status, preferred_name").eq("id", id).maybeSingle();
  if (!client) notFound();

  const [locations, details, people, alerts, notes, services, programs, readiness] = await Promise.all([
    supabase.from("client_locations").select("*").eq("client_id", id).order("approved", { ascending: false }).order("label"),
    supabase.from("client_details").select("*").eq("client_id", id).maybeSingle(),
    supabase.from("client_people").select("*").eq("client_id", id).order("active", { ascending: false }).order("kind").order("name"),
    supabase.from("client_alerts").select("*").eq("client_id", id).order("active", { ascending: false }).order("severity"),
    supabase.from("client_alert_notes").select("alert_id, details").eq("client_id", id),
    supabase.from("client_services").select("*").eq("client_id", id).order("start_date", { ascending: false }),
    supabase.from("client_programs").select("id, name, active").order("sort_order"),
    supabase.rpc("client_readiness", { p_client: id }),
  ]);
  const ready = readiness.error ? null : (readiness.data as { ready: boolean; gaps: string[]; services: { id: string; label: string; gaps: string[] }[] });
  const noteOf = new Map(((notes.data ?? []) as { alert_id: string; details: string }[]).map((n) => [n.alert_id, n.details]));
  const programChoices: [string, string][] = ((programs.data ?? []) as { id: string; name: string; active: boolean }[]).map((p) => [p.id, p.active ? p.name : `${p.name} (not in use)`]);
  const locationRows = (locations.data ?? []) as Row[];
  const locationChoices: [string, string][] = locationRows.map((l) => [l.id, `${l.label}${l.approved ? "" : " (not approved)"}`]);
  const gapsOf = new Map((ready?.services ?? []).map((s) => [s.id, s.gaps]));

  const missing = (table: SectionTable) => <p className="text-sm text-muted">This section appears after database update {SECTION_UPDATE[table]}.</p>;

  return (
    <>
      <p className="text-sm">
        <Link href="/settings/clients" className="inline-flex items-center gap-1 font-semibold text-brand hover:underline">
          <ArrowLeft aria-hidden="true" className="size-4" /> All clients
        </Link>
      </p>
      <PageHeader title={client.name} intro={`${client.client_ref}${client.preferred_name ? ` · goes by ${client.preferred_name}` : ""}`} />
      <div className="flex flex-wrap items-center gap-3">
        <ClientStatusChip status={client.status} />
        {ready ? (
          ready.ready ? (
            <span className="rounded-full bg-good-soft px-3 py-1 text-xs font-semibold text-ink">Ready for services</span>
          ) : (
            <span className="rounded-full bg-warn-soft px-3 py-1 text-xs font-semibold text-ink">Not ready for services yet</span>
          )
        ) : null}
      </div>
      {ready && !ready.ready && ready.gaps.length ? (
        <Card className="p-4">
          <h2 className="heading-sm">Before services can start</h2>
          <ul className="mt-1 list-disc pl-5 text-sm">
            {ready.gaps.map((g) => (
              <li key={g}>{g}</li>
            ))}
          </ul>
        </Card>
      ) : null}

      <Section title="Details" intro="Status and preferred name, then contact details, date of birth and identifiers (managers only).">
        <ClientCareForm client={{ id: client.id, name: client.name, client_ref: client.client_ref, status: client.status, preferred_name: client.preferred_name ?? "" }} />
        <div className="mt-4 border-t border-line pt-4">
          {details.error ? missing("client_details") : <SectionForm table="client_details" clientId={id} fields={SECTION_FIELDS.client_details} item={(details.data ?? { id: undefined }) as Row} submit="Save details" />}
        </div>
      </Section>

      <Section title="Service locations" intro="Where support happens. A location must be approved before services can use it; staff see approved, current ones with the access instructions.">
        {locations.error ? (
          missing("client_locations")
        ) : (
          <>
            <Items
              rows={locationRows}
              line={(l) => `${l.label} · ${l.address}${l.suburb ? `, ${l.suburb}` : ""}${l.approved ? "" : " · not approved"}${l.to_date ? ` · until ${day(l.to_date)}` : ""}`}
              form={(l) => <SectionForm table="client_locations" clientId={id} fields={SECTION_FIELDS.client_locations} item={l} submit="Save" />}
            />
            <Add label="Add a location">
              <SectionForm table="client_locations" clientId={id} fields={SECTION_FIELDS.client_locations} submit="Add location" />
            </Add>
          </>
        )}
      </Section>

      <Section title="Emergency contacts and representatives" intro="Sensitive: managers only. At least one current emergency contact is needed before services start.">
        {people.error ? (
          missing("client_people")
        ) : (
          <>
            <Items
              rows={(people.data ?? []) as Row[]}
              line={(p) => `${label(PERSON_KINDS, p.kind)} · ${p.name}${p.relationship ? ` (${p.relationship})` : ""}${p.active ? "" : " · not current"}`}
              form={(p) => <SectionForm table="client_people" clientId={id} fields={SECTION_FIELDS.client_people} item={p} submit="Save" />}
            />
            <Add label="Add a person">
              <SectionForm table="client_people" clientId={id} fields={SECTION_FIELDS.client_people} submit="Add person" />
            </Add>
          </>
        )}
      </Section>

      <Section title="Safety" intro="Alerts and what workers must do (staff in the client's team see current ones). Detailed risk notes are for managers only. Record 'no known safety alerts' if there are none.">
        {alerts.error ? (
          missing("client_alerts")
        ) : (
          <>
            <Items
              rows={((alerts.data ?? []) as Row[]).map((a) => ({ ...a, notes: noteOf.get(a.id) ?? "" }))}
              line={(a) => (a.kind === "no_known_alerts" ? `No known safety alerts${a.active ? "" : " · not current"}` : `${label(ALERT_KINDS, a.kind)} · ${a.title} · ${String(a.severity)}${a.active ? "" : " · not current"}`)}
              form={(a) =>
                a.kind === "no_known_alerts" ? (
                  <SectionForm table="client_alerts" clientId={id} fields={SECTION_FIELDS.client_alerts.filter((f) => f.name === "active")} item={a} submit="Save" />
                ) : (
                  <SectionForm table="client_alerts" clientId={id} fields={SECTION_FIELDS.client_alerts} item={a} submit="Save" />
                )
              }
            />
            <Add label="Add an alert">
              <SectionForm table="client_alerts" clientId={id} fields={SECTION_FIELDS.client_alerts} submit="Add alert" />
            </Add>
            {!((alerts.data ?? []) as Row[]).some((a) => a.active) ? <NoAlertsButton clientId={id} /> : null}
          </>
        )}
      </Section>

      <Section title="Service arrangements" intro="What the client receives, under which program, where and when. A service can only be made active when the client is ready for it.">
        {services.error ? (
          missing("client_services")
        ) : (
          <>
            <Items
              rows={(services.data ?? []) as Row[]}
              line={(s) => {
                const gaps = gapsOf.get(s.id);
                return `${s.label} · ${label(programChoices, s.program_id)} · ${label(SERVICE_STATUS, s.status)} · from ${day(s.start_date)}${s.end_date ? ` to ${day(s.end_date)}` : ""}${gaps?.length ? ` · ${gaps.length} to fix` : ""}`;
              }}
              form={(s) => (
                <>
                  {gapsOf.get(s.id)?.length ? (
                    <ul className="mb-2 list-disc pl-5 text-sm text-danger">
                      {gapsOf.get(s.id)!.map((g) => (
                        <li key={g}>{g}</li>
                      ))}
                    </ul>
                  ) : null}
                  <SectionForm table="client_services" clientId={id} fields={SECTION_FIELDS.client_services} item={s} choices={{ program_id: programChoices, location_id: locationChoices }} submit="Save" />
                </>
              )}
            />
            {locationChoices.length ? (
              <Add label="Add a service">
                <SectionForm table="client_services" clientId={id} fields={SECTION_FIELDS.client_services} choices={{ program_id: programChoices.filter(([, l]) => !l.endsWith("(not in use)")), location_id: locationChoices }} submit="Add service" />
              </Add>
            ) : (
              <p className="text-sm text-muted">Add a service location first.</p>
            )}
          </>
        )}
      </Section>
    </>
  );
}

function Section({ title, intro, children }: { title: string; intro: string; children: ReactNode }) {
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div>
        <h2 className="heading-sm">{title}</h2>
        <p className="text-sm text-muted">{intro}</p>
      </div>
      {children}
    </Card>
  );
}

function Items({ rows, line, form }: { rows: Row[]; line: (r: Row) => string; form: (r: Row) => ReactNode }) {
  if (!rows.length) return <p className="text-sm text-muted">None yet.</p>;
  return (
    <ul className="divide-y divide-line rounded-md border border-line">
      {rows.map((r) => (
        <li key={r.id} className="px-3 py-2">
          <details name="client-item" className="group">
            <summary className="flex cursor-pointer list-none items-center gap-3 text-sm [&::-webkit-details-marker]:hidden">
              <span className="min-w-0 flex-1">{line(r)}</span>
              <span className="text-xs font-semibold text-brand group-open:hidden">Edit</span>
              <span className="hidden text-xs font-semibold text-brand group-open:inline">Close</span>
            </summary>
            <div className="mt-3">{form(r)}</div>
          </details>
        </li>
      ))}
    </ul>
  );
}

function Add({ label: text, children }: { label: string; children: ReactNode }) {
  return (
    <details className="group rounded-md border border-dashed border-line px-3 py-2">
      <summary className="cursor-pointer list-none text-sm font-semibold text-brand [&::-webkit-details-marker]:hidden">+ {text}</summary>
      <div className="mt-3">{children}</div>
    </details>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { ArrowLeft } from "lucide-react";
import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { ClientStatusChip } from "../../../cars/manage/forms";
import { ClientCareForm } from "../care-forms";
import { NoAlertsButton, SectionForm } from "./section-form";
import { AssignForm } from "./assign-form";
import { CONTACT_WAYS, CommsForm, type Comms } from "./comms-form";
import { archiveClientDocument, endAssignment } from "./actions";
import { DocumentForm } from "./document-form";
import { canDoFor } from "@/lib/module-access";
import { ALERT_KINDS, ASSIGNED_AS, DOC_TYPE_LABELS, PERSON_KINDS, SECTION_FIELDS, SECTION_UPDATE, SERVICE_STATUS, type SectionTable } from "@/lib/client-sections";

export const metadata: Metadata = { title: "Client" };

type Row = Record<string, unknown> & { id: string };
const label = (list: [string, string][], key: unknown) => list.find(([k]) => k === key)?.[1] ?? String(key ?? "");
const day = (d: unknown) => (typeof d === "string" && d ? new Date(`${d}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

// cmeprojects (Clients & Care steps 1 to 5): one client's profile. Core
// sections (details, locations, people, safety, services) and the readiness
// check rostering will use. People managers and the system admin only; each
// section appears once its database update has been run.
export default async function ClientProfilePage({ params }: PageProps<"/settings/clients/[id]">) {
  // Who sees Clients: the Access page (update 107); which clients, the database.
  await requireSession();
  if (!(await seesClientsFor())) notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: client } = await supabase.from("car_clients").select("id, name, client_ref, status, preferred_name").eq("id", id).maybeSingle();
  if (!client) notFound();

  // cmeprojects (Stage 5): who is assigned to this client (hidden before update 106).
  // cmeprojects (Care block C3): client documents, if that section is on.
  type Doc = { id: string; doc_type: string; title: string; file_path: string; file_name: string; expires_on: string | null; version: number; created_at: string };
  const [docsRes, docsOn, canDocs] = await Promise.all([
    supabase.from("client_documents").select("id, doc_type, title, file_path, file_name, expires_on, version, created_at").eq("client_id", id).is("archived_at", null).order("created_at", { ascending: false }),
    supabase.from("app_settings").select("value").eq("key", "care.section_documents").maybeSingle(),
    canDoFor("clients.documents", "edit", id),
  ]);
  const docs = docsRes.error ? null : ((docsRes.data ?? []) as Doc[]);
  const docLinks = new Map<string, string>();
  if (docs?.length) {
    const { data: signed } = await supabase.storage.from("client-docs").createSignedUrls(docs.map((d) => d.file_path), 600);
    for (const sgn of signed ?? []) if (sgn.signedUrl && sgn.path) docLinks.set(sgn.path, sgn.signedUrl);
  }
  const showDocs = docs !== null && docsOn.data?.value !== false && (docs.length > 0 || canDocs);
  // cmeprojects (Care block C2): communication preferences, if that section is on.
  const [commsRes, commsOn, canComms] = await Promise.all([
    supabase.from("client_comms").select("preferred_contact, language, interpreter_needed, accessibility_needs, notes").eq("client_id", id).maybeSingle(),
    supabase.from("app_settings").select("value").eq("key", "care.section_comms").maybeSingle(),
    canDoFor("clients.comms", "edit", id),
  ]);
  const comms = commsRes.error ? undefined : ((commsRes.data ?? null) as Comms | null);
  const showComms = comms !== undefined && commsOn.data?.value !== false;
  const [assignRes, canAssign, staffRes] = await Promise.all([
    supabase.from("client_assignments").select("id, user_id, assigned_as, starts_on, ends_on, note, ended_at").eq("client_id", id).order("ended_at", { ascending: true, nullsFirst: true }).order("starts_on", { ascending: false }),
    canDoFor("clients.assign", "edit", id),
    supabase.from("profiles").select("id, full_name, email, role, active").eq("active", true).neq("role", "new_starter").order("full_name"),
  ]);
  const staffRows = (staffRes.data ?? []) as { id: string; full_name: string | null; email: string; role: string }[];
  const nameOfStaff = new Map(staffRows.map((p) => [p.id, p.full_name || p.email]));
  const assignments = assignRes.error ? null : ((assignRes.data ?? []) as { id: string; user_id: string; assigned_as: string; starts_on: string; ends_on: string | null; note: string; ended_at: string | null }[]);
  const today = new Date().toISOString().slice(0, 10);
  const isCurrent = (a: { starts_on: string; ends_on: string | null; ended_at: string | null }) => !a.ended_at && a.starts_on <= today && (!a.ends_on || a.ends_on >= today);
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
      {showDocs && docs ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Documents</h2>
          {docs.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {docs.map((d) => {
                const expired = d.expires_on && d.expires_on < new Date().toISOString().slice(0, 10);
                return (
                  <li key={d.id} className="px-3 py-2">
                    <div className="flex flex-wrap items-center gap-3">
                      <span className="min-w-40 flex-1">
                        {docLinks.get(d.file_path) ? (
                          <a href={docLinks.get(d.file_path)} target="_blank" rel="noreferrer" className="font-semibold text-brand hover:underline">
                            {d.title}
                          </a>
                        ) : (
                          <span className="font-semibold">{d.title}</span>
                        )}
                        <span className="block text-xs text-muted">
                          {label(DOC_TYPE_LABELS, d.doc_type)} · version {d.version} · added {day(d.created_at.slice(0, 10))}
                          {d.expires_on ? ` · ${expired ? "expired" : "expires"} ${day(d.expires_on)}` : ""}
                        </span>
                      </span>
                      {canDocs ? (
                        <form action={archiveClientDocument}>
                          <input type="hidden" name="id" value={d.id} />
                          <input type="hidden" name="client_id" value={id} />
                          <button className="text-xs font-semibold text-brand underline">Archive</button>
                        </form>
                      ) : null}
                    </div>
                    {canDocs ? (
                      <details className="mt-2">
                        <summary className="cursor-pointer text-xs font-semibold text-brand">Add a new version</summary>
                        <div className="mt-2">
                          <DocumentForm clientId={id} replaces={{ id: d.id, title: d.title, doc_type: d.doc_type }} />
                        </div>
                      </details>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">No documents yet.</p>
          )}
          {canDocs ? (
            <Add label="Add a document">
              <DocumentForm clientId={id} />
            </Add>
          ) : null}
        </Card>
      ) : null}
      {showComms && (comms || canComms) ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Communication preferences</h2>
          {canComms ? (
            <CommsForm clientId={id} comms={comms ?? null} />
          ) : comms ? (
            <dl className="grid gap-x-4 gap-y-1 text-sm sm:grid-cols-[auto_1fr]">
              <dt className="text-muted">Preferred contact</dt>
              <dd>{label(CONTACT_WAYS, comms.preferred_contact) || "Not set"}</dd>
              <dt className="text-muted">Language</dt>
              <dd>
                {comms.language || "Not set"}
                {comms.interpreter_needed ? " · needs an interpreter" : ""}
              </dd>
              {comms.accessibility_needs ? (
                <>
                  <dt className="text-muted">Needs</dt>
                  <dd className="whitespace-pre-line">{comms.accessibility_needs}</dd>
                </>
              ) : null}
            </dl>
          ) : null}
        </Card>
      ) : null}
      {assignments ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Assigned staff</h2>
          <p className="text-xs text-muted">An assignment gives a staff member this client only when their role allows it (for example case managers: assigned clients). Ending one stops their access straight away; it&apos;s kept for history.</p>
          {assignments.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {assignments.map((a) => (
                <li key={a.id} className={`flex flex-wrap items-center gap-3 px-3 py-2 ${isCurrent(a) ? "" : "text-muted"}`}>
                  <span className="min-w-40 flex-1">
                    <span className="font-semibold">{nameOfStaff.get(a.user_id) ?? "Staff member"}</span> · {label(ASSIGNED_AS, a.assigned_as)}
                    <span className="block text-xs text-muted">
                      From {day(a.starts_on)}
                      {a.ends_on ? ` until ${day(a.ends_on)}` : ""}
                      {a.ended_at ? " · ended" : isCurrent(a) ? "" : " · not started yet"}
                      {a.note ? ` · ${a.note}` : ""}
                    </span>
                  </span>
                  {canAssign && !a.ended_at ? (
                    <form action={endAssignment}>
                      <input type="hidden" name="id" value={a.id} />
                      <input type="hidden" name="client_id" value={id} />
                      <button className="text-xs font-semibold text-brand underline">End</button>
                    </form>
                  ) : null}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">Nobody is assigned yet.</p>
          )}
          {canAssign ? <Add label="Assign a staff member"><AssignForm clientId={id} staff={staffRows.map((p) => ({ id: p.id, name: p.full_name || p.email }))} /></Add> : null}
        </Card>
      ) : null}
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

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
import { archiveClientDocument, endAssignment, setCareGoalStatus, setCarePlanStatus, setWorkerInstructionActive } from "./actions";
import { CloseReviewForm, ReviewForm, type SchemeWords } from "./review-form";
import { CareGoalForm, CarePlanForm, WorkerInstructionForm, type CarePlan } from "./care-plan-form";
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
  // cmeprojects (Care block C4): care plans, goals and worker instructions, if that section is on.
  type Goal = { id: string; plan_id: string; goal: string; measure: string; status: string };
  type Instruction = { id: string; title: string; instructions: string; active: boolean };
  const [plansRes, goalsRes, instrRes, plansOn, canPlans] = await Promise.all([
    supabase.from("client_care_plans").select("id, title, status, assessed_on, starts_on, review_by, summary, document_id").eq("client_id", id).order("created_at", { ascending: false }),
    supabase.from("client_care_goals").select("id, plan_id, goal, measure, status").eq("client_id", id).order("sort_order").order("goal"),
    supabase.from("client_worker_instructions").select("id, title, instructions, active").eq("client_id", id).order("active", { ascending: false }).order("sort_order").order("title"),
    supabase.from("app_settings").select("value").eq("key", "care.section_care_plans").maybeSingle(),
    canDoFor("clients.care_plans", "edit", id),
  ]);
  const plans = plansRes.error ? null : ((plansRes.data ?? []) as CarePlan[]);
  const goals = (goalsRes.data ?? []) as Goal[];
  const instructions = instrRes.error ? null : ((instrRes.data ?? []) as Instruction[]);
  const plansSectionOn = plansOn.data?.value !== false;
  const docChoices: [string, string][] = (docs ?? []).map((d) => [d.id, `${d.title} (version ${d.version})`]);
  // cmeprojects (Care block C5): reviews and re-assessments, worded by scheme.
  type Review = { id: string; scheme: string; service_id: string | null; kind: string; due_on: string; reason: string; status: string; completed_on: string | null; outcome: string };
  const [reviewsRes, schemesRes, reviewSvcRes, reviewsOn, canReviews] = await Promise.all([
    supabase.from("client_reviews").select("id, scheme, service_id, kind, due_on, reason, status, completed_on, outcome").eq("client_id", id).order("status").order("due_on"),
    supabase.from("client_schemes").select("key, label, review_label, change_review_label").order("sort_order"),
    supabase.from("client_services").select("id, label, status, client_programs(scheme)").eq("client_id", id).neq("status", "ended"),
    supabase.from("app_settings").select("value").eq("key", "care.section_reviews").maybeSingle(),
    canDoFor("clients.reviews", "edit", id),
  ]);
  const reviews = reviewsRes.error ? null : ((reviewsRes.data ?? []) as Review[]);
  const schemeWords = (schemesRes.data ?? []) as SchemeWords[];
  const reviewServices = ((reviewSvcRes.data ?? []) as unknown as { id: string; label: string; client_programs: { scheme: string } | null }[]).map((v) => ({ id: v.id, label: v.label, scheme: v.client_programs?.scheme ?? "other" }));
  const reviewName = (r: Review) => {
    const w = schemeWords.find((k) => k.key === r.scheme);
    return `${w ? (r.kind === "scheduled" ? w.review_label : w.change_review_label) : "Review"} (${w?.label ?? r.scheme})`;
  };
  const showReviews = reviews !== null && reviewsOn.data?.value !== false && (reviews.length > 0 || canReviews);
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
      {plansSectionOn && plans && (plans.length || canPlans) ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Care plans</h2>
            <p className="text-sm text-muted">Start a draft, add its goals, then make it current (the old plan is archived). A current plan&apos;s wording is fixed: start a new draft to change it. Progress on goals can be updated any time.</p>
          </div>
          {plans.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {plans.map((p) => {
                const planGoals = goals.filter((g) => g.plan_id === p.id);
                return (
                  <li key={p.id} className={`px-3 py-2 ${p.status === "archived" ? "text-muted" : ""}`}>
                    <details name="care-plan" open={p.status === "current"}>
                      <summary className="flex cursor-pointer list-none flex-wrap items-center gap-2 [&::-webkit-details-marker]:hidden">
                        <span className="min-w-40 flex-1 font-semibold">{p.title}</span>
                        <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${p.status === "current" ? "bg-good-soft" : p.status === "draft" ? "bg-warn-soft" : "bg-line"}`}>
                          {p.status === "current" ? "Current" : p.status === "draft" ? "Draft" : "Archived"}
                        </span>
                        {p.review_by ? <span className="text-xs text-muted">review by {day(p.review_by)}</span> : null}
                      </summary>
                      <div className="mt-2 flex flex-col gap-2">
                        {canPlans && p.status === "draft" ? (
                          <CarePlanForm clientId={id} plan={p} documents={docChoices} />
                        ) : (
                          <>
                            <p className="text-xs text-muted">
                              {p.assessed_on ? `Assessed ${day(p.assessed_on)}` : "Assessment date not recorded"}
                              {p.starts_on ? ` · starts ${day(p.starts_on)}` : ""}
                              {p.document_id ? ` · document: ${label(docChoices, p.document_id) || "archived"}` : ""}
                            </p>
                            {p.summary ? <p className="whitespace-pre-line">{p.summary}</p> : null}
                          </>
                        )}
                        <h3 className="text-xs font-semibold uppercase text-muted">Goals</h3>
                        {planGoals.length ? (
                          <ul className="flex flex-col gap-1">
                            {planGoals.map((g) => (
                              <li key={g.id} className="flex flex-wrap items-center gap-2">
                                <span className="min-w-40 flex-1">
                                  {g.goal}
                                  {g.measure ? <span className="block text-xs text-muted">{g.measure}</span> : null}
                                </span>
                                {canPlans && p.status !== "archived" ? (
                                  <form action={setCareGoalStatus} className="flex items-center gap-1">
                                    <input type="hidden" name="id" value={g.id} />
                                    <input type="hidden" name="client_id" value={id} />
                                    <select name="status" defaultValue={g.status} className="rounded border border-line bg-surface px-1 py-0.5 text-xs" aria-label="Progress">
                                      <option value="active">Working on it</option>
                                      <option value="achieved">Achieved</option>
                                      <option value="discontinued">Discontinued</option>
                                    </select>
                                    <button className="text-xs font-semibold text-brand underline">Update</button>
                                  </form>
                                ) : (
                                  <span className="text-xs text-muted">{g.status === "active" ? "Working on it" : g.status === "achieved" ? "Achieved" : "Discontinued"}</span>
                                )}
                              </li>
                            ))}
                          </ul>
                        ) : (
                          <p className="text-xs text-muted">No goals yet.</p>
                        )}
                        {canPlans && p.status === "draft" ? <Add label="Add a goal"><CareGoalForm clientId={id} planId={p.id} /></Add> : null}
                        {canPlans && p.status !== "archived" ? (
                          <div className="flex flex-wrap gap-3">
                            {p.status === "draft" ? (
                              <form action={setCarePlanStatus}>
                                <input type="hidden" name="id" value={p.id} />
                                <input type="hidden" name="client_id" value={id} />
                                <input type="hidden" name="status" value="current" />
                                <button className="text-xs font-semibold text-brand underline">Make this the current plan</button>
                              </form>
                            ) : null}
                            <form action={setCarePlanStatus}>
                              <input type="hidden" name="id" value={p.id} />
                              <input type="hidden" name="client_id" value={id} />
                              <input type="hidden" name="status" value="archived" />
                              <button className="text-xs font-semibold text-brand underline">Archive</button>
                            </form>
                          </div>
                        ) : null}
                      </div>
                    </details>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">No care plans yet.</p>
          )}
          {canPlans ? <Add label="Start a new draft"><CarePlanForm clientId={id} documents={docChoices} /></Add> : null}
        </Card>
      ) : null}
      {plansSectionOn && instructions && (instructions.length || canPlans) ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Worker instructions</h2>
            <p className="text-sm text-muted">What staff do on shift. Staff in the client&apos;s team see the current ones (not the care plan).</p>
          </div>
          {instructions.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {instructions.map((w) => (
                <li key={w.id} className={`flex flex-wrap items-start gap-3 px-3 py-2 ${w.active ? "" : "text-muted"}`}>
                  <span className="min-w-40 flex-1">
                    <span className="font-semibold">{w.title}</span>
                    {w.active ? "" : " · not current"}
                    <span className="block whitespace-pre-line">{w.instructions}</span>
                  </span>
                  {canPlans ? (
                    <form action={setWorkerInstructionActive}>
                      <input type="hidden" name="id" value={w.id} />
                      <input type="hidden" name="client_id" value={id} />
                      <input type="hidden" name="active" value={w.active ? "false" : "true"} />
                      <button className="text-xs font-semibold text-brand underline">{w.active ? "Stop using" : "Use again"}</button>
                    </form>
                  ) : null}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">No worker instructions yet.</p>
          )}
          {canPlans ? <Add label="Add an instruction"><WorkerInstructionForm clientId={id} /></Add> : null}
        </Card>
      ) : null}
      {showReviews && reviews ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Reviews and re-assessments</h2>
            <p className="text-sm text-muted">Each one follows its scheme&apos;s wording and reminders (Care settings). Reminders go to the assigned care manager or support coordinator, else the managers.</p>
          </div>
          {reviews.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {reviews.map((r) => {
                const overdue = r.status === "open" && r.due_on < today;
                return (
                  <li key={r.id} className={`px-3 py-2 ${r.status === "open" ? "" : "text-muted"}`}>
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="min-w-40 flex-1 font-semibold">{reviewName(r)}</span>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${overdue ? "bg-danger-soft" : r.status === "open" ? "bg-warn-soft" : "bg-line"}`}>
                        {r.status === "open" ? (overdue ? "Overdue" : "Open") : r.status === "completed" ? "Completed" : "Cancelled"}
                      </span>
                    </div>
                    <p className="text-xs text-muted">
                      {r.service_id ? `${reviewServices.find((v) => v.id === r.service_id)?.label ?? "Service"} · ` : ""}
                      due {day(r.due_on)}
                      {r.completed_on ? ` · completed ${day(r.completed_on)}` : ""}
                    </p>
                    {r.reason ? <p className="mt-1 whitespace-pre-line">What changed: {r.reason}</p> : null}
                    {r.outcome ? <p className="mt-1 whitespace-pre-line">Outcome: {r.outcome}</p> : null}
                    {canReviews && r.status === "open" ? (
                      <details className="mt-2">
                        <summary className="cursor-pointer text-xs font-semibold text-brand">Close this review</summary>
                        <div className="mt-2">
                          <CloseReviewForm clientId={id} reviewId={r.id} documents={docChoices} />
                        </div>
                      </details>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">No reviews yet.</p>
          )}
          {canReviews ? (
            <>
              <Add label="Schedule a review"><ReviewForm clientId={id} kind="scheduled" services={reviewServices} schemes={schemeWords} /></Add>
              <Add label="Raise a change of situation"><ReviewForm clientId={id} kind="change_of_situation" services={reviewServices} schemes={schemeWords} /></Add>
            </>
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

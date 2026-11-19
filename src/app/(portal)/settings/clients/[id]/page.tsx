// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { after } from "next/server";
import type { ReactNode } from "react";
import { ArrowLeft, Mail, MapPin, Pencil, Phone, X } from "lucide-react";
import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice } from "@/components/ui";
import { ClientStatusChip } from "../../../cars/manage/forms";
import { ArchiveClientForm, ClientCareForm } from "../care-forms";
import { NoAlertsButton, SectionForm } from "./section-form";
import { AssignForm } from "./assign-form";
import { CommsForm, type Comms } from "./comms-form";
import { AddServicePanel, ServiceEditForm, type CatalogueItem, type ServiceRow } from "./service-form";
import { CommsLogForm, CommsLogList, type CommEntry } from "./comms-log";
import { SchemePicker } from "./scheme-picker";
import { ReportIncidentForm } from "../../../incidents/forms";
import { INCIDENT_KINDS, INCIDENT_SEVERITY, INCIDENT_STATUS, label as incLabel } from "@/lib/incidents";
import { ExtendAccessForm, GiveAccessForm } from "./practitioner-form";
import { archiveClientDocument, makeClientActive, promoteClientService, endPractitionerAccess, shareWithPractitioners, endAgreement, endFunding, endAssignment, setCareGoalStatus, setCarePlanStatus, setWorkerInstructionActive } from "./actions";
import { FundingForm, FundingUsedForm, type Funding } from "./funding-form";
import { AgreementForm, SignAgreementForm, type Agreement } from "./agreement-form";
import { CloseReviewForm, ReviewForm, type SchemeWords } from "./review-form";
import { CareGoalForm, CarePlanForm, WorkerInstructionForm, type CarePlan } from "./care-plan-form";
import { DocumentForm } from "./document-form";
import { canDo, canDoFor } from "@/lib/module-access";
import { ALERT_KINDS, ARCHIVE_REASONS, ASSIGNED_AS, DOC_TYPE_LABELS, GENDERS, LIVING, PERSON_KINDS, PLAN_MANAGEMENT, PRACTITIONER_SECTIONS, CLIENT_STATUS, COMMS_CONTACT_WAYS, TIME_ZONES, TITLES, SECTION_FIELDS, SECTION_UPDATE, type SectionTable } from "@/lib/client-sections";

export const metadata: Metadata = { title: "Client" };

type Row = Record<string, unknown> & { id: string };
const label = (list: [string, string][], key: unknown) => list.find(([k]) => k === key)?.[1] ?? String(key ?? "");
const day = (d: unknown) => (typeof d === "string" && d ? new Date(`${d}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

// cmeprojects (Clients & Care steps 1 to 5): one client's profile. Core
// sections (details, locations, people, safety, services) and the readiness
// check rostering will use. People managers and the system admin only; each
// section appears once its database update has been run.
export default async function ClientProfilePage({ params, searchParams }: PageProps<"/settings/clients/[id]">) {
  // Who sees Clients: the Access page (update 107); which clients, the database.
  const { profile: viewer } = await requireSession();
  if (!(await seesClientsFor())) notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const full = await supabase.from("car_clients").select("id, name, client_ref, status, preferred_name, title, given_name, middle_name, family_name, archive_reason, archive_note, archived_at").eq("id", id).maybeSingle();
  // Before update 118 the extra columns don't exist yet.
  const { data: client } = (full.error ? await supabase.from("car_clients").select("id, name, client_ref, status, preferred_name").eq("id", id).maybeSingle() : full) as {
    data: { id: string; name: string; client_ref: string; status: string; preferred_name: string | null; title?: string; given_name?: string; middle_name?: string; family_name?: string; archive_reason?: string | null; archive_note?: string; archived_at?: string | null } | null;
  };
  if (!client) notFound();
  // cmeprojects (update 140, owner's privacy decision): staff opening a client's
  // page is recorded (at most once an hour each), after the page is sent.
  // (Cookies can't be read inside after() in a page, so the signed-in client is made first.)
  const since = new Date(Date.parse(new Date().toISOString()) - 3_600_000).toISOString();
  after(async () => {
    const { data: recent, error } = await supabase.from("client_staff_views").select("id").eq("client_id", id).eq("user_id", viewer.id).gte("viewed_at", since).limit(1);
    if (!error && !recent?.length) await supabase.from("client_staff_views").insert({ client_id: id });
  });
  const viewsRes = await supabase.from("client_staff_views").select("user_id, viewed_at").eq("client_id", id).gte("viewed_at", new Date(Date.parse(new Date().toISOString()) - 30 * 86_400_000).toISOString()).order("viewed_at", { ascending: false }).limit(200);
  const canSeeViews = !viewsRes.error && (await canDoFor("clients.assign", "edit", id));
  const lastOpened = new Map<string, { at: string; times: number }>();
  for (const v of canSeeViews ? ((viewsRes.data ?? []) as { user_id: string; viewed_at: string }[]) : []) {
    const was = lastOpened.get(v.user_id);
    lastOpened.set(v.user_id, { at: was?.at ?? v.viewed_at, times: (was?.times ?? 0) + 1 });
  }
  const sp = await searchParams;
  // cmeprojects (owner's concept): View shows one tab at a time; Edit walks
  // through the sections in steps (Basic details, Support needs, Documents,
  // Funding). The same sections and checks either way.
  const STEPS: [string, string][] = [["basic", "Basic details"], ["support", "Support needs"], ["documents", "Documents"], ["funding", "Funding and agreements"]];
  const step = typeof sp.edit === "string" && STEPS.some(([k]) => k === sp.edit) ? sp.edit : null;
  const tab = typeof sp.tab === "string" ? sp.tab : "overview";

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
  // cmeprojects (Care block C6): service agreements, one scheme each (from the service's program).
  const [agreementsRes, agreementsOn, canAgreements] = await Promise.all([
    supabase.from("client_agreements").select("id, service_id, scheme, status, starts_on, ends_on, signed_on, signed_by_name, document_id, notes").eq("client_id", id).order("status").order("starts_on", { ascending: false }),
    supabase.from("app_settings").select("value").eq("key", "care.section_agreements").maybeSingle(),
    canDoFor("clients.agreements", "edit", id),
  ]);
  const agreements = agreementsRes.error ? null : ((agreementsRes.data ?? []) as Agreement[]);
  const schemeLabel = (k: string) => schemeWords.find((w) => w.key === k)?.label ?? k;
  const agreementServices: [string, string][] = reviewServices.map((v) => [v.id, `${v.label} (${schemeLabel(v.scheme)})`]);
  const showAgreements = agreements !== null && agreementsOn.data?.value !== false && (agreements.length > 0 || canAgreements);
  const AGREEMENT_STATUS: Record<string, string> = { draft: "Draft", sent: "Sent for signing", signed: "Signed", ended: "Ended" };
  // cmeprojects (Care block C7): funding and budgets, scheme rules kept apart.
  const [fundingRes, fundingOn, canFunding] = await Promise.all([
    supabase.from("client_funding").select("id, service_id, scheme, period_start, period_end, total_amount, used_amount, used_as_of, plan_management, classification, status, notes").eq("client_id", id).order("status").order("period_start", { ascending: false }),
    supabase.from("app_settings").select("value").eq("key", "care.section_funding").maybeSingle(),
    canDoFor("clients.funding", "edit", id),
  ]);
  const funding = fundingRes.error ? null : ((fundingRes.data ?? []) as Funding[]);
  const showFunding = funding !== null && fundingOn.data?.value !== false && (funding.length > 0 || canFunding);
  const aud = (n: number) => Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" });
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
    supabase.from("client_programs").select("id, name, active, scheme").order("sort_order"),
    supabase.rpc("client_readiness", { p_client: id }),
  ]);
  const ready = readiness.error ? null : (readiness.data as { ready: boolean; gaps: string[]; services: { id: string; label: string; gaps: string[] }[] });
  const noteOf = new Map(((notes.data ?? []) as { alert_id: string; details: string }[]).map((n) => [n.alert_id, n.details]));
  const programScheme = new Map(((programs.data ?? []) as { id: string; scheme?: string }[]).map((p) => [p.id, p.scheme ?? "other"]));
  const programChoices: [string, string][] = ((programs.data ?? []) as { id: string; name: string; active: boolean }[]).map((p) => [p.id, p.active ? p.name : `${p.name} (not in use)`]);
  const locationRows = (locations.data ?? []) as Row[];
  const locationChoices: [string, string][] = locationRows.map((l) => [l.id, `${l.label}${l.approved ? "" : " (not approved)"}`]);
  const gapsOf = new Map((ready?.services ?? []).map((s) => [s.id, s.gaps]));

  const TAB_SECTIONS: Record<string, string[]> = {
    overview: ["overview", "ready"],
    profile: ["details", "locations", "people", "safety", "comms"],
    services: ["services"],
    documents: ["docs"],
    care: ["plans", "instructions"],
    reviews: ["reviews"],
    agreements: ["agreements"],
    funding: ["funding"],
    staff: ["staff"],
    shifts: ["shifts"],
    comms: ["commslog"],
    incidents: ["incidents"],
    practitioners: ["practitioners"],
  };
  const STEP_SECTIONS: Record<string, string[]> = {
    basic: ["details", "locations", "staff"],
    support: ["comms", "people", "safety", "services"],
    documents: ["docs"],
    funding: ["funding", "agreements"],
  };
  const inView = (key: string) => (step ? STEP_SECTIONS[step] : (TAB_SECTIONS[tab] ?? TAB_SECTIONS.overview)).includes(key);
  // cmeprojects (rostering round 2; premium package): this client's shifts, last week to four weeks ahead.
  const { features: feats, live: liveFeats } = await requireSession();
  // cmeprojects (update 150): the SIL house they live in (switch on; the database decides who sees it).
  const homeRes = liveFeats.sil_houses === true ? await supabase.from("sil_house_residents").select("room, moved_in, sil_houses(id, name)").eq("client_id", id).is("moved_out", null).maybeSingle() : null;
  const home = homeRes && !homeRes.error && homeRes.data ? (homeRes.data as unknown as { room: string; moved_in: string; sil_houses: { id: string; name: string } | null }) : null;
  const clientShifts =
    feats.rostering !== false && (await canDo("ops.roster", "view"))
      ? ((
          await supabase
            .from("shifts")
            .select("id, worker_id, starts_at, ends_at, break_minutes, status, service_id")
            .eq("client_id", id)
            .neq("status", "cancelled")
            .gte("starts_at", new Date(Date.parse(new Date().toISOString()) - 7 * 86_400_000).toISOString())
            .lte("starts_at", new Date(Date.parse(new Date().toISOString()) + 28 * 86_400_000).toISOString())
            .order("starts_at")
        ).data as { id: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; status: string; service_id: string | null }[] | null)
      : null;
  // cmeprojects (update 134): shift notes for this client, last 60 days. Shown to
  // people who roster or who see the client's care plans (the database decides).
  const canNotes = feats.rostering !== false && (await canDoFor("clients.care_plans", "view", id));
  type ShiftNote = { shift_id: string; worker_id: string; delivered: string; client_wellbeing: string; concern: boolean; concern_note: string; created_at: string };
  const notesRes = canNotes
    ? await supabase
        .from("shift_service_records")
        .select("shift_id, worker_id, delivered, client_wellbeing, concern, concern_note, created_at")
        .eq("client_id", id)
        .gte("created_at", new Date(Date.parse(new Date().toISOString()) - 60 * 86_400_000).toISOString())
        .order("created_at", { ascending: false })
        .limit(60)
    : null;
  const shiftNotes = notesRes && !notesRes.error ? ((notesRes.data ?? []) as unknown as ShiftNote[]) : null;
  const shiftNoteOf = new Map((shiftNotes ?? []).map((n) => [n.shift_id, n]));
  const WELLBEING: Record<string, [string, string]> = {
    settled: ["Settled", "bg-good-soft"],
    some_concerns: ["Some concerns", "bg-warn-soft"],
    unwell_or_distressed: ["Unwell or distressed", "bg-danger-soft text-danger"],
  };
  // cmeprojects: the "To check" checklist (pending clients only): what's done and what's missing.
  const checking = client.status === "pending";
  const svcRows = ((services.data ?? []) as { id: string; label: string; status: string; program_id: string; location_id: string; consent_required: boolean; consent_given_on: string | null }[]).filter((v) => v.status !== "ended");
  const gapRes = checking
    ? await Promise.all([
        supabase.rpc("client_gaps", { p_client: id, p_program: null, p_location: null, p_consent_required: false, p_consent_given: null }),
        ...svcRows.map((v) => supabase.rpc("client_gaps", { p_client: id, p_program: v.program_id, p_location: v.location_id, p_consent_required: v.consent_required, p_consent_given: v.consent_given_on })),
      ])
    : [];
  // The first check has no service, so no location to look at: its location message is ignored.
  const allGaps = [...new Set(gapRes.flatMap((r, i) => ((r.data ?? []) as string[]).filter((g) => i > 0 || !/location/i.test(g))))].filter((g) => !/isn't active yet/.test(g));
  // Services whose own location isn't approved and current today (dates included).
  const badLocationServices = svcRows.filter((_, i) => ((gapRes[i + 1]?.data ?? []) as string[]).some((g) => /location/i.test(g))).map((v) => v.label);
  const todaySyd = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
  const currentApproved = locationRows.some((l) => l.approved && (!l.from_date || String(l.from_date) <= todaySyd) && (!l.to_date || String(l.to_date) >= todaySyd));
  const has = (re: RegExp) => !allGaps.some((g) => re.test(g));
  // update 148: the scheme chosen at registration (not asked before it runs).
  const schemeRes = checking ? await supabase.from("car_clients").select("scheme").eq("id", id).maybeSingle() : null;
  const regScheme = (schemeRes?.data as { scheme?: string | null } | null)?.scheme ?? null;
  const checklist: [string, boolean, string, string][] = checking
    ? [
        ...(schemeRes && !schemeRes.error ? [["Funded by (NDIS, Support at Home, …)", !!regScheme, regScheme ? (schemeWords.find((w) => w.key === regScheme)?.label ?? regScheme) : "Not chosen", `/settings/clients/${id}#to-check`] as [string, boolean, string, string]] : []),
        ["At least one approved service", svcRows.length > 0, svcRows.length ? svcRows.map((v) => v.label).join(", ") : "None yet", `/settings/clients/${id}?tab=services#services`],
        [
          "An approved service location",
          currentApproved && !badLocationServices.length,
          !locationRows.some((l) => l.approved)
            ? "Add and approve the address where support happens"
            : !currentApproved
              ? "The approved location isn't current today: check its From and To dates"
              : badLocationServices.length
                ? `${badLocationServices.join(", ")} uses a location that isn't approved or current. Choose the approved location on the service.`
                : "Approved",
          badLocationServices.length && currentApproved ? `/settings/clients/${id}?tab=services#services` : `/settings/clients/${id}?tab=profile#locations`,
        ],
        ["An emergency contact", has(/emergency/i), has(/emergency/i) ? "Recorded" : "Add one under Emergency contacts", `/settings/clients/${id}?tab=profile#emergency`],
        ["Safety answered", has(/safety/i), has(/safety/i) ? "Recorded" : "Add an alert, or record \"No known safety alerts\"", `/settings/clients/${id}?tab=profile#safety`],
        ["Date of birth (if the program needs it)", has(/date of birth/i), has(/date of birth/i) ? "Done" : "Needed for this program", `/settings/clients/${id}?tab=profile#details`],
        ["NDIS number / My Aged Care ID", has(/NDIS number|My Aged Care/i), has(/NDIS number|My Aged Care/i) ? "Done" : allGaps.filter((g) => /NDIS number|My Aged Care/i.test(g)).join(" "), `/settings/clients/${id}?tab=profile#details`],
        ["Consent (where a service needs it)", has(/consent/i), has(/consent/i) ? "Done" : "Record the consent date on the service", `/settings/clients/${id}?tab=services#services`],
      ]
    : [];
  // The registered scheme also decides what's needed before any service is added.
  if (checking && regScheme) {
    const det0 = (details.data ?? null) as { date_of_birth?: string | null; ndis_number?: string | null; aged_care_id?: string | null } | null;
    const { data: sc } = await supabase.from("client_schemes").select("needs_dob").eq("key", regScheme).maybeSingle();
    const dobRow = checklist.find(([l]) => l.startsWith("Date of birth"));
    if (dobRow && sc?.needs_dob && !det0?.date_of_birth) {
      dobRow[1] = false;
      dobRow[2] = `Needed for ${schemeWords.find((w) => w.key === regScheme)?.label ?? regScheme}`;
    }
    const idRow = checklist.find(([l]) => l.startsWith("NDIS number"));
    const idMissing = regScheme === "ndis" ? !det0?.ndis_number : regScheme === "support_at_home" ? !det0?.aged_care_id : false;
    if (idRow && idMissing) {
      idRow[1] = false;
      idRow[2] = regScheme === "ndis" ? "The NDIS number is needed" : "The My Aged Care ID is needed";
    }
  }
  const readyToActivate = checking && checklist.every(([, ok]) => ok);
  // cmeprojects (update 147): the communication log (the database decides who sees it).
  const [logRes, canWriteComms] = await Promise.all([
    supabase.from("client_communications").select("id, happened_at, method, direction, with_whom, summary, follow_up, follow_up_by, follow_up_done_at, author_id").eq("client_id", id).order("happened_at", { ascending: false }).limit(200),
    canDoFor("clients.comms", "edit", id),
  ]);
  const commsLog: CommEntry[] | null = logRes.error
    ? null
    : ((logRes.data ?? []) as (Omit<CommEntry, "author"> & { author_id: string })[]).map((e) => ({ ...e, author: nameOfStaff.get(e.author_id) ?? "Staff member" }));
  // cmeprojects (update 149): this client's incidents (the database decides who sees them).
  const [incRes, canReportIncident] = await Promise.all([
    supabase.from("client_incidents").select("id, ref, kind, severity, summary, status, occurred_at, reportable, reported_to_regulator_at, report_due_at").eq("client_id", id).order("occurred_at", { ascending: false }).limit(100),
    canDoFor("clients.incidents", "edit", id),
  ]);
  const incidents = incRes.error ? null : ((incRes.data ?? []) as { id: string; ref: string; kind: string; severity: string; summary: string; status: string; occurred_at: string; reportable: boolean; reported_to_regulator_at: string | null; report_due_at: string | null }[]);
  // cmeprojects: one shift opened in a pop-up (people who can see the roster).
  const shiftParam = typeof sp.shift === "string" && /^[0-9a-f-]{36}$/.test(sp.shift) ? sp.shift : "";
  type ShiftView = { id: string; ref?: string; worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; status: string; service_id: string | null; location_id: string | null; shift_type?: string; shift_type_other?: string; notes: string; extra_notes?: string; signatures_needed?: string[]; notified_at?: string | null };
  const [viewRes, viewTypes, viewResidents, viewAnswer] = shiftParam && clientShifts
    ? await Promise.all([
        supabase.from("shifts").select("*").eq("id", shiftParam).maybeSingle(),
        supabase.from("shift_types").select("key, label"),
        supabase.from("shift_residents").select("client_id").eq("shift_id", shiftParam),
        supabase.from("shift_responses").select("response").eq("shift_id", shiftParam).maybeSingle(),
      ])
    : [null, null, null, null];
  const viewShift = (viewRes?.data ?? null) as ShiftView | null;
  const viewNote = viewShift ? shiftNoteOf.get(viewShift.id) : undefined;
  const [{ data: viewSvc }, { data: viewLoc }, { data: viewWho }] = viewShift
    ? await Promise.all([
        viewShift.service_id ? supabase.from("client_services").select("label").eq("id", viewShift.service_id).maybeSingle() : Promise.resolve({ data: null }),
        viewShift.location_id ? supabase.from("client_locations").select("label, address, suburb").eq("id", viewShift.location_id).maybeSingle() : Promise.resolve({ data: null }),
        supabase.from("car_clients").select("id, name").in("id", ((viewResidents?.data ?? []) as { client_id: string }[]).map((r) => r.client_id).concat(["00000000-0000-0000-0000-000000000000"])),
      ])
    : [{ data: null }, { data: null }, { data: [] }];
  const SIG_LABEL: Record<string, string> = { worker_in: "worker at clock in", worker_out: "worker at clock out", client_out: "client at clock out", representative_out: "representative at clock out" };
  // cmeprojects (update 124, Stage 6; premium): Allied Health practitioners for this client.
  const seesPractitioners = feats.allied_health !== false && (await canDoFor("clients.external", "view", id));
  type PAccess = { id: string; user_id: string; sections: string[]; starts_on: string; ends_on: string; consent_on: string; reason: string; ended_at: string | null; created_at: string };
  const [pAccessRes, pNotesRes, pViewsRes, pSharedRes, pPeopleRes, canGivePractitioners] = seesPractitioners
    ? await Promise.all([
        supabase.from("client_external_access").select("id, user_id, sections, starts_on, ends_on, consent_on, reason, ended_at, created_at").eq("client_id", id).order("created_at", { ascending: false }),
        supabase.from("client_practitioner_notes").select("id, author_id, note_date, body").eq("client_id", id).order("note_date", { ascending: false }).limit(30),
        supabase.from("client_external_views").select("user_id, viewed_at").eq("client_id", id).order("viewed_at", { ascending: false }).limit(200),
        supabase.from("client_documents").select("id").eq("client_id", id).eq("shared_with_practitioners", true),
        supabase.from("profiles").select("id, full_name, email").eq("role", "external").eq("active", true).order("full_name"),
        canDoFor("clients.external", "edit", id),
      ])
    : [null, null, null, null, null, false];
  const practitionerAccess = pAccessRes && !pAccessRes.error ? ((pAccessRes.data ?? []) as PAccess[]) : null;
  const practitionerNotes = (pNotesRes?.data ?? []) as { id: string; author_id: string | null; note_date: string; body: string }[];
  const lastViewed = new Map<string, string>();
  for (const v of (pViewsRes?.data ?? []) as { user_id: string; viewed_at: string }[]) if (!lastViewed.has(v.user_id)) lastViewed.set(v.user_id, v.viewed_at);
  const sharedDocs = new Set(((pSharedRes?.data ?? []) as { id: string }[]).map((x) => x.id));
  const practitionerPeople = ((pPeopleRes?.data ?? []) as { id: string; full_name: string | null; email: string }[]).map((x) => [x.id, x.full_name || x.email] as [string, string]);
  const practitionerName = new Map(practitionerPeople);
  const todayAu = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
  const in14Days = new Date(Date.parse(`${todayAu}T12:00:00Z`) + 14 * 86_400_000).toISOString().slice(0, 10);
  const plusMonths = (n: number) => {
    const d = new Date(`${todayAu}T12:00:00`);
    d.setMonth(d.getMonth() + n);
    return d.toISOString().slice(0, 10);
  };
  const tabs: [string, string, boolean][] = [
    ["overview", "Overview", true],
    ["profile", "Profile", true],
    ["services", "Services", true],
    ["documents", "Documents", showDocs],
    ["care", "Care plans", plansSectionOn && !!plans && (plans.length > 0 || canPlans)],
    ["reviews", "Reviews", showReviews],
    ["agreements", "Agreements", showAgreements],
    ["funding", "Funding", showFunding],
    ["staff", "Assigned staff", !!assignments],
    ["shifts", "Shifts and notes", !!clientShifts || !!shiftNotes],
    ["comms", "Communication log", !!commsLog && (commsLog.length > 0 || canWriteComms)],
    ["incidents", "Incidents", !!incidents && (incidents.length > 0 || canReportIncident)],
    ["practitioners", "Practitioners", !!practitionerAccess],
  ];
  const canEditClient = await canDoFor("clients.list", "edit", id);
  // cmeprojects (update 143): the service catalogue, client shift types, and who may edit or promote services.
  const [catRes, typeRes, canEditServices, maRes] = await Promise.all([
    supabase.from("service_catalogue").select("id, name, description, schemes, shift_types, active, promoted_from").order("sort_order").order("name"),
    supabase.from("shift_types").select("*").eq("active", true).order("sort_order"),
    canDoFor("clients.services", "edit", id),
    supabase.rpc("is_manager_admin"),
  ]);
  const catalogueAll = catRes.error ? [] : ((catRes.data ?? []) as (CatalogueItem & { active: boolean; promoted_from: string | null })[]);
  const promoted = new Set(catalogueAll.map((c) => c.promoted_from).filter((v): v is string => !!v));
  const typeRows = (typeRes.data ?? []) as { key: string; label: string; used_for?: string }[];
  const clientShiftTypes: [string, string][] = typeRows.filter((t) => !t.used_for || t.used_for !== "internal").map((t) => [t.key, t.label]);
  const shiftTypeName = new Map(typeRows.map((t) => [t.key, t.label]));
  const canPromote = !catRes.error && (viewer.role === "system_admin" || maRes.data === true);
  // cmeprojects (owner, 19 Nov 2026): what's missing before this client can be rostered,
  // shown at the top of their page. The same rules the roster checks: the client is
  // active (To check done), a current approved service that lists its shift types,
  // and an approved service location.
  const rosterBlocks: [string, string][] = [];
  // A service that starts later isn't a gap: they can be rostered from that day.
  let rosterFrom: { date: string; label: string } | null = null;
  if (client.status !== "discharged") {
    if (client.status !== "active") {
      if (checking) for (const [l, ok, note, href] of checklist) if (!ok) rosterBlocks.push([`${l}: ${note}`, href]);
      rosterBlocks.push(client.status === "suspended" ? ["Their status is Suspended. Change it to Active to roster them (Profile, Details).", `/settings/clients/${id}?tab=profile#details`] : ["They're not active yet. Finish the To check steps, then Make active.", `/settings/clients/${id}#to-check`]);
    }
    const svcAll = (services.data ?? []) as { id: string; label: string; status: string; start_date: string; end_date: string | null; origin?: string; catalogue_id?: string | null; shift_types?: string[] }[];
    const current = svcAll.filter((v) => ["planned", "active"].includes(v.status) && v.start_date <= todayAu && (!v.end_date || v.end_date >= todayAu));
    const catTypesOf = new Map(catalogueAll.map((c) => [c.id, (c as { shift_types?: string[] }).shift_types ?? []]));
    const typesOf = (v: (typeof svcAll)[number]) => (v.catalogue_id ? (catTypesOf.get(v.catalogue_id) ?? []) : (v.shift_types ?? []));
    // Clients on To check get these from their checklist above.
    if (checking) {
      // nothing more
    } else if (!current.length) {
      const next = svcAll.filter((v) => ["planned", "active"].includes(v.status) && v.start_date > todayAu).sort((a, b) => a.start_date.localeCompare(b.start_date))[0];
      if (next) rosterFrom = { date: next.start_date, label: next.label };
      else rosterBlocks.push(["No current approved service. Add one on the Services tab.", `/settings/clients/${id}?tab=services#services`]);
    } else if (!catRes.error && current.every((v) => v.origin !== undefined && !typesOf(v).length)) {
      rosterBlocks.push([`The current service${current.length === 1 ? "" : "s"} (${current.map((v) => v.label).join(", ")}) ${current.length === 1 ? "doesn't" : "don't"} list any shift types. Set them on the Services tab.`, `/settings/clients/${id}?tab=services#services`]);
    }
    if (!checking && !locationRows.some((l) => l.approved)) rosterBlocks.push(["No approved service location. Add the address where support happens and approve it.", `/settings/clients/${id}?tab=profile#locations`]);
  }
  const det = (details.data ?? null) as Record<string, unknown> | null;
  const str = (v: unknown) => (typeof v === "string" ? v : "");
  const emergency = ((people.data ?? []) as Row[]).filter((p) => p.active && (p.kind === "emergency" || p.primary_contact));
  const activeAlerts = ((alerts.data ?? []) as Row[]).filter((a) => a.active && a.kind !== "no_known_alerts");
  const { data: activity } = await supabase.from("audit_log").select("id, action, created_at, actor_id, details").eq("entity", "client").eq("entity_id", id).order("created_at", { ascending: false }).limit(8);
  const actorIds = [...new Set(((activity ?? []) as { actor_id: string | null }[]).map((a) => a.actor_id).filter((v): v is string => !!v && !nameOfStaff.has(v)))];
  if (actorIds.length) {
    const { data: more } = await supabase.from("profiles").select("id, full_name, email").in("id", actorIds);
    for (const p of (more ?? []) as { id: string; full_name: string | null; email: string }[]) nameOfStaff.set(p.id, p.full_name || p.email);
  }
  const what = (a: string, d: Record<string, unknown>) =>
    a === "client_status"
      ? `Status changed from ${CLIENT_STATUS[String(d.from)] ?? d.from} to ${CLIENT_STATUS[String(d.to)] ?? d.to}`
      : a.replace(/^client_/, "").replace(/_(added|changed)$/, " $1").replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase());
  const initials = client.name.split(/\s+/).map((w) => w[0]).filter(Boolean).slice(0, 2).join("").toUpperCase();
  const clientSchemes = [...new Set(((services.data ?? []) as Row[]).filter((v) => v.status !== "ended").map((v) => programScheme.get(String(v.program_id)) ?? "other"))];

  const missing = (table: SectionTable) => <p className="text-sm text-muted">This section appears after database update {SECTION_UPDATE[table]}.</p>;

  return (
    <>
      <p className="text-sm">
        <Link href="/settings/clients" className="inline-flex items-center gap-1 font-semibold text-brand hover:underline">
          <ArrowLeft aria-hidden="true" className="size-4" /> All clients
        </Link>
      </p>
      <Card className="flex flex-col gap-3 p-4">
        <div className="flex flex-wrap items-start gap-4">
          <span aria-hidden="true" className="flex size-14 shrink-0 items-center justify-center rounded-full bg-brand-soft font-display text-lg font-semibold text-brand">
            {initials}
          </span>
          <div className="min-w-0 flex-1">
            <h1 className="heading">{client.name}</h1>
            <p className="text-sm text-muted">
              {client.client_ref}
              {client.preferred_name ? ` · goes by ${client.preferred_name}` : ""}
            </p>
            {det ? (
              <p className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm">
                {str(det.home_address) ? (
                  <span className="inline-flex items-center gap-1">
                    <MapPin aria-hidden="true" className="size-4 text-muted" />
                    {str(det.home_address)}
                  </span>
                ) : null}
                {str(det.email) ? (
                  <span className="inline-flex items-center gap-1">
                    <Mail aria-hidden="true" className="size-4 text-muted" />
                    {str(det.email)}
                  </span>
                ) : null}
                {str(det.phone) ? (
                  <span className="inline-flex items-center gap-1">
                    <Phone aria-hidden="true" className="size-4 text-muted" />
                    {str(det.phone)}
                  </span>
                ) : null}
              </p>
            ) : null}
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <ClientStatusChip status={client.status} />
              {clientSchemes.map((k) => (
                <span key={k} className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">
                  {schemeWords.find((w) => w.key === k)?.label ?? k}
                </span>
              ))}
              {ready && client.status !== "discharged" ? (
                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold text-ink ${rosterBlocks.length ? "bg-warn-soft" : rosterFrom ? "bg-brand-soft" : "bg-good-soft"}`}>{rosterBlocks.length ? "Not ready to roster yet" : rosterFrom ? `Services start ${day(rosterFrom.date)}` : "Ready to roster"}</span>
              ) : null}
            </div>
          </div>
          {canEditClient ? (
            step ? (
              <Link href={`/settings/clients/${id}`} className="rounded-lg border border-line px-3 py-1.5 text-sm font-semibold hover:bg-page">
                Done editing
              </Link>
            ) : (
              <Link href={`/settings/clients/${id}?edit=basic`} className="inline-flex items-center gap-1 rounded-lg border border-brand px-3 py-1.5 text-sm font-semibold text-brand hover:bg-brand-soft">
                <Pencil aria-hidden="true" className="size-4" /> Edit
              </Link>
            )
          ) : null}
        </div>
        {client.status === "discharged" ? (
          <Notice tone="info">
            Archived{client.archived_at ? ` on ${day(client.archived_at.slice(0, 10))}` : ""}
            {client.archive_reason ? `: ${label(ARCHIVE_REASONS, client.archive_reason)}` : ""}
            {client.archive_note ? ` (${client.archive_note})` : ""}. To bring them back, set their status to Active under Edit.
          </Notice>
        ) : null}
        {step ? (
          <ol className="grid grid-cols-2 gap-2 border-t border-line pt-3 sm:grid-cols-4">
            {STEPS.map(([k, l], i) => {
              const at = STEPS.findIndex(([x]) => x === step);
              return (
                <li key={k}>
                  <Link href={`/settings/clients/${id}?edit=${k}`} aria-current={k === step ? "step" : undefined} className="flex flex-col gap-1.5 text-xs font-semibold">
                    <span className={`h-1.5 rounded-full ${i <= at ? "bg-brand" : "bg-line"}`} />
                    <span className={k === step ? "text-ink" : "text-muted"}>
                      {i + 1}. {l}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ol>
        ) : (
          <nav aria-label="Client sections" className="thin-scroll -mx-1 flex gap-1 overflow-x-auto border-t border-line px-1 pt-2">
            {tabs
              .filter(([, , show]) => show)
              .map(([k, l]) => (
                <Link
                  key={k}
                  href={k === "overview" ? `/settings/clients/${id}` : `/settings/clients/${id}?tab=${k}`}
                  scroll={false}
                  className={`shrink-0 rounded-lg px-3 py-1.5 text-sm font-semibold ${tab === k || (k === "overview" && !TAB_SECTIONS[tab]) ? "bg-brand text-brand-fg" : "text-muted hover:bg-page hover:text-ink"}`}
                >
                  {l}
                </Link>
              ))}
          </nav>
        )}
      </Card>
      {rosterBlocks.length && !step ? (
        <div role="status" className="flex flex-col gap-1.5 rounded-xl border border-warn/50 bg-warn-soft px-4 py-3 text-sm text-ink">
          <p className="font-semibold">Can&apos;t be rostered yet: {rosterBlocks.length} thing{rosterBlocks.length === 1 ? "" : "s"} missing</p>
          <ul className="flex flex-col gap-1">
            {rosterBlocks.map(([text, href]) => (
              <li key={text} className="flex flex-wrap items-baseline gap-x-2">
                <span aria-hidden="true">•</span>
                <span className="flex-1">{text}</span>
                <Link href={href} className="text-xs font-semibold text-brand underline">
                  Fix
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
      {!rosterBlocks.length && rosterFrom && !step ? (
        <div role="status" className="rounded-xl border border-brand/20 bg-brand-soft px-4 py-3 text-sm text-ink">
          <span className="font-semibold">Can be rostered from {day(rosterFrom.date)}</span>, when &ldquo;{rosterFrom.label}&rdquo; starts. Shifts before then aren&apos;t allowed.
        </div>
      ) : null}
      {inView("practitioners") && practitionerAccess ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Allied Health practitioners</h2>
            <p className="text-sm text-muted">Outside practitioners see only what you tick, until the end date, and must use two-factor sign-in. Documents show to them only when marked &ldquo;Share with practitioners&rdquo; on the Documents tab.</p>
          </div>
          {practitionerAccess.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {practitionerAccess.map((a) => {
                const live = !a.ended_at && a.ends_on >= todayAu;
                const soon = live && a.ends_on <= in14Days;
                return (
                  <li key={a.id} className={`flex flex-col gap-2 px-3 py-2 ${live ? "" : "opacity-60"}`}>
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="flex-1 font-semibold">{practitionerName.get(a.user_id) ?? "Practitioner"}</span>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${!live ? "bg-page ring-1 ring-line" : soon ? "bg-warn-soft" : "bg-good-soft"}`}>
                        {a.ended_at ? `Ended ${day(a.ended_at.slice(0, 10))}` : live ? `Until ${day(a.ends_on)}` : `Ended ${day(a.ends_on)}`}
                      </span>
                      {live && canGivePractitioners ? (
                        <form action={endPractitionerAccess}>
                          <input type="hidden" name="id" value={a.id} />
                          <input type="hidden" name="client_id" value={id} />
                          <button className="text-xs font-semibold text-danger underline">End now</button>
                        </form>
                      ) : null}
                    </div>
                    <p className="text-xs text-muted">
                      Sees: {a.sections.length ? a.sections.map((s) => PRACTITIONER_SECTIONS.find(([k]) => k === s)?.[1].split(" (")[0] ?? s).join(", ") : "their own reports and notes only"} · consent {day(a.consent_on)}
                      {a.reason ? ` · ${a.reason}` : ""}
                      {lastViewed.get(a.user_id) ? ` · last opened ${new Date(lastViewed.get(a.user_id)!).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}` : " · not opened yet"}
                    </p>
                    {live && canGivePractitioners ? (
                      <details>
                        <summary className="cursor-pointer text-xs font-semibold text-brand">Extend or change what they see</summary>
                        <div className="mt-2">
                          <ExtendAccessForm id={a.id} clientId={id} endsOn={a.ends_on} sections={a.sections} today={todayAu} maxEnd={plusMonths(12)} />
                        </div>
                      </details>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">No practitioners have access.</p>
          )}
          {canGivePractitioners ? (
            <Add label="Give a practitioner access">
              <GiveAccessForm clientId={id} people={practitionerPeople} documents={(docs ?? []).map((x) => [x.id, x.title] as [string, string])} today={todayAu} defaultEnd={plusMonths(6)} maxEnd={plusMonths(12)} />
            </Add>
          ) : null}
          <div className="flex flex-col gap-2 border-t border-line pt-3">
            <h3 className="text-sm font-semibold">Practitioner notes</h3>
            {practitionerNotes.length ? (
              practitionerNotes.map((n) => (
                <div key={n.id} className="rounded-md border border-line p-3 text-sm">
                  <p className="text-xs text-muted">
                    {day(n.note_date)} · {(n.author_id && practitionerName.get(n.author_id)) || "Practitioner"}
                  </p>
                  <p className="mt-1 whitespace-pre-line">{n.body}</p>
                </div>
              ))
            ) : (
              <p className="text-sm text-muted">No notes yet.</p>
            )}
          </div>
        </Card>
      ) : null}
      {inView("commslog") && commsLog ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Communication log</h2>
            <p className="text-sm text-muted">Calls, texts, emails, meetings and letters with the client, their family or others. Entries can be corrected by their author for 24 hours, then stay as written.</p>
          </div>
          {canWriteComms ? (
            <details className="rounded-lg border border-dashed border-line px-3 py-2">
              <summary className="cursor-pointer text-sm font-semibold text-brand">+ Add to the log</summary>
              <div className="mt-3">
                <CommsLogForm clientId={id} />
              </div>
            </details>
          ) : null}
          <CommsLogList clientId={id} entries={commsLog} canWrite={canWriteComms} />
        </Card>
      ) : null}
      {inView("incidents") && incidents ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Incidents</h2>
            <p className="text-sm text-muted">Incidents reported for this client, including ones flagged in shift notes. Open one to follow it up.</p>
          </div>
          {canReportIncident ? (
            <details className="rounded-lg border border-dashed border-line px-3 py-2">
              <summary className="cursor-pointer text-sm font-semibold text-brand">+ Report an incident</summary>
              <div className="mt-3">
                <ReportIncidentForm clientId={id} />
              </div>
            </details>
          ) : null}
          {incidents.length ? (
            <ul className="flex flex-col divide-y divide-line">
              {incidents.map((i) => {
                const [st, stClass] = INCIDENT_STATUS[i.status] ?? [i.status, ""];
                return (
                  <li key={i.id}>
                    <Link href={`/incidents/${i.id}`} className="flex flex-wrap items-center gap-2 py-2 text-sm hover:bg-page">
                      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${stClass}`}>{st}</span>
                      <span className="font-semibold text-ink">{incLabel(INCIDENT_KINDS, i.kind)}</span>
                      <span className={i.severity === "high" || i.severity === "critical" ? "text-danger" : "text-muted"}>{incLabel(INCIDENT_SEVERITY, i.severity)}</span>
                      {i.reportable ? <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-semibold text-danger">{i.reported_to_regulator_at ? "Reportable · reported" : "Reportable"}</span> : null}
                      <span className="min-w-0 flex-1 truncate text-muted">{i.summary}</span>
                      <span className="text-xs text-muted">
                        {i.ref} · {new Date(i.occurred_at).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric" })}
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">No incidents recorded.</p>
          )}
        </Card>
      ) : null}
      {inView("shifts") && shiftNotes ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Shift notes (last 60 days)</h2>
          {shiftNotes.length ? (
            <ul className="flex flex-col gap-2 text-sm">
              {shiftNotes.map((n) => (
                <li key={n.shift_id} className={`rounded-lg border p-3 ${n.concern ? "border-danger" : "border-line"}`}>
                  <p className="flex flex-wrap items-center gap-2 text-xs text-muted">
                    <span className="font-semibold text-ink">{nameOfStaff.get(n.worker_id) ?? "Staff member"}</span>
                    <span>{new Date(n.created_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}</span>
                    {WELLBEING[n.client_wellbeing] ? <span className={`rounded-full px-2 py-0.5 font-semibold ${WELLBEING[n.client_wellbeing][1]}`}>{WELLBEING[n.client_wellbeing][0]}</span> : null}
                    {n.concern ? <span className="rounded-full bg-danger-soft px-2 py-0.5 font-semibold text-danger">Incident or issue</span> : null}
                  </p>
                  <p className="mt-1 whitespace-pre-wrap">{n.delivered}</p>
                  {n.concern && n.concern_note ? <p className="mt-1 whitespace-pre-wrap text-danger">{n.concern_note}</p> : null}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">No shift notes in that time.</p>
          )}
        </Card>
      ) : null}
      {inView("shifts") && clientShifts ? (
        <Card className="flex flex-col gap-3 p-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="heading-sm">Shifts (last week to four weeks ahead)</h2>
            <Link href={`/roster?by=client&add=${new Date().toISOString().slice(0, 10)}&client=${id}`} className="text-sm font-semibold text-brand underline">
              Add a shift
            </Link>
          </div>
          {clientShifts.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {clientShifts.map((sh) => (
                <li key={sh.id} className="flex flex-wrap items-center gap-2 px-3 py-2">
                  <Link href={`/settings/clients/${id}?tab=shifts&shift=${sh.id}`} scroll={false} className="min-w-48 flex-1 font-semibold hover:text-brand">
                    {new Date(sh.starts_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })} – {new Date(sh.ends_at).toLocaleTimeString("en-AU", { timeZone: "Australia/Sydney", hour: "numeric", minute: "2-digit" })}
                  </Link>
                  <span>{sh.worker_id ? (nameOfStaff.get(sh.worker_id) ?? "Staff member") : <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-semibold text-danger">Not filled</span>}</span>
                  {sh.status === "draft" ? <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">Draft</span> : null}
                  {shiftNoteOf.get(sh.id)?.concern ? <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-semibold text-danger">Incident or issue</span> : shiftNoteOf.has(sh.id) ? <span className="rounded-full bg-good-soft px-2 py-0.5 text-xs font-semibold">Notes in</span> : null}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">No shifts in that time.</p>
          )}
        </Card>
      ) : null}
      {checking && !step ? (
        <Card id="to-check" className="flex scroll-mt-24 flex-col gap-3 border-warn/50 p-4 target:ring-2 target:ring-warn">
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div>
              <h2 className="heading-sm">To check: getting {client.preferred_name || client.name.split(" ")[0]} ready</h2>
              <p className="text-sm text-muted">They show in lists but can&apos;t be rostered until they&apos;re active. Finish each step, then make them active.</p>
            </div>
            <span className="rounded-full bg-warn-soft px-2.5 py-0.5 text-xs font-semibold">
              {checklist.filter(([, ok]) => ok).length} of {checklist.length} done
            </span>
          </div>
          <ol className="flex flex-col divide-y divide-line rounded-lg border border-line text-sm">
            {checklist.map(([label, ok, note, href]) => (
              <li key={label} className="flex flex-wrap items-center gap-3 px-3 py-2">
                <span aria-hidden="true" className={`flex size-5 items-center justify-center rounded-full text-xs font-bold ${ok ? "bg-good text-white" : "border-2 border-warn"}`}>
                  {ok ? "✓" : ""}
                </span>
                <span className="min-w-48 flex-1">
                  <span className="font-medium">{label}</span>
                  <span className={`block text-xs ${ok ? "text-muted" : "text-warn"}`}>{note}</span>
                </span>
                {ok ? null : label.startsWith("Funded by") && canEditClient ? (
                  <SchemePicker clientId={id} schemes={schemeWords.map((w) => [w.key, w.label] as [string, string])} />
                ) : (
                  <Link href={href} className="text-xs font-semibold text-brand underline">
                    Do this
                  </Link>
                )}
              </li>
            ))}
          </ol>
          {canEditClient ? (
            readyToActivate ? (
              <form action={makeClientActive} className="flex items-center gap-3">
                <input type="hidden" name="client_id" value={id} />
                <button className="rounded-lg bg-good px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Make active</button>
                <span className="text-xs text-muted">Their pending services that have started become active too.</span>
              </form>
            ) : (
              <p className="text-xs text-muted">&ldquo;Make active&rdquo; appears once every step is done.</p>
            )
          ) : null}
        </Card>
      ) : null}
      {inView("overview") ? (
        <div className="grid gap-3 lg:grid-cols-2">
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">Contact profile</h2>
            {det ? (
              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
                <dt className="text-muted">Full name</dt>
                <dd>{[label(TITLES, client.title ?? ""), client.given_name, client.middle_name, client.family_name].filter((v) => v && v !== "—").join(" ") || client.name}</dd>
                <dt className="text-muted">Date of birth</dt>
                <dd>{day(det.date_of_birth) || "Not recorded"}</dd>
                <dt className="text-muted">Gender</dt>
                <dd>{label(GENDERS, det.gender) || "Not recorded"}</dd>
                <dt className="text-muted">Living situation</dt>
                <dd>{label(LIVING, det.living_situation) || "Not recorded"}</dd>
                {home?.sil_houses ? (
                  <>
                    <dt className="text-muted">Lives at</dt>
                    <dd>
                      <Link href={`/houses/${home.sil_houses.id}`} className="font-medium text-brand hover:underline">
                        {home.sil_houses.name}
                      </Link>
                      {home.room ? ` · ${home.room}` : ""} · since {day(home.moved_in)}
                    </dd>
                  </>
                ) : null}
                <dt className="text-muted">Time zone</dt>
                <dd>{label(TIME_ZONES, det.time_zone) || "Sydney"}</dd>
                {str(det.ndis_number) ? (
                  <>
                    <dt className="text-muted">NDIS number</dt>
                    <dd className="tabular-nums">{str(det.ndis_number)}</dd>
                  </>
                ) : null}
                {str(det.aged_care_id) ? (
                  <>
                    <dt className="text-muted">My Aged Care ID</dt>
                    <dd>{str(det.aged_care_id)}</dd>
                  </>
                ) : null}
                {Array.isArray(det.tags) && det.tags.length ? (
                  <>
                    <dt className="text-muted">Tags</dt>
                    <dd className="flex flex-wrap gap-1">
                      {(det.tags as string[]).map((t) => (
                        <span key={t} className="rounded-full bg-page px-2 py-0.5 text-xs ring-1 ring-line">
                          {t}
                        </span>
                      ))}
                    </dd>
                  </>
                ) : null}
              </dl>
            ) : (
              <p className="text-sm text-muted">Personal details are for people who manage this client.</p>
            )}
          </Card>
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">About</h2>
            <p className="whitespace-pre-line text-sm">{str(det?.about) || <span className="text-muted">Nothing recorded yet.</span>}</p>
          </Card>
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">Emergency contacts</h2>
            {people.error ? (
              <p className="text-sm text-muted">For people who manage this client.</p>
            ) : emergency.length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {emergency.map((p) => (
                  <li key={p.id}>
                    <span className="font-semibold">{String(p.name)}</span>
                    {p.relationship ? ` (${String(p.relationship)})` : ""} · {label(PERSON_KINDS, p.kind)}
                    {p.phone ? <span className="block text-muted">{String(p.phone)}</span> : null}
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-warn">No emergency contact yet.</p>
            )}
          </Card>
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">Communication preferences</h2>
            {comms ? (
              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
                <dt className="text-muted">Contact method</dt>
                <dd>{label(COMMS_CONTACT_WAYS, comms.preferred_contact) || "Not set"}</dd>
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
            ) : (
              <p className="text-sm text-muted">Not recorded yet.</p>
            )}
          </Card>
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">Safety</h2>
            {activeAlerts.length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {activeAlerts.map((a) => (
                  <li key={a.id}>
                    <span className="font-semibold">{String(a.title)}</span> · {label(ALERT_KINDS, a.kind)} · {String(a.severity)}
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted">No active alerts.</p>
            )}
          </Card>
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">Managed by</h2>
            {assignments?.filter(isCurrent).length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {assignments.filter(isCurrent).map((a) => (
                  <li key={a.id}>
                    <span className="font-semibold">{nameOfStaff.get(a.user_id) ?? "Staff member"}</span> · {label(ASSIGNED_AS, a.assigned_as)}
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted">Nobody assigned.</p>
            )}
          </Card>
          {activity?.length ? (
            <Card className="flex flex-col gap-2 p-4 lg:col-span-2">
              <h2 className="heading-sm">Recent activity</h2>
              <ul className="flex flex-col divide-y divide-line text-sm">
                {(activity as { id: string; action: string; created_at: string; actor_id: string | null; details: Record<string, unknown> }[]).map((a) => (
                  <li key={a.id} className="flex flex-wrap gap-x-3 py-1.5">
                    <span className="flex-1">{what(a.action, a.details ?? {})}</span>
                    <span className="text-xs text-muted">
                      {a.actor_id ? `${nameOfStaff.get(a.actor_id) ?? "Someone"} · ` : ""}
                      {new Date(a.created_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" })}
                    </span>
                  </li>
                ))}
              </ul>
            </Card>
          ) : null}
        </div>
      ) : null}
      {inView("docs") && showDocs && docs ? (
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
                      {canDocs && practitionerAccess ? (
                        <form action={shareWithPractitioners}>
                          <input type="hidden" name="id" value={d.id} />
                          <input type="hidden" name="client_id" value={id} />
                          <input type="hidden" name="shared" value={sharedDocs.has(d.id) ? "0" : "1"} />
                          <button className={`rounded-full px-2 py-0.5 text-xs font-semibold ${sharedDocs.has(d.id) ? "bg-good-soft" : "text-brand underline"}`}>
                            {sharedDocs.has(d.id) ? "Shared with practitioners ✓" : "Share with practitioners"}
                          </button>
                        </form>
                      ) : null}
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
      {inView("plans") && plansSectionOn && plans && (plans.length || canPlans) ? (
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
      {inView("instructions") && plansSectionOn && instructions && (instructions.length || canPlans) ? (
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
      {inView("reviews") && showReviews && reviews ? (
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
      {inView("agreements") && showAgreements && agreements ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Service agreements</h2>
            <p className="text-sm text-muted">One per service, under that service&apos;s scheme. Once signed, its dates and signature are fixed: add a new agreement for changes.</p>
          </div>
          {agreements.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {agreements.map((a) => (
                <li key={a.id} className={`px-3 py-2 ${a.status === "ended" ? "text-muted" : ""}`}>
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="min-w-40 flex-1 font-semibold">
                      {reviewServices.find((v) => v.id === a.service_id)?.label ?? "Service"} · {schemeLabel(a.scheme)}
                    </span>
                    <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${a.status === "signed" ? "bg-good-soft" : a.status === "ended" ? "bg-line" : "bg-warn-soft"}`}>{AGREEMENT_STATUS[a.status] ?? a.status}</span>
                  </div>
                  <p className="text-xs text-muted">
                    From {day(a.starts_on)}
                    {a.ends_on ? ` to ${day(a.ends_on)}` : ""}
                    {a.signed_on ? ` · signed ${day(a.signed_on)} by ${a.signed_by_name}` : ""}
                    {a.document_id ? ` · document: ${label(docChoices, a.document_id) || "archived"}` : ""}
                  </p>
                  {a.notes ? <p className="mt-1 whitespace-pre-line">{a.notes}</p> : null}
                  {canAgreements && a.status !== "ended" ? (
                    <div className="mt-2 flex flex-col gap-2">
                      {a.status !== "signed" ? (
                        <>
                          <details>
                            <summary className="cursor-pointer text-xs font-semibold text-brand">Change</summary>
                            <div className="mt-2"><AgreementForm clientId={id} agreement={a} services={agreementServices} documents={docChoices} /></div>
                          </details>
                          <details>
                            <summary className="cursor-pointer text-xs font-semibold text-brand">Record as signed</summary>
                            <div className="mt-2"><SignAgreementForm clientId={id} agreementId={a.id} documents={docChoices} /></div>
                          </details>
                        </>
                      ) : null}
                      <form action={endAgreement}>
                        <input type="hidden" name="id" value={a.id} />
                        <input type="hidden" name="client_id" value={id} />
                        <button className="text-xs font-semibold text-brand underline">End this agreement</button>
                      </form>
                    </div>
                  ) : null}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">No service agreements yet.</p>
          )}
          {canAgreements ? (
            agreementServices.length ? (
              <Add label="Add an agreement"><AgreementForm clientId={id} services={agreementServices} documents={docChoices} /></Add>
            ) : (
              <p className="text-sm text-muted">Add a service first.</p>
            )
          ) : null}
        </Card>
      ) : null}
      {inView("funding") && showFunding && funding ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Funding and budgets</h2>
            <p className="text-sm text-muted">One budget per service and period, under that service&apos;s scheme. A record for planning (AUD), not invoicing.</p>
          </div>
          {funding.length ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {funding.map((f) => {
                const total = Number(f.total_amount);
                const used = Number(f.used_amount);
                const pct = total > 0 ? Math.min(100, Math.round((used / total) * 100)) : 0;
                return (
                  <li key={f.id} className={`px-3 py-2 ${f.status === "ended" ? "text-muted" : ""}`}>
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="min-w-40 flex-1 font-semibold">
                        {reviewServices.find((v) => v.id === f.service_id)?.label ?? "Service"} · {schemeLabel(f.scheme)}
                        {f.plan_management ? ` · ${label(PLAN_MANAGEMENT, f.plan_management)}` : ""}
                        {f.classification ? ` · classification ${f.classification}` : ""}
                      </span>
                      {f.status === "ended" ? <span className="rounded-full bg-line px-2 py-0.5 text-xs font-semibold">Ended</span> : null}
                    </div>
                    <p className="text-xs text-muted">
                      {day(f.period_start)} to {day(f.period_end)} · {aud(used)} of {aud(total)} used ({pct}%){f.used_as_of ? ` as at ${day(f.used_as_of)}` : ""} · {aud(Math.max(0, total - used))} left
                    </p>
                    <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-line" aria-hidden="true">
                      <div className={`h-full ${pct >= 90 ? "bg-danger" : pct >= 75 ? "bg-warn" : "bg-good"}`} style={{ width: `${pct}%` }} />
                    </div>
                    {f.notes ? <p className="mt-1 whitespace-pre-line">{f.notes}</p> : null}
                    {canFunding && f.status !== "ended" ? (
                      <div className="mt-2 flex flex-col gap-2">
                        <details>
                          <summary className="cursor-pointer text-xs font-semibold text-brand">Update what&apos;s been used</summary>
                          <div className="mt-2"><FundingUsedForm clientId={id} funding={f} /></div>
                        </details>
                        <form action={endFunding}>
                          <input type="hidden" name="id" value={f.id} />
                          <input type="hidden" name="client_id" value={id} />
                          <button className="text-xs font-semibold text-brand underline">End this budget</button>
                        </form>
                      </div>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">No budgets yet.</p>
          )}
          {canFunding ? (
            reviewServices.length ? (
              <Add label="Add a budget"><FundingForm clientId={id} services={reviewServices.map((v) => ({ ...v, schemeLabel: schemeLabel(v.scheme) }))} /></Add>
            ) : (
              <p className="text-sm text-muted">Add a service first.</p>
            )
          ) : null}
        </Card>
      ) : null}
      {inView("comms") && showComms && (comms || canComms) ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Communication preferences</h2>
          {canComms ? (
            <CommsForm clientId={id} comms={comms ?? null} />
          ) : comms ? (
            <dl className="grid gap-x-4 gap-y-1 text-sm sm:grid-cols-[auto_1fr]">
              <dt className="text-muted">Preferred contact</dt>
              <dd>{label(COMMS_CONTACT_WAYS, comms.preferred_contact) || "Not set"}</dd>
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
      {inView("staff") && canSeeViews ? (
        <Card className="flex flex-col gap-2 p-4">
          <h2 className="heading-sm">Who opened this page (last 30 days)</h2>
          <p className="text-xs text-muted">Recorded at most once an hour for each person. Only people who assign staff to this client see this.</p>
          {lastOpened.size ? (
            <ul className="divide-y divide-line rounded-md border border-line text-sm">
              {[...lastOpened].map(([u, v]) => (
                <li key={u} className="flex flex-wrap justify-between gap-2 px-3 py-1.5">
                  <span className="font-semibold">{nameOfStaff.get(u) ?? "Staff member"}</span>
                  <span className="text-muted">
                    last {new Date(v.at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })} · {v.times} time{v.times === 1 ? "" : "s"}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">Nobody yet.</p>
          )}
        </Card>
      ) : null}
      {inView("staff") && assignments ? (
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
      {inView("ready") && client.status !== "discharged" && ready && !ready.ready && ready.gaps.length ? (
        <Card className="p-4">
          <h2 className="heading-sm">Before services can start</h2>
          <ul className="mt-1 list-disc pl-5 text-sm">
            {ready.gaps.map((g) => (
              <li key={g}>{g}</li>
            ))}
          </ul>
        </Card>
      ) : null}

      {inView("details") ? (
      <Section anchor="details" title="Details" intro="Status and preferred name, then contact details, date of birth and identifiers (managers only).">
        <ClientCareForm client={{ id: client.id, name: client.name, client_ref: client.client_ref, status: client.status, preferred_name: client.preferred_name ?? "", title: client.title, given_name: client.given_name, middle_name: client.middle_name, family_name: client.family_name }} />
        <div className="mt-4 border-t border-line pt-4">
          {details.error ? missing("client_details") : <SectionForm table="client_details" clientId={id} fields={SECTION_FIELDS.client_details} item={(details.data ?? { id: undefined }) as Row} submit="Save details" />}
        </div>
      </Section>
      ) : null}

      {inView("locations") ? (
      <Section anchor="locations" title="Service locations" intro="Where support happens. A location must be approved before services can use it; staff see approved, current ones with the access instructions.">
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
      ) : null}

      {inView("people") ? (
      <Section anchor="emergency" title="Emergency contacts and representatives" intro="Sensitive: managers only. At least one current emergency contact is needed before services start.">
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
      ) : null}

      {inView("safety") ? (
      <Section anchor="safety" title="Safety" intro="Alerts and what workers must do (staff in the client's team see current ones). Detailed risk notes are for managers only. Record 'no known safety alerts' if there are none.">
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
      ) : null}

      {inView("services") ? (
      <Section anchor="services" title="Approved Services" intro="Each service the client is approved or funded for, one per record. Rostering only offers the shift types a service covers.">
        {services.error ? (
          missing("client_services")
        ) : (
          <>
            {((services.data ?? []) as unknown as ServiceRow[]).length ? (
              <ul className="flex flex-col gap-2">
                {((services.data ?? []) as unknown as (ServiceRow & { catalogue_id?: string | null })[]).map((sv) => {
                  const gaps = gapsOf.get(sv.id);
                  const expired = sv.status !== "ended" && !!sv.end_date && sv.end_date < today;
                  const st = expired ? ["Expired", "bg-line text-muted"] : sv.status === "active" ? ["Active", "bg-good-soft text-good"] : sv.status === "planned" ? ["Pending", "bg-warn-soft"] : sv.status === "on_hold" ? ["Suspended", "bg-danger-soft text-danger"] : ["Ended", "bg-line text-muted"];
                  const types = sv.origin === "catalogue" ? (catalogueAll.find((c) => c.id === sv.catalogue_id)?.shift_types ?? []) : (sv.shift_types ?? []);
                  const agr = (agreements ?? []).filter((x) => x.service_id === sv.id && x.status !== "ended");
                  const fund = (funding ?? []).filter((x) => x.service_id === sv.id && x.status === "active");
                  return (
                    <li key={sv.id} className={`rounded-xl border p-3 ${sv.status === "ended" || expired ? "border-line bg-page" : "border-line"}`}>
                      <div className="flex flex-wrap items-start gap-2">
                        <div className="min-w-48 flex-1">
                          <p className="font-semibold">
                            {sv.label}
                            <span className={`ml-2 rounded-full px-2 py-0.5 text-[11px] font-semibold ${sv.origin === "catalogue" ? "bg-brand-soft text-brand" : sv.origin === "custom" ? "bg-yellow-soft" : "bg-line text-muted"}`}>
                              {sv.origin === "catalogue" ? "Catalogue" : sv.origin === "custom" ? "Custom" : "Older entry"}
                            </span>
                          </p>
                          {sv.description ? <p className="text-sm text-muted">{sv.description}</p> : null}
                        </div>
                        <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${st[1]}`}>{st[0]}</span>
                      </div>
                      <dl className="mt-2 grid grid-cols-[8rem_1fr] gap-x-3 gap-y-0.5 text-sm">
                        <dt className="text-muted">Program</dt>
                        <dd>{label(programChoices, sv.program_id)}</dd>
                        <dt className="text-muted">Dates</dt>
                        <dd>
                          {day(sv.start_date)}
                          {sv.end_date ? ` to ${day(sv.end_date)}` : " onwards"}
                        </dd>
                        <dt className="text-muted">Shift types</dt>
                        <dd>{types.length ? types.map((k) => shiftTypeName.get(k) ?? k).join(", ") : sv.origin === "legacy" ? "Not set (any client shift type for now)" : "None set"}</dd>
                        {agreements ? (
                          <>
                            <dt className="text-muted">Agreement</dt>
                            <dd>{agr.length ? agr.map((x) => `${AGREEMENT_STATUS[x.status] ?? x.status}${x.ends_on ? `, ends ${day(x.ends_on)}` : ""}`).join("; ") : "None yet"}</dd>
                          </>
                        ) : null}
                        {funding ? (
                          <>
                            <dt className="text-muted">Budget</dt>
                            <dd>{fund.length ? fund.map((x) => `${aud(x.used_amount)} of ${aud(x.total_amount)} used`).join("; ") : "None yet"}</dd>
                          </>
                        ) : null}
                      </dl>
                      {gaps?.length ? (
                        <ul className="mt-2 list-disc pl-5 text-sm text-danger">
                          {gaps.map((g) => (
                            <li key={g}>{g}</li>
                          ))}
                        </ul>
                      ) : null}
                      {canEditServices || (canPromote && sv.origin === "custom") ? (
                        <div className="mt-2 flex flex-wrap items-center gap-3">
                          {canEditServices ? (
                            <details className="group w-full">
                              <summary className="cursor-pointer list-none [&::-webkit-details-marker]:hidden">
                                <span className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-3 py-1.5 text-xs font-semibold text-ink shadow-sm hover:border-muted hover:bg-page group-open:hidden">
                                  <Pencil aria-hidden="true" className="size-3.5" /> View and edit details
                                </span>
                                <span className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-3 py-1.5 text-xs font-semibold text-ink shadow-sm hover:border-muted hover:bg-page hidden group-open:inline-flex">
                                  <X aria-hidden="true" className="size-3.5" /> Close
                                </span>
                              </summary>
                              <div className="mt-3">
                                <ServiceEditForm clientId={id} s={sv} programs={programChoices} locations={locationChoices} shiftTypes={clientShiftTypes} />
                              </div>
                            </details>
                          ) : null}
                          {canPromote && sv.origin === "custom" && !promoted.has(sv.id) ? (
                            <form action={promoteClientService}>
                              <input type="hidden" name="id" value={sv.id} />
                              <input type="hidden" name="client_id" value={id} />
                              <button className="text-xs font-semibold text-brand underline">Add to the service catalogue</button>
                            </form>
                          ) : null}
                          {promoted.has(sv.id) ? <span className="text-xs text-muted">In the catalogue now</span> : null}
                        </div>
                      ) : null}
                    </li>
                  );
                })}
              </ul>
            ) : (
              <p className="text-sm text-muted">No approved services yet.</p>
            )}
            {canEditServices ? (
              locationChoices.length ? (
                <AddServicePanel
                  clientId={id}
                  catalogue={catalogueAll.filter((c) => c.active)}
                  programs={((programs.data ?? []) as { id: string; name: string; active: boolean; scheme?: string }[]).filter((x) => x.active).map((x) => [x.id, x.name, x.scheme ?? "other"] as [string, string, string])}
                  locations={locationChoices}
                  shiftTypes={clientShiftTypes}
                />
              ) : (
                <p className="text-sm text-muted">Add a service location first.</p>
              )
            ) : null}
          </>
        )}
      </Section>
      ) : null}
      {step === "basic" && canEditClient && client.status !== "discharged" && client.title !== undefined ? (
        <details className="shadow-card rounded-xl border border-line bg-surface p-4">
          <summary className="cursor-pointer text-sm font-semibold text-danger">Archive this client</summary>
          <div className="mt-3">
            <ArchiveClientForm clientId={id} name={client.name} />
          </div>
        </details>
      ) : null}
      {step ? (
        <div className="flex flex-wrap items-center justify-between gap-2">
          {STEPS.findIndex(([k]) => k === step) > 0 ? (
            <Link href={`/settings/clients/${id}?edit=${STEPS[STEPS.findIndex(([k]) => k === step) - 1][0]}`} className="rounded-lg border border-line px-4 py-2 text-sm font-semibold hover:bg-page">
              ← Back
            </Link>
          ) : (
            <span />
          )}
          <span className="flex gap-2">
            <Link href={`/settings/clients/${id}`} className="rounded-lg px-4 py-2 text-sm font-semibold text-muted hover:bg-page">
              Cancel
            </Link>
            {STEPS.findIndex(([k]) => k === step) < STEPS.length - 1 ? (
              <Link href={`/settings/clients/${id}?edit=${STEPS[STEPS.findIndex(([k]) => k === step) + 1][0]}`} className="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg hover:opacity-90">
                Next →
              </Link>
            ) : (
              <Link href={`/settings/clients/${id}`} className="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg hover:opacity-90">
                Finish
              </Link>
            )}
          </span>
        </div>
      ) : null}
      {viewShift ? (
        <>
          <Link href={`/settings/clients/${id}?tab=shifts`} scroll={false} aria-label="Close" className="fixed inset-0 z-40 bg-black/20" />
          <aside role="dialog" aria-label="Shift" className="thin-scroll fixed inset-y-0 right-0 z-50 flex w-full max-w-md flex-col overflow-y-auto bg-surface shadow-2xl">
            <div className="sticky top-0 flex items-start gap-2 border-b border-line bg-surface p-4">
              <div className="min-w-0 flex-1">
                <h2 className="heading-sm">
                  {new Date(viewShift.starts_at).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", weekday: "long", day: "numeric", month: "long" })}
                </h2>
                <p className="text-sm text-muted">
                  {new Date(viewShift.starts_at).toLocaleTimeString("en-AU", { timeZone: "Australia/Sydney", hour: "numeric", minute: "2-digit" })} – {new Date(viewShift.ends_at).toLocaleTimeString("en-AU", { timeZone: "Australia/Sydney", hour: "numeric", minute: "2-digit" })}
                  {" · "}
                  {((Date.parse(viewShift.ends_at) - Date.parse(viewShift.starts_at)) / 3_600_000).toFixed(1)} h{viewShift.break_minutes ? ` (${viewShift.break_minutes} min unpaid break)` : ""}
                  {viewShift.ref ? ` · ${viewShift.ref}` : ""}
                </p>
                <span className={`mt-1 inline-block rounded-full px-2 py-0.5 text-xs font-semibold ${viewShift.status === "published" ? "bg-good-soft text-good" : "bg-brand-soft text-brand"}`}>
                  {viewShift.status === "published" ? (viewAnswer?.data?.response === "accepted" ? "Published · accepted" : viewAnswer?.data?.response === "declined" ? "Published · declined" : "Published · waiting for answer") : "Draft"}
                </span>
              </div>
              <Link href={`/settings/clients/${id}?tab=shifts`} scroll={false} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
                <X aria-hidden="true" className="size-5" />
              </Link>
            </div>
            <dl className="grid grid-cols-[8rem_1fr] gap-x-3 gap-y-2 p-4 text-sm">
              <dt className="text-muted">Worker</dt>
              <dd>{viewShift.worker_id ? (nameOfStaff.get(viewShift.worker_id) ?? "Staff member") : <span className="font-semibold text-danger">Not filled</span>}</dd>
              <dt className="text-muted">Shift type</dt>
              <dd>
                {((viewTypes?.data ?? []) as { key: string; label: string }[]).find((t) => t.key === viewShift.shift_type)?.label ?? viewShift.shift_type ?? "Standard"}
                {viewShift.shift_type === "other" && viewShift.shift_type_other ? `: ${viewShift.shift_type_other}` : ""}
              </dd>
              <dt className="text-muted">Approved service</dt>
              <dd>{(viewSvc as { label: string } | null)?.label ?? "—"}</dd>
              <dt className="text-muted">Location</dt>
              <dd>{viewLoc ? `${(viewLoc as { label: string }).label}: ${(viewLoc as { address: string }).address}` : "—"}</dd>
              {((viewWho ?? []) as { id: string; name: string }[]).length ? (
                <>
                  <dt className="text-muted">Also supporting</dt>
                  <dd>{((viewWho ?? []) as { id: string; name: string }[]).map((c) => c.name).join(", ")}</dd>
                </>
              ) : null}
              <dt className="text-muted">Instructions</dt>
              <dd className="whitespace-pre-line">{viewShift.notes || "None"}</dd>
              {viewShift.extra_notes ? (
                <>
                  <dt className="text-muted">Additional notes</dt>
                  <dd className="whitespace-pre-line">{viewShift.extra_notes}</dd>
                </>
              ) : null}
              <dt className="text-muted">Signatures</dt>
              <dd>{(viewShift.signatures_needed ?? []).map((k) => SIG_LABEL[k] ?? k).join("; ") || "Not needed"}</dd>
            </dl>
            {shiftNotes ? (
              <div className="border-t border-line p-4">
                <h3 className="mb-1 text-xs font-semibold uppercase text-muted">Shift notes</h3>
                {viewNote ? (
                  <div className={`rounded-lg border p-3 text-sm ${viewNote.concern ? "border-danger" : "border-line"}`}>
                    <p className="flex flex-wrap items-center gap-2 text-xs text-muted">
                      {WELLBEING[viewNote.client_wellbeing] ? <span className={`rounded-full px-2 py-0.5 font-semibold ${WELLBEING[viewNote.client_wellbeing][1]}`}>{WELLBEING[viewNote.client_wellbeing][0]}</span> : null}
                      {viewNote.concern ? <span className="rounded-full bg-danger-soft px-2 py-0.5 font-semibold text-danger">Incident or issue</span> : null}
                    </p>
                    <p className="mt-1 whitespace-pre-wrap">{viewNote.delivered}</p>
                    {viewNote.concern && viewNote.concern_note ? <p className="mt-1 whitespace-pre-wrap text-danger">{viewNote.concern_note}</p> : null}
                  </div>
                ) : (
                  <p className="text-sm text-muted">{Date.parse(viewShift.ends_at) < Date.parse(new Date().toISOString()) ? "No notes from the worker yet." : "Notes come in after the shift."}</p>
                )}
              </div>
            ) : null}
            <div className="mt-auto border-t border-line p-4">
              <Link href={`/roster?by=client&d=${new Date(viewShift.starts_at).toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" })}&shift=${viewShift.id}`} className="text-sm font-semibold text-brand underline">
                Open in the roster to change it
              </Link>
            </div>
          </aside>
        </>
      ) : null}
    </>
  );
}

function Section({ title, intro, children, anchor }: { title: string; intro: string; children: ReactNode; anchor?: string }) {
  return (
    <Card id={anchor} className="flex scroll-mt-24 flex-col gap-3 p-4 target:ring-2 target:ring-brand">
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
              <span className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-3 py-1.5 text-xs font-semibold text-ink shadow-sm hover:border-muted hover:bg-page group-open:hidden">
                <Pencil aria-hidden="true" className="size-3.5" /> Edit
              </span>
              <span className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-3 py-1.5 text-xs font-semibold text-ink shadow-sm hover:border-muted hover:bg-page hidden group-open:inline-flex">
                <X aria-hidden="true" className="size-3.5" /> Close
              </span>
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

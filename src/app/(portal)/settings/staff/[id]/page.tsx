// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { ArrowLeft, Mail, MapPin, Pencil, Phone } from "lucide-react";
import { Avatar } from "@/components/avatar";
import { Card, Notice, buttonClass } from "@/components/ui";
import { ProfileForm } from "@/components/profile-form";
import { requireSession } from "@/lib/session";
import { canDo, managesStaffFor } from "@/lib/module-access";
import { rolesOn, teamsOn } from "@/lib/feature-parts";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { loadPerson } from "@/lib/profiles";
import { DAYS, EMPLOYMENT, SHIFTS } from "@/lib/profiles-shared";
import { assignableRoles, inCoreTeam, JOB_TITLE_COLUMNS, ROLE_LABELS, type JobTitle, type Role } from "@/lib/roles";
import { canHelpSignIn, getPeopleRules } from "@/lib/settings";
import { PersonEditor, type PersonRow } from "../forms";
import { ChecksChip } from "../staff-table";
import { setOffboardingStep } from "./offboarding-actions";
import { LeaveBalanceForm } from "./leave-form";
import { HoldReviewForm, PlanReviewForm } from "./review-forms";
import { REVIEW_KINDS, REVIEW_OUTCOMES } from "@/lib/hr-lists";
import { AddStepForm, OffboardingForm, StartOffboardingForm } from "./offboarding-forms";
import { LEAVING_REASONS } from "@/lib/hr-lists";

export const metadata: Metadata = { title: "Staff member" };

const auDay = (d: string | null | undefined) => (d ? new Date(`${d.slice(0, 10)}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");
const LEAVE: Record<string, string> = { annual: "Annual leave", personal: "Personal (sick/carer's) leave", sick: "Sick leave", carers: "Carer's leave", unpaid: "Unpaid leave", long_service: "Long service leave", compassionate: "Compassionate leave", other: "Leave" };

// cmeprojects (owner's concept, 17 Nov 2026): one staff member's full page.
// View: tabs (Overview, Employment, Documents, Leave, Availability, Teams).
// Edit: steps (Employee information, Role and access, Documents). Only what
// this person may already see; the database decides each part.
export default async function StaffMemberPage({ params, searchParams }: PageProps<"/settings/staff/[id]">) {
  const { profile: me, features } = await requireSession();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  // People who manage staff; team leaders for their own teams' staff (reviews).
  if (!(await managesStaffFor("view")) && !(me.role === "team_leader" && (await supabase.rpc("leads_person", { p_person: id })).data === true)) notFound();
  const { data: base } = await supabase.from("profiles").select("id, full_name, email, role, job_title_id, active, joined_at, onboarded_at").eq("id", id).maybeSingle();
  if (!base) notFound();
  const person = await loadPerson(id);
  if (!person) notFound();
  const sp = await searchParams;
  const STEPS: [string, string][] = [["info", "Employee information"], ["access", "Role and access"], ["documents", "Documents"]];
  const step = typeof sp.edit === "string" && STEPS.some(([k]) => k === sp.edit) ? sp.edit : null;
  const tab = typeof sp.tab === "string" ? sp.tab : "overview";
  const showTeams = me.role === "system_admin" || teamsOn(features);
  const showTitles = me.role === "system_admin" || rolesOn(features);

  const [{ data: checks }, { data: missing }, { data: leave }, { data: contracts }, { data: openTasks }, { data: activity }, { data: titleRows }, { data: teams }, { data: links }, { data: groups }, { data: memberships }, { data: cond }] =
    await Promise.all([
      supabase.rpc("compliance_status", { p_user: id }),
      supabase.rpc("onboarding_missing", { p_user: id }),
      supabase.from("leave_periods").select("id, leave_type, start_date, end_date").eq("user_id", id).order("start_date", { ascending: false }).limit(20),
      supabase.from("contracts").select("id, title, version, status, sent_at, completed_at").eq("user_id", id).order("created_at", { ascending: false }),
      supabase.from("tasks").select("id, title, status, due_date").eq("assigned_to", id).not("status", "in", "(completed,closed)").order("due_date", { ascending: true, nullsFirst: false }).limit(10),
      supabase.from("audit_log").select("id, action, created_at, actor_id").eq("entity_id", id).order("created_at", { ascending: false }).limit(8),
      supabase.from("job_titles").select(JOB_TITLE_COLUMNS).order("sort_order").order("name"),
      supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
      supabase.from("job_title_functions").select("job_title_id, function_group_id"),
      supabase.from("function_groups").select("id, name").eq("active", true),
      supabase.from("team_members").select("team_id").eq("user_id", id),
      supabase.from("people_change_requests").select("id").eq("user_id", id).eq("kind", "conditional").eq("status", "approved").limit(1),
    ]);
  type Check = { item_id: string; kind: string; title: string; state: string; expires_on: string | null };
  const allChecks = ((checks ?? []) as Check[]).filter((c) => c.kind !== "info");
  const expired = allChecks.filter((c) => c.state === "expired").length;
  const expiring = allChecks.filter((c) => c.state === "expiring").length;
  const todo = ((missing ?? []) as string[]).length;
  const groupName = new Map(((groups ?? []) as { id: string; name: string }[]).map((g) => [g.id, g.name]));
  const groupsOf = (t: string | null) => (t ? ((links ?? []) as { job_title_id: string; function_group_id: string }[]).filter((l) => l.job_title_id === t).map((l) => groupName.get(l.function_group_id)).filter(Boolean) as string[] : []);
  const titles = showTitles ? ((titleRows ?? []) as JobTitle[]).map((t) => ({ ...t, groups: groupsOf(t.id) })) : [];
  const roleName = (base.job_title_id && titles.find((t) => t.id === base.job_title_id)?.name) || ROLE_LABELS[base.role as Role];
  const conditional = !!cond?.length && base.role !== "new_starter" && !base.onboarded_at;
  const status = !base.active ? "Deactivated" : base.role !== "new_starter" ? "Active" : base.joined_at ? "Onboarding" : "Invited";
  const priv = person.private;
  const dir = person.directory;
  const teamNames = person.teams;

  // Role and access (the same editor as the Staff page).
  const roles = assignableRoles(me.role);
  const rules = await getPeopleRules();
  const { count: managers } = await supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "manager").eq("active", true);
  let openedLink = false;
  if (step === "access") {
    try {
      const { data } = await createAdminClient().auth.admin.getUserById(id);
      openedLink = Boolean(data.user?.last_sign_in_at);
    } catch {
      openedLink = false;
    }
  }
  const extras = await supabase.from("profiles").select("extra_job_title_ids").eq("id", id).maybeSingle();
  const exempt = me.role === "system_admin" ? await supabase.from("profiles").select("mfa_exempt").eq("id", id).maybeSingle() : null;
  const row: PersonRow = {
    id,
    full_name: base.full_name,
    email: base.email,
    role: base.role as Role,
    job_title_id: base.job_title_id,
    active: base.active,
    missing: base.role === "new_starter" || conditional ? ((missing ?? []) as string[]) : null,
    lastManager: base.role === "manager" && base.active && managers === 1,
    joined: base.role !== "new_starter" || Boolean(base.joined_at),
    openedLink,
    isMe: id === me.id,
    hasPhoto: Boolean(person.photo),
    editable: roles.includes(base.role as Role) || id === me.id,
    teamIds: ((memberships ?? []) as { team_id: string }[]).map((m) => m.team_id),
    mfaExempt: exempt && !exempt.error ? Boolean(exempt.data?.mfa_exempt) : null,
    extraTitleIds: extras.error ? undefined : ((extras.data?.extra_job_title_ids ?? []) as string[]),
  };
  const needsApproval = me.role === "staff_admin" && rules.staffAdminRoleApproval && (base.role !== "new_starter" || rules.firstRoleApproval);
  const canEdit = row.editable && base.role !== "system_admin";
  const nameIds = [...new Set(((activity ?? []) as { actor_id: string | null }[]).map((a) => a.actor_id).filter((v): v is string => !!v))];
  const { data: actors } = nameIds.length ? await supabase.from("profiles").select("id, full_name, email").in("id", nameIds) : { data: [] };
  const actorName = new Map(((actors ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const today = new Date().toISOString().slice(0, 10);
  const daysTo = (d: string) => Math.round((Date.parse(`${d}T00:00:00Z`) - Date.parse(`${today}T00:00:00Z`)) / 86_400_000);

  // cmeprojects (update 119): offboarding (hidden before the update, and for yourself).
  const canOffboard = id !== me.id && (await canDo("hr.offboarding", "view"));
  const canOffboardEdit = canOffboard && (await canDo("hr.offboarding", "edit"));
  type Off = { id: string; reason: string; last_day: string; note: string; exit_notes: string; status: string; started_at: string; closed_at: string | null };
  type OffStep = { id: string; offboarding_id: string; title: string; state: string; done_at: string | null; done_by: string | null; sort_order: number };
  const offRes = canOffboard ? await supabase.from("offboardings").select("id, reason, last_day, note, exit_notes, status, started_at, closed_at").eq("user_id", id).order("started_at", { ascending: false }) : null;
  const offboardings = offRes && !offRes.error ? ((offRes.data ?? []) as Off[]) : null;
  const openOff = offboardings?.find((o) => o.status === "open") ?? null;
  const { data: stepRows } = openOff ? await supabase.from("offboarding_steps").select("id, offboarding_id, title, state, done_at, done_by, sort_order").eq("offboarding_id", openOff.id).order("sort_order") : { data: [] };
  const steps = (stepRows ?? []) as OffStep[];
  // cmeprojects (update 120): leave balances (hidden before the update).
  const balances =
    tab === "leave"
      ? await Promise.all(
          ([["annual", "Annual leave"], ["personal", "Personal/carer's leave"], ["long_service", "Long service leave"]] as [string, string][]).map(async ([k, l]) => {
            const { data, error } = await supabase.rpc("leave_balance", { p_user: id, p_type: k });
            return { key: k, label: l, days: error ? undefined : (data as number | null) };
          }),
        )
      : [];
  const balancesReady = balances.length > 0 && balances.every((b) => b.days !== undefined);
  // cmeprojects (update 121): performance and development (managers, staff
  // admins and their team leaders; hidden before the update and for yourself).
  type Review = { id: string; kind: string; due_on: string; reviewer_id: string | null; status: string; held_on: string | null; summary: string; goals: string; development: string; outcome: string; acknowledged_at: string | null };
  const revRes = id !== me.id ? await supabase.from("staff_reviews").select("id, kind, due_on, reviewer_id, status, held_on, summary, goals, development, outcome, acknowledged_at").eq("user_id", id).order("due_on", { ascending: false }) : null;
  const leadsThem = id !== me.id ? Boolean((await supabase.rpc("leads_person", { p_person: id })).data) : false;
  const canReview = id !== me.id && ((await canDo("hr.performance", "view")) || leadsThem);
  const canReviewEdit = canReview && ((await canDo("hr.performance", "edit")) || leadsThem);
  const reviews = canReview && revRes && !revRes.error ? ((revRes.data ?? []) as Review[]) : null;
  const { data: reviewerRows } =
    reviews && canReviewEdit && tab === "performance"
      ? await supabase.from("profiles").select("id, full_name, email").eq("active", true).in("role", ["manager", "staff_admin", "team_leader"]).neq("id", id).order("full_name")
      : { data: [] };
  const reviewerName = new Map(((reviewerRows ?? []) as { id: string; full_name: string | null; email: string }[]).map((r) => [r.id, r.full_name || r.email]));
  const tabs: [string, string][] = [
    ["overview", "Overview"],
    ["employment", "Employment"],
    ["documents", "Documents"],
    ["leave", "Leave"],
    ["availability", "Availability"],
    ...(showTeams ? ([["teams", "Teams"]] as [string, string][]) : []),
    ...(reviews ? ([["performance", "Performance"]] as [string, string][]) : []),
    ...(offboardings ? ([["offboarding", openOff ? "Offboarding (in progress)" : "Offboarding"]] as [string, string][]) : []),
  ];
  const tabHref = (k: string) => (k === "overview" ? `/settings/staff/${id}` : `/settings/staff/${id}?tab=${k}`);

  const checksList = (
    <>
      <p className="text-sm text-muted">Checks expiring within 60 days are flagged. Update one when it has expired or is expiring; current ones need nothing.</p>
      {allChecks.length ? (
        <ul className="flex flex-col gap-2">
          {allChecks.map((c) => {
            const due = c.expires_on ? daysTo(c.expires_on) : null;
            const needs = c.state === "expired" || c.state === "expiring";
            const [txt, tone] =
              c.state === "expired"
                ? [due !== null ? `Expired ${-due}d ago` : "Expired", "bg-danger-soft text-danger"]
                : c.state === "expiring"
                  ? [due !== null ? `Expires in ${due}d` : "Expiring", "bg-warn-soft"]
                  : c.state === "accepted" || c.state === "done"
                    ? ["Current", "bg-good-soft"]
                    : c.state === "submitted"
                      ? ["Waiting for checking", "bg-brand-soft"]
                      : c.state === "rejected"
                        ? ["Needs redoing", "bg-danger-soft text-danger"]
                        : ["To do", "bg-page ring-1 ring-line"];
            return (
              <li key={c.item_id} className="flex flex-wrap items-center gap-3 rounded-lg border border-line p-3 text-sm">
                <span className="min-w-40 flex-1">
                  <span className="block font-semibold">{c.title}</span>
                  {c.expires_on ? <span className="text-xs text-muted">{due !== null && due < 0 ? "Expired" : "Expires"} {auDay(c.expires_on)}</span> : null}
                </span>
                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tone}`}>{txt}</span>
                {needs ? (
                  <Link href={`/compliance/people/${id}`} className={buttonClass("outline")}>
                    Update
                  </Link>
                ) : null}
              </li>
            );
          })}
        </ul>
      ) : (
        <p className="text-sm text-muted">No checks apply to them.</p>
      )}
      <Link href={`/compliance/people/${id}`} className="w-fit text-sm font-semibold text-brand underline">
        Open their full onboarding record
      </Link>
    </>
  );

  return (
    <>
      <p className="text-sm">
        <Link href="/settings/staff" className="inline-flex items-center gap-1 font-semibold text-brand hover:underline">
          <ArrowLeft aria-hidden="true" className="size-4" /> All staff
        </Link>
      </p>
      <Card className="flex flex-col gap-3 p-4">
        <div className="flex flex-wrap items-start gap-4">
          <Avatar name={person.name} src={person.photo} size={56} className="bg-brand-soft text-lg text-brand" />
          <div className="min-w-0 flex-1">
            <h1 className="heading">{person.name}</h1>
            <p className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm">
              <span className="inline-flex items-center gap-1">
                <Mail aria-hidden="true" className="size-4 text-muted" />
                {person.email}
              </span>
              {dir.work_phone ? (
                <span className="inline-flex items-center gap-1">
                  <Phone aria-hidden="true" className="size-4 text-muted" />
                  {dir.work_phone}
                </span>
              ) : null}
              {priv?.address ? (
                <span className="inline-flex items-center gap-1">
                  <MapPin aria-hidden="true" className="size-4 text-muted" />
                  {priv.address}
                </span>
              ) : null}
            </p>
            <div className="mt-2 flex flex-wrap items-center gap-1.5">
              <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">{roleName}</span>
              <ChecksChip r={{ expired, expiring, todo, status }} />
              {status !== "Active" ? <span className="rounded-full bg-page px-2 py-0.5 text-xs font-semibold ring-1 ring-line">{status}</span> : null}
              {conditional ? <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold">Conditional role</span> : null}
              {openOff ? <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-semibold text-danger">Leaving {auDay(openOff.last_day)}</span> : null}
            </div>
          </div>
          {canEdit ? (
            step ? (
              <Link href={`/settings/staff/${id}`} className="rounded-lg border border-line px-3 py-1.5 text-sm font-semibold hover:bg-page">
                Done editing
              </Link>
            ) : (
              <Link href={`/settings/staff/${id}?edit=info`} className="inline-flex items-center gap-1 rounded-lg border border-brand px-3 py-1.5 text-sm font-semibold text-brand hover:bg-brand-soft">
                <Pencil aria-hidden="true" className="size-4" /> Edit
              </Link>
            )
          ) : null}
        </div>
        {step ? (
          <ol className="grid grid-cols-3 gap-2 border-t border-line pt-3">
            {STEPS.map(([k, l], i) => {
              const at = STEPS.findIndex(([x]) => x === step);
              return (
                <li key={k}>
                  <Link href={`/settings/staff/${id}?edit=${k}`} aria-current={k === step ? "step" : undefined} className="flex flex-col gap-1.5 text-xs font-semibold">
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
          <nav aria-label="Staff member sections" className="thin-scroll -mx-1 flex gap-1 overflow-x-auto border-t border-line px-1 pt-2">
            {tabs.map(([k, l]) => (
              <Link
                key={k}
                href={tabHref(k)}
                scroll={false}
                className={`shrink-0 rounded-lg px-3 py-1.5 text-sm font-semibold ${tab === k || (k === "overview" && !tabs.some(([t]) => t === tab)) ? "bg-brand text-brand-fg" : "text-muted hover:bg-page hover:text-ink"}`}
              >
                {l}
              </Link>
            ))}
          </nav>
        )}
      </Card>

      {step === "info" ? (
        <Card className="p-4">
          <h2 className="heading-sm mb-3">Employee information</h2>
          <ProfileForm person={person} employment={true} />
        </Card>
      ) : step === "access" ? (
        <Card className="p-4">
          <h2 className="heading-sm mb-3">Role and access</h2>
          {row.editable ? (
            <PersonEditor
              person={row}
              roles={roles}
              titles={titles}
              teams={showTeams ? ((teams ?? []) as { id: string; name: string }[]) : []}
              isManager={me.role === "manager" || me.role === "system_admin"}
              canResetMfa={me.role === "system_admin"}
              canHelpSignIn={canHelpSignIn(me.role, rules) && (me.role === "system_admin" || base.role !== "system_admin")}
              needsApproval={needsApproval}
            />
          ) : (
            <p className="text-sm text-muted">Only a system admin can change a system admin.</p>
          )}
        </Card>
      ) : step === "documents" ? (
        <Card className="flex flex-col gap-3 p-4">
          <h2 className="heading-sm">Documents and checks</h2>
          {checksList}
        </Card>
      ) : tab === "performance" && reviews ? (
        <div className="flex flex-col gap-3">
          {reviews.filter((r) => r.status === "planned").map((r) => (
            <Card key={r.id} className="flex flex-col gap-3 p-4">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="heading-sm flex-1">{REVIEW_KINDS.find(([k]) => k === r.kind)?.[1] ?? r.kind}</h2>
                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${r.due_on < today ? "bg-danger-soft text-danger" : "bg-warn-soft"}`}>
                  {r.due_on < today ? "Overdue" : "Due"} {auDay(r.due_on)}
                </span>
              </div>
              {r.reviewer_id ? <p className="text-sm text-muted">Reviewer: {reviewerName.get(r.reviewer_id) ?? (r.reviewer_id === me.id ? "you" : "set")}</p> : null}
              {canReviewEdit ? <HoldReviewForm id={r.id} userId={id} kind={r.kind} today={today} /> : null}
            </Card>
          ))}
          {canReviewEdit ? (
            <Card className="flex flex-col gap-2 p-4">
              <h2 className="heading-sm">Plan a review</h2>
              <p className="text-sm text-muted">Probation reviews, annual reviews and check-ins. The reviewer is reminded 14 days before and if it&apos;s overdue. {person.name} sees it once it&apos;s held, and acknowledges it.</p>
              <PlanReviewForm userId={id} me={me.id} reviewers={((reviewerRows ?? []) as { id: string; full_name: string | null; email: string }[]).map((r) => ({ id: r.id, name: r.full_name || r.email }))} />
            </Card>
          ) : null}
          {reviews.filter((r) => r.status !== "planned").length ? (
            <Card className="p-4">
              <h2 className="heading-sm mb-2">Held and cancelled</h2>
              <ul className="flex flex-col divide-y divide-line text-sm">
                {reviews
                  .filter((r) => r.status !== "planned")
                  .map((r) => (
                    <li key={r.id} className="py-2">
                      <p className="font-semibold">
                        {REVIEW_KINDS.find(([k]) => k === r.kind)?.[1] ?? r.kind} · {r.status === "held" ? `held ${auDay(r.held_on)}` : "cancelled"}
                        {r.outcome ? ` · ${REVIEW_OUTCOMES.find(([k]) => k === r.outcome)?.[1]}` : ""}
                        {r.status === "held" ? <span className="font-normal text-muted"> · {r.acknowledged_at ? `acknowledged ${auDay(r.acknowledged_at)}` : "not acknowledged yet"}</span> : null}
                      </p>
                      {r.summary ? <p className="whitespace-pre-line">{r.summary}</p> : null}
                      {r.goals ? <p className="mt-1 whitespace-pre-line"><span className="text-muted">Goals: </span>{r.goals}</p> : null}
                      {r.development ? <p className="mt-1 whitespace-pre-line"><span className="text-muted">Development: </span>{r.development}</p> : null}
                    </li>
                  ))}
              </ul>
            </Card>
          ) : null}
        </div>
      ) : tab === "offboarding" && offboardings ? (
        <div className="flex flex-col gap-3">
          {openOff ? (
            <Card className="flex flex-col gap-3 p-4">
              <div>
                <h2 className="heading-sm">Offboarding: {LEAVING_REASONS.find(([k]) => k === openOff.reason)?.[1] ?? openOff.reason}</h2>
                <p className="text-sm text-muted">
                  Last day {auDay(openOff.last_day)} · started {auDay(openOff.started_at)}
                  {openOff.note ? ` · ${openOff.note}` : ""}
                </p>
              </div>
              <ul className="flex flex-col divide-y divide-line rounded-lg border border-line text-sm">
                {steps.map((st) => (
                  <li key={st.id} className="flex flex-wrap items-center gap-2 px-3 py-2">
                    <span className={`min-w-48 flex-1 ${st.state !== "todo" ? "text-muted line-through decoration-1" : "font-medium"}`}>{st.title}</span>
                    <span className="text-xs text-muted">{st.state === "done" ? `Done ${auDay(st.done_at)}` : st.state === "not_needed" ? "Not needed" : ""}</span>
                    {canOffboardEdit ? (
                      <span className="flex gap-1">
                        {(st.state === "todo" ? [["done", "Done"], ["not_needed", "Not needed"]] : [["todo", "Undo"]]).map(([v, l]) => (
                          <form key={v} action={setOffboardingStep}>
                            <input type="hidden" name="id" value={st.id} />
                            <input type="hidden" name="user_id" value={id} />
                            <input type="hidden" name="state" value={v} />
                            <button className="rounded-md border border-line px-2 py-1 text-xs font-semibold hover:bg-page">{l}</button>
                          </form>
                        ))}
                      </span>
                    ) : null}
                  </li>
                ))}
              </ul>
              {canOffboardEdit ? (
                <>
                  <AddStepForm offboardingId={openOff.id} userId={id} />
                  {steps.some((st) => st.state === "todo" && st.title.startsWith("Portal account")) && base.active ? (
                    <p className="text-xs text-muted">
                      To deactivate their account, go to{" "}
                      <Link href={`/settings/staff/${id}?edit=access`} className="font-semibold text-brand underline">
                        Edit → Role and access
                      </Link>{" "}
                      (that step then ticks itself).
                    </p>
                  ) : null}
                  <div className="border-t border-line pt-3">
                    <OffboardingForm id={openOff.id} userId={id} lastDay={openOff.last_day} exitNotes={openOff.exit_notes} allDone={steps.every((st) => st.state !== "todo")} />
                  </div>
                </>
              ) : null}
            </Card>
          ) : canOffboardEdit ? (
            <Card className="flex flex-col gap-3 p-4">
              <div>
                <h2 className="heading-sm">Start offboarding</h2>
                <p className="text-sm text-muted">When someone is leaving: record why and their last day, then work through the checklist (car, equipment, client keys, handover, exit interview, final pay, account).</p>
              </div>
              <StartOffboardingForm userId={id} name={person.name} />
            </Card>
          ) : (
            <Card className="p-4">
              <p className="text-sm text-muted">No offboarding in progress.</p>
            </Card>
          )}
          {offboardings.filter((o) => o.status !== "open").length ? (
            <Card className="p-4">
              <h2 className="heading-sm mb-2">Earlier</h2>
              <ul className="flex flex-col gap-1 text-sm">
                {offboardings
                  .filter((o) => o.status !== "open")
                  .map((o) => (
                    <li key={o.id}>
                      {o.status === "completed" ? "Completed" : "Cancelled"} {auDay(o.closed_at)} · {LEAVING_REASONS.find(([k]) => k === o.reason)?.[1] ?? o.reason} · last day {auDay(o.last_day)}
                      {o.exit_notes ? <span className="block whitespace-pre-line text-muted">{o.exit_notes}</span> : null}
                    </li>
                  ))}
              </ul>
            </Card>
          ) : null}
        </div>
      ) : tab === "employment" ? (
        <Card className="p-4">
          <Rows
            rows={[
              ["Role", `${roleName}${groupsOf(base.job_title_id).length ? ` · ${groupsOf(base.job_title_id).join(" · ")}` : ""}`],
              ["Access level", ROLE_LABELS[base.role as Role]],
              ["Employment type", priv ? EMPLOYMENT[priv.employment_type ?? ""] || "Not set" : "—"],
              ["Start date", auDay(priv?.start_date) || "Not recorded"],
              ["Employee ID", priv?.employee_id || "Not recorded"],
              ["Department", dir.department || "Not recorded"],
              ["Status", status],
              ["Conditional role", conditional ? `Yes: onboarding to finish (${todo} to do)` : "No"],
            ]}
          />
        </Card>
      ) : tab === "documents" ? (
        <div className="grid gap-3 lg:grid-cols-2">
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="heading-sm">Checks and qualifications</h2>
            {checksList}
          </Card>
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="heading-sm">Contracts</h2>
            {(contracts ?? []).length ? (
              <ul className="flex flex-col divide-y divide-line text-sm">
                {((contracts ?? []) as { id: string; title: string; version: number; status: string; completed_at: string | null }[]).map((c) => (
                  <li key={c.id} className="flex flex-wrap gap-2 py-1.5">
                    <Link href={`/contracts/${c.id}`} className="flex-1 font-semibold hover:text-brand">
                      {c.title} <span className="font-normal text-muted">v{c.version}</span>
                    </Link>
                    <span className="text-xs text-muted">
                      {c.status.replace(/_/g, " ")}
                      {c.completed_at ? ` · ${auDay(c.completed_at)}` : ""}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted">None you can see.</p>
            )}
          </Card>
        </div>
      ) : tab === "leave" ? (
        <div className="flex flex-col gap-3">
        {balancesReady ? (
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="heading-sm">Leave balances</h2>
            <div className="grid gap-2 sm:grid-cols-3">
              {balances.map((b) => (
                <div key={b.key} className="rounded-lg border border-line p-3">
                  <p className="text-xs text-muted">{b.label}</p>
                  <p className={`font-display text-xl font-semibold ${b.days !== null && b.days !== undefined && b.days < 0 ? "text-danger" : ""}`}>
                    {b.days === null || b.days === undefined ? "—" : `${Number(b.days).toFixed(1)} days`}
                  </p>
                </div>
              ))}
            </div>
            {canEdit && id !== me.id ? (
              <details>
                <summary className="cursor-pointer text-sm font-semibold text-brand">Set a balance</summary>
                <div className="mt-2">
                  <LeaveBalanceForm userId={id} today={today} />
                </div>
              </details>
            ) : null}
          </Card>
        ) : null}
        <Card className="flex flex-col gap-2 p-4">
          <h2 className="heading-sm">Approved leave</h2>
          {(leave ?? []).length ? (
            <ul className="flex flex-col divide-y divide-line text-sm">
              {((leave ?? []) as { id: string; leave_type: string; start_date: string; end_date: string }[]).map((l) => (
                <li key={l.id} className={`flex flex-wrap gap-2 py-1.5 ${l.end_date < today ? "text-muted" : ""}`}>
                  <span className="flex-1 font-semibold">{LEAVE[l.leave_type] ?? l.leave_type.replace(/_/g, " ")}</span>
                  <span>
                    {auDay(l.start_date)}
                    {l.end_date !== l.start_date ? ` to ${auDay(l.end_date)}` : ""}
                    {l.start_date <= today && l.end_date >= today ? " · on leave now" : ""}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">No approved leave recorded.</p>
          )}
          <p className="text-xs text-muted">
            Leave comes from approved requests. See everyone on the{" "}
            <Link href="/people/leave" className="text-brand underline">
              leave calendar
            </Link>
            .
          </p>
        </Card>
        </div>
      ) : tab === "availability" ? (
        <Card className="p-4">
          <h2 className="heading-sm mb-3">Weekly availability</h2>
          {priv ? (
            <div className="overflow-x-auto">
              <table className="text-sm">
                <thead>
                  <tr>
                    <th />
                    {DAYS.map(([d, l]) => (
                      <th key={d} scope="col" className="px-2 py-1 text-xs font-semibold text-muted">
                        {l}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {SHIFTS.map(([s, l]) => (
                    <tr key={s}>
                      <th scope="row" className="pr-3 text-left text-xs font-semibold text-muted">
                        {l}
                      </th>
                      {DAYS.map(([d]) => {
                        const on = (priv.availability?.[d] ?? []).includes(s);
                        return (
                          <td key={d} className="px-1 py-1">
                            <span aria-label={on ? "Available" : "Not available"} className={`block size-7 rounded-md ${on ? "bg-good" : "bg-line/60"}`} />
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p className="text-sm text-muted">Not shared with you.</p>
          )}
        </Card>
      ) : tab === "teams" ? (
        <Card className="p-4">
          <h2 className="heading-sm mb-2">Teams</h2>
          <p className="text-sm">{inCoreTeam(base.role as Role) ? "Core team" : teamNames.length ? teamNames.join(", ") : "No team yet."}</p>
          <p className="mt-2 text-xs text-muted">Change their team under Edit → Role and access.</p>
        </Card>
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          <Card className="p-4">
            <h2 className="heading-sm mb-2">Contact profile</h2>
            <Rows
              rows={[
                ["Full name", person.name],
                ["Preferred name", dir.preferred_name || "—"],
                ["Phone", dir.work_phone || "Not recorded"],
                ["Email", person.email],
                ["Address", priv?.address || (priv ? "Not recorded" : "—")],
                ["Employment", priv ? EMPLOYMENT[priv.employment_type ?? ""] || "Not set" : "—"],
                ["Start date", auDay(priv?.start_date) || "Not recorded"],
                ["Skills", dir.skills.length ? dir.skills.join(", ") : "—"],
              ]}
            />
          </Card>
          <div className="flex flex-col gap-3">
            <Card className="p-4">
              <h2 className="heading-sm mb-2">Emergency contact</h2>
              {priv?.emergency_name || priv?.emergency_phone ? (
                <p className="text-sm">
                  <span className="font-semibold">{priv.emergency_name}</span>
                  {priv.emergency_phone ? <span className="block text-muted">{priv.emergency_phone}</span> : null}
                </p>
              ) : (
                <p className="text-sm text-muted">{priv ? "No emergency contact recorded." : "Not shared with you."}</p>
              )}
            </Card>
            <Card className="p-4">
              <h2 className="heading-sm mb-2">Checks</h2>
              <div className="flex items-center gap-2">
                <ChecksChip r={{ expired, expiring, todo, status }} />
                <Link href={tabHref("documents")} className="text-sm font-semibold text-brand underline">
                  See them
                </Link>
              </div>
              {todo && (base.role === "new_starter" || conditional) ? (
                <Notice tone="info">
                  Onboarding isn&apos;t finished ({todo} to do).{" "}
                  <Link href={`/settings/staff/${id}?edit=access`} className="font-semibold underline">
                    {conditional ? "See the conditional role" : "Give a conditional role"}
                  </Link>
                </Notice>
              ) : null}
            </Card>
            <Card className="p-4">
              <h2 className="heading-sm mb-2">Open tasks</h2>
              {(openTasks ?? []).length ? (
                <ul className="flex flex-col gap-1 text-sm">
                  {((openTasks ?? []) as { id: string; title: string; status: string; due_date: string | null }[]).map((t) => (
                    <li key={t.id}>
                      <Link href={`/tasks/${t.id}`} className="font-semibold hover:text-brand">
                        {t.title}
                      </Link>
                      <span className="text-xs text-muted">{t.due_date ? ` · due ${auDay(t.due_date)}` : ""}</span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted">None you can see.</p>
              )}
            </Card>
          </div>
          {(activity ?? []).length ? (
            <Card className="p-4 lg:col-span-2">
              <h2 className="heading-sm mb-2">Recent activity</h2>
              <ul className="flex flex-col divide-y divide-line text-sm">
                {((activity ?? []) as { id: string; action: string; created_at: string; actor_id: string | null }[]).map((a) => (
                  <li key={a.id} className="flex flex-wrap gap-x-3 py-1.5">
                    <span className="flex-1">{a.action.replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase())}</span>
                    <span className="text-xs text-muted">
                      {a.actor_id ? `${actorName.get(a.actor_id) ?? "Someone"} · ` : ""}
                      {new Date(a.created_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" })}
                    </span>
                  </li>
                ))}
              </ul>
            </Card>
          ) : null}
        </div>
      )}

      {step ? (
        <div className="flex flex-wrap items-center justify-between gap-2">
          {STEPS.findIndex(([k]) => k === step) > 0 ? (
            <Link href={`/settings/staff/${id}?edit=${STEPS[STEPS.findIndex(([k]) => k === step) - 1][0]}`} className="rounded-lg border border-line px-4 py-2 text-sm font-semibold hover:bg-page">
              ← Back
            </Link>
          ) : (
            <span />
          )}
          <span className="flex gap-2">
            <Link href={`/settings/staff/${id}`} className="rounded-lg px-4 py-2 text-sm font-semibold text-muted hover:bg-page">
              Cancel
            </Link>
            {STEPS.findIndex(([k]) => k === step) < STEPS.length - 1 ? (
              <Link href={`/settings/staff/${id}?edit=${STEPS[STEPS.findIndex(([k]) => k === step) + 1][0]}`} className="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg hover:opacity-90">
                Next →
              </Link>
            ) : (
              <Link href={`/settings/staff/${id}`} className="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg hover:opacity-90">
                Finish
              </Link>
            )}
          </span>
        </div>
      ) : null}
    </>
  );
}

function Rows({ rows }: { rows: [string, ReactNode][] }) {
  return (
    <dl className="grid grid-cols-[9rem_1fr] gap-x-4 gap-y-1.5 text-sm">
      {rows.map(([k, v]) => (
        <div key={k} className="contents">
          <dt className="text-muted">{k}</dt>
          <dd>{v}</dd>
        </div>
      ))}
    </dl>
  );
}

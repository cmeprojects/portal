// Staff Portal · © cmeproject. All rights reserved.
import { photoLinks, type PhotoOwner } from "@/lib/avatars";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { nowMs } from "@/lib/access";
import { requireSession } from "@/lib/session";
import { managesStaffFor } from "@/lib/module-access";
import { rolesOn, teamsOn } from "@/lib/feature-parts";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { assignableRoles, inCoreTeam, JOB_TITLE_COLUMNS, ROLE_HELP, ROLE_LABELS, ROLES, type JobTitle, type Role } from "@/lib/roles";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { PersonEditor, type PersonRow } from "./forms";
import { ChecksChip, StaffTable, type StaffRow } from "./staff-table";
import { InviteDialog } from "./invite-dialog";
import { canDo } from "@/lib/module-access";
import { addDays, mondayOf, shiftHours, sydneyInstant, sydneyToday } from "@/lib/sydney-time";
import { canHelpSignIn, canInvite, getPeopleRules } from "@/lib/settings";
import { decideChangeRequest } from "./actions";
import { FormPending } from "@/components/form-pending";
import { PageFloat } from "@/components/page-float";

export const metadata: Metadata = { title: "Staff" };

// Who has signed in at least once (from the sign-in system).
async function joinedIds(): Promise<Set<string> | null> {
  try {
    const { data } = await createAdminClient().auth.admin.listUsers({ perPage: 1000 });
    return new Set(data.users.filter((u) => u.last_sign_in_at).map((u) => u.id));
  } catch {
    return null;
  }
}

export default async function StaffPage({ searchParams }: PageProps<"/settings/staff">) {
  const { profile: me, features } = await requireSession();
  // Who manages staff: the Access page (update 101).
  if (!(await managesStaffFor("view"))) notFound();
  // Teams or Roles switched off: hidden from everyone but the system admin (cmeprojects).
  const showTeams = me.role === "system_admin" || teamsOn(features);
  const showTitles = me.role === "system_admin" || rolesOn(features);
  const supabase = await createClient();
  // Seeing this page clears "approved / declined" alerts from your bell.
  await supabase.rpc("mark_request_updates_seen", { p_kind: "role" });
  const [{ data: people }, { data: teams }, { data: memberships }, { data: titleRows }, joined, { data: requests }] = await Promise.all([
    supabase
      .from("profiles")
      .select("id, full_name, email, role, job_title_id, active, deactivated_at, onboarded_at, joined_at")
      .order("active", { ascending: false })
      .order("full_name"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("team_members").select("team_id, user_id"),
    supabase.from("job_titles").select(JOB_TITLE_COLUMNS).order("sort_order").order("name"),
    joinedIds(),
    supabase
      .from("people_change_requests")
      .select("id, kind, user_id, from_value, to_value, reason, requested_by, requested_at")
      .in("kind", ["role", "conditional"])
      .eq("status", "pending")
      .order("requested_at"),
  ]);
  // cmeprojects (Stage 2 and 5): the function group(s) each role belongs to, shown
  // in place of the access level (which shows on hover). Hidden before update 93.
  const [{ data: linkRows }, { data: groupRows }] = await Promise.all([
    supabase.from("job_title_functions").select("job_title_id, function_group_id"),
    supabase.from("function_groups").select("id, name").eq("active", true),
  ]);
  // cmeprojects: who is a Manager Administrator right now (nominated by the
  // system admin on the Access page), with their dates for the badge.
  const { data: desigRows } = await supabase.from("admin_designations").select("user_id, status, starts_at, expires_at");
  const now = nowMs();
  const maDates = new Map(
    ((desigRows ?? []) as { user_id: string; status: string; starts_at: string; expires_at: string | null }[])
      .filter((d) => d.status === "active" && new Date(d.starts_at).getTime() <= now && (!d.expires_at || new Date(d.expires_at).getTime() > now))
      .map((d) => [d.user_id, d]),
  );
  const auDay = (iso: string) => new Date(iso).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "Australia/Sydney" });
  const groupName = new Map(((groupRows ?? []) as { id: string; name: string }[]).map((g) => [g.id, g.name]));
  const groupsOfTitle = (titleId: string | null) =>
    titleId ? ((linkRows ?? []) as { job_title_id: string; function_group_id: string }[]).filter((l) => l.job_title_id === titleId).map((l) => groupName.get(l.function_group_id)).filter(Boolean) as string[] : [];
  // cmeprojects: photos, read on their own so a copy without photos still works.
  const { data: photoRows } = await supabase.from("profiles").select("id, avatar_ref");
  const photos = await photoLinks((photoRows ?? []) as PhotoOwner[]);
  // Who the system admin let off two-factor login (read on its own: before update 48 there's no such column).
  const exemptRows = me.role === "system_admin" ? await supabase.from("profiles").select("id, mfa_exempt") : null;
  const mfaExemptOf = (id: string): boolean | null =>
    exemptRows && !exemptRows.error ? Boolean((exemptRows.data ?? []).find((r) => r.id === id)?.mfa_exempt) : null;
  const titles = showTitles ? ((titleRows ?? []) as JobTitle[]).map((t) => ({ ...t, groups: groupsOfTitle(t.id) })) : [];
  const activeManagers = (people ?? []).filter((p) => p.role === "manager" && p.active).length;
  // cmeprojects: who has a conditional role (given before onboarding finished).
  const { data: condRows } = await supabase.from("people_change_requests").select("user_id").eq("kind", "conditional").eq("status", "approved");
  const conditionalIds = new Set(((condRows ?? []) as { user_id: string }[]).map((r) => r.user_id).filter((id) => (people ?? []).some((p) => p.id === id && p.role !== "new_starter" && !p.onboarded_at && p.active)));
  // New starters (and conditional roles): what's still missing from onboarding.
  const missingFor = new Map(
    await Promise.all(
      (people ?? [])
        .filter((p) => (p.role === "new_starter" || conditionalIds.has(p.id)) && p.active)
        .map(async (p) => {
          const { data } = await supabase.rpc("onboarding_missing", { p_user: p.id });
          return [p.id, (data ?? []) as string[]] as const;
        }),
    ),
  );
  // Documents that have expired or expire soon, per person (and every check, for the panel).
  type Check = { item_id: string; kind: string; title: string; state: string; expires_on: string | null; before_work: boolean; category: string | null };
  const compliance = new Map<string, Check[]>();
  const expiryFor = new Map(
    await Promise.all(
      (people ?? [])
        .filter((p) => p.active && p.role !== "system_admin")
        .map(async (p) => {
          const { data } = await supabase.rpc("compliance_status", { p_user: p.id });
          const rows = (data ?? []) as { title: string; state: string }[];
          compliance.set(p.id, (data ?? []) as Check[]);
          return [
            p.id,
            {
              expired: rows.filter((r) => r.state === "expired").map((r) => r.title),
              expiring: rows.filter((r) => r.state === "expiring").map((r) => r.title),
            },
          ] as const;
        }),
    ),
  );
  const titleName = new Map(titles.map((t) => [t.id, t.name]));
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  type RoleValue = { role: Role; title: string | null };
  const roleText = (v: RoleValue) => (v.title && titleName.get(v.title)) || ROLE_LABELS[v.role];
  const pending = new Map((requests ?? []).map((q) => [q.user_id as string, q]));
  const canApprove = me.role === "manager" || me.role === "system_admin";
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone: "Australia/Melbourne" });
  const roles = assignableRoles(me.role);
  const rules = await getPeopleRules();
  // Staff admins send role changes for approval, if the system admin's rules say so.
  const needsApproval = (role: Role) =>
    me.role === "staff_admin" && rules.staffAdminRoleApproval && (role !== "new_starter" || rules.firstRoleApproval);
  const teamName = new Map((teams ?? []).map((t) => [t.id, t.name]));
  const teamsOf = (id: string) =>
    (memberships ?? [])
      .filter((m) => m.user_id === id)
      .map((m) => teamName.get(m.team_id))
      .filter(Boolean)
      .join(", ");

  // cmeprojects (owner's concept): one row per person; the panel on the right
  // holds everything about them (Details, Access, Compliance, Tasks).
  const sp = await searchParams;
  const picked = typeof sp.p === "string" && (people ?? []).some((p) => p.id === sp.p) ? sp.p : null;
  const tab = typeof sp.t === "string" && ["details", "access", "compliance", "tasks"].includes(sp.t) ? sp.t : "details";
  const statusOf = (p: { active: boolean; role: string; joined_at: string | null; id: string }) =>
    !p.active ? "Deactivated" : p.role !== "new_starter" ? "Active" : p.joined_at ? "Onboarding" : joined?.has(p.id) ? "Not set up yet" : "Invite sent";
  const { data: privRows } = await supabase.from("staff_private").select("user_id, employment_type, start_date");
  // cmeprojects (update 119): who is leaving (open offboarding), if this person may see it.
  const { data: leavingRows } = await supabase.from("offboardings").select("user_id, last_day").eq("status", "open");
  const leaving = new Map(((leavingRows ?? []) as { user_id: string; last_day: string }[]).map((r) => [r.user_id, r.last_day]));
  // cmeprojects (update 122): rostered hours this week and the next shift (people who see the roster).
  const seesRoster = features.rostering !== false && (await canDo("ops.roster", "view"));
  const weekStart = sydneyInstant(mondayOf(sydneyToday()));
  const weekEnd = sydneyInstant(addDays(mondayOf(sydneyToday()), 7));
  const { data: shiftRows, error: shiftError } = seesRoster
    ? await supabase.from("shifts").select("worker_id, starts_at, ends_at, break_minutes").neq("status", "cancelled").not("worker_id", "is", null).gte("ends_at", weekStart).order("starts_at").limit(5000)
    : { data: [], error: true };
  const rosterShown = seesRoster && !shiftError;
  const weekHours = new Map<string, number>();
  const nextShift = new Map<string, string>();
  const nowIso = new Date().toISOString();
  for (const sh of (shiftRows ?? []) as { worker_id: string; starts_at: string; ends_at: string; break_minutes: number }[]) {
    if (sh.starts_at < weekEnd) weekHours.set(sh.worker_id, (weekHours.get(sh.worker_id) ?? 0) + shiftHours(sh));
    if (sh.starts_at > nowIso && !nextShift.has(sh.worker_id)) nextShift.set(sh.worker_id, sh.starts_at);
  }
  const priv = new Map(((privRows ?? []) as { user_id: string; employment_type: string | null; start_date: string | null }[]).map((r) => [r.user_id, r]));
  const EMPLOYMENT: Record<string, string> = { full_time: "Full-time", part_time: "Part-time", casual: "Casual", contractor: "Contractor", fixed_term: "Fixed term" };
  const employmentText = (v: string | null | undefined) => (v ? (EMPLOYMENT[v] ?? v.replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase())) : "");
  const rowsForTable: StaffRow[] = (people ?? []).map((p) => {
    const ma = p.role === "manager" && maDates.has(p.id);
    const isMe = p.id === me.id;
    const team = !showTeams ? "" : inCoreTeam(p.role as Role) ? "Core team" : p.role === "system_admin" || p.role === "new_starter" ? "" : teamsOf(p.id) || "No team";
    return {
      id: p.id,
      name: p.full_name || "(no name yet)",
      email: p.email,
      photo: photos[p.id] ?? null,
      role: (p.job_title_id ? titleName.get(p.job_title_id) : undefined) ?? ROLE_LABELS[p.role as Role],
      sub: groupsOfTitle(p.job_title_id).join(" · "),
      team,
      employment: employmentText(priv.get(p.id)?.employment_type),
      startDate: priv.get(p.id)?.start_date ?? "",
      status: statusOf(p),
      expired: expiryFor.get(p.id)?.expired.length ?? 0,
      expiring: expiryFor.get(p.id)?.expiring.length ?? 0,
      todo: missingFor.get(p.id)?.length ?? 0,
      conditional: conditionalIds.has(p.id),
      waiting: pending.has(p.id),
      leaving: leaving.get(p.id) ?? "",
      hours: rosterShown ? (weekHours.get(p.id) ?? 0) : null,
      nextShift: nextShift.get(p.id) ?? "",
      tag: [isMe ? "you" : "", ma ? "administrator" : ""].filter(Boolean).join(" · "),
      protectedAdmin: p.role === "system_admin",
    };
  });
  const current = (people ?? []).filter((p) => p.active && p.role !== "system_admin");
  const tiles = [
    { n: current.filter((p) => p.role !== "new_starter").length, label: "Active staff", tone: "" },
    { n: current.filter((p) => p.role === "new_starter").length + conditionalIds.size, label: "Invited or onboarding (incl. conditional)", tone: "" },
    { n: current.filter((p) => (expiryFor.get(p.id)?.expired.length ?? 0) + (expiryFor.get(p.id)?.expiring.length ?? 0) > 0).length, label: "Staff with checks expiring or expired", tone: "border-l-4 border-l-danger" },
    rosterShown
      ? { n: Math.round([...weekHours.values()].reduce((a, b) => a + b, 0)), label: "Rostered hours this week", tone: "" }
      : { n: (requests ?? []).length, label: "Role changes waiting for approval", tone: (requests ?? []).length ? "border-l-4 border-l-warn" : "" },
  ];
  const sel = picked ? (people ?? []).find((p) => p.id === picked)! : null;
  const selRow = sel ? rowsForTable.find((r) => r.id === sel.id)! : null;
  const [extras, progs, programList] = sel
    ? await Promise.all([
        supabase.from("profiles").select("extra_job_title_ids").eq("id", sel.id).maybeSingle(),
        supabase.from("profiles").select("program_ids").eq("id", sel.id).maybeSingle(),
        supabase.from("client_programs").select("id, name").eq("active", true).order("sort_order").then((r) => r.data ?? []),
      ])
    : [null, null, []];
  const selPerson: PersonRow | null = sel
    ? {
        ...sel,
        role: sel.role as Role,
        job_title_id: sel.job_title_id,
        missing: missingFor.get(sel.id) ?? null,
        lastManager: sel.role === "manager" && sel.active && activeManagers === 1,
        joined: sel.role !== "new_starter" || Boolean(sel.joined_at),
        openedLink: joined ? joined.has(sel.id) : false,
        isMe: sel.id === me.id,
        hasPhoto: Boolean(photos[sel.id]),
        editable: roles.includes(sel.role as Role) || sel.id === me.id,
        teamIds: (memberships ?? []).filter((m) => m.user_id === sel.id).map((m) => m.team_id),
        mfaExempt: mfaExemptOf(sel.id),
        extraTitleIds: !extras || extras.error ? undefined : ((extras.data?.extra_job_title_ids ?? []) as string[]),
        programIds: !progs || progs.error ? undefined : ((progs.data?.program_ids ?? []) as string[]),
      }
    : null;
  const { data: dirRow } = sel ? await supabase.from("staff_directory").select("work_phone, department, skills").eq("user_id", sel.id).maybeSingle() : { data: null };
  const { data: selTasks } =
    sel && tab === "tasks"
      ? await supabase.from("tasks").select("id, number, title, status, due_date, priority").eq("assigned_to", sel.id).not("status", "in", "(completed,closed)").order("due_date", { ascending: true, nullsFirst: false }).limit(20)
      : { data: null };
  const href = (t: string) => `/settings/staff?p=${picked}${t === "details" ? "" : `&t=${t}`}`;
  const selChecks = sel ? (compliance.get(sel.id) ?? []).filter((c) => c.kind !== "info") : [];
  const daysTo = (d: string) => Math.round((Date.parse(`${d}T00:00:00Z`) - Date.parse(`${new Date().toISOString().slice(0, 10)}T00:00:00Z`)) / 86_400_000);
  const CHECK_STATE: Record<string, [string, string]> = {
    accepted: ["Current", "bg-good-soft"],
    done: ["Done", "bg-good-soft"],
    submitted: ["Waiting for checking", "bg-brand-soft"],
    todo: ["To do", "bg-page ring-1 ring-line"],
    rejected: ["Needs redoing", "bg-danger-soft text-danger"],
    expired: ["Expired", "bg-danger-soft text-danger"],
    expiring: ["Expiring soon", "bg-warn-soft"],
  };

  return (
    <>
      <PageHeader
        title="Staff"
        intro="Your team, their roles and their checks. Click someone to see and manage everything about them."
        action={
          canInvite(me.role, rules) ? <InviteDialog /> : undefined
        }
      />

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {tiles.map((t) => (
          <Card key={t.label} className={`p-4 ${t.n ? t.tone : ""}`}>
            <p className="font-display text-2xl font-semibold">{t.n}</p>
            <p className="text-xs text-muted">{t.label}</p>
          </Card>
        ))}
      </div>

      {(requests ?? []).length ? (
        <Card className="overflow-hidden border-warn/40">
          <h2 className="heading-sm border-b border-line px-5 py-3">Role changes waiting for approval · {(requests ?? []).length}</h2>
          <ul className="divide-y divide-line">
            {(requests ?? []).map((q) => (
              <li key={q.id} className="flex flex-wrap items-center justify-between gap-3 px-5 py-3">
                <div className="min-w-60 flex-1 text-sm">
                  <p>
                    <strong>{nameOf.get(q.user_id!) ?? "Someone"}</strong>: {roleText(q.from_value as RoleValue)} → <strong>{roleText(q.to_value as RoleValue)}</strong>
                    {q.kind === "conditional" ? <> <Badge tone="warn">Conditional</Badge></> : null}
                  </p>
                  {q.kind === "conditional" ? <ConditionalDetails value={q.to_value as ConditionalValue} teamName={teamName} /> : null}
                  <p className="text-xs text-muted">
                    Asked by {nameOf.get(q.requested_by) ?? "Admin"} · {when.format(new Date(q.requested_at))}
                    {q.reason ? ` · “${q.reason}”` : ""}
                  </p>
                </div>
                {canApprove && q.user_id !== me.id ? (
                  <div className="flex gap-2">
                    <form action={decideChangeRequest}>
                      <input type="hidden" name="request_id" value={q.id} />
                      <input type="hidden" name="decision" value="approve" />
                      <button className={buttonClass("primary")}>Approve<FormPending /></button>
                    </form>
                    <form action={decideChangeRequest}>
                      <input type="hidden" name="request_id" value={q.id} />
                      <input type="hidden" name="decision" value="decline" />
                      <button className={buttonClass("outline")}>Decline<FormPending /></button>
                    </form>
                  </div>
                ) : (
                  <Badge tone="warn">Waiting for a manager</Badge>
                )}
              </li>
            ))}
          </ul>
        </Card>
      ) : null}

      <StaffTable rows={rowsForTable} selected={picked} showTeams={showTeams} showRoster={rosterShown} />

      <Card className="p-5">
        <h2 className="mb-3 heading-sm">Access levels: the base each role builds on</h2>
        <p className="mb-3 text-sm text-muted">
          Every role (job title) sits on one of these. It&apos;s only the starting point: the role and its function group get more on the Access page, and these defaults can be changed there too. Roles are added on the Roles page.
        </p>
        <dl className="grid gap-3 md:grid-cols-2">
          {ROLES.filter((r) => r !== "system_admin" || me.role === "system_admin").map((r) => (
            <div key={r}>
              <dt className="font-semibold">{ROLE_LABELS[r]}</dt>
              <dd className="text-sm text-muted">{ROLE_HELP[r]}</dd>
            </div>
          ))}
        </dl>
      </Card>

      {sel && selRow && selPerson ? (
        <>
          <Link href="/settings/staff" scroll={false} aria-label="Close" className="fixed inset-0 z-40 bg-black/25" />
          <aside role="dialog" aria-label={selRow.name} className="thin-scroll fixed inset-y-0 right-0 z-50 flex w-full max-w-2xl flex-col overflow-y-auto bg-surface shadow-2xl">
            <div className="flex items-start gap-3 border-b border-line p-5">
              <div className="min-w-0 flex-1">
                <h2 className="heading">{selRow.name}</h2>
                <p className="text-sm text-muted">{selRow.email}</p>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">{selRow.role}</span>
                  <ChecksChip r={selRow} />
                  {selRow.status !== "Active" ? <span className="rounded-full bg-page px-2 py-0.5 text-xs font-semibold ring-1 ring-line">{selRow.status}</span> : null}
                  {selRow.conditional ? <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold">Conditional role</span> : null}
                </div>
              </div>
              <span className="flex gap-2">
                <Link href={`/settings/staff/${sel.id}`} className={buttonClass("primary")}>
                  View full profile
                </Link>
                <Link href="/settings/staff" scroll={false} className={buttonClass("outline")}>
                  Close
                </Link>
              </span>
            </div>
            <nav aria-label="Person sections" className="flex gap-1 border-b border-line px-4">
              {[
                ["details", "Details"],
                ["access", "Role and access"],
                ["compliance", "Compliance"],
                ["tasks", "Tasks"],
              ].map(([k, l]) => (
                <Link key={k} href={href(k)} scroll={false} className={`-mb-px border-b-2 px-3 py-2.5 text-sm font-semibold ${tab === k ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"}`}>
                  {l}
                </Link>
              ))}
            </nav>
            <div className="flex flex-col gap-4 p-5 text-sm">
              {tab === "details" ? (
                <>
                  <dl className="grid grid-cols-[9rem_1fr] gap-x-4 gap-y-2">
                    <dt className="text-muted">Role</dt>
                    <dd>
                      {selRow.role}
                      {selRow.sub ? <span className="text-muted"> · {selRow.sub}</span> : null}
                    </dd>
                    <dt className="text-muted">Access level</dt>
                    <dd>{ROLE_LABELS[sel.role as Role]}</dd>
                    {showTeams ? (
                      <>
                        <dt className="text-muted">Team</dt>
                        <dd>{selRow.team || "—"}</dd>
                      </>
                    ) : null}
                    <dt className="text-muted">Employment</dt>
                    <dd>{selRow.employment || "Not recorded"}</dd>
                    <dt className="text-muted">Start date</dt>
                    <dd>{selRow.startDate ? auDay(`${selRow.startDate}T00:00:00`) : "Not recorded"}</dd>
                    <dt className="text-muted">Phone</dt>
                    <dd>{(dirRow as { work_phone?: string } | null)?.work_phone || "Not recorded"}</dd>
                    <dt className="text-muted">Email</dt>
                    <dd>{sel.email}</dd>
                    <dt className="text-muted">Status</dt>
                    <dd>{selRow.status}</dd>
                    {maDates.has(sel.id) ? (
                      <>
                        <dt className="text-muted">Administrator</dt>
                        <dd>
                          Manager Administrator since {auDay(maDates.get(sel.id)!.starts_at)}
                          {maDates.get(sel.id)!.expires_at ? ` until ${auDay(maDates.get(sel.id)!.expires_at!)}` : ""}
                        </dd>
                      </>
                    ) : null}
                  </dl>
                  {(() => {
                    const quals = (compliance.get(sel.id) ?? []).filter((c) => c.state === "accepted" && (c.expires_on || c.category === "qualification"));
                    const skills = ((dirRow as { skills?: string[] | string | null } | null)?.skills ?? []) as string[] | string;
                    const list = [...quals.map((c) => c.title), ...(Array.isArray(skills) ? skills : skills ? String(skills).split(",") : [])].map((v) => v.trim()).filter(Boolean);
                    return list.length ? (
                      <div>
                        <h3 className="mb-1.5 font-semibold">Qualifications and skills</h3>
                        <div className="flex flex-wrap gap-1.5">
                          {[...new Set(list)].map((q) => (
                            <span key={q} className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold">
                              {q}
                            </span>
                          ))}
                        </div>
                      </div>
                    ) : null;
                  })()}
                  {selPerson.missing?.length ? (
                    <div className="rounded-lg border border-warn/40 bg-warn-soft/40 p-3">
                      <p className="font-semibold">Onboarding still to do</p>
                      <ul className="mt-1 list-disc pl-5">
                        {selPerson.missing.map((m) => (
                          <li key={m}>{m}</li>
                        ))}
                      </ul>
                      <Link href={href("access")} scroll={false} className="mt-2 inline-block font-semibold text-brand underline">
                        {selRow.conditional ? "See the conditional role" : "Give a conditional role"}
                      </Link>
                    </div>
                  ) : null}
                  <p className="text-xs text-muted">
                    Their own profile, contact and private details are on{" "}
                    <Link href={`/people?p=${sel.id}`} className="text-brand underline">
                      their directory card
                    </Link>
                    .
                  </p>
                </>
              ) : tab === "access" ? (
                selPerson.editable ? (
                  <PersonEditor
                    person={selPerson}
                    programs={programList as { id: string; name: string }[]}
                    roles={roles}
                    titles={titles}
                    teams={showTeams ? (teams ?? []) : []}
                    isManager={me.role === "manager" || me.role === "system_admin"}
                    canResetMfa={me.role === "system_admin"}
                    canHelpSignIn={canHelpSignIn(me.role, rules) && (me.role === "system_admin" || sel.role !== "system_admin")}
                    needsApproval={needsApproval(selPerson.role)}
                  />
                ) : (
                  <p className="text-muted">Only a system admin can change a system admin.</p>
                )
              ) : tab === "compliance" ? (
                <>
                  <p className="text-muted">Checks expiring within 60 days are flagged. Update one when it has expired or is expiring; current ones need nothing.</p>
                  {selChecks.length ? (
                    <ul className="flex flex-col gap-2">
                      {selChecks.map((c) => {
                        const [txt, tone] = CHECK_STATE[c.state] ?? [c.state, "bg-page ring-1 ring-line"];
                        const due = c.expires_on ? daysTo(c.expires_on) : null;
                        const needs = c.state === "expired" || c.state === "expiring";
                        return (
                          <li key={c.item_id} className="flex flex-wrap items-center gap-3 rounded-lg border border-line p-3">
                            <span className="min-w-40 flex-1">
                              <span className="block font-semibold">{c.title}</span>
                              {c.expires_on ? <span className="text-xs text-muted">{due !== null && due < 0 ? "Expired" : "Expires"} {auDay(`${c.expires_on}T00:00:00`)}</span> : null}
                            </span>
                            <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tone}`}>
                              {c.state === "expired" && due !== null ? `Expired ${-due}d ago` : c.state === "expiring" && due !== null ? `Expires in ${due}d` : txt}
                            </span>
                            {needs ? (
                              <Link href={`/compliance/people/${sel.id}`} className={buttonClass("outline")}>
                                Update
                              </Link>
                            ) : null}
                          </li>
                        );
                      })}
                    </ul>
                  ) : (
                    <p className="text-muted">No checks apply to them.</p>
                  )}
                  <Link href={`/compliance/people/${sel.id}`} className="w-fit text-sm font-semibold text-brand underline">
                    Open their full onboarding record
                  </Link>
                </>
              ) : (
                <>
                  {(selTasks ?? []).length ? (
                    <ul className="flex flex-col divide-y divide-line rounded-lg border border-line">
                      {((selTasks ?? []) as { id: string; number: number | null; title: string; status: string; due_date: string | null; priority: string }[]).map((t) => (
                        <li key={t.id} className="flex flex-wrap items-center gap-2 px-3 py-2">
                          <Link href={`/tasks/${t.id}`} className="min-w-40 flex-1 font-semibold hover:text-brand">
                            {t.title}
                          </Link>
                          <span className="text-xs text-muted">
                            {t.status.replace(/_/g, " ")}
                            {t.due_date ? ` · due ${auDay(`${t.due_date}T00:00:00`)}` : ""}
                          </span>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <p className="text-muted">No open tasks you can see.</p>
                  )}
                </>
              )}
            </div>
          </aside>
        </>
      ) : null}
      {/* Floating icons (owner, 20 Nov 2026). */}
      <PageFloat />
    </>
  );
}

type ConditionalValue = { deadline: string; missing: string[]; teams: string[] };

function ConditionalDetails({ value, teamName }: { value: ConditionalValue; teamName: Map<string, string> }) {
  const deadline = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${value.deadline}T00:00:00Z`));
  return (
    <div className="mt-1 text-xs text-muted">
      <p>Finish onboarding by {deadline}. Still to do: {value.missing.join(", ")}.</p>
      {value.teams?.length ? <p>Teams: {value.teams.map((t) => teamName.get(t) ?? "a team").join(", ")}</p> : null}
    </div>
  );
}

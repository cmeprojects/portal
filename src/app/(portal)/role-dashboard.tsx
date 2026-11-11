// Staff Portal · © cmeproject. All rights reserved.
import { Celebrations } from "@/components/celebrations";
import { getPeople } from "@/lib/register-data";
import Link from "next/link";
import type { ReactNode } from "react";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { canSeeComplianceReport, getPeopleRules, getTimeZone } from "@/lib/settings";
import { endOfWeek, formatDue, todayIn, type Priority, type Status } from "@/lib/tasks";
import { refLabel } from "@/lib/registers";
import { ManagerBoard, type BoardTask } from "./manager-board";
import { onboardingOn } from "@/lib/feature-parts";
import { isDone, type ItemState } from "@/lib/compliance";
import { formsOn } from "@/lib/forms";
import { Bars, Panel, Tile } from "@/components/dash";
import { PageHeader, buttonClass } from "@/components/ui";
import { AlertTriangle, Car, Plus, Clock, FileWarning, Inbox, ListChecks, MailQuestion, Siren, Upload, UserPlus, Users } from "lucide-react";

// cmeprojects: each role's dashboard, in the same style as the system admin's.
//   Manager:     the whole operation.
//   Staff admin: staffing (invites, onboarding, documents, role changes).
//   Team leader: their team and the clients their team looks after.
// Every tile and panel is its own small piece, and each role's dashboard is a
// list of them, so a new module (for example rostering) adds its own pieces
// and puts them in the right roles' lists. Everything is read as the signed-in
// person, so the database's own rules decide what they can count.

const DONE = ["completed", "closed"];
const DAY = 86_400_000;
type Supa = Awaited<ReturnType<typeof createClient>>;
type Ctx = { supabase: Supa; me: string; today: string; timeZone: string; features: Record<string, boolean>; complianceReport: boolean };
type Piece = (ctx: Ctx) => Promise<{ board?: ReactNode; tile?: ReactNode; panel?: ReactNode } | null>;

const plus = (today: string, days: number) => new Date(Date.parse(`${today}T00:00:00Z`) + days * DAY).toISOString().slice(0, 10);
const count = async (q: PromiseLike<{ count: number | null }>) => (await q).count ?? 0;
const nameMap = async (supabase: Supa, ids: string[]) => {
  if (!ids.length) return new Map<string, string>();
  const { data } = await supabase.from("profiles").select("id, full_name, email").in("id", ids);
  return new Map((data ?? []).map((p) => [p.id as string, (p.full_name || p.email) as string]));
};
const topBars = (by: Map<string, number>, names: Map<string, string>, n = 8) =>
  [...by.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, n)
    .map(([id, value]) => ({ label: names.get(id) ?? "Not assigned", value }));
const Empty = ({ children }: { children: ReactNode }) => <p className="text-sm text-muted">{children}</p>;

// ---------------------------------------------------------------------------
// Tasks (manager)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Manager: the interactive board (tiles, status, people, registers, ageing, trend)
// ---------------------------------------------------------------------------

const managerBoard: Piece = async ({ supabase, today, timeZone }) => {
  const since = plus(today, -55);
  const [{ data: open }, { data: regs }, { data: made }, { data: closed }, { data: finished }] = await Promise.all([
    supabase.from("tasks").select("id, ref_number, title, status, priority, due_date, assigned_to, registry_id").not("status", "in", `(${DONE.join(",")})`).order("due_date", { ascending: true, nullsFirst: false }).limit(3000),
    supabase.from("registries").select("id, name, prefix"),
    supabase.from("tasks").select("created_at").gte("created_at", since).limit(10000),
    supabase.from("tasks").select("completed_at, closed_at").or(`completed_at.gte.${since},closed_at.gte.${since}`).limit(10000),
    supabase.from("tasks").select("due_date, completed_at").gte("completed_at", plus(today, -29)).not("due_date", "is", null).limit(10000),
  ]);
  const regOf = new Map((regs ?? []).map((r) => [r.id as string, r as { id: string; name: string; prefix: string }]));
  const names = await nameMap(supabase, [...new Set((open ?? []).map((t) => t.assigned_to as string))]);
  const tasks: BoardTask[] = (open ?? []).map((t) => ({
    id: t.id,
    ref: refLabel(regOf.get(t.registry_id)?.prefix, t.ref_number),
    title: t.title,
    status: t.status as Status,
    priority: t.priority as Priority,
    due: t.due_date,
    dueLabel: formatDue(t.due_date, today, t.status as Status),
    assignedTo: t.assigned_to,
    assignee: names.get(t.assigned_to) ?? "Not assigned",
    registryId: t.registry_id,
    register: regOf.get(t.registry_id)?.name ?? "",
  }));
  const start = Date.parse(`${since}T00:00:00Z`);
  const weeks = Array.from({ length: 8 }, (_, i) => ({
    label: new Date(start + i * 7 * DAY).toLocaleDateString("en-AU", { day: "numeric", month: "short", timeZone: "UTC" }),
    opened: 0,
    closed: 0,
  }));
  const wk = (iso: string) => Math.min(7, Math.max(0, Math.floor((Date.parse(iso) - start) / (7 * DAY))));
  for (const t of made ?? []) weeks[wk(t.created_at)].opened++;
  for (const t of closed ?? []) {
    const at = (t.completed_at ?? t.closed_at) as string | null;
    if (at && at >= since) weeks[wk(at)].closed++;
  }
  const done = (finished ?? []).filter((t) => t.completed_at);
  const onTime = { finished: done.length, onTime: done.filter((t) => new Intl.DateTimeFormat("en-CA", { timeZone }).format(new Date(t.completed_at as string)) <= (t.due_date as string)).length };
  const allNames = [...names.entries()] as [string, string][];
  const people = (await getPeople()).filter((p) => p.active && p.role !== "system_admin").map((p) => [p.id, p.label] as [string, string]);
  return { board: <ManagerBoard tasks={tasks} today={today} weekEnd={endOfWeek(today)} weeks={weeks} onTime={onTime} names={allNames} handTo={people} timeZone={timeZone} /> };
};

// ---------------------------------------------------------------------------
// People and compliance (manager and staff admin)
// ---------------------------------------------------------------------------

const onboardingDone: Piece = async ({ supabase, features, complianceReport }) => {
  if (!onboardingOn(features) || !complianceReport) return null;
  const { data } = await supabase.from("profiles").select("onboarded_at").eq("active", true).not("role", "in", "(system_admin,external)");
  const all = data?.length ?? 0;
  const done = (data ?? []).filter((p) => p.onboarded_at).length;
  return { tile: <Tile label="Onboarding complete" value={all ? `${Math.round((done / all) * 100)}%` : "–"} note={`${done} of ${all} staff`} icon={Users} tone={all && done === all ? "good" : undefined} href="/compliance" /> };
};

const documentsExpiring: Piece = async ({ supabase, today, features, complianceReport }) => {
  if (!onboardingOn(features) || !complianceReport) return null;
  const n = await count(supabase.from("compliance_records").select("id", { count: "exact", head: true }).in("status", ["accepted", "submitted", "done"]).lte("expires_on", plus(today, 30)));
  return { tile: <Tile label="Documents expiring" value={n} note="Expired or due in 30 days" icon={FileWarning} tone={n ? "warn" : undefined} href="/compliance" /> };
};

const uploadsToCheck: Piece = async ({ supabase, features, complianceReport }) => {
  if (!onboardingOn(features) || !complianceReport) return null;
  return { tile: <Tile label="Uploads to check" value={await count(supabase.from("compliance_records").select("id", { count: "exact", head: true }).eq("status", "submitted"))} note="Sent by staff, not checked yet" icon={Upload} tone="warn" href="/compliance" /> };
};

const invitesPending: Piece = async ({ supabase }) => ({
  tile: <Tile label="Invites not accepted" value={await count(supabase.from("profiles").select("id", { count: "exact", head: true }).eq("active", true).is("joined_at", null))} note="Haven't signed in yet" icon={MailQuestion} href="/settings/staff" />,
});

const newStarters: Piece = async ({ supabase }) => {
  const { data } = await supabase.from("profiles").select("id, full_name, email, joined_at").eq("active", true).eq("role", "new_starter").order("full_name").limit(8);
  return {
    tile: <Tile label="New starters" value={data?.length ?? 0} note="Waiting for a role" icon={UserPlus} href="/settings/staff" />,
    panel: (
      <Panel title="New starters" action={<Link href="/compliance" className="text-xs font-semibold text-brand underline">Onboarding</Link>}>
        {data?.length ? (
          <ul className="flex flex-col divide-y divide-line text-sm">
            {data.map((p) => (
              <li key={p.id} className="flex items-center justify-between gap-2 py-2">
                <Link href={`/compliance/people/${p.id}`} className="font-medium hover:text-brand">{p.full_name || p.email}</Link>
                <span className="text-xs text-muted">{p.joined_at ? "Joined" : "Invite sent"}</span>
              </li>
            ))}
          </ul>
        ) : (
          <Empty>No new starters right now.</Empty>
        )}
      </Panel>
    ),
  };
};

const roleChanges: Piece = async ({ supabase }) => {
  const { data } = await supabase.from("people_change_requests").select("id, kind, to_value, user_id, team_id, requested_at").eq("status", "pending").order("requested_at").limit(6);
  const names = await nameMap(supabase, (data ?? []).map((r) => r.user_id).filter(Boolean) as string[]);
  return {
    panel: (
      <Panel title="Role and team changes waiting" action={<Link href="/settings/staff" className="text-xs font-semibold text-brand underline">Staff</Link>}>
        {data?.length ? (
          <ul className="flex flex-col divide-y divide-line text-sm">
            {data.map((r) => (
              <li key={r.id} className="py-2">
                <span className="font-medium">{(r.user_id && names.get(r.user_id)) || "A team"}</span>
                <span className="text-muted"> · {r.kind === "team" ? "team change" : `to ${String(r.to_value).replace(/_/g, " ")}`}</span>
              </li>
            ))}
          </ul>
        ) : (
          <Empty>Nothing waiting for a manager.</Empty>
        )}
      </Panel>
    ),
  };
};

const noTeam: Piece = async ({ supabase }) => {
  const [{ data: people }, { data: members }] = await Promise.all([
    supabase.from("profiles").select("id, full_name, email").eq("active", true).in("role", ["support_worker", "team_leader"]).order("full_name"),
    supabase.from("team_members").select("user_id"),
  ]);
  const inTeam = new Set((members ?? []).map((m) => m.user_id));
  const loose = (people ?? []).filter((p) => !inTeam.has(p.id));
  return {
    panel: (
      <Panel title="Staff with no team" action={<Link href="/settings/teams" className="text-xs font-semibold text-brand underline">Teams</Link>}>
        {loose.length ? (
          <ul className="flex flex-wrap gap-2 text-sm">
            {loose.slice(0, 12).map((p) => (
              <li key={p.id} className="rounded-full bg-page px-3 py-1 ring-1 ring-line">{p.full_name || p.email}</li>
            ))}
          </ul>
        ) : (
          <Empty>Everyone is in a team.</Empty>
        )}
      </Panel>
    ),
  };
};

const recentlyJoined: Piece = async ({ supabase, today }) => {
  const { data } = await supabase.from("profiles").select("id, full_name, email, joined_at").gte("joined_at", plus(today, -30)).order("joined_at", { ascending: false }).limit(6);
  return {
    panel: (
      <Panel title="Joined in the last 30 days">
        {data?.length ? (
          <ul className="flex flex-col divide-y divide-line text-sm">
            {data.map((p) => (
              <li key={p.id} className="flex justify-between gap-2 py-2">
                <span className="font-medium">{p.full_name || p.email}</span>
                <span className="text-xs text-muted">{new Date(p.joined_at as string).toLocaleDateString("en-AU", { day: "numeric", month: "short" })}</span>
              </li>
            ))}
          </ul>
        ) : (
          <Empty>Nobody new this month.</Empty>
        )}
      </Panel>
    ),
  };
};

// ---------------------------------------------------------------------------
// Other modules (shown only when they're switched on)
// ---------------------------------------------------------------------------

const newEnquiries: Piece = async ({ supabase, today, features }) => {
  if (features.assistant !== true) return null;
  return { tile: <Tile label="New enquiries" value={await count(supabase.from("website_enquiries").select("id", { count: "exact", head: true }).gte("created_at", plus(today, -7)))} note="From the website, last 7 days" icon={Inbox} href="/enquiries" /> };
};

const carsOut: Piece = async ({ supabase, features }) => {
  if (features.vehicles !== true) return null;
  return { tile: <Tile label="Cars out now" value={await count(supabase.from("car_trips").select("id", { count: "exact", head: true }).is("returned_at", null))} icon={Car} href="/reports/cars" /> };
};

// cmeprojects: requests waiting for this person to act (HR Pack → My requests).
const requestsWaiting: Piece = async ({ supabase, me, features }) => {
  if (features.hr_requests === false) return null;
  const { data, error } = await supabase.from("requests").select("id, requester, type, partner_ok").in("status", ["pending", "info_needed"]).limit(100);
  if (error) return null; // before live update 56
  const mine = await Promise.all(
    (data ?? []).filter((r) => r.requester !== me && (r.type !== "swap" || r.partner_ok === true)).map(async (r) => (await supabase.rpc("can_act_on_request", { p_request: r.id })).data === true),
  );
  const n = mine.filter(Boolean).length;
  return { tile: <Tile label="Requests waiting" value={n} note="Leave, swaps and more, for you to approve" icon={Inbox} tone="warn" href="/people/requests" /> };
};

// ---------------------------------------------------------------------------
// Team leader
// ---------------------------------------------------------------------------

async function myTeam(supabase: Supa, me: string) {
  const { data: led } = await supabase.from("team_leaders").select("team_id").eq("user_id", me);
  const teamIds = (led ?? []).map((l) => l.team_id as string);
  const { data: members } = teamIds.length ? await supabase.from("team_members").select("user_id").in("team_id", teamIds) : { data: [] };
  return { teamIds, memberIds: [...new Set((members ?? []).map((m) => m.user_id as string))].filter((id) => id !== me) };
}

const teamTasks: Piece = async ({ supabase, me, today }) => {
  const { memberIds } = await myTeam(supabase, me);
  const ids = [...memberIds, me];
  const { data } = await supabase.from("tasks").select("assigned_to, due_date").not("status", "in", `(${DONE.join(",")})`).in("assigned_to", ids).limit(5000);
  const open = data ?? [];
  const by = new Map<string, number>(memberIds.map((id) => [id, 0]));
  for (const t of open) by.set(t.assigned_to, (by.get(t.assigned_to) ?? 0) + 1);
  const names = await nameMap(supabase, [...by.keys()]);
  return {
    tile: (
      <>
        <Tile label="Team open tasks" value={open.length} note={`${memberIds.length} in your team`} icon={ListChecks} href="/tasks" />
        <Tile label="Team overdue" value={open.filter((t) => t.due_date && t.due_date < today).length} icon={AlertTriangle} tone="danger" href="/tasks#all" />
      </>
    ),
    panel: (
      <Panel title="Open tasks by team member">
        {memberIds.length ? <Bars rows={topBars(by, names, 12)} /> : <Empty>You don&apos;t lead a team yet. A manager sets this on the Teams page.</Empty>}
      </Panel>
    ),
  };
};

const escalatedToMe: Piece = async ({ supabase, me }) => ({
  tile: <Tile label="Escalated to you" value={await count(supabase.from("tasks").select("id", { count: "exact", head: true }).eq("status", "escalated").eq("escalated_to", me))} icon={Siren} tone="danger" href="/tasks" />,
});

const teamOnboarding: Piece = async ({ supabase, me, features }) => {
  if (!onboardingOn(features)) return null;
  const { memberIds } = await myTeam(supabase, me);
  if (!memberIds.length) return null;
  const { data } = await supabase.from("profiles").select("onboarded_at").in("id", memberIds).eq("active", true);
  const done = (data ?? []).filter((p) => p.onboarded_at).length;
  return { tile: <Tile label="Team onboarding" value={`${done} of ${data?.length ?? 0}`} note="Finished their onboarding" icon={Clock} href="/compliance" /> };
};

const teamClients: Piece = async ({ supabase }) => {
  const { data, error } = await supabase.rpc("my_team_clients");
  if (error) return null; // before live update 54
  const rows = (data ?? []) as { client_id: string; client_name: string; team_name: string; open_tasks: number; overdue_tasks: number }[];
  return {
    panel: (
      <Panel title="Clients your team looks after" className="lg:col-span-2">
        {rows.length ? (
          <ul className="grid gap-2 sm:grid-cols-2">
            {rows.map((c) => (
              <li key={c.client_id} className="flex items-center justify-between gap-3 rounded-lg border border-line px-3 py-2 text-sm">
                <span className="min-w-0">
                  <span className="block truncate font-medium">{c.client_name}</span>
                  <span className="block truncate text-xs text-muted">{c.team_name}</span>
                </span>
                <span className="text-right text-xs">
                  <span className="block font-semibold tabular-nums">{c.open_tasks} open</span>
                  {Number(c.overdue_tasks) ? <span className="block text-danger tabular-nums">{c.overdue_tasks} overdue</span> : null}
                </span>
              </li>
            ))}
          </ul>
        ) : (
          <Empty>No clients linked to your team yet. A manager or staff admin links them on the Clients page.</Empty>
        )}
      </Panel>
    ),
  };
};

// ---------------------------------------------------------------------------
// Which pieces each role sees (add a new module's pieces here)
// ---------------------------------------------------------------------------

const LAYOUTS: Record<"manager" | "staff_admin" | "team_leader", { intro: string; pieces: Piece[] }> = {
  manager: {
    intro: "How the whole operation is going today.",
    pieces: [managerBoard, requestsWaiting, onboardingDone, documentsExpiring, newEnquiries, carsOut],
  },
  staff_admin: {
    intro: "Staffing at a glance: invites, onboarding, documents and changes.",
    pieces: [invitesPending, newStarters, uploadsToCheck, requestsWaiting, documentsExpiring, onboardingDone, roleChanges, noTeam, recentlyJoined],
  },
  team_leader: {
    intro: "Your team and the clients it looks after.",
    pieces: [teamTasks, escalatedToMe, requestsWaiting, teamOnboarding, teamClients],
  },
};

export function hasRoleDashboard(role: string): role is keyof typeof LAYOUTS {
  return role in LAYOUTS;
}

export async function RoleDashboard() {
  const { profile, features } = await requireSession();
  if (!hasRoleDashboard(profile.role)) return null;
  const supabase = await createClient();
  const [timeZone, rules] = await Promise.all([getTimeZone(), getPeopleRules()]);
  const ctx: Ctx = { supabase, me: profile.id, today: todayIn(timeZone), timeZone, features, complianceReport: canSeeComplianceReport(profile.role, rules) };
  const layout = LAYOUTS[profile.role];
  const parts = (await Promise.all(layout.pieces.map((p) => p(ctx).catch(() => null)))).filter(Boolean) as { board?: ReactNode; tile?: ReactNode; panel?: ReactNode }[];
  const firstName = profile.full_name?.split(" ")[0];
  return (
    <>
      <PageHeader
        title="Dashboard"
        intro={`${firstName ? `Hi ${firstName}. ` : ""}${layout.intro}`}
        action={
          <Link href="/tasks/new" className={buttonClass("primary")}>
            <Plus aria-hidden="true" className="size-4" />New task
          </Link>
        }
      />
      {/* cmeprojects Phase 5: birthdays and work anniversaries. */}
      <Celebrations me={profile.id} />
      {parts.map((p, i) => (p.board ? <div key={`b${i}`} className="contents">{p.board}</div> : null))}
      {parts.some((p) => p.tile) ? <div className="grid grid-cols-2 gap-3 md:grid-cols-4">{parts.map((p, i) => (p.tile ? <div key={i} className="contents">{p.tile}</div> : null))}</div> : null}
      <div className="grid gap-4 lg:grid-cols-2">{parts.map((p, i) => (p.panel ? <div key={i} className="contents">{p.panel}</div> : null))}</div>
    </>
  );
}

// ---------------------------------------------------------------------------
// Support workers: no dashboard, just a short "to do" strip above My tasks
// ---------------------------------------------------------------------------

export async function WorkerReminders() {
  const { profile, features } = await requireSession();
  const supabase = await createClient();
  const items: { text: string; href: string }[] = [];
  if (onboardingOn(features)) {
    const { data } = await supabase.rpc("compliance_status", { p_user: profile.id });
    const left = ((data ?? []) as { state: ItemState }[]).filter((s) => !isDone(s.state)).length;
    if (left) items.push({ text: `${left} onboarding item${left === 1 ? "" : "s"} to finish`, href: "/onboarding" });
  }
  if (formsOn(features)) {
    const [{ data: sent }, { data: done }] = await Promise.all([
      supabase.from("form_recipients").select("form_id").eq("user_id", profile.id),
      supabase.from("form_completions").select("form_id").eq("user_id", profile.id),
    ]);
    const finished = new Set((done ?? []).map((d) => d.form_id));
    const left = (sent ?? []).filter((s) => !finished.has(s.form_id)).length;
    if (left) items.push({ text: `${left} form${left === 1 ? "" : "s"} to fill in`, href: "/forms" });
  }
  if (features.vehicles === true) {
    const { count: out } = await supabase.from("car_trips").select("id", { count: "exact", head: true }).eq("driver_id", profile.id).is("returned_at", null);
    if (out) items.push({ text: "You have a car out. Return it when you're back", href: "/cars" });
  }
  if (!items.length) return null;
  return (
    <ul className="flex flex-wrap gap-2" aria-label="To do">
      {items.map((i) => (
        <li key={i.href}>
          <Link href={i.href} className="inline-flex min-h-10 items-center gap-2 rounded-full border border-warn/30 bg-warn-soft px-4 text-sm font-medium text-ink hover:border-warn">
            <span aria-hidden="true" className="size-2 rounded-full bg-warn" />
            {i.text} →
          </Link>
        </li>
      ))}
    </ul>
  );
}

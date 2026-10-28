// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { assignableRoles, inCoreTeam, JOB_TITLE_COLUMNS, ROLE_HELP, ROLE_LABELS, ROLES, type JobTitle, type Role } from "@/lib/roles";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { InviteForm, PersonEditor, type PersonRow } from "./forms";
import { getPeopleRules } from "@/lib/settings";
import { decideChangeRequest } from "./actions";

export const metadata: Metadata = { title: "Staff & roles" };

const ROLE_TONE: Record<Role, "dark" | "soft" | "grey"> = {
  new_starter: "grey",
  system_admin: "dark",
  staff_admin: "dark",
  manager: "soft",
  team_leader: "soft",
  support_worker: "grey",
};

// Who has signed in at least once (from the sign-in system).
async function joinedIds(): Promise<Set<string> | null> {
  try {
    const { data } = await createAdminClient().auth.admin.listUsers({ perPage: 1000 });
    return new Set(data.users.filter((u) => u.last_sign_in_at).map((u) => u.id));
  } catch {
    return null;
  }
}

export default async function StaffPage() {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const supabase = await createClient();
  // Seeing this page clears "approved / declined" alerts from your bell.
  await supabase.rpc("mark_request_updates_seen", { p_kind: "role" });
  const [{ data: people }, { data: teams }, { data: memberships }, { data: titleRows }, joined, { data: requests }] = await Promise.all([
    supabase
      .from("profiles")
      .select("id, full_name, email, role, job_title_id, active, deactivated_at")
      .order("active", { ascending: false })
      .order("full_name"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("team_members").select("team_id, user_id"),
    supabase.from("job_titles").select(JOB_TITLE_COLUMNS).order("sort_order").order("name"),
    joinedIds(),
    supabase
      .from("people_change_requests")
      .select("id, user_id, from_value, to_value, reason, requested_by, requested_at")
      .eq("kind", "role")
      .eq("status", "pending")
      .order("requested_at"),
  ]);
  const titles = (titleRows ?? []) as JobTitle[];
  const titleName = new Map(titles.map((t) => [t.id, t.name]));
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  type RoleValue = { role: Role; title: string | null };
  const roleText = (v: RoleValue) => (v.title && titleName.get(v.title)) || ROLE_LABELS[v.role];
  const pending = new Map((requests ?? []).map((q) => [q.user_id as string, q]));
  const canApprove = me.role === "manager" || me.role === "system_admin";
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone: "Australia/Melbourne" });
  const roles = assignableRoles(me.role);
  const rules = await getPeopleRules();
  const generalOnly = rules.generalInvitesOnly && me.role !== "system_admin";
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

  return (
    <>
      <PageHeader
        title="Staff & roles"
        intro="Invite people with any email address (no Microsoft account needed). Put people into teams on the Teams page. Deactivating someone stops them signing in straight away; their tasks and history stay."
      />

      {(requests ?? []).length ? (
        <Card className="overflow-hidden border-warn/40">
          <h2 className="heading-sm border-b border-line px-5 py-3">Role changes waiting for approval · {(requests ?? []).length}</h2>
          <ul className="divide-y divide-line">
            {(requests ?? []).map((q) => (
              <li key={q.id} className="flex flex-wrap items-center justify-between gap-3 px-5 py-3">
                <div className="min-w-60 flex-1 text-sm">
                  <p>
                    <strong>{nameOf.get(q.user_id!) ?? "Someone"}</strong>: {roleText(q.from_value as RoleValue)} → <strong>{roleText(q.to_value as RoleValue)}</strong>
                  </p>
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
                      <button className={buttonClass("primary")}>Approve</button>
                    </form>
                    <form action={decideChangeRequest}>
                      <input type="hidden" name="request_id" value={q.id} />
                      <input type="hidden" name="decision" value="decline" />
                      <button className={buttonClass("outline")}>Decline</button>
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

      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Invite someone</h2>
        <InviteForm roles={generalOnly ? ["new_starter"] : roles} titles={titles} teams={generalOnly || (me.role === "staff_admin" && rules.staffAdminTeamApproval) ? null : teams ?? []} />
      </Card>

      <div className="flex flex-col gap-3">
        {(people ?? []).map((p) => {
          const row: PersonRow = {
            ...p,
            role: p.role as Role,
            job_title_id: p.job_title_id,
            joined: joined ? joined.has(p.id) : true,
            isMe: p.id === me.id,
            editable: roles.includes(p.role as Role) || p.id === me.id,
          };
          const status = !p.active ? "Deactivated" : row.joined ? "Active" : "Invite sent";
          return (
            <Card key={p.id} className="p-0">
              <details className="group">
                <summary className="flex min-h-16 cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-brand-soft text-sm font-semibold text-brand" aria-hidden="true">
                    {(p.full_name || p.email).split(" ").map((w: string) => w[0]).slice(0, 2).join("").toUpperCase()}
                  </span>
                  <span className="min-w-48 flex-1">
                    <span className={`block font-semibold ${p.active ? "" : "text-muted"}`}>
                      {p.full_name || "(no name yet)"} {row.isMe ? <span className="font-normal text-muted">(you)</span> : null}
                    </span>
                    <span className="block text-sm text-muted">{p.email}</span>
                  </span>
                  {p.job_title_id && titleName.get(p.job_title_id) ? <span className="text-sm">{titleName.get(p.job_title_id)}</span> : null}
                  <Badge tone={ROLE_TONE[row.role]}>{ROLE_LABELS[row.role]}</Badge>
                  {pending.has(p.id) ? <Badge tone="warn">→ {roleText(pending.get(p.id)!.to_value as RoleValue)} waiting</Badge> : null}
                  <span className="w-40 text-sm text-muted">
                    {inCoreTeam(row.role) ? "Core team" : row.role === "system_admin" || row.role === "new_starter" ? "" : teamsOf(p.id) || "No team"}
                  </span>
                  <Badge tone={status === "Active" ? "good" : status === "Invite sent" ? "soft" : "grey"}>{status}</Badge>
                  <span className="text-sm font-semibold text-brand group-open:hidden">{row.editable ? "Edit" : "View"}</span>
                  <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                </summary>
                <div className="px-5 pb-5">
                  {row.editable ? (
                    <PersonEditor
                      person={row}
                      roles={roles}
                      titles={titles}
                      canResetMfa={me.role === "system_admin"}
                      needsApproval={needsApproval(row.role)}
                    />
                  ) : (
                    <p className="border-t border-line pt-4 text-sm text-muted">
                      Only a system admin can change a system admin.
                    </p>
                  )}
                </div>
              </details>
            </Card>
          );
        })}
      </div>

      <Card className="p-5">
        <h2 className="mb-3 heading-sm">What each access level can do</h2>
        <p className="mb-3 text-sm text-muted">Every role (job title) is linked to one of these. Managers add roles on the Roles page.</p>
        <dl className="grid gap-3 md:grid-cols-2">
          {ROLES.filter((r) => r !== "system_admin" || me.role === "system_admin").map((r) => (
            <div key={r}>
              <dt className="font-semibold">{ROLE_LABELS[r]}</dt>
              <dd className="text-sm text-muted">{ROLE_HELP[r]}</dd>
            </div>
          ))}
        </dl>
      </Card>
    </>
  );
}

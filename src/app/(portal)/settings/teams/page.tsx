// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { inCoreTeam, ROLE_LABELS, type Role } from "@/lib/roles";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { decideChangeRequest } from "../staff/actions";
import { NewTeamForm, TeamForm } from "./forms";
import { getPeopleRules } from "@/lib/settings";

export const metadata: Metadata = { title: "Teams" };

type TeamValue = { members: string[]; leader: string | null };

export default async function TeamsPage() {
  const { profile: me } = await requireRole(PEOPLE_MANAGERS);
  const supabase = await createClient();
  // Seeing this page clears "approved / declined" alerts from your bell.
  await supabase.rpc("mark_request_updates_seen", { p_kind: "team" });
  const [{ data: teams }, { data: leaderRows }, { data: memberRows }, { data: people }, { data: requests }] = await Promise.all([
    supabase.from("teams").select("id, name, active, is_core").order("active", { ascending: false }).order("name"),
    supabase.from("team_leaders").select("team_id, user_id"),
    supabase.from("team_members").select("team_id, user_id"),
    supabase.from("profiles").select("id, full_name, email, role").eq("active", true).order("full_name"),
    supabase
      .from("people_change_requests")
      .select("id, team_id, from_value, to_value, reason, requested_by, requested_at")
      .eq("kind", "team")
      .eq("status", "pending")
      .order("requested_at"),
  ]);
  const rules = await getPeopleRules();
  const everyone = (people ?? []).map((p) => ({ ...p, role: p.role as Role, name: p.full_name || p.email }));
  const nameOf = new Map(everyone.map((p) => [p.id, p.name]));
  const teamName = new Map((teams ?? []).map((t) => [t.id, t.name]));
  const core = everyone.filter((p) => inCoreTeam(p.role));
  const others = (teams ?? []).filter((t) => !t.is_core);
  const teamsOf = (userId: string) => (memberRows ?? []).filter((m) => m.user_id === userId).map((m) => m.team_id);
  const canApprove = me.role === "manager" || me.role === "system_admin";
  const pendingFor = new Map((requests ?? []).map((q) => [q.team_id as string, q]));
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone: "Australia/Melbourne" });

  // What a team request changes, in plain words.
  function describe(from: TeamValue, to: TeamValue): string {
    const added = to.members.filter((m) => !from.members.includes(m)).map((m) => nameOf.get(m) ?? "someone");
    const removed = from.members.filter((m) => !to.members.includes(m)).map((m) => nameOf.get(m) ?? "someone");
    const parts = [];
    if (added.length) parts.push(`add ${added.join(", ")}`);
    if (removed.length) parts.push(`remove ${removed.join(", ")}`);
    if (from.leader !== to.leader) parts.push(to.leader ? `team leader ${nameOf.get(to.leader) ?? "someone"}` : "no team leader");
    return parts.join("; ") || "no change";
  }

  return (
    <>
      <SectionTabs section="people" current="/settings/teams" />
      <PageHeader
        title="Teams"
        intro="Support workers can be in several teams. A team leader leads one team and sees everyone's tasks in it. Managers and staff admins are the core team, which works across every team."
      />

      {(requests ?? []).length ? (
        <Card className="overflow-hidden border-warn/40">
          <h2 className="heading-sm border-b border-line px-5 py-3">Team changes waiting for approval · {(requests ?? []).length}</h2>
          <ul className="divide-y divide-line">
            {(requests ?? []).map((q) => (
              <li key={q.id} className="flex flex-wrap items-center justify-between gap-3 px-5 py-3">
                <div className="min-w-60 flex-1 text-sm">
                  <p>
                    <strong>{teamName.get(q.team_id!) ?? "A team"}</strong>: {describe(q.from_value as TeamValue, q.to_value as TeamValue)}
                  </p>
                  <p className="text-xs text-muted">
                    Asked by {nameOf.get(q.requested_by) ?? "Admin"} · {when.format(new Date(q.requested_at))}
                    {q.reason ? ` · “${q.reason}”` : ""}
                  </p>
                </div>
                {canApprove ? (
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
        <NewTeamForm />
      </Card>

      <Card className="flex flex-col gap-2 p-5">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="heading-sm">{(teams ?? []).find((t) => t.is_core)?.name ?? "Management (core team)"}</h2>
          <Badge tone="dark">Every team</Badge>
        </div>
        <p className="text-sm text-muted">
          Managers and staff admins are in this team automatically. Managers see every team&apos;s tasks; staff admins look after people in
          any team but don&apos;t see their tasks.
        </p>
        <p className="text-sm">
          {core.length ? core.map((p) => `${p.name} (${ROLE_LABELS[p.role]})`).join(", ") : "No one yet"}
        </p>
      </Card>

      {others.length === 0 ? (
        <p className="text-sm text-muted">No teams yet.</p>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {others.map((team) => {
            const memberIds = (memberRows ?? []).filter((m) => m.team_id === team.id).map((m) => m.user_id);
            const leaderId = (leaderRows ?? []).find((l) => l.team_id === team.id)?.user_id ?? null;
            // Team leaders belong to one team only.
            const free = (p: (typeof everyone)[number]) => teamsOf(p.id).every((t) => t === team.id);
            const members = everyone
              .filter((p) => p.role === "support_worker" || (p.role === "team_leader" && free(p)))
              .map((p) => ({ id: p.id, name: p.name, detail: ROLE_LABELS[p.role] }));
            const leaders = everyone
              .filter((p) => p.role === "team_leader" && free(p))
              .map((p) => ({ id: p.id, name: p.name, detail: "" }));
            const waiting = pendingFor.get(team.id);
            return (
              <Card key={team.id} className="flex flex-col gap-4 p-5">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <h2 className="heading-sm">{team.name}</h2>
                  <span className="flex gap-2">
                    {waiting ? <Badge tone="warn">Change waiting</Badge> : null}
                    {team.active ? <Badge tone="good">In use</Badge> : <Badge tone="grey">Not in use</Badge>}
                  </span>
                </div>
                <p className="text-sm">
                  <span className="text-muted">Leader: </span>
                  {leaderId ? nameOf.get(leaderId) ?? "—" : "None"}
                  <span className="text-muted"> · Members: </span>
                  {memberIds.length ? memberIds.map((id) => nameOf.get(id) ?? "—").join(", ") : "No one yet"}
                </p>
                <details>
                  <summary className="cursor-pointer text-sm font-semibold text-brand">Change team</summary>
                  <div className="mt-4">
                    <TeamForm
                      team={team}
                      memberIds={memberIds}
                      leaderId={leaderId}
                      members={members}
                      leaders={leaders}
                      needsApproval={me.role === "staff_admin" && rules.staffAdminTeamApproval}
                    />
                  </div>
                </details>
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}

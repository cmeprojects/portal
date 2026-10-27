// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Badge, Card, PageHeader } from "@/components/ui";
import { NewTeamForm, TeamForm } from "./forms";

export const metadata: Metadata = { title: "Teams" };

export default async function TeamsPage() {
  await requireRole(PEOPLE_MANAGERS);
  const supabase = await createClient();
  const [{ data: teams }, { data: leaders }, { data: people }] = await Promise.all([
    supabase.from("teams").select("id, name, active").order("active", { ascending: false }).order("name"),
    supabase.from("team_leaders").select("team_id, user_id"),
    supabase.from("profiles").select("id, full_name, email, role, team_id, active").eq("active", true).order("full_name"),
  ]);
  const candidates = (people ?? []).filter((p) => ["team_leader", "manager", "system_admin"].includes(p.role));

  return (
    <>
      <PageHeader
        eyebrow="Settings"
        title="Teams"
        intro="A team leader sees their own tasks and the tasks of everyone in the teams they lead. Put people into a team on the Staff & roles page."
      />
      <Card className="p-5">
        <NewTeamForm />
      </Card>
      {(teams ?? []).length === 0 ? (
        <p className="text-sm text-muted">No teams yet.</p>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {(teams ?? []).map((team) => {
            const members = (people ?? []).filter((p) => p.team_id === team.id);
            return (
              <Card key={team.id} className="flex flex-col gap-4 p-5">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <h2 className="heading-sm">{team.name}</h2>
                  {team.active ? <Badge tone="good">In use</Badge> : <Badge tone="grey">Not in use</Badge>}
                </div>
                <div>
                  <p className="text-xs font-medium tracking-wider text-muted uppercase">Members</p>
                  <p className="text-sm">
                    {members.length ? members.map((m) => m.full_name || m.email).join(", ") : "No one yet"}
                  </p>
                </div>
                <TeamForm
                  team={team}
                  leaderIds={(leaders ?? []).filter((l) => l.team_id === team.id).map((l) => l.user_id)}
                  candidates={candidates}
                />
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}

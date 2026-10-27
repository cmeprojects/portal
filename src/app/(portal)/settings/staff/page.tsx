// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole, STAFF_ADMINS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { assignableRoles, ROLE_HELP, ROLE_LABELS, ROLES, type Role } from "@/lib/roles";
import { Badge, Card, PageHeader } from "@/components/ui";
import { InviteForm, PersonEditor, type PersonRow } from "./forms";

export const metadata: Metadata = { title: "Staff & roles" };

const ROLE_TONE: Record<Role, "dark" | "soft" | "grey"> = {
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
  const { profile: me } = await requireRole(STAFF_ADMINS);
  const supabase = await createClient();
  const [{ data: people }, { data: teams }, joined] = await Promise.all([
    supabase.from("profiles").select("id, full_name, email, role, team_id, active, deactivated_at").order("active", { ascending: false }).order("full_name"),
    supabase.from("teams").select("id, name").eq("active", true).order("name"),
    joinedIds(),
  ]);
  const roles = assignableRoles(me.role);
  const teamName = new Map((teams ?? []).map((t) => [t.id, t.name]));

  return (
    <>
      <PageHeader
        eyebrow="Settings"
        title="Staff & roles"
        intro="Invite people with any email address (no Microsoft account needed). Deactivating someone stops them signing in straight away; their tasks and history stay."
      />

      <Card className="p-5">
        <h2 className="mb-4 text-lg font-bold">Invite someone</h2>
        <InviteForm roles={roles} teams={teams ?? []} />
      </Card>

      <div className="flex flex-col gap-3">
        {(people ?? []).map((p) => {
          const row: PersonRow = {
            ...p,
            role: p.role as Role,
            joined: joined ? joined.has(p.id) : true,
            isMe: p.id === me.id,
            editable: roles.includes(p.role as Role),
          };
          const status = !p.active ? "Deactivated" : row.joined ? "Active" : "Invite sent";
          return (
            <Card key={p.id} className="p-0">
              <details className="group">
                <summary className="flex min-h-16 cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-brand-soft text-sm font-extrabold text-brand" aria-hidden="true">
                    {(p.full_name || p.email).split(" ").map((w: string) => w[0]).slice(0, 2).join("").toUpperCase()}
                  </span>
                  <span className="min-w-48 flex-1">
                    <span className={`block font-bold ${p.active ? "" : "text-muted"}`}>
                      {p.full_name || "(no name yet)"} {row.isMe ? <span className="font-normal text-muted">(you)</span> : null}
                    </span>
                    <span className="block text-sm text-muted">{p.email}</span>
                  </span>
                  <Badge tone={ROLE_TONE[row.role]}>{ROLE_LABELS[row.role]}</Badge>
                  <span className="w-32 text-sm text-muted">{p.team_id ? teamName.get(p.team_id) ?? "" : "No team"}</span>
                  <Badge tone={status === "Active" ? "good" : status === "Invite sent" ? "soft" : "grey"}>{status}</Badge>
                  <span className="text-sm font-semibold text-brand group-open:hidden">{row.editable ? "Edit" : "View"}</span>
                  <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                </summary>
                <div className="px-5 pb-5">
                  {row.editable ? (
                    <PersonEditor person={row} roles={roles} teams={teams ?? []} canResetMfa={me.role === "system_admin"} />
                  ) : (
                    <p className="border-t border-line pt-4 text-[15px] text-muted">
                      Only a system admin can change a {ROLE_LABELS[row.role].toLowerCase()}.
                    </p>
                  )}
                </div>
              </details>
            </Card>
          );
        })}
      </div>

      <Card className="p-5">
        <h2 className="mb-3 text-lg font-bold">What each role can do</h2>
        <dl className="grid gap-3 md:grid-cols-2">
          {ROLES.map((r) => (
            <div key={r}>
              <dt className="font-bold">{ROLE_LABELS[r]}</dt>
              <dd className="text-[15px] text-muted">{ROLE_HELP[r]}</dd>
            </div>
          ))}
        </dl>
      </Card>
    </>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { rolesOn } from "@/lib/feature-parts";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { JOB_TITLE_COLUMNS, ROLE_HELP, ROLE_LABELS, type JobTitle } from "@/lib/roles";
import { Badge, Card, PageHeader } from "@/components/ui";
import { JobTitleForm, NewJobTitleForm } from "./forms";
import { FunctionGroupForm } from "./function-group-forms";

export const metadata: Metadata = { title: "Roles" };

export default async function RolesPage() {
  // Job titles: the system admin always; others when Roles is on and the area is theirs (cmeprojects).
  const { profile, features } = await requireSession();
  if (profile.role !== "system_admin" && !(rolesOn(features) && (await getMyAdminAreas(profile.role)).includes("roles"))) redirect("/");
  const supabase = await createClient();
  const [{ data: rows }, { data: people }, groupsRes, linksRes, partsRes, mapRes] = await Promise.all([
    supabase.from("job_titles").select(JOB_TITLE_COLUMNS).order("sort_order").order("name"),
    supabase.from("profiles").select("job_title_id").not("job_title_id", "is", null),
    // cmeprojects (Stage 1, update 92): hidden before the update.
    supabase.from("function_groups").select("id, key, name, description, active").order("sort_order").order("name"),
    // cmeprojects (Stage 2, update 93): which groups each role belongs to (hidden before the update).
    supabase.from("job_title_functions").select("job_title_id, function_group_id"),
    // cmeprojects (Stage 4, update 104): parts a group looks after (hidden before the update).
    supabase.from("app_modules").select("id, label, category, sensitivity, parent_id").eq("status", "active").is("parent_id", null).order("sort_order"),
    supabase.from("function_group_modules").select("function_group_id, module_id"),
  ]);
  const parts = mapRes.error
    ? null
    : ((partsRes.data ?? []) as { id: string; label: string; category: string; sensitivity: string }[])
        .filter((m) => !m.id.startsWith("cat_") && m.category !== "workspace" && m.sensitivity !== "protected")
        .map((m) => ({ id: m.id, label: m.label, category: m.category }));
  const partsOf = (groupId: string) => ((mapRes.data ?? []) as { function_group_id: string; module_id: string }[]).filter((r) => r.function_group_id === groupId).map((r) => r.module_id);
  const links = linksRes.error ? null : ((linksRes.data ?? []) as { job_title_id: string; function_group_id: string }[]);
  const groupsOf = (titleId: string) => (links ?? []).filter((l) => l.job_title_id === titleId).map((l) => l.function_group_id);
  const groups = groupsRes.error ? null : ((groupsRes.data ?? []) as { id: string; key: string; name: string; description: string; active: boolean }[]);
  const titles = (rows ?? []) as JobTitle[];
  const count = (id: string) => (people ?? []).filter((p) => p.job_title_id === id).length;

  return (
    <>
      <PageHeader
        title="Roles"
        intro="Job titles like Nurse or House coordinator, each linked to an access level."
      />
      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Add a role</h2>
        <NewJobTitleForm groups={links && groups ? groups : null} />
      </Card>

      {titles.length === 0 ? (
        <p className="text-sm text-muted">No roles yet. People are shown by their access level until you add some.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {titles.map((t) => (
            <Card key={t.id} className="p-0">
              <details name="role" className="group">
                <summary className="flex min-h-14 cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3">
                  <span className={`min-w-48 flex-1 font-semibold ${t.active ? "" : "text-muted"}`}>{t.name}</span>
                  <Badge tone="soft">{ROLE_LABELS[t.access_level]}</Badge>
                  <span className="w-24 text-sm text-muted">
                    {count(t.id)} {count(t.id) === 1 ? "person" : "people"}
                  </span>
                  {t.active ? <Badge tone="good">In use</Badge> : <Badge tone="grey">Not in use</Badge>}
                  <span className="text-sm font-semibold text-brand group-open:hidden">Edit</span>
                  <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                </summary>
                <div className="border-t border-line px-5 py-5">
                  <JobTitleForm title={t} inUse={count(t.id)} groups={links && groups ? groups : null} chosen={groupsOf(t.id)} />
                </div>
              </details>
            </Card>
          ))}
        </div>
      )}

      {groups ? (
        <Card className="p-5">
          <h2 className="heading-sm">Function groups</h2>
          <p className="mb-3 text-sm text-muted">
            The business functions roles belong to, for example Care &amp; Coordination. Each role belongs to at least one group. Groups don&apos;t give anyone access yet. A group is never deleted: untick In use instead.
          </p>
          <ul className="divide-y divide-line rounded-md border border-line">
            {groups.map((g) => (
              <li key={g.id} className="px-3 py-3">
                <details className="group">
                  <summary className="flex cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1 [&::-webkit-details-marker]:hidden">
                    <span className={`min-w-40 flex-1 font-semibold ${g.active ? "" : "text-muted"}`}>{g.name}</span>
                    {links ? <span className="text-sm text-muted">{links.filter((l) => l.function_group_id === g.id).length} roles</span> : null}
                    {g.active ? <Badge tone="good">In use</Badge> : <Badge tone="grey">Not in use</Badge>}
                    <span className="text-sm font-semibold text-brand group-open:hidden">Edit</span>
                    <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                  </summary>
                  {g.description ? <p className="mt-1 text-sm text-muted group-open:hidden">{g.description}</p> : null}
                  <div className="mt-3">
                    <FunctionGroupForm group={g} parts={parts} chosen={partsOf(g.id)} />
                  </div>
                </details>
              </li>
            ))}
          </ul>
          <div className="mt-4 border-t border-line pt-4">
            <h3 className="mb-2 text-sm font-semibold">Add a group</h3>
            <FunctionGroupForm />
          </div>
        </Card>
      ) : null}

      <Card className="p-5">
        <h2 className="mb-3 heading-sm">Access levels</h2>
        <dl className="grid gap-3 md:grid-cols-2">
          {(["support_worker", "team_leader", "manager", "staff_admin"] as const).map((r) => (
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

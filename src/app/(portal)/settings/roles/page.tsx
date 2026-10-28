// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { JOB_TITLE_COLUMNS, ROLE_HELP, ROLE_LABELS, type JobTitle } from "@/lib/roles";
import { Badge, Card, PageHeader } from "@/components/ui";
import { JobTitleForm, NewJobTitleForm } from "./forms";

export const metadata: Metadata = { title: "Roles" };

export default async function RolesPage() {
  await requireRole(["manager", "system_admin"]);
  const supabase = await createClient();
  const [{ data: rows }, { data: people }] = await Promise.all([
    supabase.from("job_titles").select(JOB_TITLE_COLUMNS).order("sort_order").order("name"),
    supabase.from("profiles").select("job_title_id").not("job_title_id", "is", null),
  ]);
  const titles = (rows ?? []) as JobTitle[];
  const count = (id: string) => (people ?? []).filter((p) => p.job_title_id === id).length;

  return (
    <>
      <PageHeader
        title="Roles"
        intro="Add the roles your organisation uses, like Nurse or House coordinator. Each role is linked to an access level, which decides what the person can see and do."
      />
      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Add a role</h2>
        <NewJobTitleForm />
      </Card>

      {titles.length === 0 ? (
        <p className="text-sm text-muted">No roles yet. People are shown by their access level until you add some.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {titles.map((t) => (
            <Card key={t.id} className="p-0">
              <details className="group">
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
                  <JobTitleForm title={t} inUse={count(t.id)} />
                </div>
              </details>
            </Card>
          ))}
        </div>
      )}

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

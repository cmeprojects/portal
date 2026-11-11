// Staff Portal · © cmeproject. All rights reserved.
import { createClient } from "@/lib/supabase/server";
import { getCreateRoles } from "@/lib/register-data";
import type { Metadata } from "next";
import { requireTaskAccess } from "@/lib/session";
import { getSla, getTimeZone, getRequiredWhen } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { ROLE_LABELS, canTakeTasks } from "@/lib/roles";
import { getPeopleRules } from "@/lib/settings";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { fieldsForTaskForm } from "@/lib/registers";
import { Card, Notice, PageHeader } from "@/components/ui";
import { NewTaskForm } from "./form";

export const metadata: Metadata = { title: "New task" };

export default async function NewTaskPage({ searchParams }: PageProps<"/tasks/new">) {
  const { profile, features } = await requireTaskAccess();
  const rules = await getPeopleRules();
  const { register } = await searchParams;
  const [registries, allFields, people, assets, timeZone, sla, requiredWhen] = await Promise.all([
    getRegistries(),
    getFields(),
    getPeople(),
    getAssets(),
    getTimeZone(),
    getSla(),
    getRequiredWhen(),
  ]);
  // Some roles (support workers by default) only raise General tasks and questions.
  const limited = rules.limitedTaskRoles.includes(profile.role);
  // A register can choose who creates tasks in it (cmeprojects); otherwise the limited-roles rule applies.
  const createRoles = await getCreateRoles();
  // A register's own managers can always create tasks in it.
  const { data: managed } = await (await createClient()).from("registry_managers").select("registry_id").eq("user_id", profile.id);
  const manages = new Set((managed ?? []).map((m) => m.registry_id as string));
  const allowed = (r: (typeof registries)[number]) => {
    if (profile.role === "system_admin" || manages.has(r.id)) return true;
    const roles = createRoles.get(r.id) ?? [];
    return roles.length ? roles.includes(profile.role) : !limited || r.is_default;
  };
  const taskRegistries = registries.filter((r) => r.active && r.kind === "tasks" && allowed(r));

  if (features.tasks === false) {
    return (
      <>
        <PageHeader title="New task" />
        <Notice>Tasks are switched off at the moment.</Notice>
      </>
    );
  }

  // cmeprojects: client names for "who is this about" (empty before live update 54).
  const { data: clientRows } = await (await createClient()).rpc("clients_to_pick");
  const clients = ((clientRows ?? []) as { id: string; name: string }[]);
  return (
    <>
      <PageHeader
        title={limited ? "New task or question" : "New task"}
        intro={
          limited
            ? "Raise a general task or ask a question, and pick who should look at it. You'll see how it's going in My tasks → My requests and questions."
            : "Choose a register, fill in the details and pick who will look after it."
        }
      />
      <Card className="max-w-4xl p-5 sm:p-7">
        <NewTaskForm
          registries={taskRegistries}
          fields={fieldsForTaskForm(allFields, requiredWhen)}
          people={people.filter((p) => p.active && canTakeTasks(p.role, rules.newStarterTasks)).map((p) => ({ id: p.id, name: p.name, detail: ROLE_LABELS[p.role] }))}
          assets={assets.filter((a) => !a.archived)}
          meId={profile.id}
          today={todayIn(timeZone)}
          initialRegistryId={typeof register === "string" ? register : undefined}
          sla={sla.days}
          weekdaysOnly={sla.weekdaysOnly}
          askChoice={limited}
          clients={clients}
        />
      </Card>
    </>
  );
}

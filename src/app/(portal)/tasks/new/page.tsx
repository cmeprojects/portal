// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireTaskAccess } from "@/lib/session";
import { getSla, getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { ROLE_LABELS, canTakeTasks } from "@/lib/roles";
import { getPeopleRules } from "@/lib/settings";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { Card, Notice, PageHeader } from "@/components/ui";
import { NewTaskForm } from "./form";

export const metadata: Metadata = { title: "New task" };

export default async function NewTaskPage({ searchParams }: PageProps<"/tasks/new">) {
  const { profile, features } = await requireTaskAccess();
  const rules = await getPeopleRules();
  const { register } = await searchParams;
  const [registries, fields, people, assets, timeZone, sla] = await Promise.all([
    getRegistries(),
    getFields(),
    getPeople(),
    getAssets(),
    getTimeZone(),
    getSla(),
  ]);
  const taskRegistries = registries.filter((r) => r.active && r.kind === "tasks");

  if (features.tasks === false) {
    return (
      <>
        <PageHeader title="New task" />
        <Notice>Tasks are switched off at the moment.</Notice>
      </>
    );
  }

  return (
    <>
      <PageHeader title="New task" intro="Choose a register, fill in the details and pick who will look after it." />
      <Card className="max-w-4xl p-5 sm:p-7">
        <NewTaskForm
          registries={taskRegistries}
          fields={fields}
          people={people.filter((p) => p.active && canTakeTasks(p.role, rules.newStarterTasks)).map((p) => ({ id: p.id, name: p.name, detail: ROLE_LABELS[p.role] }))}
          assets={assets.filter((a) => !a.archived)}
          meId={profile.id}
          today={todayIn(timeZone)}
          initialRegistryId={typeof register === "string" ? register : undefined}
          sla={sla.days}
          weekdaysOnly={sla.weekdaysOnly}
        />
      </Card>
    </>
  );
}

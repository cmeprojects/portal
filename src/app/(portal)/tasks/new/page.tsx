// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { Card, Notice, PageHeader } from "@/components/ui";
import { NewTaskForm } from "./form";

export const metadata: Metadata = { title: "New task" };

export default async function NewTaskPage() {
  const { profile, features } = await requireSession();
  const supabase = await createClient();
  const [{ data: registries }, { data: people }, timeZone] = await Promise.all([
    supabase.from("registries").select("id, name, requires_approval").eq("active", true).order("sort_order").order("name"),
    supabase.from("profiles").select("id, full_name, email, role").eq("active", true).order("full_name"),
    getTimeZone(),
  ]);

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
      <PageHeader title="New task" intro="Create a task and choose who will look after it." />
      <Card className="max-w-4xl p-5 sm:p-7">
        {(registries ?? []).length === 0 ? (
          <Notice>There are no registries yet. Ask a staff admin to add one.</Notice>
        ) : (
          <NewTaskForm
            registries={registries ?? []}
            people={(people ?? []).map((p) => ({
              id: p.id,
              name: p.full_name || p.email,
              detail: ROLE_LABELS[p.role as Role],
            }))}
            meId={profile.id}
            today={todayIn(timeZone)}
          />
        )}
      </Card>
    </>
  );
}

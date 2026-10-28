// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireTaskAccess } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getRegistries } from "@/lib/register-data";
import { DONE } from "@/lib/tasks";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";

export const metadata: Metadata = { title: "Registers" };

export default async function RegistersPage() {
  const { profile } = await requireTaskAccess();
  const supabase = await createClient();
  const registries = (await getRegistries()).filter((r) => r.active);
  // Staff admins see every register's open tasks as an overview (counts only here).
  const overview = profile.role === "staff_admin";
  const [{ data: openTasks }, { data: records }, { data: counts }] = await Promise.all([
    overview
      ? Promise.resolve({ data: [] as { registry_id: string }[] })
      : supabase.from("tasks").select("registry_id").is("parent_task_id", null).not("status", "in", `(${DONE.join(",")})`).limit(5000),
    supabase.from("records").select("registry_id").eq("archived", false).limit(5000),
    overview ? supabase.rpc("register_open_counts") : Promise.resolve({ data: [] as { registry_id: string; open_tasks: number }[] }),
  ]);
  const count = (id: string) =>
    (overview
      ? Number(((counts ?? []) as { registry_id: string; open_tasks: number }[]).find((c) => c.registry_id === id)?.open_tasks ?? 0)
      : (openTasks ?? []).filter((t) => t.registry_id === id).length) + (records ?? []).filter((r) => r.registry_id === id).length;
  const canCreate = profile.role === "manager" || profile.role === "system_admin";

  return (
    <>
      <PageHeader
        title="Registers"
        intro="Every task lives in one place. Each register shows its own tasks with its own columns."
        action={canCreate ? <Link href="/registers/new" className={buttonClass("primary")}>+ New register</Link> : null}
      />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {registries.map((r) => (
          <Link key={r.id} href={`/registers/${r.id}`} className="block">
            <Card className="flex h-full flex-col gap-2 p-5 hover:border-brand">
              <div className="flex items-start justify-between gap-2">
                <h2 className="heading-sm">{r.name}</h2>
                <Badge tone="grey">{r.prefix}</Badge>
              </div>
              {r.description ? <p className="text-sm text-muted">{r.description}</p> : null}
              <p className="mt-auto pt-2 text-sm font-semibold text-brand">
                {count(r.id)} {r.kind === "records" ? "items" : "open"}
                {r.kind === "records" ? " · list" : r.requires_approval ? " · approval needed to close" : ""}
              </p>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}

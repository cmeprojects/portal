// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getRegistries } from "@/lib/register-data";
import { DONE } from "@/lib/tasks";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";

export const metadata: Metadata = { title: "Registers" };

export default async function RegistersPage() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const registries = (await getRegistries()).filter((r) => r.active);
  const [{ data: openTasks }, { data: records }] = await Promise.all([
    supabase.from("tasks").select("registry_id").is("parent_task_id", null).not("status", "in", `(${DONE.join(",")})`).limit(5000),
    supabase.from("records").select("registry_id").eq("archived", false).limit(5000),
  ]);
  const count = (id: string) =>
    (openTasks ?? []).filter((t) => t.registry_id === id).length + (records ?? []).filter((r) => r.registry_id === id).length;
  const canCreate = ["manager", "staff_admin", "system_admin"].includes(profile.role);

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
                <h2 className="text-lg font-extrabold">{r.name}</h2>
                <Badge tone="grey">{r.prefix}</Badge>
              </div>
              {r.description ? <p className="text-[15px] text-muted">{r.description}</p> : null}
              <p className="mt-auto pt-2 text-[15px] font-semibold text-brand">
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

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { canSeeRegisters, getPeopleRules } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { getRegistries } from "@/lib/register-data";
import { DONE } from "@/lib/tasks";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { setRegistryApproval } from "./setup-actions";

export const metadata: Metadata = { title: "Registers" };

export default async function RegistersPage() {
  const { profile } = await requireTaskAccess();
  // Who sees Registers is set by the system admin (System settings → Tasks).
  if (!canSeeRegisters(profile.role, await getPeopleRules())) redirect("/");
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
  // Managers change the registers they're named on; the system admin changes any.
  const { data: mine } = canCreate ? await supabase.from("registry_managers").select("registry_id").eq("user_id", profile.id) : { data: [] };
  const manages = (id: string) => profile.role === "system_admin" || (mine ?? []).some((m) => m.registry_id === id);

  return (
    <>
      <PageHeader
        title="Registers"
        intro="Every task lives in one place. Each register shows its own tasks with its own columns."
        action={canCreate ? <Link href="/registers/new" className={buttonClass("primary")}>+ New register</Link> : null}
      />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {registries.map((r) => (
          <Card key={r.id} className="flex h-full flex-col hover:border-brand">
            <Link href={`/registers/${r.id}`} className="flex flex-1 flex-col gap-2 p-5 pb-3">
              <div className="flex items-start justify-between gap-2">
                <h2 className="heading-sm">{r.name}</h2>
                <Badge tone="grey">{r.prefix}</Badge>
              </div>
              {r.description ? <p className="text-sm text-muted">{r.description}</p> : null}
              <p className="mt-auto pt-2 text-sm font-semibold text-brand">
                {count(r.id)} {r.kind === "records" ? "items" : "open"}
                {r.kind === "records" ? " · list" : r.requires_approval ? " · approval needed to close" : ""}
              </p>
            </Link>
            {manages(r.id) && r.kind === "tasks" ? (
              <form action={setRegistryApproval} className="flex items-center justify-between gap-3 border-t border-line px-5 py-2.5">
                <input type="hidden" name="id" value={r.id} />
                <input type="hidden" name="on" value={r.requires_approval ? "false" : "true"} />
                <span className="text-sm text-muted">Manager approval to close tasks</span>
                <button
                  role="switch"
                  aria-checked={r.requires_approval}
                  aria-label={`${r.name}: approval to close ${r.requires_approval ? "on" : "off"}`}
                  className={`flex h-8 min-w-16 items-center justify-center gap-1.5 rounded-md px-2.5 text-xs font-semibold ${
                    r.requires_approval ? "bg-brand text-brand-fg" : "border border-field bg-surface text-muted"
                  }`}
                >
                  <span aria-hidden="true" className={`h-2 w-2 rounded-full ${r.requires_approval ? "bg-brand-fg" : "bg-muted"}`} />
                  {r.requires_approval ? "On" : "Off"}
                </button>
              </form>
            ) : null}
          </Card>
        ))}
      </div>
    </>
  );
}

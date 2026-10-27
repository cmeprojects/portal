// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole, STAFF_ADMINS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Badge, Card, PageHeader } from "@/components/ui";
import { RegistryForm } from "./form";

export const metadata: Metadata = { title: "Registries" };

export default async function RegistriesPage() {
  await requireRole(STAFF_ADMINS);
  const supabase = await createClient();
  const [{ data: registries }, { data: links }, { data: people }] = await Promise.all([
    supabase.from("registries").select("id, name, description, requires_approval, active").order("active", { ascending: false }).order("sort_order").order("name"),
    supabase.from("registry_managers").select("registry_id, user_id"),
    supabase.from("profiles").select("id, full_name, email, role").eq("active", true).in("role", ["manager", "system_admin"]).order("full_name"),
  ]);
  const candidates = people ?? [];
  const nameOf = new Map(candidates.map((p) => [p.id, p.full_name || p.email]));

  return (
    <>
      <PageHeader
        eyebrow="Settings"
        title="Registries"
        intro="Each registry has its own managers. Managers see every task in the registries they look after."
      />
      <details className="rounded-[20px] border border-line bg-white">
        <summary className="flex min-h-14 cursor-pointer list-none items-center px-5 font-bold text-brand">+ Add a registry</summary>
        <div className="px-5 pb-5">
          <RegistryForm candidates={candidates} />
        </div>
      </details>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {(registries ?? []).map((r) => {
          const managerIds = (links ?? []).filter((l) => l.registry_id === r.id).map((l) => l.user_id);
          return (
            <Card key={r.id} className="flex flex-col gap-3 p-5">
              <div className="flex items-start justify-between gap-2">
                <h2 className={`text-lg font-extrabold ${r.active ? "" : "text-muted"}`}>{r.name}</h2>
                {!r.active ? <Badge tone="grey">Not in use</Badge> : null}
              </div>
              {r.description ? <p className="text-[15px] text-muted">{r.description}</p> : null}
              <div>
                <p className="text-[13px] font-bold uppercase tracking-wide text-muted">Managers</p>
                <p className={`text-[15px] font-semibold ${managerIds.length ? "" : "text-warn"}`}>
                  {managerIds.length ? managerIds.map((id) => nameOf.get(id) ?? "Former manager").join(", ") : "No manager yet"}
                </p>
              </div>
              <div className="flex items-center justify-between gap-3 border-t border-line pt-3">
                <span className="text-[15px]">Manager approval needed to close</span>
                <Badge tone={r.requires_approval ? "dark" : "grey"}>{r.requires_approval ? "Yes" : "No"}</Badge>
              </div>
              <details>
                <summary className="flex min-h-11 cursor-pointer list-none items-center font-semibold text-brand">Edit</summary>
                <div className="pt-2">
                  <RegistryForm registry={r} managerIds={managerIds} candidates={candidates} />
                </div>
              </details>
            </Card>
          );
        })}
      </div>
    </>
  );
}

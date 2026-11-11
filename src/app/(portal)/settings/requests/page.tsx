// Staff Portal · © cmeproject. All rights reserved.
import { getMyAdminAreas } from "@/lib/settings";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { REQUEST_TYPES } from "@/lib/requests-shared";
import { Card, PageHeader } from "@/components/ui";
import { RequestTypeForm } from "./type-form";

export const metadata: Metadata = { title: "Request approvals" };

// cmeprojects: the system admin decides who approves each request type
// (HR Pack → My requests), who's told, and where unattended requests go.
export default async function RequestSettingsPage() {
  // cmeprojects: the system admin, or whoever looks after HR Pack (Delegation).
  const { live, profile } = await requireRole(["system_admin", "manager", "staff_admin"]);
  if (profile.role !== "system_admin" && !(await getMyAdminAreas(profile.role)).includes("hr")) notFound();
  const supabase = await createClient();
  const [{ data: types, error }, { data: people }] = await Promise.all([
    supabase.from("request_types").select("*").order("sort_order"),
    supabase.from("profiles").select("id, full_name, email").eq("active", true).in("role", ["manager", "staff_admin", "team_leader"]).order("full_name"),
  ]);
  if (error) notFound(); // before live update 56
  const list = (people ?? []).map((p) => ({ id: p.id, name: p.full_name || p.email }));
  return (
    <>
      <PageHeader title="Request approvals" intro="Who approves each kind of request, who's told, and where requests go if nobody acts." />
      {(types ?? []).map((t) => {
        const meta = REQUEST_TYPES.find((x) => x.key === t.key);
        const on = meta ? live[meta.feature] !== false : true;
        return (
          <Card key={t.key} className="p-5">
            <details name="request-type" className="group">
              <summary className="flex cursor-pointer list-none items-center gap-3 [&::-webkit-details-marker]:hidden">
                <span className="flex-1">
                  <span className="block font-semibold">{t.label}</span>
                  <span className="block text-xs text-muted">
                    {on ? "On" : "Switched off in Settings → Features → HR Pack"} · first: {t.first_approvers.join(", ").replace(/user:[0-9a-f-]+/g, "chosen person")}
                    {t.second_approvers.length ? ` · then: ${t.second_approvers.join(", ").replace(/user:[0-9a-f-]+/g, "chosen person")}` : ""}
                  </span>
                </span>
                <span className="text-sm font-semibold text-brand group-open:hidden">Open</span>
                <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
              </summary>
              <div className="mt-4 border-t border-line pt-4">
                <RequestTypeForm type={t} people={list} />
              </div>
            </details>
          </Card>
        );
      })}
    </>
  );
}

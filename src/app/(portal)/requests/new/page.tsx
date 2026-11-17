// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { REQUEST_TYPES } from "@/lib/requests-shared";
import { Card, PageHeader } from "@/components/ui";
import { NewRequestForm } from "./form";

export const metadata: Metadata = { title: "New request" };

export default async function NewRequestPage({ searchParams }: PageProps<"/requests/new">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false || profile.role === "system_admin") notFound();
  const types = REQUEST_TYPES.filter((t) => live[t.feature] !== false).map((t) => t.key);
  const supabase = await createClient();
  const { data: people } = await supabase.from("profiles").select("id, full_name, email, role").eq("active", true).neq("id", profile.id).not("role", "in", "(system_admin,new_starter,external)").order("full_name");
  const type = (await searchParams).type;
  // cmeprojects: who approves each type and when it escalates, as set in Portal settings → Request approvals.
  const { data: routeRows } = await supabase.from("request_types").select("key, first_approvers, second_approvers, escalate_days, escalate_to");
  const routes = Object.fromEntries(
    ((routeRows ?? []) as { key: string; first_approvers: string[]; second_approvers: string[]; escalate_days: number; escalate_to: string[] }[]).map((r) => [
      r.key,
      { first: r.first_approvers, second: r.second_approvers, escalateDays: r.escalate_days, escalateTo: r.escalate_to },
    ]),
  );
  // cmeprojects (update 120): their own leave balances, shown before they send a leave request.
  const balances: Record<string, number> = {};
  for (const k of ["annual", "personal", "long_service"]) {
    const { data, error } = await supabase.rpc("leave_balance", { p_user: profile.id, p_type: k });
    if (!error && data !== null && data !== undefined && Number.isFinite(Number(data))) balances[k] = Number(data);
  }
  return (
    <>
      <p className="text-sm">
        <Link href="/requests" className="text-brand underline">
          ← My requests
        </Link>
      </p>
      <PageHeader title="New request" intro="Choose what you need. You'll see who's approving it and can track it in My requests." />
      <Card className="max-w-3xl p-5 sm:p-7">
        {types.length ? (
          <NewRequestForm
            types={types}
            colleagues={(people ?? []).map((p) => ({ id: p.id, name: p.full_name || p.email }))}
            today={todayIn(await getTimeZone())}
            initial={typeof type === "string" ? type : undefined}
            routes={routes}
            balances={balances}
          />
        ) : (
          <p className="text-sm text-muted">No request types are switched on at the moment.</p>
        )}
      </Card>
    </>
  );
}

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
          />
        ) : (
          <p className="text-sm text-muted">No request types are switched on at the moment.</p>
        )}
      </Card>
    </>
  );
}

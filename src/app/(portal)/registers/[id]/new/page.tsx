// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { Card, PageHeader } from "@/components/ui";
import { RecordForm } from "../../../records/record-form";

export const metadata: Metadata = { title: "Add item" };

export default async function NewRecordPage({ params }: PageProps<"/registers/[id]/new">) {
  const { id } = await params;
  await requireSession();
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) notFound();
  if (registry.kind !== "records") redirect(`/tasks/new?register=${id}`);
  const supabase = await createClient();
  const { data: manages } = await supabase.rpc("manages_registry", { p_registry_id: id });
  if (!manages) redirect(`/registers/${id}`);
  const [fields, people, assets, timeZone] = await Promise.all([getFields(), getPeople(), getAssets(), getTimeZone()]);

  return (
    <>
      <Link href={`/registers/${id}`} className="text-sm font-semibold text-brand">
        ← {registry.name}
      </Link>
      <PageHeader title={`Add to ${registry.name}`} />
      <Card className="max-w-4xl p-5 sm:p-7">
        <RecordForm
          registry={registry}
          fields={fields.filter((f) => f.registry_id === id && f.active)}
          people={people.filter((p) => p.active).map((p) => ({ id: p.id, label: p.name }))}
          assets={assets.filter((a) => !a.archived)}
          today={todayIn(timeZone)}
        />
      </Card>
    </>
  );
}

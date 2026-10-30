// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { hasPin } from "@/lib/car-pin";
import { formContext, loadFeature } from "@/lib/custom-features";
import { staffAppOn } from "@/lib/staff-app";
import { FeatureForm } from "@/components/feature-form";
import { LiveRefresh } from "@/components/live-refresh";

export async function generateMetadata({ params }: PageProps<"/app/f/[slug]">): Promise<Metadata> {
  const def = await loadFeature({ slug: (await params).slug });
  return { title: def?.feature.menu_label ?? "Not found" };
}

// A built feature inside the Staff app: the same form as the portal, full screen.
export default async function StaffAppFeature({ params }: PageProps<"/app/f/[slug]">) {
  const { profile, features } = await requireSession();
  if (!staffAppOn(features)) notFound();
  const def = await loadFeature({ slug: (await params).slug });
  if (!def || def.feature.status !== "published" || !def.feature.enabled || !def.feature.in_app) notFound();
  if (!(await hasPin(profile.id))) redirect("/app/unlock");
  const supabase = await createClient();
  const { data: canFill } = await supabase.rpc("can_fill_feature", { p_feature: def.feature.id });
  if (!canFill) notFound();
  const ctx = await formContext(def.feature.id, profile.id);
  return (
    <>
      <LiveRefresh tables={["custom_entries"]} />
      <Link href="/app" className="-mb-1 self-start text-sm font-semibold text-brand">
        ‹ All
      </Link>
      <section className="rounded-xl border border-line bg-surface p-4">
        <FeatureForm feature={def.feature} fields={def.fields} clients={ctx.clients} staff={ctx.staff} me={ctx.me} targets={ctx.targets} timeZone={ctx.timeZone} mode="live" />
      </section>
    </>
  );
}

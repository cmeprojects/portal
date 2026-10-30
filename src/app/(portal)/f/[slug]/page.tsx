// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formContext, loadFeature } from "@/lib/custom-features";
import { getTimeZone } from "@/lib/settings";
import { FeatureForm } from "@/components/feature-form";
import { Card } from "@/components/ui";
import { LiveRefresh } from "@/components/live-refresh";

export async function generateMetadata({ params }: PageProps<"/f/[slug]">): Promise<Metadata> {
  const def = await loadFeature({ slug: (await params).slug });
  return { title: def?.feature.name ?? "Not found" };
}

// A feature built in the Feature builder: the form staff fill in, and their recent entries.
export default async function FeaturePage({ params }: PageProps<"/f/[slug]">) {
  const { profile } = await requireSession();
  const def = await loadFeature({ slug: (await params).slug });
  if (!def || def.feature.status !== "published" || !def.feature.enabled) notFound();
  const { feature, fields } = def;
  const supabase = await createClient();
  const can = (what: string) => supabase.rpc("can_manage_feature", { p_feature: feature.id, p_what: what });
  const [{ data: canFill }, ctx, timeZone, { data: mine }, ...rights] = await Promise.all([
    supabase.rpc("can_fill_feature", { p_feature: feature.id }),
    formContext(feature.id, profile.id),
    getTimeZone(),
    supabase.from("custom_entries").select("id, created_at, client_name, data").eq("feature_id", feature.id).eq("created_by", profile.id).order("created_at", { ascending: false }).limit(8),
    can("fix"),
    can("targets"),
    can("options"),
  ]);
  const canManage = rights.some((r) => r.data);
  const when = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  const total = fields.find((f) => f.id === feature.total_field);
  const choice = fields.find((f) => f.type === "choice" && !f.archived);

  return (
    <div className="flex w-full max-w-xl flex-col gap-5">
      <LiveRefresh tables={["custom_entries"]} />
      {canManage ? (
        <Link href={`/f/${feature.slug}/manage`} className="self-end text-sm font-semibold text-brand underline">
          Manage: fix entries, targets and lists
        </Link>
      ) : null}
      {canFill ? (
        <Card className="p-4 sm:p-5">
          <FeatureForm feature={feature} fields={fields} clients={ctx.clients} staff={ctx.staff} me={ctx.me} targets={ctx.targets} timeZone={ctx.timeZone} mode="live" />
        </Card>
      ) : (
        <Card className="p-5 text-sm">
          <h1 className="heading-sm">{feature.name}</h1>
          <p className="mt-2 text-muted">You can see this feature&apos;s entries in its report. Filling it in is for other roles.</p>
        </Card>
      )}
      {mine?.length ? (
        <section className="flex flex-col gap-2">
          <h2 className="heading-sm">Your recent entries</h2>
          <ul className="divide-y divide-line rounded-xl border border-line bg-surface text-sm">
            {mine.map((e) => {
              const d = e.data as Record<string, unknown>;
              return (
                <li key={e.id} className="flex flex-wrap justify-between gap-x-3 px-4 py-2.5">
                  <span>
                    <span className="block font-semibold">{e.client_name || feature.name}</span>
                    <span className="block text-xs text-muted">{when.format(new Date(e.created_at))}</span>
                  </span>
                  <span className="text-right">
                    {total && d[total.id] != null ? `${Number(d[total.id]).toLocaleString("en-AU")} ${total.unit}` : ""}
                    {choice && d[choice.id] ? <span className="block text-xs text-muted">{String(d[choice.id])}</span> : null}
                  </span>
                </li>
              );
            })}
          </ul>
        </section>
      ) : null}
    </div>
  );
}

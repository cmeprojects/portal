// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formContext, loadFeature } from "@/lib/custom-features";
import { Manage, type ManageEntry } from "./manage";
import { LiveRefresh } from "@/components/live-refresh";

const daysAgo = (n: number) => new Date(Date.now() - n * 86_400_000).toISOString();

export async function generateMetadata({ params }: PageProps<"/f/[slug]/manage">): Promise<Metadata> {
  const def = await loadFeature({ slug: (await params).slug });
  return { title: def ? `Manage ${def.feature.name}` : "Not found" };
}

// cmeprojects: what managers may change on a feature, as the system admin
// allowed in the Feature builder: fix entries, client targets, drop-down options.
export default async function ManageFeaturePage({ params }: PageProps<"/f/[slug]/manage">) {
  const { profile } = await requireSession();
  const def = await loadFeature({ slug: (await params).slug });
  if (!def || def.feature.status !== "published" || !def.feature.enabled) notFound();
  const { feature, fields } = def;
  const supabase = await createClient();
  const can = (what: string) => supabase.rpc("can_manage_feature", { p_feature: feature.id, p_what: what });
  const [{ data: fix }, { data: targets }, { data: options }] = await Promise.all([can("fix"), can("targets"), can("options")]);
  if (!fix && !targets && !options) notFound();

  const since = daysAgo(31);
  const [ctx, { data: rows }] = await Promise.all([
    formContext(feature.id, profile.id),
    fix
      ? supabase
          .from("custom_entries")
          .select("id, created_at, created_by, client_name, data, corrected_at, correction_reason")
          .eq("feature_id", feature.id)
          .gte("created_at", since)
          .order("created_at", { ascending: false })
          .limit(200)
      : Promise.resolve({ data: [] as never[] }),
  ]);
  const ids = [...new Set((rows ?? []).map((r) => r.created_by))];
  const { data: people } = ids.length ? await supabase.from("profiles").select("id, full_name, email").in("id", ids) : { data: [] };
  const name = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const entries: ManageEntry[] = (rows ?? []).map((r) => ({
    id: Number(r.id),
    created_at: r.created_at,
    by: name.get(r.created_by) ?? "",
    client_name: r.client_name,
    data: r.data as Record<string, unknown>,
    corrected_at: r.corrected_at,
    correction_reason: r.correction_reason,
  }));
  const total = fields.find((f) => f.id === feature.total_field);

  return (
    <div className="flex w-full max-w-3xl flex-col gap-4">
      <LiveRefresh tables={["custom_entries", "custom_fields"]} />
      <div>
        <p className="text-xs text-muted">
          <Link href={`/f/${feature.slug}`} className="underline">
            {feature.name}
          </Link>{" "}
          › Manage
        </p>
        <h1 className="heading">Manage {feature.name}</h1>
      </div>
      <Manage
        feature={feature}
        fields={fields.filter((f) => !f.archived)}
        ctx={ctx}
        entries={entries}
        can={{ fix: Boolean(fix), targets: Boolean(targets) && Boolean(total && feature.group_field), options: Boolean(options) }}
      />
    </div>
  );
}

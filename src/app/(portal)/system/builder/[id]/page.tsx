// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formContext, loadFeature } from "@/lib/custom-features";
import { SectionTabs } from "@/components/section-tabs";
import { Builder } from "./builder";
import type { AlertDraft } from "../actions";

export const metadata: Metadata = { title: "Feature builder" };

export default async function BuildFeaturePage({ params }: PageProps<"/system/builder/[id]">) {
  const { profile } = await requireRole(["system_admin"]);
  const def = await loadFeature({ id: (await params).id });
  if (!def) notFound();
  const supabase = await createClient();
  const [ctx, { data: entries, count }, { data: alerts }] = await Promise.all([
    formContext(def.feature.id, profile.id),
    supabase.from("custom_entries").select("data", { count: "exact" }).eq("feature_id", def.feature.id).order("created_at", { ascending: false }).limit(2000),
    supabase.from("custom_alerts").select("*").eq("feature_id", def.feature.id).order("created_at"),
  ]);
  // Answers staff typed themselves in drop-downs (not in the list), most used first.
  const typed: Record<string, [string, number][]> = {};
  for (const f of def.fields.filter((x) => x.type === "choice" && x.allow_other)) {
    const n = new Map<string, number>();
    for (const e of entries ?? []) {
      const v = (e.data as Record<string, unknown>)[f.id];
      if (typeof v === "string" && v && !f.options.includes(v)) n.set(v, (n.get(v) ?? 0) + 1);
    }
    typed[f.id] = [...n.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12);
  }

  return (
    <>
      <SectionTabs section="settings" current="/system/builder" />
      <Builder
        key={def.feature.id}
        feature={def.feature}
        fields={def.fields.filter((f) => !f.archived)}
        ctx={ctx}
        typed={typed}
        entryCount={count ?? 0}
        alerts={((alerts ?? []) as AlertDraft[]).map((a) => ({ ...a, at_hour: a.at_hour ?? null, limit_value: a.limit_value == null ? null : Number(a.limit_value) }))}
      />
    </>
  );
}

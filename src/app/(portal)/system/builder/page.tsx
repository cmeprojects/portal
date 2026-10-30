// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Badge, Card, PageHeader } from "@/components/ui";
import { SectionTabs } from "@/components/section-tabs";
import { NewFeatureForm, IncludedSwitch } from "./forms";

export const metadata: Metadata = { title: "Feature builder" };

// cmeprojects: the system admin builds features (forms staff fill in, with
// their own menu item and report) and chooses which are in the package.
export default async function BuilderPage() {
  await requireRole(["system_admin"]);
  const supabase = await createClient();
  const [{ data: features }, { data: counts }] = await Promise.all([
    supabase.from("custom_features").select("id, slug, name, status, enabled, updated_at").order("sort_order").order("name"),
    supabase.from("custom_entries").select("feature_id"),
  ]);
  const entries = (id: string) => (counts ?? []).filter((c) => c.feature_id === id).length;

  return (
    <>
      <SectionTabs section="settings" current="/system/builder" />
      <PageHeader
        title="Feature builder"
        intro="Build your own features: a form staff fill in from the menu or their phone, with the date, time and their name recorded, and its own report. Only you can build them."
      />
      <Card className="p-5">
        <h2 className="mb-3 heading-sm">New feature</h2>
        <NewFeatureForm />
      </Card>
      {(features ?? []).length ? (
        <Card className="overflow-hidden">
          <h2 className="heading-sm border-b border-line px-5 py-3">Your features</h2>
          <ul className="divide-y divide-line">
            {(features ?? []).map((f) => (
              <li key={f.id} className="flex flex-wrap items-center gap-3 px-5 py-3">
                <span className="min-w-48 flex-1">
                  <Link href={`/system/builder/${f.id}`} className="font-semibold text-brand hover:underline">
                    {f.name}
                  </Link>
                  <span className="block text-xs text-muted">
                    {entries(f.id).toLocaleString("en-AU")} {entries(f.id) === 1 ? "entry" : "entries"} · /f/{f.slug}
                  </span>
                </span>
                <Badge tone="soft">Premium</Badge>
                {f.status === "published" ? <Badge tone="good">Live</Badge> : <Badge tone="grey">Draft</Badge>}
                {f.status === "published" ? <IncludedSwitch id={f.id} enabled={f.enabled} /> : <span className="text-xs text-muted">Publish to switch on</span>}
                <Link href={`/system/builder/${f.id}`} className="text-sm font-semibold text-brand underline">
                  Edit
                </Link>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}
    </>
  );
}

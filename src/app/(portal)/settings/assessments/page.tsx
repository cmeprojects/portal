// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ClipboardCheck } from "lucide-react";
import { requireSession } from "@/lib/session";
import { managesPrograms } from "@/lib/programs-access";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader } from "@/components/ui";
import { NewTemplateForm } from "./template-forms";

export const metadata: Metadata = { title: "Assessment templates" };

// cmeprojects (update 159): assessment templates, with versions. Manager
// Administrators and the care settings area (the database checks too).
export default async function AssessmentTemplatesPage() {
  await requireSession();
  if (!(await managesPrograms())) notFound();
  const supabase = await createClient();
  const [tplRes, verRes, schemeRes] = await Promise.all([
    supabase.from("assessment_templates").select("id, name, description, schemes, active").order("name"),
    supabase.from("assessment_versions").select("id, template_id, version, status, effective_from").order("version", { ascending: false }),
    supabase.from("client_schemes").select("key, label").order("sort_order"),
  ]);
  if (tplRes.error) {
    return (
      <Card className="p-5 text-sm text-muted">Assessment templates aren&apos;t set up yet (update 159).</Card>
    );
  }
  const templates = (tplRes.data ?? []) as { id: string; name: string; description: string; schemes: string[]; active: boolean }[];
  const versions = (verRes.data ?? []) as { id: string; template_id: string; version: number; status: string; effective_from: string | null }[];
  const schemes = ((schemeRes.data ?? []) as { key: string; label: string }[]).map((s) => [s.key, s.label] as [string, string]);
  const schemeLabel = (k: string) => schemes.find(([x]) => x === k)?.[1] ?? k;
  const day = (v: string | null) => (v ? v.split("-").reverse().join("/") : "");
  return (
    <div className="flex flex-col gap-4">
      <PageHeader
        eyebrow="Portal settings"
        title="Assessment templates"
        intro="Templates for client assessments: sections, questions, questions that only show when needed, and the findings answers make. A published version never changes; changes go into a new version, and completed assessments keep the version they used."
        action={
          <Link href="/settings" className="text-sm font-semibold text-brand underline">
            Back to settings
          </Link>
        }
      />
      <Card className="overflow-hidden">
        {templates.length === 0 ? (
          <EmptyState icon={ClipboardCheck} title="No assessment templates yet" text="Make one below." />
        ) : (
          <ul className="divide-y divide-line">
            {templates.map((t) => {
              const mine = versions.filter((v) => v.template_id === t.id);
              const live = mine.find((v) => v.status === "published");
              const draft = mine.find((v) => v.status === "draft");
              return (
                <li key={t.id} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3 text-sm">
                  <span className="min-w-56 flex-1">
                    <Link href={`/settings/assessments/${t.id}`} className="font-semibold hover:text-brand hover:underline">
                      {t.name}
                    </Link>
                    {!t.active ? <span className="ml-2 rounded-full bg-page px-2 py-0.5 text-xs text-muted ring-1 ring-line">Not in use</span> : null}
                    <span className="block text-xs text-muted">{t.schemes.length ? t.schemes.map(schemeLabel).join(", ") : "All programs"}</span>
                  </span>
                  <span className="text-xs text-muted">
                    {live ? `v${live.version} published${live.effective_from ? ` from ${day(live.effective_from)}` : ""}` : "Not published yet"}
                    {draft ? ` · v${draft.version} draft` : ""}
                  </span>
                  <Link href={`/settings/assessments/${t.id}`} className="rounded-lg border border-line px-3 py-1.5 text-xs font-semibold hover:bg-page">
                    {draft ? "Edit draft" : "Open"}
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </Card>
      <Card className="p-4">
        <h2 className="heading-sm mb-2">New template</h2>
        <NewTemplateForm schemes={schemes} />
      </Card>
    </div>
  );
}

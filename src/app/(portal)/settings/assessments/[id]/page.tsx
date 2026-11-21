// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { managesPrograms } from "@/lib/programs-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import type { AQuestion, ASection } from "@/lib/assessment-rules";
import { TemplateDetailsForm, TemplateEditor, VersionActions } from "../template-forms";
import { VersionHistory, WhatChanged, whatChanged, type VersionRow } from "../version-history";

export const metadata: Metadata = { title: "Assessment template" };

// cmeprojects (update 159): one template. The draft version can be edited;
// published and retired versions are shown as they are (they never change).
export default async function AssessmentTemplatePage({ params, searchParams }: PageProps<"/settings/assessments/[id]">) {
  await requireSession();
  if (!(await managesPrograms())) notFound();
  const { id } = await params;
  const sp = await searchParams;
  const supabase = await createClient();
  const [{ data: tpl }, { data: verRows }, { data: schemeRows }] = await Promise.all([
    supabase.from("assessment_templates").select("id, name, description, schemes, active").eq("id", id).maybeSingle(),
    supabase.from("assessment_versions").select("id, version, status, effective_from, published_at, created_by, created_at, published_by").eq("template_id", id).order("version", { ascending: false }),
    supabase.from("client_schemes").select("key, label").order("sort_order"),
  ]);
  if (!tpl) notFound();
  const t = tpl as { id: string; name: string; description: string; schemes: string[]; active: boolean };
  const versions = (verRows ?? []) as VersionRow[];
  const wanted = typeof sp.v === "string" ? versions.find((v) => String(v.version) === sp.v) : undefined;
  const shown = wanted ?? versions.find((v) => v.status === "draft") ?? versions.find((v) => v.status === "published") ?? versions[0];
  const [{ data: secRows }, { data: qRows }] = shown
    ? await Promise.all([
        supabase.from("assessment_sections").select("id, title, sort_order, enabled, rule").eq("version_id", shown.id).order("sort_order"),
        supabase.from("assessment_questions").select("id, section_id, key, label, type, required, help, options, validation, rule, mappings, sort_order").eq("version_id", shown.id).order("sort_order"),
      ])
    : [{ data: [] }, { data: [] }];
  // cmeprojects (update 160): version history and what changed from the version before.
  const prevVer = shown ? versions.find((v) => v.version === shown.version - 1) : undefined;
  const people = [...new Set(versions.flatMap((v) => [v.created_by, v.published_by]).filter((x): x is string => !!x))];
  const [{ data: prevSec }, { data: prevQ }, { data: useRows }, { data: nameRows }] = await Promise.all([
    prevVer ? supabase.from("assessment_sections").select("id, title, sort_order, enabled, rule").eq("version_id", prevVer.id) : Promise.resolve({ data: [] }),
    prevVer ? supabase.from("assessment_questions").select("id, section_id, key, label, type, required, help, options, validation, rule, mappings, sort_order").eq("version_id", prevVer.id) : Promise.resolve({ data: [] }),
    supabase.from("client_assessments").select("version_id").eq("template_id", id).neq("status", "cancelled"),
    people.length ? supabase.from("profiles").select("id, full_name, email").in("id", people) : Promise.resolve({ data: [] }),
  ]);
  const uses = new Map<string, number>();
  for (const r of (useRows ?? []) as { version_id: string }[]) uses.set(r.version_id, (uses.get(r.version_id) ?? 0) + 1);
  const names = new Map(((nameRows ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const changes = shown && prevVer ? whatChanged((prevSec ?? []) as ASection[], (prevQ ?? []) as AQuestion[], (secRows ?? []) as ASection[], (qRows ?? []) as AQuestion[]) : null;
  const schemes = ((schemeRows ?? []) as { key: string; label: string }[]).map((s) => [s.key, s.label] as [string, string]);
  const day = (v: string | null) => (v ? v.split("-").reverse().join("/") : "");
  return (
    <div className="flex flex-col gap-4">
      <PageHeader
        eyebrow="Assessment templates"
        title={t.name}
        action={
          <Link href="/settings/assessments" className="text-sm font-semibold text-brand underline">
            All templates
          </Link>
        }
      />
      <Card className="p-4">
        <TemplateDetailsForm template={t} schemes={schemes} />
      </Card>
      <Card className="p-4">
        <div className="mb-3 flex flex-wrap items-center gap-2">
          <h2 className="heading-sm flex-1">Versions</h2>
          <VersionActions templateId={t.id} hasDraft={versions.some((v) => v.status === "draft")} published={versions.find((v) => v.status === "published")?.id ?? null} />
        </div>
        <nav aria-label="Versions" className="flex flex-wrap gap-1.5">
          {versions.map((v) => (
            <Link
              key={v.id}
              href={`/settings/assessments/${t.id}?v=${v.version}`}
              aria-current={shown?.id === v.id ? "page" : undefined}
              className={`rounded-full px-3 py-1 text-xs font-semibold ring-1 ${shown?.id === v.id ? "bg-brand text-brand-fg ring-brand" : "bg-surface text-muted ring-line hover:text-ink"}`}
            >
              v{v.version} · {v.status === "draft" ? "Draft" : v.status === "published" ? `Published${v.effective_from ? ` from ${day(v.effective_from)}` : ""}` : "Retired"}
            </Link>
          ))}
        </nav>
        <details className="mt-3">
          <summary className="cursor-pointer text-sm font-semibold text-brand">Version history</summary>
          <div className="mt-2">
            <VersionHistory templateId={t.id} versions={versions} names={names} uses={uses} shownId={shown?.id} />
            <p className="mt-1 text-xs text-muted">Each completed assessment keeps the exact version it used. Published versions never change; a new version is a copy.</p>
          </div>
        </details>
        {changes && prevVer && shown ? (
          <div className="mt-3 rounded-md border border-line p-3">
            <WhatChanged from={prevVer.version} to={shown.version} changes={changes} />
          </div>
        ) : null}
      </Card>
      {shown ? (
        <TemplateEditor
          templateId={t.id}
          version={shown}
          sections={(secRows ?? []) as ASection[]}
          questions={(qRows ?? []) as AQuestion[]}
        />
      ) : null}
    </div>
  );
}

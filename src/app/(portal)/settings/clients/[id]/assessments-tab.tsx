// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import Link from "next/link";
import { ClipboardList } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState } from "@/components/ui";
import { StartAssessmentForm } from "./start-assessment";

// cmeprojects (update 159): the client's assessments (Assessments tab).
export async function AssessmentsTab({ clientId, canEdit }: { clientId: string; canEdit: boolean }) {
  const supabase = await createClient();
  const [aRes, { data: tRows }, { data: vRows }, { data: eRows }, { data: pRows }] = await Promise.all([
    supabase.from("client_assessments").select("id, template_id, enrolment_id, status, assessed_on, completed_at, created_at, assessment_templates(name), assessment_versions(version)").eq("client_id", clientId).order("created_at", { ascending: false }),
    supabase.from("assessment_templates").select("id, name, schemes, active").eq("active", true).order("name"),
    supabase.from("assessment_versions").select("template_id").eq("status", "published"),
    supabase.from("client_enrolments").select("id, program_id, scheme, status").eq("client_id", clientId).neq("status", "ended"),
    supabase.from("client_programs").select("id, name"),
  ]);
  if (aRes.error) return <Card className="p-5 text-sm text-muted">Assessments aren&apos;t set up yet (update 159).</Card>;
  type Row = { id: string; template_id: string; enrolment_id: string | null; status: string; assessed_on: string; completed_at: string | null; assessment_templates: { name: string } | null; assessment_versions: { version: number } | null };
  const rows = (aRes.data ?? []) as unknown as Row[];
  const progName = new Map(((pRows ?? []) as { id: string; name: string }[]).map((p) => [p.id, p.name]));
  const enrolments = ((eRows ?? []) as { id: string; program_id: string; scheme: string; status: string }[]).map((e) => ({ id: e.id, scheme: e.scheme, name: progName.get(e.program_id) ?? "Program", paused: e.status === "paused" }));
  const published = new Set(((vRows ?? []) as { template_id: string }[]).map((v) => v.template_id));
  const templates = ((tRows ?? []) as { id: string; name: string; schemes: string[] }[]).filter((t) => published.has(t.id) && (!t.schemes.length || enrolments.some((e) => t.schemes.includes(e.scheme))));
  const latestCompleted = rows.find((r) => r.status === "completed");
  const current = rows.filter((r) => r.status === "draft" || r.status === "completed");
  const older = rows.filter((r) => r.status === "superseded" || r.status === "cancelled");
  const day = (v: string) => v.split("-").reverse().join("/");
  const line = (r: Row) => (
    <li key={r.id} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-4 py-3 text-sm">
      <span className="min-w-56 flex-1">
        <span className="font-semibold">
          {r.assessment_templates?.name ?? "Assessment"} <span className="font-normal text-muted">v{r.assessment_versions?.version}</span>
        </span>
        <span className="block text-xs text-muted">
          {r.enrolment_id ? (enrolments.find((e) => e.id === r.enrolment_id)?.name ?? "Program") : "All programs"} · assessed {day(r.assessed_on)}
        </span>
      </span>
      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${r.status === "draft" ? "bg-warn-soft text-warn" : r.status === "completed" ? "bg-good-soft text-good" : "bg-page text-muted ring-1 ring-line"}`}>
        {{ draft: "Draft", completed: "Completed", superseded: "Superseded", cancelled: "Cancelled" }[r.status] ?? r.status}
      </span>
      <Link href={`/settings/clients/${clientId}/assessments/${r.id}`} className="rounded-lg border border-line px-3 py-1.5 text-xs font-semibold hover:bg-page">
        {r.status === "draft" && canEdit ? "Continue" : "View"}
      </Link>
    </li>
  );
  return (
    <section id="assessments" className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        <ClipboardList aria-hidden="true" className="size-5 text-brand" />
        <h2 className="heading-sm flex-1">Assessments</h2>
      </div>
      {canEdit ? (
        <StartAssessmentForm
          clientId={clientId}
          templates={templates.map((t) => ({ id: t.id, name: t.name, schemes: t.schemes }))}
          enrolments={enrolments}
          latest={latestCompleted ? { id: latestCompleted.id, label: `${latestCompleted.assessment_templates?.name ?? "assessment"} of ${day(latestCompleted.assessed_on)}`, templateId: latestCompleted.template_id } : null}
        />
      ) : null}
      <Card className="overflow-hidden">
        {current.length === 0 ? <EmptyState icon={ClipboardList} title="No assessments yet" text={canEdit ? "Start one above." : "None recorded."} /> : <ul className="divide-y divide-line">{current.map(line)}</ul>}
      </Card>
      {older.length ? (
        <details className="rounded-xl border border-line bg-surface">
          <summary className="cursor-pointer px-4 py-2 text-sm font-semibold text-muted">Superseded and cancelled ({older.length})</summary>
          <ul className="divide-y divide-line border-t border-line">{older.map(line)}</ul>
        </details>
      ) : null}
    </section>
  );
}

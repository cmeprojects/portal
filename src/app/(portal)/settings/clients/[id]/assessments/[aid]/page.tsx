// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { requireSession } from "@/lib/session";
import { canDoFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui";
import type { AQuestion, ASection, Answers } from "@/lib/assessment-rules";
import type { Reused } from "@/components/assessment-form";
import { AssessmentFill, type Finding } from "./assessment-fill";

export const metadata: Metadata = { title: "Assessment" };

// cmeprojects (update 159): one client assessment. The database decides who
// may see and change it; opening it is recorded (once an hour per person).
export default async function AssessmentPage({ params }: PageProps<"/settings/clients/[id]/assessments/[aid]">) {
  await requireSession();
  const { id: clientId, aid } = await params;
  const supabase = await createClient();
  const { data: a } = await supabase
    .from("client_assessments")
    .select("id, client_id, enrolment_id, template_id, version_id, status, assessed_on, answers, reused, replaces_id, replaced_by, completed_at, cancel_reason, updated_at, assessment_templates(name), assessment_versions(version)")
    .eq("id", aid)
    .eq("client_id", clientId)
    .maybeSingle();
  if (!a) notFound();
  const row = a as unknown as {
    id: string; client_id: string; enrolment_id: string | null; template_id: string; version_id: string; status: "draft" | "completed" | "superseded" | "cancelled"; assessed_on: string;
    answers: Answers; reused: Reused; replaces_id: string | null; replaced_by: string | null; completed_at: string | null; cancel_reason: string; updated_at: string;
    assessment_templates: { name: string } | null; assessment_versions: { version: number } | null;
  };
  await supabase.from("client_staff_views").insert({ client_id: clientId, area: "assessment" });
  const fromIds = [...new Set(Object.values(row.reused ?? {}).map((r) => r.from))];
  const [{ data: client }, { data: secRows }, { data: qRows }, { data: fRows }, { data: fromRows }, canEdit] = await Promise.all([
    supabase.from("car_clients").select("name").eq("id", clientId).maybeSingle(),
    supabase.from("assessment_sections").select("id, title, sort_order, enabled, rule").eq("version_id", row.version_id).order("sort_order"),
    supabase.from("assessment_questions").select("id, section_id, key, label, type, required, help, options, validation, rule, mappings, sort_order").eq("version_id", row.version_id).order("sort_order"),
    supabase.from("assessment_findings").select("id, kind, text, detail, origin, source_key, source_answer, state, edited").eq("assessment_id", aid).order("created_at"),
    fromIds.length ? supabase.from("client_assessments").select("id, completed_at, assessment_templates(name)").in("id", fromIds) : Promise.resolve({ data: [] }),
    canDoFor("clients.assessments", "edit", clientId),
  ]);
  const day = (v: string | null) => (v ? new Date(v).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric" }) : "");
  const reusedFrom = Object.fromEntries(((fromRows ?? []) as unknown as { id: string; completed_at: string | null; assessment_templates: { name: string } | null }[]).map((r) => [r.id, `${r.assessment_templates?.name ?? "assessment"} of ${day(r.completed_at)}`]));
  const statusWord = { draft: "Draft", completed: `Completed ${day(row.completed_at)}`, superseded: "Superseded (a newer assessment replaced it)", cancelled: `Cancelled: ${row.cancel_reason}` }[row.status];
  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm print:hidden">
        <Link href={`/settings/clients/${clientId}?tab=assessments`} className="inline-flex items-center gap-1 font-semibold text-brand hover:underline">
          <ArrowLeft aria-hidden="true" className="size-4" /> {(client as { name?: string } | null)?.name ?? "Client"}: assessments
        </Link>
      </p>
      <PageHeader
        eyebrow={`${(client as { name?: string } | null)?.name ?? ""} · assessment`}
        title={`${row.assessment_templates?.name ?? "Assessment"} (v${row.assessment_versions?.version ?? "?"})`}
        intro={`${statusWord}. Assessed on ${row.assessed_on.split("-").reverse().join("/")}.`}
      />
      {row.status === "superseded" && row.replaced_by ? (
        <p className="text-sm print:hidden">
          <Link href={`/settings/clients/${clientId}/assessments/${row.replaced_by}`} className="font-semibold text-brand underline">
            Open the assessment that replaced it
          </Link>
        </p>
      ) : null}
      <AssessmentFill
        id={row.id}
        clientId={clientId}
        templateId={row.template_id}
        enrolmentId={row.enrolment_id}
        status={row.status}
        canEdit={canEdit}
        sections={(secRows ?? []) as ASection[]}
        questions={(qRows ?? []) as AQuestion[]}
        answers={row.answers ?? {}}
        reused={row.reused ?? {}}
        reusedFrom={reusedFrom}
        updatedAt={row.updated_at}
        findings={(fRows ?? []) as Finding[]}
      />
    </div>
  );
}

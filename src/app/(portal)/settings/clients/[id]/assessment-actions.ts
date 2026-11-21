// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { logDownload } from "@/lib/download-log";
import type { FormState } from "@/lib/form";
import { FINDING_KINDS, type Answers } from "@/lib/assessment-rules";

// cmeprojects (update 159): client assessments. The database checks who may,
// the version, every answer, completion and findings; these actions add the
// friendly messages and the "someone else saved first" check.
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const page = (clientId: string, id?: string) => {
  revalidatePath(`/settings/clients/${clientId}`);
  if (id) revalidatePath(`/settings/clients/${clientId}/assessments/${id}`);
};

type Q = { key: string; type: string; options: string[] };

export async function startAssessment(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const clientId = String(form.get("client_id") ?? "");
  const templateId = String(form.get("template_id") ?? "");
  const enrolmentId = String(form.get("enrolment_id") ?? "");
  const fromId = String(form.get("from_id") ?? "");
  const replaces = form.get("replaces") === "on";
  if (!isId(clientId) || !isId(templateId)) return { error: "Choose an assessment." };
  const supabase = await createClient();
  const { data: ver } = await supabase.from("assessment_versions").select("id").eq("template_id", templateId).eq("status", "published").maybeSingle();
  if (!ver) return { error: "That assessment isn't published yet." };
  const { data: newQs } = await supabase.from("assessment_questions").select("key, type, options").eq("version_id", ver.id);
  // Reuse: same key and same kind of answer, and (for choices) still one of the options.
  const answers: Answers = {};
  const reused: Record<string, { from: string; confirmed: boolean }> = {};
  if (isId(fromId)) {
    const { data: prev } = await supabase.from("client_assessments").select("id, version_id, answers, client_id, status").eq("id", fromId).maybeSingle();
    if (prev && prev.client_id === clientId && ["completed", "superseded"].includes(prev.status)) {
      const { data: oldQs } = await supabase.from("assessment_questions").select("key, type, options").eq("version_id", prev.version_id);
      const oldType = new Map(((oldQs ?? []) as Q[]).map((q) => [q.key, q.type]));
      for (const q of (newQs ?? []) as Q[]) {
        const a = (prev.answers as Answers)[q.key];
        if (a === undefined || a === "" || oldType.get(q.key) !== q.type) continue;
        if (q.type === "choice" && !q.options.includes(String(a))) continue;
        if (q.type === "multi" && (!Array.isArray(a) || a.some((x) => !q.options.includes(x)))) continue;
        answers[q.key] = a;
        reused[q.key] = { from: prev.id, confirmed: false };
      }
    }
  }
  const { data, error } = await supabase
    .from("client_assessments")
    .insert({ client_id: clientId, template_id: templateId, version_id: ver.id, enrolment_id: isId(enrolmentId) ? enrolmentId : null, answers, reused, replaces_id: replaces && isId(fromId) ? fromId : null })
    .select("id")
    .single();
  if (error || !data) return { error: friendlyError(error) };
  page(clientId);
  redirect(`/settings/clients/${clientId}/assessments/${data.id}`);
}

export type SaveResult = { error?: string; updatedAt?: string; stale?: boolean };

// Save the answers (and confirmations) if nobody else saved since this person loaded them.
export async function saveAssessment(id: string, answers: Answers, confirmed: string[], expectedUpdatedAt: string): Promise<SaveResult> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data: now } = await supabase.from("client_assessments").select("client_id, reused, updated_at, status").eq("id", id).maybeSingle();
  if (!now) return { error: "You can't see this assessment." };
  if (now.status !== "draft") return { error: "This assessment isn't a draft any more.", stale: true };
  if (now.updated_at !== expectedUpdatedAt) return { error: "Changed by someone else. Reload to see their changes.", stale: true };
  const reused = { ...(now.reused as Record<string, { from: string; confirmed: boolean }>) };
  for (const k of confirmed) if (reused[k]) reused[k] = { ...reused[k], confirmed: true };
  const { data, error } = await supabase.from("client_assessments").update({ answers, reused }).eq("id", id).eq("updated_at", expectedUpdatedAt).select("updated_at");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Changed by someone else. Reload to see their changes.", stale: true };
  page(now.client_id as string, id);
  return { updatedAt: (data[0] as { updated_at: string }).updated_at };
}

export async function completeAssessment(id: string, expectedUpdatedAt: string): Promise<SaveResult> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("client_assessments").update({ status: "completed" }).eq("id", id).eq("status", "draft").eq("updated_at", expectedUpdatedAt).select("client_id, updated_at");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Changed by someone else. Reload to see their changes.", stale: true };
  page((data[0] as { client_id: string }).client_id, id);
  return { updatedAt: (data[0] as { updated_at: string }).updated_at };
}

export async function cancelAssessment(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("id") ?? "");
  const reason = String(form.get("cancel_reason") ?? "").trim().slice(0, 300);
  if (!isId(id)) return { error: "Something went wrong." };
  if (!reason) return { error: "Say why this assessment is cancelled." };
  const { data, error } = await (await createClient()).from("client_assessments").update({ status: "cancelled", cancel_reason: reason }).eq("id", id).eq("status", "draft").select("client_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a draft can be cancelled." };
  page((data[0] as { client_id: string }).client_id, id);
  return { message: "Assessment cancelled. It's kept with the client's records." };
}

export async function addFinding(assessmentId: string, kind: string, text: string, detail: string): Promise<FormState> {
  await requireSession();
  if (!isId(assessmentId)) return { error: "Something went wrong." };
  if (!FINDING_KINDS.some(([k]) => k === kind)) return { error: "Choose the kind of finding." };
  if (!text.trim()) return { error: "Write the finding." };
  const supabase = await createClient();
  const { data: a } = await supabase.from("client_assessments").select("client_id").eq("id", assessmentId).maybeSingle();
  if (!a) return { error: "You can't see this assessment." };
  const { error } = await supabase.from("assessment_findings").insert({ assessment_id: assessmentId, client_id: a.client_id, kind, text: text.trim().slice(0, 1000), detail: detail.trim().slice(0, 2000) });
  if (error) return { error: friendlyError(error) };
  page(a.client_id as string, assessmentId);
  return { message: "Finding added." };
}

export async function updateFinding(id: string, patch: { kind?: string; text?: string; detail?: string; state?: "active" | "withdrawn" }): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  if (patch.kind && !FINDING_KINDS.some(([k]) => k === patch.kind)) return { error: "Choose the kind of finding." };
  if (patch.text !== undefined && !patch.text.trim()) return { error: "Write the finding." };
  const row: Record<string, string> = {};
  if (patch.kind) row.kind = patch.kind;
  if (patch.text !== undefined) row.text = patch.text.trim().slice(0, 1000);
  if (patch.detail !== undefined) row.detail = patch.detail.trim().slice(0, 2000);
  if (patch.state) row.state = patch.state;
  const { data, error } = await (await createClient()).from("assessment_findings").update(row).eq("id", id).select("client_id, assessment_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this finding." };
  const f = data[0] as { client_id: string; assessment_id: string };
  page(f.client_id, f.assessment_id);
  return { message: "Finding saved." };
}

// Printing is recorded every time (owner's decision D).
export async function recordAssessmentPrint(id: string): Promise<void> {
  await requireSession();
  if (!isId(id)) return;
  const supabase = await createClient();
  const { data } = await supabase.from("client_assessments").select("client_id, assessment_templates(name)").eq("id", id).maybeSingle();
  if (!data) return;
  const name = (data as unknown as { assessment_templates: { name: string } | null }).assessment_templates?.name ?? "Assessment";
  await logDownload({ kind: "record", action: "print", label: `Printed assessment: ${name}`, clientId: data.client_id as string, details: { assessment: id } });
}

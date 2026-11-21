// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { managesPrograms } from "@/lib/programs-access";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { ATYPES, FINDING_KINDS, OPS, type Mapping, type Rule } from "@/lib/assessment-rules";

// cmeprojects (update 159): assessment templates. Manager Administrators and
// the care settings area make and change drafts and publish them; a published
// version never changes (the database refuses it), so changes go into a new version.
async function requireTemplates() {
  await requireSession();
  if (!(await managesPrograms())) throw new Error("You can't change assessment templates.");
}
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const SCHEMES = ["ndis", "support_at_home", "chsp", "private", "other"];
function done(templateId?: string) {
  revalidatePath("/settings/assessments");
  if (templateId) revalidatePath(`/settings/assessments/${templateId}`);
}

export async function createTemplate(_: FormState, form: FormData): Promise<FormState> {
  await requireTemplates();
  const name = String(form.get("name") ?? "").trim().slice(0, 120);
  if (!name) return { error: "Give the template a name." };
  const schemes = form.getAll("schemes").map(String).filter((s) => SCHEMES.includes(s));
  const supabase = await createClient();
  const { data: t, error } = await supabase.from("assessment_templates").insert({ name, description: String(form.get("description") ?? "").trim().slice(0, 1000), schemes }).select("id").single();
  if (error || !t) return { error: friendlyError(error) };
  const { data: v, error: vErr } = await supabase.from("assessment_versions").insert({ template_id: t.id }).select("id").single();
  if (vErr || !v) return { error: friendlyError(vErr) };
  await supabase.from("assessment_sections").insert({ version_id: v.id, title: "Section 1", sort_order: 1 });
  done();
  redirect(`/settings/assessments/${t.id}`);
}

export async function saveTemplateDetails(_: FormState, form: FormData): Promise<FormState> {
  await requireTemplates();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "Something went wrong." };
  const name = String(form.get("name") ?? "").trim().slice(0, 120);
  if (!name) return { error: "Give the template a name." };
  const { data, error } = await (await createClient())
    .from("assessment_templates")
    .update({ name, description: String(form.get("description") ?? "").trim().slice(0, 1000), schemes: form.getAll("schemes").map(String).filter((s) => SCHEMES.includes(s)), active: form.get("active") === "on" })
    .eq("id", id)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this template." };
  done(id);
  return { message: "Saved." };
}

export async function saveSection(_: FormState, form: FormData): Promise<FormState> {
  await requireTemplates();
  const id = String(form.get("id") ?? "");
  const versionId = String(form.get("version_id") ?? "");
  const templateId = String(form.get("template_id") ?? "");
  const title = String(form.get("title") ?? "").trim().slice(0, 120);
  if (!title) return { error: "Give the section a title." };
  const rule = parseRule(String(form.get("rule") ?? ""));
  const row = { title, enabled: form.get("enabled") === "on", rule, sort_order: Number(form.get("sort_order")) || 0 };
  const supabase = await createClient();
  const { error } = isId(id) ? await supabase.from("assessment_sections").update(row).eq("id", id) : await supabase.from("assessment_sections").insert({ ...row, version_id: versionId });
  if (error) return { error: friendlyError(error) };
  done(templateId);
  return { message: "Section saved." };
}

export async function deleteDraftPart(table: "assessment_sections" | "assessment_questions", id: string, templateId: string): Promise<FormState> {
  await requireTemplates();
  if (!isId(id)) return { error: "Something went wrong." };
  const { error } = await (await createClient()).from(table).delete().eq("id", id);
  if (error) return { error: friendlyError(error) };
  done(templateId);
  return { message: "Removed from the draft." };
}

export async function moveQuestion(id: string, otherId: string, templateId: string): Promise<FormState> {
  await requireTemplates();
  if (!isId(id) || !isId(otherId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data } = await supabase.from("assessment_questions").select("id, sort_order").in("id", [id, otherId]);
  const rows = (data ?? []) as { id: string; sort_order: number }[];
  if (rows.length !== 2) return { error: "Something went wrong." };
  const [a, b] = rows;
  const e1 = await supabase.from("assessment_questions").update({ sort_order: b.sort_order }).eq("id", a.id);
  const e2 = await supabase.from("assessment_questions").update({ sort_order: a.sort_order }).eq("id", b.id);
  if (e1.error || e2.error) return { error: friendlyError(e1.error ?? e2.error) };
  done(templateId);
  return { message: "Moved." };
}

function parseRule(raw: string): Rule {
  if (!raw) return null;
  try {
    const r = JSON.parse(raw) as Rule;
    if (!r || !Array.isArray(r.when)) return null;
    const when = r.when.filter((c) => c && typeof c.q === "string" && OPS.some(([o]) => o === c.op)).slice(0, 10);
    return when.length ? { match: r.match === "any" ? "any" : "all", when } : null;
  } catch {
    return null;
  }
}
function parseMappings(raw: string): Mapping[] {
  try {
    const list = JSON.parse(raw || "[]") as Mapping[];
    return (Array.isArray(list) ? list : [])
      .filter((m) => m && FINDING_KINDS.some(([k]) => k === m.kind) && typeof m.text === "string" && m.text.trim())
      .map((m) => ({ kind: m.kind, text: m.text.trim().slice(0, 500), when: m.when && OPS.some(([o]) => o === m.when?.op) ? m.when : { op: "answered" as const } }))
      .slice(0, 10);
  } catch {
    return [];
  }
}

export async function saveQuestion(_: FormState, form: FormData): Promise<FormState> {
  await requireTemplates();
  const id = String(form.get("id") ?? "");
  const templateId = String(form.get("template_id") ?? "");
  const label = String(form.get("label") ?? "").trim().slice(0, 300);
  const key = String(form.get("key") ?? "").trim();
  const type = String(form.get("type") ?? "text");
  if (!label) return { error: "Write the question." };
  if (!/^[a-z][a-z0-9_]{0,59}$/.test(key)) return { error: "The question key uses lower-case letters, numbers and _ (for example lives_alone)." };
  if (!ATYPES.some(([t]) => t === type)) return { error: "Choose the kind of answer." };
  const options = String(form.get("options") ?? "")
    .split("\n")
    .map((o) => o.trim())
    .filter(Boolean)
    .slice(0, 30);
  if ((type === "choice" || type === "multi") && options.length < 2) return { error: "Add at least two options, one per line." };
  const validation: Record<string, number> = {};
  const min = String(form.get("min") ?? "").trim();
  const max = String(form.get("max") ?? "").trim();
  if (type === "number" && min !== "") validation.min = Number(min);
  if (type === "number" && max !== "") validation.max = Number(max);
  if (Object.values(validation).some((n) => !Number.isFinite(n))) return { error: "The lowest and highest must be numbers." };
  const row = {
    section_id: String(form.get("section_id") ?? ""),
    key,
    label,
    type,
    required: form.get("required") === "on",
    help: String(form.get("help") ?? "").trim().slice(0, 300),
    options: type === "choice" || type === "multi" ? options : [],
    validation,
    rule: parseRule(String(form.get("rule") ?? "")),
    mappings: parseMappings(String(form.get("mappings") ?? "")),
    sort_order: Number(form.get("sort_order")) || 0,
  };
  const supabase = await createClient();
  const { error } = isId(id)
    ? await supabase.from("assessment_questions").update(row).eq("id", id)
    : await supabase.from("assessment_questions").insert({ ...row, version_id: String(form.get("version_id") ?? "") });
  if (error) return { error: error.code === "23505" ? "Another question in this version already uses that key." : friendlyError(error) };
  done(templateId);
  return { message: "Question saved." };
}

export async function publishVersion(_: FormState, form: FormData): Promise<FormState> {
  await requireTemplates();
  const id = String(form.get("version_id") ?? "");
  const templateId = String(form.get("template_id") ?? "");
  const from = String(form.get("effective_from") ?? "");
  if (!isId(id)) return { error: "Something went wrong." };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(from)) return { error: "Choose the date it takes effect." };
  const { data, error } = await (await createClient()).from("assessment_versions").update({ status: "published", effective_from: from }).eq("id", id).eq("status", "draft").select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "This version isn't a draft any more. Reload the page." };
  done(templateId);
  return { message: "Published. New assessments use this version." };
}

export async function newVersion(templateId: string): Promise<FormState> {
  await requireTemplates();
  if (!isId(templateId)) return { error: "Something went wrong." };
  const { error } = await (await createClient()).rpc("assessment_new_version", { p_template: templateId });
  if (error) return { error: friendlyError(error) };
  done(templateId);
  return { message: "A new draft version was made from the latest one." };
}

export async function retireVersion(versionId: string, templateId: string): Promise<FormState> {
  await requireTemplates();
  if (!isId(versionId)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("assessment_versions").update({ status: "retired" }).eq("id", versionId).eq("status", "published").select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only the published version can be retired." };
  done(templateId);
  return { message: "Retired. It can't be used for new assessments; completed ones keep it." };
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 160): care plans, support plans and proposed budgets.
// The database decides who may do each step (approve right, not the maker or
// submitter), what can change at each status, and keeps every source link;
// these actions only shape the request and give friendly messages.
export type DocKind = "care" | "support" | "budget";
type Step = "submit" | "take_back" | "approve" | "changes" | "withdraw";

const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const TABLE: Record<DocKind, string> = { care: "client_care_plans", support: "client_support_plans", budget: "client_budget_proposals" };
const LINES: Record<DocKind, { table: string; parent: string }> = {
  care: { table: "client_care_plan_items", parent: "plan_id" },
  support: { table: "client_support_plan_lines", parent: "plan_id" },
  budget: { table: "client_budget_lines", parent: "proposal_id" },
};
const SECTIONS = ["need", "risk", "requirement", "intervention", "instruction", "monitoring", "preference"];
const refresh = (clientId: string) => revalidatePath(`/settings/clients/${clientId}`);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const num = (v: unknown, max: number): number | null | "bad" => {
  const s = String(v ?? "").trim();
  if (!s) return null;
  const n = Number(s);
  return Number.isFinite(n) && n >= 0 && n <= max ? Math.round(n * 100) / 100 : "bad";
};
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);

export async function generateCareDocuments(assessmentId: string): Promise<FormState & { clientId?: string }> {
  await requireSession();
  if (!isId(assessmentId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("generate_care_documents", { p_assessment: assessmentId });
  if (error) return { error: friendlyError(error) };
  const made = ((data as { made?: string[] } | null)?.made ?? []) as string[];
  const { data: a } = await supabase.from("client_assessments").select("client_id").eq("id", assessmentId).maybeSingle();
  if (a) {
    refresh(a.client_id as string);
    revalidatePath(`/settings/clients/${a.client_id}/assessments/${assessmentId}`);
  }
  return {
    message: made.length
      ? `Made a draft ${made.join(", ")}. Nothing is approved until someone reviews it.`
      : "Drafts from this assessment already exist; nothing was changed.",
    clientId: a?.client_id as string | undefined,
  };
}

export async function setDocStep(kind: DocKind, id: string, step: Step, note = ""): Promise<FormState> {
  await requireSession();
  if (!TABLE[kind] || !isId(id)) return { error: "Something went wrong." };
  const approved = kind === "care" ? "current" : "approved";
  const row: Record<string, string> =
    step === "submit" ? { status: "pending_review" }
    : step === "take_back" ? { status: "draft" }
    : step === "approve" ? { status: approved }
    : step === "changes" ? { status: "changes_required", review_note: clip(note, 1000) }
    : kind === "care" ? { status: "archived" } : { status: "" };
  if (!row.status) return { error: "Something went wrong." };
  if (step === "changes" && !row.review_note) return { error: "Say what needs changing." };
  const { data, error } = await (await createClient()).from(TABLE[kind]).update(row).eq("id", id).select("client_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't do that on this one." };
  refresh((data[0] as { client_id: string }).client_id);
  const done: Record<Step, string> = {
    submit: "Sent for review.",
    take_back: "Taken back to draft.",
    approve: "Approved. Any earlier approved one is now superseded (kept).",
    changes: "Sent back with what needs changing.",
    withdraw: "Withdrawn. It's kept with the client's records.",
  };
  return { message: done[step] };
}

// Lines and items: added, changed or removed only while their document is a draft or needs changes.
export async function saveDocLine(kind: DocKind, parentId: string, clientId: string, values: Record<string, string>, lineId?: string): Promise<FormState> {
  await requireSession();
  if (!LINES[kind] || !isId(parentId) || !isId(clientId) || (lineId && !isId(lineId))) return { error: "Something went wrong." };
  let row: Record<string, string | number | null>;
  if (kind === "care") {
    if (!SECTIONS.includes(values.section)) return { error: "Choose a section." };
    row = { section: values.section, text: clip(values.text, 1000), detail: clip(values.detail, 2000) };
    if (!row.text) return { error: "Write the item." };
  } else if (kind === "support") {
    const hours = num(values.hours_per_week, 168);
    if (hours === "bad") return { error: "Hours a week is a number from 0 to 168." };
    row = {
      support: clip(values.support, 500),
      frequency: clip(values.frequency, 200),
      hours_per_week: hours,
      delivery: clip(values.delivery, 1000),
      responsibilities: clip(values.responsibilities, 1000),
      instructions: clip(values.instructions, 2000),
      service_id: isId(values.service_id) ? values.service_id : null,
    };
    if (!row.support) return { error: "Say what the support is." };
  } else {
    const hours = num(values.hours_per_week, 168);
    const weeks = num(values.weeks, 104);
    const rate = num(values.estimated_rate, 10000);
    if (hours === "bad") return { error: "Hours a week is a number from 0 to 168." };
    if (weeks === "bad") return { error: "Weeks is a number from 0 to 104." };
    if (rate === "bad") return { error: "The estimated rate is an amount from $0 to $10,000 an hour." };
    row = { description: clip(values.description, 500), hours_per_week: hours, weeks, estimated_rate: rate, service_id: isId(values.service_id) ? values.service_id : null };
    if (!row.description) return { error: "Describe the line." };
  }
  const supabase = await createClient();
  const { table, parent } = LINES[kind];
  const { error } = lineId
    ? await supabase.from(table).update(row).eq("id", lineId)
    : await supabase.from(table).insert({ ...row, [parent]: parentId, client_id: clientId, sort_order: 1000 });
  if (error) return { error: friendlyError(error) };
  refresh(clientId);
  return { message: lineId ? "Saved." : "Added." };
}

export async function removeDocLine(kind: DocKind, lineId: string, clientId: string): Promise<FormState> {
  await requireSession();
  if (!LINES[kind] || !isId(lineId) || !isId(clientId)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from(LINES[kind].table).delete().eq("id", lineId).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only lines on a draft can be removed." };
  refresh(clientId);
  return { message: "Removed." };
}

// Support plan and budget headings (care plans keep their own form).
export async function saveDocHeader(kind: "support" | "budget", id: string, clientId: string, values: Record<string, string>): Promise<FormState> {
  await requireSession();
  if (!isId(id) || !isId(clientId)) return { error: "Something went wrong." };
  const title = clip(values.title, 120);
  if (!title) return { error: "Give it a title." };
  let row: Record<string, string | null>;
  if (kind === "support") {
    row = { title, summary: clip(values.summary, 4000), starts_on: ymd(values.starts_on), review_by: ymd(values.review_by) };
    if (row.starts_on && row.review_by && row.review_by < row.starts_on) return { error: "The review date is after the start date." };
  } else {
    const start = ymd(values.period_start);
    const end = ymd(values.period_end);
    if (!start || !end) return { error: "Give the budget period's start and end." };
    if (end < start) return { error: "The period ends after it starts." };
    row = { title, period_start: start, period_end: end, notes: clip(values.notes, 2000) };
  }
  const { data, error } = await (await createClient()).from(TABLE[kind]).update(row).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "It can only change while it's a draft or needs changes." };
  refresh(clientId);
  return { message: "Saved." };
}

// A support plan or proposed budget started by hand (not from an assessment).
export async function startDoc(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const kind = String(form.get("kind") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  const enrolmentId = String(form.get("enrolment_id") ?? "");
  const title = clip(form.get("title"), 120);
  if ((kind !== "support" && kind !== "budget") || !isId(clientId)) return { error: "Something went wrong." };
  if (!title) return { error: "Give it a title." };
  const row: Record<string, string | null> = { client_id: clientId, title, enrolment_id: isId(enrolmentId) ? enrolmentId : null };
  if (kind === "budget") {
    const start = ymd(form.get("period_start"));
    const end = ymd(form.get("period_end"));
    if (!start || !end) return { error: "Give the budget period's start and end." };
    if (end < start) return { error: "The period ends after it starts." };
    row.period_start = start;
    row.period_end = end;
    const sp = String(form.get("support_plan_id") ?? "");
    row.support_plan_id = isId(sp) ? sp : null;
  }
  const { error } = await (await createClient()).from(TABLE[kind as DocKind]).insert(row);
  if (error) return { error: friendlyError(error) };
  refresh(clientId);
  return { message: "Draft added." };
}

// Client or representative agreement, once the plan is approved.
export async function recordAgreement(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const clientId = String(form.get("client_id") ?? "");
  const kind = String(form.get("kind") ?? "");
  const planId = String(form.get("plan_id") ?? "");
  const who = String(form.get("who") ?? "");
  const method = String(form.get("method") ?? "");
  const agreedOn = ymd(form.get("agreed_on"));
  const documentId = String(form.get("document_id") ?? "");
  if (!isId(clientId) || !isId(planId) || (kind !== "care" && kind !== "support")) return { error: "Something went wrong." };
  if (!["signed", "written", "verbal"].includes(method)) return { error: "Choose how they agreed." };
  if (!agreedOn) return { error: "Give the date they agreed." };
  if (agreedOn > new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" })) return { error: "The date can't be in the future." };
  const supabase = await createClient();
  let agreedName = "";
  let personId: string | null = null;
  if (who === "client") {
    const { data: c } = await supabase.from("car_clients").select("name").eq("id", clientId).maybeSingle();
    agreedName = (c?.name as string) ?? "Client";
  } else if (isId(who)) {
    const { data: p } = await supabase.from("client_people").select("name").eq("id", who).eq("client_id", clientId).maybeSingle();
    if (!p) return { error: "Choose who agreed." };
    agreedName = p.name as string;
    personId = who;
  } else return { error: "Choose who agreed." };
  const { error } = await supabase.from("client_plan_agreements").insert({
    client_id: clientId,
    [kind === "care" ? "care_plan_id" : "support_plan_id"]: planId,
    agreed_by: personId ? "person" : "client",
    person_id: personId,
    agreed_name: agreedName,
    method,
    agreed_on: agreedOn,
    document_id: isId(documentId) ? documentId : null,
    notes: clip(form.get("notes"), 1000),
  });
  if (error) return { error: friendlyError(error) };
  refresh(clientId);
  return { message: "Agreement recorded." };
}

// An approved plan's instruction item becomes a worker instruction (once).
export async function addToWorkerInstructions(itemId: string, clientId: string, title: string): Promise<FormState> {
  await requireSession();
  if (!isId(itemId) || !isId(clientId)) return { error: "Something went wrong." };
  const heading = clip(title, 120);
  if (!heading) return { error: "Give the instruction a heading." };
  const supabase = await createClient();
  const { data: item } = await supabase.from("client_care_plan_items").select("text, detail").eq("id", itemId).maybeSingle();
  if (!item) return { error: "You can't see that item." };
  const text = [item.text, item.detail].filter(Boolean).join("\n").slice(0, 2000);
  const { error } = await supabase.from("client_worker_instructions").insert({ client_id: clientId, title: heading, instructions: text, source_item_id: itemId });
  if (error) return { error: error.code === "23505" ? "That item is already a worker instruction." : friendlyError(error) };
  refresh(clientId);
  return { message: "Added to worker instructions. Staff in the client's team now see it." };
}

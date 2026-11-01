// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import type { FormInfo, FormQuestion } from "@/lib/form-types";

// Forms (cmeprojects, premium).

export const formsOn = (features: Record<string, boolean>) => features.forms === true;

export const canMakeForms = cache(async (): Promise<boolean> => {
  const { data } = await (await createClient()).rpc("can_make_forms");
  return Boolean(data);
});

const asQuestion = (q: Record<string, unknown>): FormQuestion => ({
  ...(q as unknown as FormQuestion),
  options: Array.isArray(q.options) ? (q.options as string[]) : [],
});

export async function loadForm(id: string): Promise<{ form: FormInfo; questions: FormQuestion[] } | null> {
  if (!/^[0-9a-f-]{36}$/.test(id)) return null;
  const supabase = await createClient();
  const { data: form } = await supabase.from("forms").select("*").eq("id", id).maybeSingle();
  if (!form) return null;
  const { data: questions } = await supabase.from("form_questions").select("*").eq("form_id", id).order("sort_order");
  return { form: form as FormInfo, questions: (questions ?? []).map(asQuestion) };
}

// The link people open (and the QR code points to).
export const formUrl = (siteUrl: string, id: string) => `${siteUrl}/forms/${id}`;

// cmeprojects: forms waiting for this person that aren't Compliance items
// (those are listed with the rest of My onboarding already): sent to them,
// or open to everyone. Done ones drop off unless they can be filled again.
export async function getFormsToFill(userId: string): Promise<{ id: string; title: string; due_date: string | null; started: boolean }[]> {
  const supabase = await createClient();
  const { data: ids, error } = await supabase.rpc("my_forms_to_fill");
  const list = error ? [] : ((ids ?? []) as string[]);
  if (!list.length) return [];
  const [{ data: forms }, { data: items }, { data: done }, { data: drafts }] = await Promise.all([
    supabase.from("forms").select("id, title, due_date, repeatable").in("id", list),
    supabase.from("compliance_items").select("form_id").in("form_id", list),
    supabase.from("form_completions").select("form_id").eq("user_id", userId).in("form_id", list),
    supabase.from("form_responses").select("form_id").eq("user_id", userId).eq("status", "draft").in("form_id", list),
  ]);
  const inCompliance = new Set((items ?? []).map((i) => i.form_id));
  const finished = new Set((done ?? []).map((d) => d.form_id));
  const started = new Set((drafts ?? []).map((d) => d.form_id));
  return (forms ?? [])
    .filter((f) => !inCompliance.has(f.id) && (!finished.has(f.id) || f.repeatable))
    .map((f) => ({ id: f.id, title: f.title, due_date: f.due_date, started: started.has(f.id) }));
}

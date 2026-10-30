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

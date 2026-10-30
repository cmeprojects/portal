// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { isRole } from "@/lib/roles";
import { text, type FormState } from "@/lib/form";
import { QTYPES, hasOptions, type FormAnswers, type FormInfo, type FormQuestion } from "@/lib/form-types";

// Forms (cmeprojects). The database checks who may do what (the maker and
// people they share with); these just pass the choices on.

type Result = { error?: string; message?: string };

function refresh(id?: string) {
  revalidatePath("/forms", "layout");
  if (id) revalidatePath(`/forms/${id}`, "layout");
}

export async function createForm(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const title = text(form, "title").slice(0, 120);
  if (!title) return { error: "Give the form a name, for example Staff survey." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("forms").insert({ title, created_by: profile.id }).select("id").single();
  if (error || !data) return { error: error ? friendlyError(error) : "Only the people the system admin chose can make forms." };
  refresh();
  redirect(`/forms/${data.id}/edit`);
}

type Draft = {
  form: Pick<FormInfo, "title" | "intro" | "repeatable" | "anonymous" | "show_header" | "show_contact" | "notify_creator" | "due_date" | "closes_on">;
  questions: FormQuestion[];
};

// Saves the form and its questions in order. Removed questions that already
// have answers are hidden (kept in old replies), never deleted.
export async function saveForm(id: string, draft: Draft): Promise<Result & { ids?: Record<string, string> }> {
  await requireSession();
  const f = draft.form;
  if (!f.title.trim()) return { error: "Give the form a name." };
  const questions = draft.questions.filter((q) => !q.archived);
  for (const q of questions) {
    if (!q.label.trim()) return { error: "Every question needs some words." };
    if (!(q.type in QTYPES)) return { error: `${q.label}: choose the kind of answer.` };
    if (hasOptions(q.type) && q.options.filter((o) => o.trim()).length < 2) return { error: `${q.label}: add at least two choices.` };
  }
  const iso = (d: string | null) => (d && /^\d{4}-\d{2}-\d{2}$/.test(d) ? d : null);
  const supabase = await createClient();
  const { error } = await supabase
    .from("forms")
    .update({
      title: f.title.trim().slice(0, 120),
      intro: f.intro.trim().slice(0, 2000),
      repeatable: f.repeatable,
      anonymous: f.anonymous,
      show_header: f.show_header,
      show_contact: f.show_contact,
      notify_creator: f.notify_creator,
      due_date: iso(f.due_date),
      closes_on: iso(f.closes_on),
      updated_at: new Date().toISOString(),
    })
    .eq("id", id);
  if (error) return { error: friendlyError(error) };

  const { data: existing } = await supabase.from("form_questions").select("id").eq("form_id", id);
  const ids: Record<string, string> = {};
  for (const [i, q] of questions.entries()) {
    const row = {
      label: q.label.trim().slice(0, 300),
      type: q.type,
      required: q.required,
      help: q.help.trim().slice(0, 300),
      options: hasOptions(q.type) ? [...new Set(q.options.map((o) => o.trim()).filter(Boolean))].slice(0, 50) : [],
      sort_order: i + 1,
      archived: false,
    };
    if (q.id.startsWith("new-")) {
      const { data, error: e } = await supabase.from("form_questions").insert({ ...row, form_id: id }).select("id").single();
      if (e || !data) return { error: friendlyError(e) };
      ids[q.id] = data.id;
    } else {
      const { error: e } = await supabase.from("form_questions").update(row).eq("id", q.id).eq("form_id", id);
      if (e) return { error: friendlyError(e) };
      ids[q.id] = q.id;
    }
  }
  // Taken off the form: delete if no one has answered it, otherwise hide it.
  const kept = new Set(Object.values(ids));
  const gone = (existing ?? []).filter((q) => !kept.has(q.id)).map((q) => q.id);
  if (gone.length) {
    const { count } = await supabase.from("form_responses").select("id", { count: "exact", head: true }).eq("form_id", id);
    if (count) await supabase.from("form_questions").update({ archived: true }).in("id", gone);
    else await supabase.from("form_questions").delete().in("id", gone);
  }
  refresh(id);
  return { message: "Saved.", ids };
}

export async function publishForm(id: string): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  const { count } = await supabase.from("form_questions").select("id", { count: "exact", head: true }).eq("form_id", id).eq("archived", false);
  if (!count) return { error: "Add at least one question first." };
  const { error } = await supabase.from("forms").update({ status: "published", enabled: true, published_at: new Date().toISOString() }).eq("id", id);
  if (error) return { error: friendlyError(error) };
  refresh(id);
  return { message: "Published. Now send it to people, put it in Compliance, or share the link." };
}

export async function setFormOn(id: string, on: boolean): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  const { error } = await supabase.from("forms").update({ enabled: on }).eq("id", id);
  if (error) return { error: friendlyError(error) };
  if (!on) await supabase.rpc("form_out_of_compliance", { p_form: id });
  refresh(id);
  return { message: on ? "Turned on. People can fill it in again." : "Turned off. No one can fill it in; replies are kept." };
}

export async function deleteForm(id: string): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  await supabase.rpc("form_out_of_compliance", { p_form: id });
  const { data, error } = await supabase.from("forms").delete().eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only the person who made the form, or someone it's shared with, can delete it." };
  refresh();
  return { message: "Deleted." };
}

// A copy to start from: same questions and settings, as a new draft.
export async function copyForm(id: string): Promise<Result> {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const [{ data: f }, { data: qs }] = await Promise.all([
    supabase.from("forms").select("*").eq("id", id).maybeSingle(),
    supabase.from("form_questions").select("*").eq("form_id", id).eq("archived", false).order("sort_order"),
  ]);
  if (!f) return { error: "Form not found." };
  const { data: copy, error } = await supabase
    .from("forms")
    .insert({
      title: `${f.title} (copy)`.slice(0, 120),
      intro: f.intro,
      repeatable: f.repeatable,
      anonymous: f.anonymous,
      show_header: f.show_header,
      show_contact: f.show_contact,
      notify_creator: f.notify_creator,
      created_by: profile.id,
    })
    .select("id")
    .single();
  if (error || !copy) return { error: error ? friendlyError(error) : "Only the people the system admin chose can make forms." };
  if (qs?.length) {
    await supabase.from("form_questions").insert(
      qs.map((q) => ({ form_id: copy.id, label: q.label, type: q.type, required: q.required, help: q.help, options: q.options, sort_order: q.sort_order })),
    );
  }
  refresh();
  redirect(`/forms/${copy.id}/edit`);
}

export async function sendForm(id: string, choice: { users: string[]; team: string; everyone: boolean; due: string }): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  if (choice.due !== undefined) {
    await supabase.from("forms").update({ due_date: /^\d{4}-\d{2}-\d{2}$/.test(choice.due) ? choice.due : null }).eq("id", id);
  }
  if (!choice.everyone && !choice.team && !choice.users.length) return { error: "Choose people, a team or everyone." };
  const { data, error } = await supabase.rpc("send_form", {
    p_form: id,
    p_users: choice.users.filter((u) => /^[0-9a-f-]{36}$/.test(u)),
    p_team: /^[0-9a-f-]{36}$/.test(choice.team) ? choice.team : null,
    p_everyone: choice.everyone,
  });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  const n = Number(data);
  return { message: `Sent to ${n} ${n === 1 ? "person" : "people"}. They've been told by the bell and email.` };
}

export async function remindForm(id: string): Promise<Result> {
  await requireSession();
  const { data, error } = await (await createClient()).rpc("remind_form", { p_form: id });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  const n = Number(data);
  return { message: n ? `Reminded ${n} ${n === 1 ? "person" : "people"}.` : "Everyone it was sent to has filled it in." };
}

export async function formToCompliance(id: string, roles: string[], teams: string[]): Promise<Result> {
  await requireSession();
  const { error } = await (await createClient()).rpc("form_to_compliance", {
    p_form: id,
    p_roles: roles.filter(isRole).filter((r) => r !== "system_admin"),
    p_teams: teams.filter((t) => /^[0-9a-f-]{36}$/.test(t)),
  });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  revalidatePath("/onboarding");
  return { message: "It's in Compliance. Staff see it in My onboarding, and it counts in the Compliance report." };
}

export async function formOutOfCompliance(id: string): Promise<Result> {
  await requireSession();
  const { error } = await (await createClient()).rpc("form_out_of_compliance", { p_form: id });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  return { message: "Taken out of Compliance. Replies are kept." };
}

export async function shareForm(id: string, userId: string, on: boolean): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  const { error } = on
    ? await supabase.from("form_collaborators").upsert({ form_id: id, user_id: userId })
    : await supabase.from("form_collaborators").delete().eq("form_id", id).eq("user_id", userId);
  if (error) return { error: on ? "Only the person who made the form can share it." : friendlyError(error) };
  refresh(id);
  return { message: on ? "Shared. They can edit it and see the replies." : "No longer shared with them." };
}

// Staff: send a reply, or save it to finish later.
export async function submitReply(id: string, answers: FormAnswers, send: boolean): Promise<Result> {
  await requireSession();
  const { error } = await (await createClient()).rpc("submit_form_response", { p_form: id, p_answers: answers, p_send: send });
  if (error) return { error: friendlyError(error) };
  refresh(id);
  revalidatePath("/onboarding");
  return { message: send ? "Sent. Thank you." : "Saved. Come back to finish it any time." };
}

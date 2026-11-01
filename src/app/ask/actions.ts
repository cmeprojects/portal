// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { EMAIL, text } from "@/lib/form";
import { answerQuestion, assistantOn, getVisitor, loadSettings } from "@/lib/assistant";
import type { Answer } from "@/lib/assistant-shared";

// The public website's actions: anyone can ask a question or leave their
// details, so everything is checked and capped here.

type Turn = { question: string; answer: string };

// Signed in: the chat is saved (and its earlier turns come from the database).
// Not signed in: the browser sends its own earlier turns, kept until it's closed.
export async function askQuestion(question: string, chatId: string | null, history: Turn[]): Promise<{ answer: Answer; chatId: string | null } | { error: string }> {
  try {
    return await ask(question, chatId, history);
  } catch (e) {
    // Never a blank "page couldn't load": a plain message (and the reason for
    // signed-in staff, so it can be fixed), and the details in the server log.
    console.error("cmeprojects assistant: askQuestion failed", e);
    const staff = Boolean((await getVisitor().catch(() => null))?.userId);
    const why = e instanceof Error ? e.message : String(e);
    return { error: `Sorry, something went wrong. Please try again, or contact us.${staff ? ` (For the admin: ${why.slice(0, 200)})` : ""}` };
  }
}

async function ask(question: string, chatId: string | null, history: Turn[]): Promise<{ answer: Answer; chatId: string | null } | { error: string }> {
  if (!(await assistantOn())) return { error: "The assistant isn't available right now." };
  const q = String(question ?? "").trim().slice(0, 500);
  if (q.length < 3) return { error: "Please type a question." };
  const [settings, visitor] = await Promise.all([loadSettings(), getVisitor()]);

  if (!visitor.userId) {
    const earlier = (Array.isArray(history) ? history : []).slice(-4).map((t) => ({ question: String(t.question).slice(0, 300), answer: String(t.answer).slice(0, 600) }));
    return { answer: await answerQuestion(q, settings, visitor.audiences, earlier), chatId: null };
  }

  const supabase = await createClient();
  let id = chatId && /^[0-9a-f-]{36}$/.test(chatId) ? chatId : null;
  let earlier: Turn[] = [];
  if (id) {
    const { data } = await supabase.from("assistant_messages").select("question, answer").eq("chat_id", id).order("id", { ascending: false }).limit(4);
    earlier = (data ?? []).reverse();
  }
  const answer = await answerQuestion(q, settings, visitor.audiences, earlier);
  if (!id) {
    const { data } = await supabase.from("assistant_chats").insert({ title: q.slice(0, 80) }).select("id").single();
    id = data?.id ?? null;
  }
  if (id) await supabase.from("assistant_messages").insert({ chat_id: id, question: q, answer: answer.text, sources: answer.sources, answered: answer.answered });
  return { answer, chatId: id };
}

// Signing out from the website keeps them on the website.
export async function signOutWebsite() {
  await (await createClient()).auth.signOut();
  redirect("/ask");
}

export async function deleteChat(chatId: string): Promise<void> {
  await (await createClient()).from("assistant_chats").delete().eq("id", chatId);
}

export const NEEDS = ["Daily living support", "Community access", "Supported independent living", "Not sure yet"];
const SUPPORT_FOR = ["Me", "A family member", "Someone I support (coordinator)", "Other"];
const PLANS = ["Yes", "Not yet", "Not sure"];
const MANAGED = ["Self-managed", "Plan-managed", "NDIA-managed", "Don't know"];
const TIMES = ["Any time", "Morning", "Afternoon", "After 5 pm"];
const HEARD = ["Support coordinator", "Google", "Friend or family", "Other"];

export type EnquiryState = { error?: string; done?: boolean } | null;

const pick = (v: string, allowed: string[]) => (allowed.includes(v) ? v : "");

export async function submitEnquiry(_: EnquiryState, form: FormData): Promise<EnquiryState> {
  if (!(await assistantOn())) return { error: "Sorry, this form isn't available right now. Please call us." };
  // A hidden box real people never fill in.
  if (text(form, "website")) return { done: true };
  const full_name = text(form, "full_name").slice(0, 120);
  const phone = text(form, "phone").slice(0, 40);
  const email = text(form, "email").slice(0, 200);
  if (!full_name) return { error: "Please tell us your name." };
  if (phone.replace(/\D/g, "").length < 8) return { error: "Please give a phone number we can call you on." };
  if (email && !EMAIL.test(email)) return { error: "That email doesn't look right." };
  if (form.get("consent") !== "on") return { error: "Please tick the box so we can contact you." };

  const admin = createAdminClient();
  const { count } = await admin
    .from("website_enquiries")
    .select("id", { count: "exact", head: true })
    .gte("created_at", new Date(Date.now() - 3_600_000).toISOString());
  if ((count ?? 0) >= 30) return { error: "We've had a lot of enquiries in the last hour. Please call us instead." };

  const asked = text(form, "asked").slice(0, 500);
  const { error } = await admin.from("website_enquiries").insert({
    full_name,
    phone,
    email,
    suburb: text(form, "suburb").slice(0, 100),
    support_for: pick(text(form, "support_for"), SUPPORT_FOR),
    has_plan: pick(text(form, "has_plan"), PLANS),
    managed_by: pick(text(form, "managed_by"), MANAGED),
    needs: form.getAll("needs").map(String).filter((n) => NEEDS.includes(n)),
    best_time: pick(text(form, "best_time"), TIMES),
    heard_from: pick(text(form, "heard_from"), HEARD),
    message: text(form, "message").slice(0, 1000),
    asked,
    source: asked ? "chat" : "form",
    consent: true,
  });
  if (error) return { error: "Sorry, something went wrong. Please call us instead." };
  return { done: true };
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { EMAIL, text } from "@/lib/form";
import { answerQuestion, assistantOn, loadSettings, visitorAudiences, type Answer } from "@/lib/assistant";

// The public website's actions: anyone can ask a question or leave their
// details, so everything is checked and capped here.

export async function askQuestion(question: string): Promise<Answer | { error: string }> {
  if (!(await assistantOn())) return { error: "The assistant isn't available right now." };
  const q = String(question ?? "").trim();
  if (q.length < 3) return { error: "Please type a question." };
  const [settings, audiences] = await Promise.all([loadSettings(), visitorAudiences()]);
  return answerQuestion(q, settings, audiences);
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

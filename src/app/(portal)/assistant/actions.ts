// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { checkPhone } from "@/lib/phone";
import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";
import { AUDIENCES } from "@/lib/assistant-shared";
import { readScanned } from "@/lib/assistant";
import { saveDraft } from "@/lib/drafts";

// The Assistant's settings and document library (system admin only; the
// database checks it again).

const refresh = () => revalidatePath("/assistant");

// Website settings are saved one part at a time, so each person only changes
// what they may: the system admin everything, a manager given "Website"
// only where it looks for answers.
type Part = "landing" | "answers" | "limits";

async function canManageWebsite(): Promise<{ admin: boolean; ok: boolean }> {
  const { profile } = await requireSession();
  const admin = profile.role === "system_admin";
  return { admin, ok: admin || (await getMyAdminAreas(profile.role)).includes("website") };
}

export async function saveAssistantSettings(_: FormState, form: FormData): Promise<FormState> {
  const part = text(form, "part") as Part;
  const who = await canManageWebsite();
  if (!who.ok || (part !== "answers" && !who.admin)) return { error: "Only the system admin can change this part." };
  const lines = (name: string, max: number, len: number) =>
    text(form, name)
      .split(/\n+/)
      .map((l) => l.trim().slice(0, len))
      .filter(Boolean)
      .slice(0, max);
  let row: Record<string, unknown>;
  if (part === "landing") {
    // cmeprojects: the support number is checked like every other phone number.
    const phone = checkPhone(text(form, "phone_country") || "AU", text(form, "phone"));
    if (!phone.ok) return { error: `Support number: ${phone.error}` };
    const heading = text(form, "heading").slice(0, 120);
    if (!heading) return { error: "The heading can't be empty." };
    row = {
      heading,
      intro: text(form, "intro").slice(0, 400),
      suggestions: lines("suggestions", 8, 80),
      phone: phone.value,
      disclaimer: text(form, "disclaimer").slice(0, 300),
      show_credits: form.get("show_credits") === "on",
      offer_call: form.get("offer_call") === "on",
    };
  } else if (part === "answers") {
    const scope = (name: string) => (["documents", "web", "both"].includes(text(form, name)) ? text(form, name) : "documents");
    // Websites: just the address, like ndis.gov.au.
    const sites = lines("trusted_sites", 30, 100)
      .map((l) => l.replace(/^https?:\/\//i, "").replace(/^www\./i, "").split("/")[0].toLowerCase())
      .filter((l) => /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(l));
    row = {
      scope_public: scope("scope_public"),
      scope_staff: scope("scope_staff"),
      scope_managers: scope("scope_managers"),
      trusted_sites: [...new Set(sites)],
      fallback: text(form, "fallback").slice(0, 400),
    };
  } else if (part === "limits") {
    const limit = Number(text(form, "monthly_limit_aud"));
    const hourly = Math.round(Number(text(form, "hourly_limit")));
    const credit = Number(text(form, "credit_aud") || 0);
    if (!(limit >= 0 && limit <= 100000)) return { error: "The monthly limit should be a dollar amount, like 50." };
    if (!(hourly >= 1 && hourly <= 500)) return { error: "Questions per hour should be between 1 and 500." };
    if (!(credit >= 0 && credit <= 100000)) return { error: "The credit should be a dollar amount, like 20." };
    const since = text(form, "credit_since");
    row = {
      model: text(form, "model") === "sonnet" ? "sonnet" : "haiku",
      monthly_limit_aud: limit,
      hourly_limit: hourly,
      credit_aud: credit,
      credit_since: /^\d{4}-\d{2}-\d{2}$/.test(since) ? since : null,
      log_questions: form.get("log_questions") === "on",
    };
  } else return { error: "Something went wrong. Please refresh and try again." };
  // cmeprojects: saved as a draft; it goes live when deployed.
  const result = await saveDraft("website", part, row);
  refresh();
  return result;
}

const MAX_BYTES = 10 * 1024 * 1024;

const IMAGES: Record<string, string> = { ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp" };

// Pulls the words out of an uploaded file (PDF, Word, text, or a photo). A
// scanned PDF or a photo is read by the AI, which costs a little.
async function readText(file: File): Promise<{ text: string; costUsd: number }> {
  const name = file.name.toLowerCase();
  const bytes = new Uint8Array(await file.arrayBuffer());
  const image = Object.entries(IMAGES).find(([ext]) => name.endsWith(ext))?.[1];
  if (image || name.endsWith(".pdf")) {
    if (name.endsWith(".pdf")) {
      const { extractText, getDocumentProxy } = await import("unpdf");
      const pdf = await getDocumentProxy(bytes.slice());
      const { text: words, totalPages } = await extractText(pdf, { mergePages: true });
      // Real text on the pages: no need for the AI.
      if (words.replace(/\s/g, "").length > 40 * Math.max(1, totalPages)) return { text: words, costUsd: 0 };
    }
    const read = await readScanned(bytes, image ?? "application/pdf");
    if (!read) throw new Error("Please paste the words in: this looks like a scanned page, and reading scans needs the AI key (see the note at the top).");
    return read;
  }
  if (name.endsWith(".docx")) {
    const mammoth = await import("mammoth");
    return { text: (await mammoth.extractRawText({ buffer: Buffer.from(bytes) })).value, costUsd: 0 };
  }
  if (name.endsWith(".txt") || name.endsWith(".md")) return { text: new TextDecoder().decode(bytes), costUsd: 0 };
  throw new Error("Please use a PDF, a Word file (.docx), a text file (.txt) or a photo (.jpg, .png).");
}

export async function addDocument(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  if (!(await canManageWebsite()).ok) return { error: "Only the system admin (or a manager given Website) can add documents." };
  const file = form.get("file");
  let body = text(form, "body");
  let title = text(form, "title").slice(0, 200);
  let readCost = 0;
  const audience = text(form, "audience");
  if (!AUDIENCES.includes(audience as (typeof AUDIENCES)[number])) return { error: "Choose who can use this document." };
  if (file instanceof File && file.size > 0) {
    if (file.size > MAX_BYTES) return { error: "That file is over 10 MB. Please use a smaller one." };
    try {
      const read = await readText(file);
      body = read.text;
      readCost = read.costUsd;
    } catch (e) {
      return { error: e instanceof Error && e.message.startsWith("Please") ? e.message : "We couldn't read that file. If it's a scanned PDF (a picture of a page), paste the words in instead." };
    }
    if (!title) title = file.name.replace(/\.[^.]+$/, "").slice(0, 200);
  }
  body = body.replace(/\r\n?/g, "\n").replace(/[ \t]+\n/g, "\n").replace(/\n{3,}/g, "\n\n").trim();
  if (!title) return { error: "Give the document a name." };
  if (body.length < 20) return { error: "There's no text to read. Upload a file or paste the words in." };
  if (body.length > 400_000) return { error: "That document is very long. Please split it into smaller ones." };

  const supabase = await createClient();
  const { data, error } = await supabase.from("assistant_documents").insert({ title, audience, body, created_by: profile.id, read_cost_usd: readCost }).select("id").single();
  if (error || !data) return { error: friendlyError(error) };
  const { error: indexError } = await supabase.rpc("assistant_index", { p_document: data.id });
  if (indexError) return { error: friendlyError(indexError) };
  refresh();
  return { message: `Added "${title}". The assistant can use it now.` };
}

export async function setDocumentAudience(form: FormData) {
  if (!(await canManageWebsite()).ok) return;
  const audience = text(form, "audience");
  if (!AUDIENCES.includes(audience as (typeof AUDIENCES)[number])) return;
  await (await createClient()).from("assistant_documents").update({ audience }).eq("id", text(form, "id"));
  refresh();
}

export async function deleteDocument(form: FormData) {
  if (!(await canManageWebsite()).ok) return;
  await (await createClient()).from("assistant_documents").delete().eq("id", text(form, "id"));
  refresh();
}

// "Test the AI connection": one tiny request, so the system admin knows the
// key and credit work before relying on it. Costs a fraction of a cent.
export async function testAiConnection(): Promise<{ ok: boolean; message: string }> {
  const who = await canManageWebsite();
  if (!who.admin) return { ok: false, message: "Only the system admin can run this." };
  if (!process.env.ANTHROPIC_API_KEY) return { ok: false, message: "No AI key yet. Add ANTHROPIC_API_KEY in Vercel, then redeploy." };
  const started = Date.now();
  try {
    const { default: Anthropic } = await import("@anthropic-ai/sdk");
    const res = await new Anthropic().messages.create({ model: "claude-haiku-5-5", max_tokens: 20, messages: [{ role: "user", content: "Reply with the single word OK." }] });
    const reply = res.content.flatMap((b) => (b.type === "text" ? [b.text] : [])).join("").trim();
    return { ok: true, message: `Connected. The AI replied "${reply.slice(0, 20)}" in ${((Date.now() - started) / 1000).toFixed(1)} seconds.` };
  } catch (e) {
    const status = (e as { status?: number }).status;
    const text = e instanceof Error ? e.message : String(e);
    if (status === 401) return { ok: false, message: "The key wasn't accepted. Copy it again from console.anthropic.com, update it in Vercel and redeploy." };
    if (status === 400 && /credit|balance/i.test(text)) return { ok: false, message: "The key works but there's no credit. Add credit in console.anthropic.com → Billing." };
    if (status === 429) return { ok: false, message: "Too many requests right now, or a spending limit was reached in the Anthropic console. Try again in a minute." };
    return { ok: false, message: `It didn't connect (${status ?? "no response"}): ${text.slice(0, 160)}` };
  }
}

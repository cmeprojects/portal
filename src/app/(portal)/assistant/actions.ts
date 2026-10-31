// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";
import { AUDIENCES } from "@/lib/assistant-shared";
import { readScanned } from "@/lib/assistant";

// The Assistant's settings and document library (system admin only; the
// database checks it again).

const refresh = () => revalidatePath("/assistant");

export async function saveAssistantSettings(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const limit = Number(text(form, "monthly_limit_aud"));
  const hourly = Math.round(Number(text(form, "hourly_limit")));
  if (!(limit >= 0 && limit <= 100000)) return { error: "The monthly limit should be a dollar amount, like 50." };
  if (!(hourly >= 1 && hourly <= 500)) return { error: "Questions per hour should be between 1 and 500." };
  const model = text(form, "model") === "sonnet" ? "sonnet" : "haiku";
  const heading = text(form, "heading").slice(0, 120);
  if (!heading) return { error: "The heading can't be empty." };
  const scope = (name: string) => (["documents", "web", "both"].includes(text(form, name)) ? text(form, name) : "documents");
  const lines = (name: string, max: number, len: number) =>
    text(form, name)
      .split(/\n+/)
      .map((l) => l.trim().slice(0, len))
      .filter(Boolean)
      .slice(0, max);
  // Websites: just the address, like ndis.gov.au.
  const sites = lines("trusted_sites", 30, 100)
    .map((l) => l.replace(/^https?:\/\//i, "").replace(/^www\./i, "").split("/")[0].toLowerCase())
    .filter((l) => /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(l));
  const supabase = await createClient();
  const { error } = await supabase
    .from("assistant_settings")
    .update({
      model,
      heading,
      intro: text(form, "intro").slice(0, 400),
      disclaimer: text(form, "disclaimer").slice(0, 300),
      fallback: text(form, "fallback").slice(0, 400),
      phone: text(form, "phone").slice(0, 40),
      offer_call: form.get("offer_call") === "on",
      log_questions: form.get("log_questions") === "on",
      show_credits: form.get("show_credits") === "on",
      suggestions: lines("suggestions", 8, 80),
      scope_public: scope("scope_public"),
      scope_staff: scope("scope_staff"),
      scope_managers: scope("scope_managers"),
      trusted_sites: [...new Set(sites)],
      monthly_limit_aud: limit,
      hourly_limit: hourly,
    })
    .eq("id", true);
  if (!error) await supabase.from("app_settings").update({ value: form.get("front_page") === "on" }).eq("key", "website.front_page");
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Saved." };
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
  const { profile } = await requireRole(["system_admin"]);
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
  await requireRole(["system_admin"]);
  const audience = text(form, "audience");
  if (!AUDIENCES.includes(audience as (typeof AUDIENCES)[number])) return;
  await (await createClient()).from("assistant_documents").update({ audience }).eq("id", text(form, "id"));
  refresh();
}

export async function deleteDocument(form: FormData) {
  await requireRole(["system_admin"]);
  await (await createClient()).from("assistant_documents").delete().eq("id", text(form, "id"));
  refresh();
}

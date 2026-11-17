// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 124, Stage 6): what an Allied Health practitioner can do
// for a client they've been given. The database checks the access each time.
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const DOC_MIME = [
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
];

async function requirePractitioner() {
  const session = await requireSession();
  if (session.profile.role !== "external") throw new Error("This is for Allied Health practitioners.");
  return session;
}

export async function uploadReport(_: FormState, form: FormData): Promise<FormState> {
  await requirePractitioner();
  const clientId = String(form.get("client_id") ?? "");
  const path = String(form.get("file_path") ?? "");
  const fileName = String(form.get("file_name") ?? "").slice(0, 160);
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  if (!path || !path.startsWith(`${clientId}/`) || path.slice(clientId.length + 1).includes("/")) return { error: "Choose a file and wait for it to upload." };
  const docType = String(form.get("doc_type") ?? "report") === "assessment" ? "assessment" : "report";
  const supabase = await createClient();
  const base = path.slice(clientId.length + 1);
  const { data: listed } = await supabase.storage.from("client-docs").list(clientId, { search: base, limit: 5 });
  const meta = (listed ?? []).find((o) => o.name === base)?.metadata as { mimetype?: string; size?: number } | undefined;
  if (!meta?.mimetype || !meta.size) return { error: "The file didn't upload. Please try again." };
  if (!DOC_MIME.includes(meta.mimetype)) return { error: "Only PDF, images (JPEG, PNG, WebP, HEIC) and Word documents." };
  if (meta.size > 10 * 1024 * 1024) return { error: "That file is over 10 MB." };
  const title = String(form.get("title") ?? "").trim().slice(0, 120) || fileName.slice(0, 120) || "Report";
  const { error } = await supabase.from("client_documents").insert({
    client_id: clientId,
    doc_type: docType,
    title,
    file_path: path,
    file_name: fileName || base,
    mime_type: meta.mimetype,
    size_bytes: meta.size,
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/practitioner/${clientId}`);
  return { message: "Report uploaded. The client's case manager will be told." };
}

export async function saveNote(_: FormState, form: FormData): Promise<FormState> {
  await requirePractitioner();
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  const body = String(form.get("body") ?? "").trim();
  const noteDate = String(form.get("note_date") ?? "");
  if (!isId(clientId) || (id && !isId(id))) return { error: "That didn't save. Please reload the page." };
  if (!body) return { error: "Write the note first." };
  if (body.length > 5000) return { error: "Keep the note under 5,000 characters." };
  const date = /^\d{4}-\d{2}-\d{2}$/.test(noteDate) ? noteDate : undefined;
  const supabase = await createClient();
  const { error } = id
    ? await supabase.from("client_practitioner_notes").update({ body, ...(date ? { note_date: date } : {}) }).eq("id", id)
    : await supabase.from("client_practitioner_notes").insert({ client_id: clientId, body, ...(date ? { note_date: date } : {}) });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/practitioner/${clientId}`);
  return { message: id ? "Note changed." : "Note added. The client's case manager will be told." };
}

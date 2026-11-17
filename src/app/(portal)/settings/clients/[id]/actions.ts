// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";

// Clients: the Access page (update 107); the database checks each client and part.
async function requireClients() {
  const session = await requireSession();
  if (!(await seesClientsFor())) throw new Error("You can't change clients.");
  return session;
}
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { SECTION_FIELDS, type SectionTable } from "@/lib/client-sections";

const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);

// cmeprojects (Clients & Care steps 2 to 5): saves one item in a client's
// profile (a location, their details, a person, an alert or a service). Only
// the fields listed for that section are accepted; the database checks the
// rest (who may save, approvals, readiness) and logs the change.
export async function saveClientSection(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const table = String(form.get("table") ?? "") as SectionTable;
  const fields = SECTION_FIELDS[table];
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  if (!fields || !isId(clientId) || (id && !isId(id))) return { error: "That didn't save. Please reload the page." };

  const values: Record<string, unknown> = {};
  let notes: string | null = null;
  for (const f of fields) {
    const raw = String(form.get(f.name) ?? "").trim();
    if (f.name === "notes") {
      notes = raw.slice(0, f.max ?? 5000);
      continue;
    }
    if (f.type === "checkbox") values[f.name] = form.get(f.name) === "on";
    else if (f.type === "date") values[f.name] = /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : null;
    else if (f.type === "select" && f.options) values[f.name] = f.options.some(([k]) => k === raw) ? raw : f.options[0][0];
    else if (f.type === "select") values[f.name] = isId(raw) ? raw : null;
    else values[f.name] = raw.slice(0, f.max ?? 200);
    if (f.required && !values[f.name]) return { error: `Fill in ${f.label.toLowerCase()}.` };
  }

  const supabase = await createClient();
  let error;
  let savedId = id;
  if (table === "client_details") {
    ({ error } = await supabase.from("client_details").upsert({ client_id: clientId, ...values }, { onConflict: "client_id" }));
  } else if (id) {
    ({ error } = await supabase.from(table).update(values).eq("id", id).eq("client_id", clientId));
  } else {
    const res = await supabase.from(table).insert({ client_id: clientId, ...values }).select("id").single();
    error = res.error;
    savedId = (res.data?.id as string) ?? "";
  }
  if (!error && table === "client_alerts" && savedId && notes !== null) {
    ({ error } = await supabase.from("client_alert_notes").upsert({ alert_id: savedId, client_id: clientId, details: notes }, { onConflict: "alert_id" }));
  }
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: id || table === "client_details" ? "Saved." : "Added." };
}

// "No known safety alerts": answers the safety step when there's nothing to record.
export async function recordNoAlerts(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "Choose a client." };
  const supabase = await createClient();
  const { error } = await supabase
    .from("client_alerts")
    .insert({ client_id: clientId, kind: "no_known_alerts", severity: "low", title: "No known safety alerts", worker_instructions: "" });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Recorded: no known safety alerts." };
}

// cmeprojects (Stage 5, update 106): assign a staff member to this client, or
// end an assignment. The database checks who may (Assigning staff), stops
// self-assignment, and keeps every assignment (ended, never deleted).
export async function assignStaff(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const as = String(form.get("assigned_as") ?? "case_manager");
  const startsOn = String(form.get("starts_on") ?? "");
  const endsOn = String(form.get("ends_on") ?? "");
  if (!isId(clientId) || !isId(userId)) return { error: "Choose a staff member." };
  if (!["case_manager", "support_coordinator", "intake", "key_worker", "other"].includes(as)) return { error: "Choose what they're assigned as." };
  const day = /^\d{4}-\d{2}-\d{2}$/;
  const { error } = await (await createClient()).from("client_assignments").insert({
    client_id: clientId,
    user_id: userId,
    assigned_as: as,
    ...(day.test(startsOn) ? { starts_on: startsOn } : {}),
    ...(day.test(endsOn) ? { ends_on: endsOn } : {}),
    note: String(form.get("note") ?? "").slice(0, 300),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Assigned." };
}

export async function endAssignment(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_assignments").update({ ended_at: new Date().toISOString() }).eq("id", id);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (Care block C2, update 111): communication preferences. The
// database checks who may (Communication preferences, edit, for this client).
export async function saveComms(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  const contact = String(form.get("preferred_contact") ?? "");
  if (!["", "phone", "sms", "email", "in_person", "through_representative"].includes(contact)) return { error: "Choose how to contact them." };
  const values = {
    client_id: clientId,
    preferred_contact: contact,
    language: String(form.get("language") ?? "").trim().slice(0, 60),
    interpreter_needed: form.get("interpreter_needed") === "on",
    accessibility_needs: String(form.get("accessibility_needs") ?? "").trim().slice(0, 1000),
    notes: String(form.get("notes") ?? "").trim().slice(0, 1000),
  };
  const { error } = await (await createClient()).from("client_comms").upsert(values, { onConflict: "client_id" });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Saved." };
}

// cmeprojects (Care block C3, update 112): client documents. The private
// store and the database check who may (Client documents, for this client),
// the type (PDF, images, Word) and the size (10 MB). Files are never changed
// or deleted: a new version replaces one, and archiving hides it.
const DOC_TYPES = ["consent", "assessment", "plan", "report", "agreement", "correspondence", "identity", "other"];
const DOC_MIME = ["application/pdf", "image/jpeg", "image/png", "image/webp", "image/heic", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"];

export async function uploadClientDocument(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const replaces = String(form.get("replaces_id") ?? "");
  const path = String(form.get("file_path") ?? "");
  const fileName = String(form.get("file_name") ?? "").slice(0, 160);
  if (!isId(clientId) || (replaces && !isId(replaces))) return { error: "That didn't save. Please reload the page." };
  if (!path || !path.startsWith(`${clientId}/`) || path.slice(clientId.length + 1).includes("/")) return { error: "Choose a file and wait for it to upload." };
  const docType = String(form.get("doc_type") ?? "other");
  if (!DOC_TYPES.includes(docType)) return { error: "Choose the type of document." };
  const supabase = await createClient();
  // The stored file's real type and size (and proof it's there and readable).
  const base = path.slice(clientId.length + 1);
  const { data: listed } = await supabase.storage.from("client-docs").list(clientId, { search: base, limit: 5 });
  const meta = (listed ?? []).find((o) => o.name === base)?.metadata as { mimetype?: string; size?: number } | undefined;
  if (!meta?.mimetype || !meta.size) return { error: "The file didn't upload. Please try again." };
  if (!DOC_MIME.includes(meta.mimetype)) return { error: "Only PDF, images (JPEG, PNG, WebP, HEIC) and Word documents." };
  if (meta.size > 10 * 1024 * 1024) return { error: "That file is over 10 MB." };
  const title = String(form.get("title") ?? "").trim().slice(0, 120) || fileName.slice(0, 120) || "Document";
  const expires = String(form.get("expires_on") ?? "");
  const { error } = await supabase.from("client_documents").insert({
    client_id: clientId,
    doc_type: docType,
    title,
    file_path: path,
    file_name: fileName || base,
    mime_type: meta.mimetype,
    size_bytes: meta.size,
    expires_on: /^\d{4}-\d{2}-\d{2}$/.test(expires) ? expires : null,
    replaces_id: replaces || null,
  });
  if (error) return { error: friendlyError(error) };
  if (replaces) await supabase.from("client_documents").update({ archived_at: new Date().toISOString() }).eq("id", replaces);
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: replaces ? "New version added." : "Document added." };
}

export async function archiveClientDocument(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_documents").update({ archived_at: new Date().toISOString() }).eq("id", id);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (Care block C4, update 113): care plans, goals and worker
// instructions. The database checks who may (Care plans, for this client),
// keeps one current plan, fixes a plan's wording once it's current and never
// deletes anything.
const ymd = (v: FormDataEntryValue | null) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);

export async function saveCarePlan(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  const documentId = String(form.get("document_id") ?? "");
  if (!isId(clientId) || (id && !isId(id)) || (documentId && !isId(documentId))) return { error: "That didn't save. Please reload the page." };
  const title = String(form.get("title") ?? "").trim().slice(0, 120);
  if (!title) return { error: "Give the plan a title." };
  const values = {
    title,
    assessed_on: ymd(form.get("assessed_on")),
    starts_on: ymd(form.get("starts_on")),
    review_by: ymd(form.get("review_by")),
    summary: String(form.get("summary") ?? "").trim().slice(0, 5000),
    document_id: documentId || null,
  };
  const supabase = await createClient();
  const { error } = id
    ? await supabase.from("client_care_plans").update(values).eq("id", id).eq("client_id", clientId)
    : await supabase.from("client_care_plans").insert({ client_id: clientId, ...values });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: id ? "Saved." : "Draft added." };
}

export async function setCarePlanStatus(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!isId(id) || !isId(clientId) || !["current", "archived"].includes(status)) return;
  await (await createClient()).from("client_care_plans").update({ status }).eq("id", id).eq("client_id", clientId);
  revalidatePath(`/settings/clients/${clientId}`);
}

export async function saveCareGoal(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const planId = String(form.get("plan_id") ?? "");
  if (!isId(clientId) || !isId(planId)) return { error: "That didn't save. Please reload the page." };
  const goal = String(form.get("goal") ?? "").trim().slice(0, 500);
  if (!goal) return { error: "Write the goal." };
  const { error } = await (await createClient())
    .from("client_care_goals")
    .insert({ client_id: clientId, plan_id: planId, goal, measure: String(form.get("measure") ?? "").trim().slice(0, 500) });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Goal added." };
}

export async function setCareGoalStatus(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!isId(id) || !isId(clientId) || !["active", "achieved", "discontinued"].includes(status)) return;
  await (await createClient()).from("client_care_goals").update({ status }).eq("id", id).eq("client_id", clientId);
  revalidatePath(`/settings/clients/${clientId}`);
}

export async function saveWorkerInstruction(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  const title = String(form.get("title") ?? "").trim().slice(0, 120);
  const instructions = String(form.get("instructions") ?? "").trim().slice(0, 2000);
  if (!title || !instructions) return { error: "Fill in the heading and the instructions." };
  const { error } = await (await createClient()).from("client_worker_instructions").insert({ client_id: clientId, title, instructions });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Added." };
}

export async function setWorkerInstructionActive(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_worker_instructions").update({ active: form.get("active") === "true" }).eq("id", id).eq("client_id", clientId);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (Care block C5, update 114): reviews and re-assessments. The
// database takes the scheme from the service's program (so NDIS and Support
// at Home never mix), checks who may (Reviews, for this client) and keeps
// closed reviews as they were. A change of situation sends its reminder
// straight away (the same hourly job, which only sends what's due once).
const SCHEMES = ["ndis", "support_at_home", "private", "other"];

export async function addClientReview(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const serviceId = String(form.get("service_id") ?? "");
  const scheme = String(form.get("scheme") ?? "");
  const kind = String(form.get("kind") ?? "scheduled");
  if (!isId(clientId) || (serviceId && !isId(serviceId))) return { error: "That didn't save. Please reload the page." };
  if (!serviceId && !SCHEMES.includes(scheme)) return { error: "Choose the service or the scheme." };
  if (!["scheduled", "change_of_situation"].includes(kind)) return { error: "Choose the kind of review." };
  const dueOn = ymd(form.get("due_on"));
  if (kind === "scheduled" && !dueOn) return { error: "Choose the due date." };
  const reason = String(form.get("reason") ?? "").trim().slice(0, 1000);
  const { error } = await (await createClient()).from("client_reviews").insert({
    client_id: clientId,
    service_id: serviceId || null,
    scheme: SCHEMES.includes(scheme) ? scheme : "other",
    kind,
    due_on: dueOn ?? new Date().toISOString().slice(0, 10),
    reason,
  });
  if (error) return { error: friendlyError(error) };
  if (kind === "change_of_situation") {
    const { error: alertError } = await createAdminClient().rpc("run_care_alerts");
    if (alertError) console.error("care alerts", alertError.message);
  }
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: kind === "change_of_situation" ? "Raised. The care team has been told." : "Added." };
}

export async function closeClientReview(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  const status = String(form.get("status") ?? "");
  const documentId = String(form.get("document_id") ?? "");
  if (!isId(id) || !isId(clientId) || (documentId && !isId(documentId)) || !["completed", "cancelled"].includes(status)) return { error: "That didn't save. Please reload the page." };
  const outcome = String(form.get("outcome") ?? "").trim().slice(0, 2000);
  if (status === "completed" && !outcome) return { error: "Record the outcome." };
  const { error } = await (await createClient())
    .from("client_reviews")
    .update({ status, outcome, completed_on: status === "completed" ? ymd(form.get("completed_on")) : null, document_id: documentId || null })
    .eq("id", id)
    .eq("client_id", clientId);
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: status === "completed" ? "Completed." : "Cancelled." };
}

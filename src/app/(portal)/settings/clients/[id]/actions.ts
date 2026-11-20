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
import { sydneyInstant } from "@/lib/sydney-time";
import { checkAuPhone, checkDob, checkEmail, checkFullAddress, checkPostcode, checkStreet, type Check } from "@/lib/validate";
// "2026-11-19T14:30" (Sydney wall clock) -> an instant.
const sydneyLocalToIso = (v: string) => sydneyInstant(v.slice(0, 10), v.slice(11, 16));

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
    // A greyed-out field (not applicable to this client) isn't sent: it keeps what's stored.
    if (f.type !== "checkbox" && !form.has(f.name)) continue;
    const raw = String(form.get(f.name) ?? "").trim();
    if (f.name === "notes") {
      notes = raw.slice(0, f.max ?? 5000);
      continue;
    }
    if (f.name === "tags") values.tags = [...new Set(raw.split(",").map((t) => t.trim().replace(/[<>]/g, "").slice(0, 30)).filter(Boolean))].slice(0, 10);
    else if (f.type === "checkbox") values[f.name] = form.get(f.name) === "on";
    else if (f.type === "date") values[f.name] = /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : null;
    else if (f.type === "select" && f.options) values[f.name] = f.options.some(([k]) => k === raw) ? raw : f.options[0][0];
    else if (f.type === "select") values[f.name] = isId(raw) ? raw : null;
    else values[f.name] = raw.slice(0, f.max ?? 200);
    if (f.required && !values[f.name]) return { error: `Fill in ${f.label.toLowerCase()}.` };
  }

  // The home address in parts (owner, 20 Nov 2026): street, suburb, state, postcode, saved as one line.
  if (table === "client_details" && form.has("home_street")) {
    const street = String(form.get("home_street") ?? "").trim().slice(0, 200);
    const suburb = String(form.get("home_suburb") ?? "").trim().slice(0, 60);
    const pc = String(form.get("home_postcode") ?? "").trim().slice(0, 4);
    const st = String(values.state ?? "");
    const need = [!street && "street address", !suburb && "suburb", !pc && "postcode", !st && "state"].filter(Boolean);
    if (need.length) return { error: `Fill in the ${need.join(", ")}.` };
    const sCheck = checkStreet(street);
    if (!sCheck.ok) return { error: `Street address: ${sCheck.error}` };
    const pCheck = checkPostcode(st, pc);
    if (!pCheck.ok) return { error: `Postcode: ${pCheck.error}` };
    values.home_address = `${sCheck.value}, ${suburb} ${st} ${pc}`;
  }
  // cmeprojects (owner's standing rule): emails, Australian phone numbers and addresses are checked before saving.
  const fix = (key: string, c: Check, what: string) => {
    if (!c.ok) return `${what}: ${c.error}`;
    if (key in values) values[key] = c.value;
    return "";
  };
  // Only what's changed is checked: details saved before the checks (an older address
  // format, say) don't stop the rest of the section from saving.
  const supabase0 = await createClient();
  const { data: before } =
    table === "client_details"
      ? await supabase0.from("client_details").select("*").eq("client_id", clientId).maybeSingle()
      : id
        ? await supabase0.from(table).select("*").eq("id", id).maybeSingle()
        : { data: null };
  const was = (before ?? null) as Record<string, unknown> | null;
  const changed = (...keys: string[]) => !was || keys.some((k) => k in values && String(was[k] ?? "") !== String(values[k] ?? ""));
  const problems: string[] = [];
  if ("phone" in values && changed("phone")) problems.push(fix("phone", checkAuPhone(String(values.phone ?? "")), "Phone"));
  if ("email" in values && changed("email")) problems.push(fix("email", checkEmail(String(values.email ?? "")), "Email"));
  if (table === "client_details" && values.home_address && changed("home_address", "state")) {
    const a = checkFullAddress(String(values.home_address));
    problems.push(fix("home_address", a, "Home address"));
    const st = a.ok ? a.value.match(/ (NSW|VIC|QLD|WA|SA|TAS|ACT|NT) \d{4}$/)?.[1] : null;
    if (st && values.state && values.state !== st) problems.push(`State: the home address is in ${st}, but ${values.state} is chosen.`);
  }
  if (table === "client_details") {
    if (values.date_of_birth && changed("date_of_birth")) problems.push(fix("date_of_birth", checkDob(String(values.date_of_birth)), "Date of birth"));
    if (values.ndis_number && changed("ndis_number")) {
      values.ndis_number = String(values.ndis_number).replace(/\s/g, "");
      if (!/^\d{9}$/.test(String(values.ndis_number))) problems.push("NDIS number: it's 9 digits.");
    }
    if (values.aged_care_id && changed("aged_care_id")) {
      values.aged_care_id = String(values.aged_care_id).replace(/\s/g, "").toUpperCase();
      if (!/^AC\d{8}$/.test(String(values.aged_care_id))) problems.push("My Aged Care ID: it's AC followed by 8 numbers (for example AC12345678).");
    }
  }
  if (table === "client_locations" && changed("address", "suburb", "state", "postcode")) {
    problems.push(fix("address", checkStreet(String(values.address ?? "")), "Street address"));
    if (!values.suburb || !values.state || !values.postcode) problems.push("Fill in the suburb, state and postcode too.");
    else problems.push(fix("postcode", checkPostcode(String(values.state), String(values.postcode)), "Postcode"));
  }
  const problem = problems.filter(Boolean);
  if (problem.length) return { error: problem.join(" ") };

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
const SCHEMES = ["ndis", "support_at_home", "chsp", "private", "other"];

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

// cmeprojects (Care block C6, update 115): service agreements. The database
// takes the scheme from the service's program, checks who may (Service
// agreements, for this client) and fixes a signed agreement's dates and
// signature.
export async function saveAgreement(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  const serviceId = String(form.get("service_id") ?? "");
  const documentId = String(form.get("document_id") ?? "");
  const step = String(form.get("step") ?? "save");
  if (!isId(clientId) || (id && !isId(id)) || (!id && !isId(serviceId)) || (documentId && !isId(documentId))) return { error: "Choose the service." };
  const supabase = await createClient();
  let error;
  if (step === "sign" && id) {
    const signedOn = ymd(form.get("signed_on"));
    const by = String(form.get("signed_by_name") ?? "").trim().slice(0, 120);
    if (!signedOn || !by) return { error: "Record when it was signed and who signed it." };
    ({ error } = await supabase
      .from("client_agreements")
      .update({ status: "signed", signed_on: signedOn, signed_by_name: by, ...(documentId ? { document_id: documentId } : {}) })
      .eq("id", id)
      .eq("client_id", clientId));
  } else {
    const startsOn = ymd(form.get("starts_on"));
    if (!startsOn) return { error: "Choose the start date." };
    const status = String(form.get("status") ?? "draft");
    const values = {
      starts_on: startsOn,
      ends_on: ymd(form.get("ends_on")),
      status: ["draft", "sent"].includes(status) ? status : "draft",
      notes: String(form.get("notes") ?? "").trim().slice(0, 1000),
      document_id: documentId || null,
    };
    ({ error } = id
      ? await supabase.from("client_agreements").update(values).eq("id", id).eq("client_id", clientId)
      : await supabase.from("client_agreements").insert({ client_id: clientId, service_id: serviceId, ...values }));
  }
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: step === "sign" ? "Recorded as signed." : id ? "Saved." : "Agreement added." };
}

export async function endAgreement(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_agreements").update({ status: "ended" }).eq("id", id).eq("client_id", clientId);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (Care block C7, update 116): funding and budgets. The database
// takes the scheme from the service's program and keeps each scheme's rules
// apart (NDIS: plan management; Support at Home: classification).
const money = (v: FormDataEntryValue | null) => {
  const n = Number(String(v ?? "").replace(/[$,\s]/g, ""));
  return Number.isFinite(n) && n >= 0 && n < 1e10 ? Math.round(n * 100) / 100 : null;
};

export async function saveFunding(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  const serviceId = String(form.get("service_id") ?? "");
  if (!isId(clientId) || (id && !isId(id)) || (!id && !isId(serviceId))) return { error: "Choose the service." };
  const supabase = await createClient();
  if (id) {
    const used = money(form.get("used_amount"));
    if (used === null) return { error: "Enter the amount used, in dollars." };
    const { error } = await supabase
      .from("client_funding")
      .update({ used_amount: used, used_as_of: ymd(form.get("used_as_of")) ?? new Date().toISOString().slice(0, 10), notes: String(form.get("notes") ?? "").trim().slice(0, 1000) })
      .eq("id", id)
      .eq("client_id", clientId);
    if (error) return { error: friendlyError(error) };
  } else {
    const start = ymd(form.get("period_start"));
    const end = ymd(form.get("period_end"));
    const total = money(form.get("total_amount"));
    if (!start || !end) return { error: "Choose the period." };
    if (total === null) return { error: "Enter the total, in dollars." };
    const pm = String(form.get("plan_management") ?? "");
    const cls = Number(form.get("classification") ?? "");
    const { error } = await supabase.from("client_funding").insert({
      client_id: clientId,
      service_id: serviceId,
      period_start: start,
      period_end: end,
      total_amount: total,
      plan_management: ["ndia", "plan", "self"].includes(pm) ? pm : null,
      classification: Number.isInteger(cls) && cls >= 1 && cls <= 8 ? cls : null,
      notes: String(form.get("notes") ?? "").trim().slice(0, 1000),
    });
    if (error) return { error: friendlyError(error) };
  }
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: id ? "Saved." : "Budget added." };
}

export async function endFunding(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_funding").update({ status: "ended" }).eq("id", id).eq("client_id", clientId);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (update 124, Stage 6): Allied Health practitioner access. The
// database checks who may give it, the 12-month limit and the consent date.
const SECTIONS = ["details", "alerts", "care_plan", "documents", "notes"];
export async function givePractitionerAccess(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const endsOn = String(form.get("ends_on") ?? "");
  const consentOn = String(form.get("consent_on") ?? "");
  const consentDoc = String(form.get("consent_document_id") ?? "");
  const sections = form.getAll("sections").map(String).filter((s) => SECTIONS.includes(s));
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  if (!isId(userId)) return { error: "Choose the practitioner." };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(endsOn)) return { error: "Choose when access ends." };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(consentOn)) return { error: "Record the date the client (or their representative) agreed." };
  const { error } = await (await createClient()).from("client_external_access").insert({
    client_id: clientId,
    user_id: userId,
    sections,
    ends_on: endsOn,
    consent_on: consentOn,
    consent_note: String(form.get("consent_note") ?? "").trim().slice(0, 500),
    consent_document_id: isId(consentDoc) ? consentDoc : null,
    reason: String(form.get("reason") ?? "").trim().slice(0, 500),
  });
  if (error) return { error: error.message.includes("client_external_access_one_open") ? "That practitioner already has access. Extend it instead." : friendlyError(error) };
  await createAdminClient().rpc("run_practitioner_alerts");
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Access given. The practitioner has been told." };
}

export async function extendPractitionerAccess(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  const endsOn = String(form.get("ends_on") ?? "");
  const sections = form.getAll("sections").map(String).filter((s) => SECTIONS.includes(s));
  if (!isId(id) || !isId(clientId) || !/^\d{4}-\d{2}-\d{2}$/.test(endsOn)) return { error: "Choose the new end date." };
  const { error } = await (await createClient()).from("client_external_access").update({ ends_on: endsOn, sections }).eq("id", id);
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Saved." };
}

export async function endPractitionerAccess(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_external_access").update({ ended_at: new Date().toISOString() }).eq("id", id);
  revalidatePath(`/settings/clients/${clientId}`);
}

export async function shareWithPractitioners(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_documents").update({ shared_with_practitioners: form.get("shared") === "1" }).eq("id", id);
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (update 143): approved services. A service comes from the
// catalogue (name and description copied) or is added for this client only
// (its own name, description and shift types). The database checks who may,
// the program, readiness, duplicates and the shift types.
function serviceDetails(form: FormData) {
  const date = (k: string) => (/^\d{4}-\d{2}-\d{2}$/.test(String(form.get(k) ?? "")) ? String(form.get(k)) : null);
  const status = String(form.get("status") ?? "planned");
  return {
    program_id: isId(String(form.get("program_id") ?? "")) ? String(form.get("program_id")) : null,
    location_id: isId(String(form.get("location_id") ?? "")) ? String(form.get("location_id")) : null,
    start_date: date("start_date"),
    end_date: date("end_date"),
    status: ["planned", "active", "on_hold", "ended"].includes(status) ? status : "planned",
    scheduling_notes: String(form.get("scheduling_notes") ?? "").trim().slice(0, 1000),
    consent_required: form.get("consent_required") === "on",
    consent_given_on: date("consent_given_on"),
    consent_note: String(form.get("consent_note") ?? "").trim().slice(0, 500),
  };
}
const customDetails = (form: FormData) => ({
  label: String(form.get("label") ?? "").trim().slice(0, 80),
  description: String(form.get("description") ?? "").trim().slice(0, 1000),
  shift_types: [...new Set(form.getAll("shift_types").map(String).filter((k) => /^[a-z][a-z0-9_]{1,40}$/.test(k)))],
});

export async function addClientService(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  const details = serviceDetails(form);
  if (!details.program_id) return { error: "Choose the program." };
  if (!details.location_id) return { error: "Choose where the service is delivered." };
  if (!details.start_date) return { error: "Choose the start date." };
  if (details.end_date && details.end_date < details.start_date) return { error: "The end date is before the start date." };
  const catalogueId = String(form.get("catalogue_id") ?? "");
  let row: Record<string, unknown>;
  if (form.get("mode") === "custom") {
    const c = customDetails(form);
    if (!c.label) return { error: "Give the service a name." };
    if (!c.description) return { error: "Describe the service." };
    if (!c.shift_types.length) return { error: "Choose the shift types this service covers." };
    row = { ...details, ...c, origin: "custom", client_id: clientId };
  } else {
    if (!isId(catalogueId)) return { error: "Choose a service from the catalogue." };
    row = { ...details, catalogue_id: catalogueId, label: "From the catalogue", client_id: clientId };
  }
  const { error } = await (await createClient()).from("client_services").insert(row);
  if (error) return { error: error.code === "23505" ? "This client already has that service under that program." : friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Service added." };
}

export async function updateClientService(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  if (!isId(clientId) || !isId(id)) return { error: "That didn't save. Please reload the page." };
  const details = serviceDetails(form);
  if (!details.program_id || !details.location_id || !details.start_date) return { error: "Fill in the program, location and start date." };
  if (details.end_date && details.end_date < details.start_date) return { error: "The end date is before the start date." };
  // Custom and older services: their own name, description and shift types can be corrected (logged).
  const own: Partial<ReturnType<typeof customDetails>> = form.get("origin") === "catalogue" ? {} : customDetails(form);
  if ("label" in own && !own.label) return { error: "Give the service a name." };
  if (form.get("origin") === "custom" && own.shift_types && !own.shift_types.length) return { error: "Choose the shift types this service covers." };
  const { error } = await (await createClient()).from("client_services").update({ ...details, ...own }).eq("id", id).eq("client_id", clientId);
  if (error) return { error: error.code === "23505" ? "This client already has that service under that program." : friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Saved." };
}

// Manager Administrators: copy a custom service into the catalogue. The client's service stays as it was.
export async function promoteClientService(form: FormData) {
  const { profile } = await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  const supabase = await createClient();
  const { data: ma } = await supabase.rpc("is_manager_admin");
  if (profile.role !== "system_admin" && ma !== true) return;
  const { data: s } = await supabase.from("client_services").select("label, description, shift_types, origin").eq("id", id).maybeSingle();
  if (!s || s.origin !== "custom") return;
  await supabase.from("service_catalogue").insert({ name: s.label, description: s.description, shift_types: s.shift_types, promoted_from: id });
  revalidatePath(`/settings/clients/${clientId}`);
}

// cmeprojects (update 147): the communication log. The database checks who
// may write it, keeps the author, and keeps entries as written after 24 hours.
const METHODS = ["phone", "sms", "email", "meeting", "video", "letter", "other"];
export async function addCommunication(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  const method = String(form.get("method") ?? "");
  const summary = String(form.get("summary") ?? "").trim().slice(0, 2000);
  if (!METHODS.includes(method)) return { error: "Choose how it happened." };
  if (!summary) return { error: "Write a short summary." };
  const at = String(form.get("happened_at") ?? "");
  const followBy = String(form.get("follow_up_by") ?? "");
  const { error } = await (await createClient()).from("client_communications").insert({
    client_id: clientId,
    method,
    direction: form.get("direction") === "in" ? "in" : "out",
    with_whom: String(form.get("with_whom") ?? "").trim().slice(0, 120),
    summary,
    follow_up: String(form.get("follow_up") ?? "").trim().slice(0, 500),
    follow_up_by: /^\d{4}-\d{2}-\d{2}$/.test(followBy) ? followBy : null,
    ...(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(at) ? { happened_at: sydneyLocalToIso(at) } : {}),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  revalidatePath("/settings/clients");
  return { message: "Added to the communication log." };
}

export async function setFollowUpDone(form: FormData) {
  await requireClients();
  const id = String(form.get("id") ?? "");
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(id) || !isId(clientId)) return;
  await (await createClient()).from("client_communications").update({ follow_up_done_at: form.get("done") === "1" ? new Date().toISOString() : null }).eq("id", id).eq("client_id", clientId);
  revalidatePath(`/settings/clients/${clientId}`);
  revalidatePath("/settings/clients");
}

// cmeprojects: the "To check" checklist's last step. Makes the client active,
// then each pending service that's ready and has started (the database checks
// every one). Says what couldn't be made active and why.
export async function makeClientActive(form: FormData) {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return;
  const supabase = await createClient();
  const { error } = await supabase.from("car_clients").update({ status: "active" }).eq("id", clientId).eq("status", "pending");
  if (!error) {
    const today = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
    const { data: pending } = await supabase.from("client_services").select("id").eq("client_id", clientId).eq("status", "planned").lte("start_date", today);
    for (const s of (pending ?? []) as { id: string }[]) await supabase.from("client_services").update({ status: "active" }).eq("id", s.id);
  }
  revalidatePath(`/settings/clients/${clientId}`);
  revalidatePath("/settings/clients");
}

// cmeprojects (update 158): a client's programs (enrolments). Add, pause,
// resume, end and make main. The database checks who may, and the rules
// (one open enrolment per program, nothing ends while services, agreements or
// budgets are open, "Funded by" follows the main program), and records each change.
const isDay = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v);
const sydToday = () => new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
function enrolmentDone(clientId: string) {
  revalidatePath(`/settings/clients/${clientId}`);
  revalidatePath("/settings/clients");
}

export async function addEnrolment(_: FormState, form: FormData): Promise<FormState> {
  await requireClients();
  const clientId = String(form.get("client_id") ?? "");
  const programId = String(form.get("program_id") ?? "");
  const startsOn = String(form.get("starts_on") ?? "") || sydToday();
  if (!isId(clientId)) return { error: "That didn't save. Please reload the page." };
  if (!isId(programId)) return { error: "Choose a program." };
  if (!isDay(startsOn)) return { error: "Choose the start date." };
  const supabase = await createClient();
  // The ID the program's scheme needs (saved on their details, as before).
  const { data: prog } = await supabase.from("client_programs").select("scheme").eq("id", programId).maybeSingle();
  const scheme = (prog as { scheme?: string } | null)?.scheme ?? "";
  const ndis = String(form.get("ndis_number") ?? "").replace(/\s/g, "");
  const mac = String(form.get("aged_care_id") ?? "").replace(/\s/g, "").toUpperCase();
  if (scheme === "ndis" && ndis && !/^\d{9}$/.test(ndis)) return { error: "Enter their NDIS number (9 digits)." };
  if (MAC_SCHEMES_158.includes(scheme) && mac && !/^AC\d{8}$/.test(mac)) return { error: "Enter their My Aged Care ID (AC followed by 8 numbers, for example AC12345678)." };
  const { error } = await supabase.from("client_enrolments").insert({ client_id: clientId, program_id: programId, starts_on: startsOn });
  if (error) return { error: friendlyError(error) };
  const idPatch: Record<string, string> = {};
  if (scheme === "ndis" && ndis) idPatch.ndis_number = ndis;
  if (MAC_SCHEMES_158.includes(scheme) && mac) idPatch.aged_care_id = mac;
  if (Object.keys(idPatch).length) {
    const { error: dError } = await supabase.from("client_details").update(idPatch).eq("client_id", clientId);
    if (dError) {
      enrolmentDone(clientId);
      return { error: `The program was added, but the ID wasn't saved: ${friendlyError(dError)}` };
    }
  }
  enrolmentDone(clientId);
  return { message: "Program added." };
}
const MAC_SCHEMES_158 = ["support_at_home", "chsp"];

async function changeEnrolment(id: string, patch: Record<string, unknown>, done: string): Promise<FormState> {
  await requireClients();
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("client_enrolments").update(patch).eq("id", id).select("client_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this client's programs." };
  enrolmentDone((data[0] as { client_id: string }).client_id);
  return { message: done };
}

export async function pauseEnrolment(_: FormState, form: FormData): Promise<FormState> {
  const from = String(form.get("paused_from") ?? "");
  const until = String(form.get("paused_until") ?? "");
  if (!isDay(from)) return { error: "Choose when the pause starts." };
  if (until && !isDay(until)) return { error: "Choose a valid expected return date." };
  return changeEnrolment(String(form.get("id") ?? ""), { status: "paused", paused_from: from, paused_until: until || null, pause_reason: String(form.get("pause_reason") ?? "").trim().slice(0, 300) }, "Program paused.");
}

export async function resumeEnrolment(id: string): Promise<FormState> {
  return changeEnrolment(id, { status: "active" }, "Program resumed.");
}

export async function makeMainEnrolment(id: string): Promise<FormState> {
  return changeEnrolment(id, { is_main: true }, "Main program changed.");
}

export async function endEnrolment(_: FormState, form: FormData): Promise<FormState> {
  const endsOn = String(form.get("ends_on") ?? "");
  const reason = String(form.get("end_reason") ?? "").trim().slice(0, 300);
  if (!isDay(endsOn)) return { error: "Choose the end date." };
  if (!reason) return { error: "Say why this program is ending." };
  return changeEnrolment(String(form.get("id") ?? ""), { status: "ended", ends_on: endsOn, end_reason: reason }, "Program ended.");
}

export type OpenItem = { kind: "service" | "agreement" | "budget" | "review"; label: string; href: string };

// What would stop a program ending on a date (reviews are shown, but don't stop it).
export async function enrolmentOpenItems(id: string, endsOn: string): Promise<{ items: OpenItem[]; error?: string }> {
  await requireClients();
  if (!isId(id) || !isDay(endsOn)) return { items: [], error: "Choose the end date." };
  const supabase = await createClient();
  const { data: e } = await supabase.from("client_enrolments").select("client_id, program_id").eq("id", id).maybeSingle();
  if (!e) return { items: [], error: "You can't see this program." };
  const { client_id: clientId, program_id: programId } = e as { client_id: string; program_id: string };
  const { data: svcs } = await supabase.from("client_services").select("id, label, status, end_date").eq("client_id", clientId).eq("program_id", programId);
  const services = (svcs ?? []) as { id: string; label: string; status: string; end_date: string | null }[];
  const ids = services.map((s) => s.id);
  const name = new Map(services.map((s) => [s.id, s.label]));
  const [ag, fu, rv] = ids.length
    ? await Promise.all([
        supabase.from("client_agreements").select("service_id").in("service_id", ids).neq("status", "ended"),
        supabase.from("client_funding").select("service_id, period_end").in("service_id", ids).eq("status", "active"),
        supabase.from("client_reviews").select("service_id, due_on").in("service_id", ids).eq("status", "open"),
      ])
    : [{ data: [] }, { data: [] }, { data: [] }];
  const base = `/settings/clients/${clientId}`;
  const items: OpenItem[] = [
    ...services.filter((s) => s.status !== "ended" && (!s.end_date || s.end_date > endsOn)).map((s) => ({ kind: "service" as const, label: s.label, href: `${base}?tab=services#services` })),
    ...((ag.data ?? []) as { service_id: string }[]).map((a) => ({ kind: "agreement" as const, label: `Agreement for ${name.get(a.service_id) ?? "a service"}`, href: `${base}?tab=agreements` })),
    ...((fu.data ?? []) as { service_id: string; period_end: string | null }[]).filter((f) => !f.period_end || f.period_end > endsOn).map((f) => ({ kind: "budget" as const, label: `Budget for ${name.get(f.service_id) ?? "a service"}`, href: `${base}?tab=funding` })),
    ...((rv.data ?? []) as { service_id: string; due_on: string }[]).map((r) => ({ kind: "review" as const, label: `Review for ${name.get(r.service_id) ?? "a service"}, due ${r.due_on.split("-").reverse().join("/")}`, href: `${base}?tab=reviews` })),
  ];
  return { items };
}

// Shifts already rostered in a pause (listed so they can be cancelled on the roster; never changed here).
export async function shiftsInPause(id: string, from: string, until: string): Promise<{ count: number; first?: string }> {
  await requireClients();
  if (!isId(id) || !isDay(from) || (until && !isDay(until))) return { count: 0 };
  const supabase = await createClient();
  const { data: e } = await supabase.from("client_enrolments").select("client_id, program_id").eq("id", id).maybeSingle();
  if (!e) return { count: 0 };
  const { client_id: clientId, program_id: programId } = e as { client_id: string; program_id: string };
  const { data: svcs } = await supabase.from("client_services").select("id").eq("client_id", clientId).eq("program_id", programId);
  const ids = ((svcs ?? []) as { id: string }[]).map((s) => s.id);
  if (!ids.length) return { count: 0 };
  let q = supabase.from("shifts").select("starts_at").in("service_id", ids).neq("status", "cancelled").gte("starts_at", sydneyInstant(from, "00:00")).order("starts_at");
  if (until) q = q.lte("starts_at", sydneyInstant(until, "23:59"));
  const { data } = await q;
  const rows = (data ?? []) as { starts_at: string }[];
  return { count: rows.length, first: rows[0] ? new Date(rows[0].starts_at).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney" }) : undefined };
}

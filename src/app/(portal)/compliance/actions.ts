// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { canManageCompliance, getPeopleRules } from "@/lib/settings";
import { friendlyError } from "@/lib/db-error";
import { isRole } from "@/lib/roles";
import { text, type FormState } from "@/lib/form";

async function requireComplianceManager() {
  const session = await requireSession();
  if (!canManageCompliance(session.profile.role, await getPeopleRules())) {
    throw new Error("Only people who manage Compliance can do this");
  }
  return session;
}

export async function saveItem(_: FormState, form: FormData): Promise<FormState> {
  await requireComplianceManager();
  const id = text(form, "id");
  const kind = text(form, "kind");
  if (!["read", "training", "upload", "agreement"].includes(kind)) return { error: "Choose what kind of item this is." };
  const title = text(form, "title");
  if (!title) return { error: "Give it a title." };
  const link = text(form, "link_url");
  if (link && !/^https?:\/\//i.test(link)) return { error: "Links start with https://" };

  const values: Record<string, unknown> = {
    kind,
    title,
    description: text(form, "description"),
    body: text(form, "body"),
    link_url: link,
    needs_expiry: form.get("needs_expiry") === "on",
    active: id ? form.get("active") === "on" : true,
    applies_roles: form.getAll("applies_roles").map(String).filter(isRole),
    applies_teams: form.getAll("applies_teams").map(String),
    sort_order: Number(text(form, "sort_order")) || 0,
    // cmeprojects (update 58): needed before working, document details, job titles.
    before_work: form.get("before_work") === "on",
    applies_titles: form.getAll("applies_titles").map(String).filter((t) => /^[0-9a-f-]{36}$/.test(t)),
  };
  if (kind === "upload") {
    values.category = ["qualification", "certificate", "screening", "licence", "insurance", "identity", "other"].includes(text(form, "category")) ? text(form, "category") : "";
    values.needs_issue_date = form.get("needs_issue_date") === "on";
    values.needs_number = form.get("needs_number") === "on";
  }
  if (kind === "training") {
    values.certificate = ["none", "optional", "required"].includes(text(form, "certificate")) ? text(form, "certificate") : "optional";
    values.needs_expiry = form.get("needs_expiry") === "on";
  }
  const filePath = text(form, "file_path");
  if (filePath) {
    values.file_path = filePath;
    values.file_name = text(form, "file_name");
  }
  if (form.get("remove_file") === "on") {
    values.file_path = null;
    values.file_name = null;
  }

  const supabase = await createClient();
  if (id) {
    if (form.get("new_version") === "on") {
      const { data: current } = await supabase.from("compliance_items").select("version").eq("id", id).single();
      values.version = (current?.version ?? 1) + 1;
    }
    const { data, error } = await supabase.from("compliance_items").update(values).eq("id", id).select("id");
    if (error) return { error: friendlyError(error) };
    if (!data?.length) return { error: "You don't have permission to change this." };
  } else {
    const { error } = await supabase.from("compliance_items").insert(values);
    if (error) return { error: friendlyError(error) };
  }
  revalidatePath("/compliance");
  revalidatePath("/onboarding");
  return { message: id ? (values.version ? "Saved. Everyone it applies to will be asked to confirm again." : "Saved.") : `"${title}" added. Everyone it applies to has been told.` };
}

export async function reviewUpload(_: FormState, form: FormData): Promise<FormState> {
  await requireComplianceManager();
  const decision = text(form, "decision");
  const accept = decision === "accept";
  const supabase = await createClient();
  // cmeprojects: ask for a new copy (keeps the old one in the history).
  if (decision === "replace") {
    const { error } = await supabase.rpc("request_replacement", { p_record_id: Number(text(form, "record_id")), p_note: text(form, "note") });
    if (error) return { error: friendlyError(error) };
    revalidatePath("/compliance", "layout");
    return { message: "They've been asked to upload a new copy." };
  }
  const { error } = await supabase.rpc("review_compliance_upload", {
    p_record_id: Number(text(form, "record_id")),
    p_accept: accept,
    p_note: text(form, "note"),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/compliance", "layout");
  return { message: accept ? "Marked as checked." : "Sent back. They've been asked to upload it again." };
}

// A staff admin or manager uploads a document for someone.
export async function uploadForPerson(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const path = text(form, "file_path");
  if (!path) return { error: "Choose a file and wait for it to upload." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("submit_compliance_upload_for", {
    p_user_id: text(form, "user_id"),
    p_item_id: text(form, "item_id"),
    p_path: path,
    p_name: text(form, "file_name"),
    p_expires: text(form, "expires_on") || null,
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/compliance", "layout");
  return { message: "Uploaded. They've been told." };
}

// cmeprojects (update 58): clearance to work and overrides. The database
// decides who may (managers, or staff admins when delegated).
export async function changeClearance(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const user = text(form, "user_id");
  const op = text(form, "op");
  const supabase = await createClient();
  const { error } =
    op === "grant"
      ? await supabase.rpc("grant_clearance", { p_user: user, p_note: text(form, "note") })
      : op === "revoke"
        ? await supabase.rpc("revoke_clearance", { p_user: user, p_reason: text(form, "note") })
        : op === "override"
          ? await supabase.rpc("grant_work_override", { p_user: user, p_reason: text(form, "note"), p_until: text(form, "until") || null })
          : await supabase.rpc("end_work_override", { p_id: Number(text(form, "override_id")) });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/compliance", "layout");
  revalidatePath("/people");
  return {
    message:
      op === "grant"
        ? "Cleared to work. They've been told, and anything left is a Finish onboarding task due within a week."
        : op === "revoke"
          ? "Clearance removed."
          : op === "override"
            ? "Override given. They can work until the end date."
            : "Override ended.",
  };
}

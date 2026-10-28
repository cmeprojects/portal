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
  if (!["read", "training", "upload"].includes(kind)) return { error: "Choose what kind of item this is." };
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
  };
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
  const accept = text(form, "decision") === "accept";
  const supabase = await createClient();
  const { error } = await supabase.rpc("review_compliance_upload", {
    p_record_id: Number(text(form, "record_id")),
    p_accept: accept,
    p_note: text(form, "note"),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/compliance", "layout");
  return { message: accept ? "Marked as checked." : "Sent back. They've been asked to upload it again." };
}

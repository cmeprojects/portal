// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireTaskAccess } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { CHOICE_COLOURS, FIELD_TYPES, keyFromLabel, type ChoiceColour, type FieldType } from "@/lib/registers";
import { text, type FormState } from "@/lib/form";
import { slaFromForm } from "@/lib/tasks";

const PREFIX = /^[A-Z0-9]{2,6}$/;
const on = (form: FormData, name: string) => form.get(name) === "on";

function options(form: FormData): string[] {
  return [...new Set(text(form, "options").split(/\r?\n/).map((o) => o.trim()).filter(Boolean))].slice(0, 100);
}

// Colours chosen for each choice (inputs named colour::<choice>).
function colours(form: FormData, opts: string[]): Record<string, ChoiceColour> {
  const out: Record<string, ChoiceColour> = {};
  for (const o of opts) {
    const c = form.get(`colour::${o}`);
    if (typeof c === "string" && (CHOICE_COLOURS as readonly string[]).includes(c)) out[o] = c as ChoiceColour;
  }
  return out;
}

function refresh(id: string) {
  revalidatePath(`/registers/${id}`);
  revalidatePath(`/registers/${id}/setup`);
  revalidatePath("/registers");
}

export async function createRegistry(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireTaskAccess();
  if (!["manager", "system_admin"].includes(profile.role)) return { error: "Only managers and the system admin can create registers." };
  const name = text(form, "name");
  const prefix = text(form, "prefix").toUpperCase();
  const kind = text(form, "kind") === "records" ? "records" : "tasks";
  if (!name) return { error: "Give the register a name." };
  if (prefix && !PREFIX.test(prefix)) return { error: "The prefix should be 2 to 6 letters or numbers, like RSK." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("registries")
    .insert({
      name,
      description: text(form, "description"),
      kind,
      prefix: prefix || null,
      requires_approval: kind === "tasks" && on(form, "requires_approval"),
      title_label: kind === "records" ? "Name" : "Title",
      sort_order: 500,
    })
    .select("id")
    .single();
  if (error || !data) return { error: friendlyError(error, "We couldn't create the register.") };
  revalidatePath("/registers");
  redirect(`/registers/${data.id}/setup?created=1`);
}

export async function saveRegistrySettings(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const id = text(form, "id");
  const name = text(form, "name");
  const prefix = text(form, "prefix").toUpperCase();
  if (!name) return { error: "Give the register a name." };
  if (!PREFIX.test(prefix)) return { error: "The prefix should be 2 to 6 letters or numbers, like RSK." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("registries")
    .update({
      name,
      prefix,
      description: text(form, "description"),
      title_label: text(form, "title_label") || "Title",
      description_label: text(form, "description_label") || "Description",
      requires_approval: on(form, "requires_approval"),
      show_due_date: on(form, "show_due_date"),
      show_review_date: on(form, "show_review_date"),
      review_label: text(form, "review_label") || "Next review date",
      show_outcome: on(form, "show_outcome"),
      outcome_required: on(form, "show_outcome") && on(form, "outcome_required"),
      outcome_label: text(form, "outcome_label") || "Outcome / actions taken",
      active: on(form, "active"),
      // Blank everywhere = use the company's SLA.
      sla_days: Object.keys(slaFromForm(form, "rsla_")).length ? slaFromForm(form, "rsla_") : null,
    })
    .eq("id", id)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can only change registers you manage." };
  refresh(id);
  return { message: "Saved." };
}

export async function saveManagers(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const id = text(form, "id");
  const managers = form.getAll("managers").map(String);
  const supabase = await createClient();
  const { data: current } = await supabase.from("registry_managers").select("user_id").eq("registry_id", id);
  const now = (current ?? []).map((m) => m.user_id);
  const remove = now.filter((u) => !managers.includes(u));
  const add = managers.filter((u) => !now.includes(u));
  // Add first, so a manager removing themselves still leaves someone in charge.
  if (add.length) {
    const { error } = await supabase.from("registry_managers").insert(add.map((user_id) => ({ registry_id: id, user_id })));
    if (error) return { error: friendlyError(error) };
  }
  if (remove.length) {
    const { error } = await supabase.from("registry_managers").delete().eq("registry_id", id).in("user_id", remove);
    if (error) return { error: friendlyError(error) };
  }
  refresh(id);
  return { message: "Managers saved." };
}

export async function addField(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const registryId = text(form, "registry_id");
  const label = text(form, "label");
  const type = text(form, "type") as FieldType;
  if (!label) return { error: "Give the field a label." };
  if (!FIELD_TYPES.includes(type)) return { error: "Choose a type." };
  const opts = options(form);
  if ((type === "choice" || type === "multi_choice") && opts.length < 2) return { error: "Add at least two choices, one per line." };

  const supabase = await createClient();
  const { data: existing } = await supabase.from("registry_fields").select("key, sort_order").eq("registry_id", registryId);
  const taken = new Set((existing ?? []).map((f) => f.key));
  const base = keyFromLabel(label);
  let key = base;
  for (let n = 2; taken.has(key); n++) key = `${base.slice(0, 36)}_${n}`;
  const sort = Math.max(0, ...(existing ?? []).map((f) => f.sort_order)) + 10;

  const { error } = await supabase.from("registry_fields").insert({
    registry_id: registryId,
    key,
    label,
    type,
    required: on(form, "required"),
    options: opts,
    help: text(form, "help"),
    sort_order: sort,
  });
  if (error) return { error: friendlyError(error, "We couldn't add the field. Check you manage this register.") };
  refresh(registryId);
  return { message: `Added "${label}".` };
}

export async function updateField(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const id = text(form, "id");
  const registryId = text(form, "registry_id");
  const label = text(form, "label");
  const type = text(form, "type") as FieldType;
  if (!label) return { error: "Give the field a label." };
  if (!FIELD_TYPES.includes(type)) return { error: "Choose a type." };
  const opts = options(form);
  if ((type === "choice" || type === "multi_choice") && opts.length < 2) return { error: "Add at least two choices, one per line." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("registry_fields")
    .update({
      label,
      type,
      required: on(form, "required"),
      options: opts,
      option_colors: type === "choice" ? colours(form, opts) : {},
      help: text(form, "help"),
      active: on(form, "active"),
    })
    .eq("id", id)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can only change fields of registers you manage." };
  refresh(registryId);
  return { message: "Saved." };
}

export async function moveField(form: FormData) {
  await requireTaskAccess();
  const id = text(form, "id");
  const registryId = text(form, "registry_id");
  const dir = text(form, "dir") === "up" ? -1 : 1;
  const supabase = await createClient();
  const { data: list } = await supabase.from("registry_fields").select("id, sort_order").eq("registry_id", registryId).order("sort_order");
  const fields = list ?? [];
  const i = fields.findIndex((f) => f.id === id);
  const j = i + dir;
  if (i < 0 || j < 0 || j >= fields.length) return;
  // Renumber so every field has its own position, then swap the two.
  const order = fields.map((f) => f.id);
  [order[i], order[j]] = [order[j], order[i]];
  for (const [n, fid] of order.entries()) {
    await supabase.from("registry_fields").update({ sort_order: (n + 1) * 10 }).eq("id", fid);
  }
  refresh(registryId);
}

// Quick switch on the Registers page: do tasks in this register need a manager's approval to close?
export async function setRegistryApproval(form: FormData) {
  const { profile } = await requireTaskAccess();
  if (!["manager", "system_admin"].includes(profile.role)) return;
  const id = text(form, "id");
  const supabase = await createClient();
  await supabase.from("registries").update({ requires_approval: text(form, "on") === "true" }).eq("id", id).eq("kind", "tasks");
  refresh(id);
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import type { Answers } from "@/lib/feature-types";

export type TodayRow = { id: number; created_at: string; data: Record<string, unknown>; by_name: string; mine: boolean };
export type SaveResult =
  | { ok: true; entryId: number; clientId: string; today: TodayRow[]; savedAt: string; data: Record<string, unknown> }
  | { ok: false; error: string };

// Save an entry; the database checks every answer and records who and when.
export async function submitEntry(featureId: string, data: Answers): Promise<SaveResult> {
  await requireSession();
  const supabase = await createClient();
  const { data: id, error } = await supabase.rpc("submit_custom_entry", { p_feature: featureId, p_data: data });
  if (error) return { ok: false, error: friendlyError(error) };
  const { data: entry } = await supabase.from("custom_entries").select("client_id, created_at, data").eq("id", id).single();
  const clientId = entry?.client_id ?? "";
  const { data: today } = clientId
    ? await supabase.rpc("custom_client_today", { p_feature: featureId, p_client: clientId })
    : { data: [] };
  revalidatePath("/f", "layout");
  return {
    ok: true,
    entryId: Number(id),
    clientId,
    today: (today ?? []) as TodayRow[],
    savedAt: entry?.created_at ?? new Date().toISOString(),
    data: (entry?.data ?? {}) as Record<string, unknown>,
  };
}

export async function undoEntry(id: number): Promise<{ error: string | null }> {
  await requireSession();
  const supabase = await createClient();
  const { error } = await supabase.rpc("undo_custom_entry", { p_id: id });
  revalidatePath("/f", "layout");
  return { error: error ? friendlyError(error) : null };
}

type Result = { error?: string; message?: string };

// Fix an entry after the undo time (managers when the feature allows it, and
// the system admin). The database checks the answers and keeps the old ones.
export async function fixEntry(id: number, data: Answers, reason: string): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  const { error } = await supabase.rpc("correct_custom_entry", { p_id: id, p_data: data, p_reason: reason });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/f", "layout");
  return { message: "Entry fixed. The change log keeps what it was." };
}

// The daily target for everyone and each client's own (blank = none).
export async function saveTargets(featureId: string, defaultTarget: number | null, targets: Record<string, number | null>): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  const { error } = await supabase.rpc("set_custom_targets", { p_feature: featureId, p_default: defaultTarget, p_targets: targets });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/f", "layout");
  revalidatePath("/system/builder", "layout");
  return { message: "Targets saved." };
}

export async function saveOptions(fieldId: string, options: string[]): Promise<Result> {
  await requireSession();
  const supabase = await createClient();
  const { error } = await supabase.rpc("set_custom_field_options", { p_field: fieldId, p_options: options });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/f", "layout");
  revalidatePath("/system/builder", "layout");
  return { message: "List saved." };
}

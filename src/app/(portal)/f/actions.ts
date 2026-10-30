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

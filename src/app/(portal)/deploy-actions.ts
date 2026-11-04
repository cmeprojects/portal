// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";

// cmeprojects: make saved settings live, or throw them away. The database
// decides whose drafts each person may deploy (the system admin: everyone's).

export async function deployDrafts(): Promise<{ error?: string; message?: string }> {
  await requireSession();
  const { data, error } = await (await createClient()).rpc("deploy_drafts");
  if (error) return { error: friendlyError(error) };
  revalidatePath("/", "layout");
  const n = Number(data ?? 0);
  return { message: n ? `Deployed: ${n} change${n === 1 ? " is" : "s are"} now live.` : "There was nothing to deploy." };
}

export async function discardDrafts(): Promise<{ error?: string; message?: string }> {
  await requireSession();
  const { data, error } = await (await createClient()).rpc("discard_drafts");
  if (error) return { error: friendlyError(error) };
  revalidatePath("/", "layout");
  const n = Number(data ?? 0);
  return { message: n ? `Discarded ${n} saved change${n === 1 ? "" : "s"}.` : "There was nothing to discard." };
}

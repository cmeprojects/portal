// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { isAccessArea, type Grant } from "@/lib/access";

const PAGE = "/settings/access";
const UUID = /^[0-9a-f-]{36}$/;

// cmeprojects: give someone access. The system admin gives first grants; a
// manager passes on their own (never wider). The database checks every rule.
export async function giveAccess(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole(["system_admin", "manager"]);
  const admin = profile.role === "system_admin";
  const area = String(form.get("area") ?? "");
  const userId = String(form.get("user_id") ?? "");
  const scope = String(form.get("scope") ?? "all");
  if (!isAccessArea(area)) return { error: "Choose what they can access." };
  if (!UUID.test(userId)) return { error: "Choose a person." };
  if (!["all", "teams", "people"].includes(scope)) return { error: "Choose who it covers." };
  const ids = scope === "teams" ? form.getAll("teams").map(String) : scope === "people" ? form.getAll("people").map(String) : [];
  if (ids.some((i) => !UUID.test(i))) return { error: "Something went wrong. Please refresh and try again." };
  if (scope !== "all" && !ids.length) return { error: scope === "teams" ? "Choose at least one team." : "Choose at least one person." };
  const expiry = String(form.get("expires") ?? "");
  if (expiry && !/^\d{4}-\d{2}-\d{2}$/.test(expiry)) return { error: "Choose a valid end date." };
  // Ends at the end of that day, Sydney time (daylight saving included).
  const expiresAt = expiry ? endOfDaySydney(expiry) : null;
  if (expiresAt && new Date(expiresAt) <= new Date()) return { error: "The end date must be in the future." };

  const supabase = await createClient();
  let parentId: string | null = null;
  if (!admin) {
    const { data: mine } = await supabase
      .from("access_grants")
      .select("id")
      .eq("user_id", profile.id)
      .eq("area", area)
      .eq("can_pass_on", true)
      .is("revoked_at", null)
      .maybeSingle();
    if (!mine) return { error: "You can't pass this access on." };
    parentId = mine.id;
  }

  // An expired grant for the same person and area is closed first.
  const { data: old } = await supabase.from("access_grants").select("id, expires_at").eq("user_id", userId).eq("area", area).is("revoked_at", null).maybeSingle();
  if (old) {
    if (!old.expires_at || new Date(old.expires_at) > new Date()) return { error: "They already have this access. Remove it first to change it." };
    await supabase.from("access_grants").update({ revoked_at: new Date().toISOString() }).eq("id", old.id);
  }

  const { error } = await supabase.from("access_grants").insert({
    area,
    user_id: userId,
    scope,
    scope_ids: ids,
    can_pass_on: admin && form.get("pass_on") === "on",
    can_reveal_tfn: area === "payroll_tax" && form.get("tfn") === "on",
    expires_at: expiresAt,
    parent_id: parentId,
    granted_by: profile.id,
    note: String(form.get("note") ?? "").trim().slice(0, 300),
  });
  if (error) {
    if (error.code === "42501") return { error: "That isn't allowed: you can only give access you have, to the people allowed, and never wider or longer." };
    return { error: friendlyError(error) };
  }
  revalidatePath(PAGE);
  return { message: "Access given. It works straight away." };
}

// Remove access (and anything passed on from it). It stays in the history.
export async function removeAccess(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin", "manager"]);
  const id = String(form.get("id") ?? "");
  if (!UUID.test(id)) return { error: "Something went wrong. Please refresh and try again." };
  const { data, error } = await (await createClient())
    .from("access_grants")
    .update({ revoked_at: new Date().toISOString() } satisfies Partial<Grant>)
    .eq("id", id)
    .is("revoked_at", null)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't remove this access, or it's already gone." };
  revalidatePath(PAGE);
  return { message: "Access removed. It stopped straight away." };
}

function endOfDaySydney(day: string): string {
  const probe = new Date(`${day}T12:00:00Z`);
  const offset =
    new Intl.DateTimeFormat("en-AU", { timeZone: "Australia/Sydney", timeZoneName: "longOffset" }).formatToParts(probe).find((p) => p.type === "timeZoneName")?.value.replace("GMT", "") || "+10:00";
  return new Date(`${day}T23:59:59${offset}`).toISOString();
}

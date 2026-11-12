// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { ACCESS_LABEL, isAccessArea, type Grant } from "@/lib/access";
import { createAdminClient } from "@/lib/supabase/admin";

const PAGE = "/settings/access";
const UUID = /^[0-9a-f-]{36}$/;

// Remove access (and anything passed on from it). It stays in the history.
export async function removeAccess(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole(["system_admin", "manager"]);
  const id = String(form.get("id") ?? "");
  if (!UUID.test(id)) return { error: "Something went wrong. Please refresh and try again." };
  const { data, error } = await (await createClient())
    .from("access_grants")
    .update({ revoked_at: new Date().toISOString() } satisfies Partial<Grant>)
    .eq("id", id)
    .is("revoked_at", null)
    .select("id, user_id, area");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't remove this access, or it's already gone." };
  const row = data[0] as { user_id: string; area: string };
  await createAdminClient().from("audit_log").insert({ actor_id: profile.id, action: "access_removed", entity: "profile", entity_id: row.user_id, details: { what: isAccessArea(row.area) ? ACCESS_LABEL[row.area] : row.area } });
  await createAdminClient().rpc("notify", {
    p_user: row.user_id,
    p_kind: "access",
    p_title: "Your access changed",
    p_body: `Removed: ${isAccessArea(row.area) ? ACCESS_LABEL[row.area] : row.area}.`,
    p_href: "/settings/access",
    p_email: true,
  });
  revalidatePath(PAGE);
  return { message: "Access removed. It stopped straight away." };
}

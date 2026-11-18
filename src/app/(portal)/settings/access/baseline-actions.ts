// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (Stage 3, update 94, D-047): grants held by a function group, a
// job title or an access level. The system admin sets any of them; a Manager
// Administrator sets groups and roles only, within what they may pass on, and
// changes only the grants they gave. A changed grant is revoked and given
// again (history kept). The database checks every rule
// (switched-over modules only, sensitive never to a group, and so on).
export type BaselineEntry = { module: string; effect: "allow" | "restrict"; actions: string[]; scope: "all" | "own_teams" | "assigned" | "programs" };
type Holder = { kind: "group" | "title" | "level"; id: string };

const UUID = /^[0-9a-f-]{36}$/;
const LEVELS = ["support_worker", "team_leader", "manager", "staff_admin"];

export async function saveBaselines(holder: Holder, entries: BaselineEntry[]): Promise<FormState> {
  const { profile } = await requireRole(["system_admin", "manager"]);
  const isAdmin = profile.role === "system_admin";
  if (!isAdmin && holder.kind === "level") return { error: "Only the system admin sets access-level defaults." };
  if (!["group", "title", "level"].includes(holder.kind) || (holder.kind === "level" ? !LEVELS.includes(holder.id) : !UUID.test(holder.id))) return { error: "Choose who it's for." };
  if (!Array.isArray(entries) || entries.length > 100) return { error: "Something went wrong. Please refresh and try again." };
  for (const e of entries) {
    if (!/^[a-z_]+(\.[a-z_]+)*$/.test(e.module) || !["allow", "restrict"].includes(e.effect) || !["all", "own_teams", "assigned", "programs"].includes(e.scope) || ((e.scope === "assigned" || e.scope === "programs") && (!e.module.startsWith("clients.") || e.module === "clients.assign")) || !Array.isArray(e.actions) || e.actions.some((a) => !/^[a-z_]+$/.test(a))) {
      return { error: "Something went wrong. Please refresh and try again." };
    }
  }
  const col = holder.kind === "group" ? "function_group_id" : holder.kind === "title" ? "job_title_id" : "access_level";
  const supabase = await createClient();
  if (!isAdmin) {
    const { data: ma } = await supabase.rpc("is_manager_admin");
    if (ma !== true) return { error: "You can't make this change." };
  }
  const { data: allLive, error: readError } = await supabase.from("access_baselines").select("id, module_id, effect, actions, scope, granted_by").eq(col, holder.id).is("revoked_at", null);
  if (readError) return { error: friendlyError(readError) };
  // A Manager Administrator works only with the grants they gave.
  const live = isAdmin ? allLive : (allLive ?? []).filter((r) => r.granted_by === profile.id);
  const taken = new Set((allLive ?? []).filter((r) => !live?.includes(r)).map((r) => r.module_id as string));
  if (entries.some((e) => taken.has(e.module))) return { error: "Someone else has already set one of these parts for them. Ask the system admin to change it." };
  const want = new Map(entries.map((e) => [e.module, e]));
  const same = (r: { effect: string; actions: string[]; scope: string }, e: BaselineEntry) => r.effect === e.effect && r.scope === e.scope && [...r.actions].sort().join() === [...e.actions].sort().join();
  const rows = (live ?? []) as { id: string; module_id: string; effect: string; actions: string[]; scope: string }[];
  const toRevoke = rows.filter((r) => !want.has(r.module_id) || !same(r, want.get(r.module_id)!));
  const toAdd = entries.filter((e) => { const r = rows.find((x) => x.module_id === e.module); return !r || !same(r, e); });
  if (!toRevoke.length && !toAdd.length) return { message: "Nothing changed." };
  if (toRevoke.length) {
    const { error } = await supabase.from("access_baselines").update({ revoked_at: new Date().toISOString() }).in("id", toRevoke.map((r) => r.id));
    if (error) return { error: friendlyError(error) };
  }
  if (toAdd.length) {
    const { error } = await supabase.from("access_baselines").insert(toAdd.map((e) => ({ [col]: holder.id, module_id: e.module, effect: e.effect, actions: e.actions, scope: e.scope })));
    if (error) return { error: friendlyError(error) };
  }
  await createAdminClient().from("audit_log").insert({
    actor_id: profile.id,
    action: "role_group_access_changed",
    entity: holder.kind === "group" ? "function_group" : holder.kind === "title" ? "job_title" : "access_level",
    entity_id: holder.id,
    details: { given: toAdd.map((e) => `${e.module} (${e.effect}${e.actions.length ? ": " + e.actions.join(", ") : ""}${e.scope === "own_teams" ? ", own teams" : e.scope === "programs" ? ", their programs" : e.scope === "assigned" ? ", assigned clients" : ""})`), removed: toRevoke.filter((r) => !want.has(r.module_id)).map((r) => r.module_id) },
  });
  revalidatePath("/settings/access");
  return { message: "Saved." };
}

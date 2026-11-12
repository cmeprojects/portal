// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

const PAGE = "/settings/access";
const UUID = /^[0-9a-f-]{36}$/;
const MODULE = /^[a-z_]+(\.[a-z_]+)*$/;

// cmeprojects: every access change is written to the change log, saying who
// did it, to whom and exactly what (the database has already allowed it).
async function log(actor: string, action: string, subject: string, details: Record<string, unknown>) {
  await createAdminClient().from("audit_log").insert({ actor_id: actor, action, entity: "profile", entity_id: subject, details });
}

function endOfDaySydney(day: string): string {
  const probe = new Date(`${day}T12:00:00Z`);
  const offset =
    new Intl.DateTimeFormat("en-AU", { timeZone: "Australia/Sydney", timeZoneName: "longOffset" }).formatToParts(probe).find((p) => p.type === "timeZoneName")?.value.replace("GMT", "") || "+10:00";
  return new Date(`${day}T23:59:59${offset}`).toISOString();
}

function endDate(form: FormData): { at: string | null; error?: string } {
  const v = String(form.get("expires") ?? "");
  if (!v) return { at: null };
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) return { at: null, error: "Choose a valid end date." };
  const at = endOfDaySydney(v);
  return new Date(at) <= new Date() ? { at: null, error: "The end date must be in the future." } : { at };
}

// Nominate a manager as a Manager Administrator (system admin only).
export async function nominateAdmin(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole(["system_admin"]);
  const userId = String(form.get("user_id") ?? "");
  if (!UUID.test(userId)) return { error: "Choose a manager." };
  const end = endDate(form);
  if (end.error) return { error: end.error };
  const note = String(form.get("note") ?? "").trim().slice(0, 300);
  const { error } = await (await createClient()).from("admin_designations").insert({ user_id: userId, granted_by: profile.id, expires_at: end.at, note });
  if (error) {
    if (error.code === "23505") return { error: "They're already a Manager Administrator." };
    if (error.code === "42501") return { error: "Only active managers can be nominated." };
    return { error: friendlyError(error) };
  }
  await log(profile.id, "admin_nominated", userId, { until: end.at, note });
  revalidatePath(PAGE);
  return { message: "Nominated. You can now give them admin access below." };
}

// Suspend, resume or end a nomination. Ending also removes their module access.
export async function changeNomination(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireRole(["system_admin"]);
  const id = String(form.get("id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!UUID.test(id) || !["active", "suspended", "ended"].includes(status)) return { error: "Something went wrong. Please refresh and try again." };
  const { data, error } = await (await createClient()).from("admin_designations").update({ status }).eq("id", id).neq("status", "ended").select("user_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "This nomination has already ended." };
  const action = status === "active" ? "admin_resumed" : status === "suspended" ? "admin_suspended" : "admin_ended";
  await log(profile.id, action, data[0].user_id, {});
  revalidatePath(PAGE);
  return {
    message:
      status === "active" ? "Resumed. Their admin access works again." : status === "suspended" ? "Suspended. Their admin access (and what they passed on) stopped straight away." : "Ended. Their admin access was removed.",
  };
}

export type ModuleEntry = { module: string; effect: "allow" | "restrict"; actions: string[] };
export type SaveModuleAccess = { userId: string; entries: ModuleEntry[]; scope: "all" | "teams"; teams: string[]; expires: string; passOn: boolean; note: string };

type Live = { id: string; module_id: string; effect: string; actions: string[]; scope: string; scope_ids: string[]; expires_at: string | null; can_pass_on: boolean; granted_by: string | null };

// Save one person's module access: what changed is closed and given again
// (old grants stay in the history), what was taken off is removed.
export async function saveModuleAccess(input: SaveModuleAccess): Promise<FormState> {
  const { profile } = await requireRole(["system_admin", "manager"]);
  const admin = profile.role === "system_admin";
  if (!UUID.test(input.userId)) return { error: "Choose a person." };
  if (!Array.isArray(input.entries) || input.entries.length > 200) return { error: "Something went wrong. Please refresh and try again." };
  for (const e of input.entries) {
    if (!MODULE.test(e.module) || !["allow", "restrict"].includes(e.effect) || !Array.isArray(e.actions) || e.actions.some((a) => !/^[a-z_]+$/.test(a))) {
      return { error: "Something went wrong. Please refresh and try again." };
    }
    if (!admin && e.effect === "restrict") return { error: "Only the system admin can block parts." };
  }
  const scope = input.scope === "teams" ? "teams" : "all";
  const teams = scope === "teams" ? input.teams.filter((t) => UUID.test(t)) : [];
  if (scope === "teams" && !teams.length) return { error: "Choose at least one team." };
  const form = new FormData();
  form.set("expires", input.expires ?? "");
  const end = endDate(form);
  if (end.error) return { error: end.error };
  const passOn = admin && Boolean(input.passOn);
  const note = String(input.note ?? "").trim().slice(0, 300);

  const supabase = await createClient();
  const [{ data: theirs }, { data: mine }, { data: mods }] = await Promise.all([
    supabase.from("access_grants").select("id, module_id, effect, actions, scope, scope_ids, expires_at, can_pass_on, granted_by").eq("user_id", input.userId).is("area", null).is("revoked_at", null),
    admin
      ? Promise.resolve({ data: [] as Live[] })
      : supabase.from("access_grants").select("id, module_id, effect, actions, scope, scope_ids, expires_at, can_pass_on, granted_by").eq("user_id", profile.id).is("area", null).is("revoked_at", null).eq("can_pass_on", true),
    supabase.from("app_modules").select("id, parent_id, category, label, sensitivity, actions"),
  ]);
  const byId = new Map((mods ?? []).map((m) => [m.id as string, m]));
  const labelOf = (id: string) => byId.get(id)?.label ?? id;
  const current = ((theirs ?? []) as Live[]).filter((g) => admin || g.granted_by === profile.id);
  const others = ((theirs ?? []) as Live[]).filter((g) => !current.includes(g));

  // Which of my pass-on grants covers a module (nearest first).
  const parentFor = (module: string): string | null => {
    const m = byId.get(module);
    if (!m) return null;
    const chain: string[] = [module];
    if (m.sensitivity === "normal") {
      let p = m.parent_id as string | null;
      while (p) {
        chain.push(p);
        p = (byId.get(p)?.parent_id as string | null) ?? null;
      }
      chain.push(`cat_${m.category}`);
    }
    for (const c of chain) {
      const g = ((mine ?? []) as Live[]).find((x) => x.module_id === c && x.effect === "allow");
      if (g) return g.id;
    }
    return null;
  };

  const same = (g: Live, e: ModuleEntry) =>
    g.effect === e.effect &&
    [...g.actions].sort().join() === [...e.actions].sort().join() &&
    g.scope === scope &&
    [...g.scope_ids].sort().join() === [...teams].sort().join() &&
    (g.expires_at ? new Date(g.expires_at).getTime() : 0) === (end.at ? new Date(end.at).getTime() : 0) &&
    g.can_pass_on === passOn;

  // Passing on: "everything" means everything they hold (their actions, if limited).
  if (!admin) {
    for (const e of input.entries) {
      const parent = parentFor(e.module);
      if (!parent) return { error: `You can't pass on ${labelOf(e.module)}.` };
      const held = ((mine ?? []) as Live[]).find((g) => g.id === parent)?.actions ?? [];
      if (held.length) {
        const own = (byId.get(e.module)?.actions as string[] | undefined) ?? [];
        e.actions = (e.actions.length ? e.actions : own).filter((a) => held.includes(a));
        if (!e.actions.length) return { error: `You can't pass on any of ${labelOf(e.module)}'s actions.` };
      }
    }
  }
  const wanted = new Map(input.entries.map((e) => [e.module, e]));
  if (others.some((g) => wanted.has(g.module_id))) return { error: "Someone else already gave them part of this. Ask them or the system admin to change it." };
  const toClose = current.filter((g) => !wanted.has(g.module_id) || !same(g, wanted.get(g.module_id) as ModuleEntry));
  const toAdd = input.entries.filter((e) => {
    const g = current.find((x) => x.module_id === e.module);
    return !g || !same(g, e);
  });
  if (!toClose.length && !toAdd.length) return { message: "Nothing changed." };

  const rows = [];
  for (const e of toAdd) {
    const parent = admin ? null : parentFor(e.module);
    if (!admin && !parent) return { error: `You can't pass on ${labelOf(e.module)}.` };
    rows.push({
      module_id: e.module,
      effect: e.effect,
      actions: e.actions,
      user_id: input.userId,
      scope,
      scope_ids: teams,
      expires_at: end.at,
      can_pass_on: passOn && e.effect === "allow",
      parent_id: parent,
      granted_by: profile.id,
      note,
    });
  }
  if (toClose.length) {
    const { error } = await supabase.from("access_grants").update({ revoked_at: new Date().toISOString() }).in("id", toClose.map((g) => g.id));
    if (error) return { error: friendlyError(error) };
  }
  if (rows.length) {
    const { error } = await supabase.from("access_grants").insert(rows);
    if (error) {
      // Put back what was closed, so a refused save changes nothing.
      if (toClose.length) {
        await supabase.from("access_grants").insert(
          toClose.map((g) => ({ module_id: g.module_id, effect: g.effect, actions: g.actions, user_id: input.userId, scope: g.scope, scope_ids: g.scope_ids, expires_at: g.expires_at, can_pass_on: g.can_pass_on, granted_by: profile.id, parent_id: null, note: "restored after a refused change" })),
        );
      }
      if (error.code === "42501") return { error: admin ? "That isn't allowed. Admin access only goes to a Manager Administrator, and protected parts can't be given." : "That isn't allowed: only what you may pass on, to a staff admin, never wider or longer." };
      return { error: friendlyError(error) };
    }
  }
  const describe = (e: { module: string; effect: string; actions: string[] }) =>
    `${e.module.startsWith("cat_") ? `everything in ${labelOf(e.module)}` : labelOf(e.module)}${e.effect === "restrict" ? " (blocked)" : e.actions.length ? ` (${e.actions.join(", ").replace(/_/g, " ")})` : ""}`;
  await log(profile.id, "module_access_changed", input.userId, {
    given: toAdd.map(describe),
    removed: toClose.filter((g) => !wanted.has(g.module_id)).map((g) => describe({ module: g.module_id, effect: g.effect, actions: g.actions })),
    until: end.at,
    note,
  });
  revalidatePath(PAGE);
  return { message: "Saved. It works straight away." };
}

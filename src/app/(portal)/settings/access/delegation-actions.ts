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
  await tell(userId, "You're now a Manager Administrator", `The system admin can now give you admin access to parts of the portal${end.at ? `, until ${dayText(end.at)}` : ""}. You'll be told what you can use.`);
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
  await tell(
    data[0].user_id,
    status === "active" ? "Your admin access is back" : status === "suspended" ? "Your admin access is paused" : "You're no longer a Manager Administrator",
    status === "active" ? "The system admin resumed your Manager Administrator access." : status === "suspended" ? "The system admin paused your Manager Administrator access, and what you passed on." : "Your admin access was removed. Staff records access, if you have it, is unchanged.",
  );
  revalidatePath(PAGE);
  return {
    message:
      status === "active" ? "Resumed. Their admin access works again." : status === "suspended" ? "Suspended. Their admin access (and what they passed on) stopped straight away." : "Ended. Their admin access was removed.",
  };
}

export type ModuleEntry = { module: string; effect: "allow" | "restrict"; actions: string[] };
export type SaveModuleAccess = {
  userId: string;
  entries: ModuleEntry[];
  scope: "all" | "teams" | "people";
  ids: string[];
  expires: string;
  passOn: boolean;
  note: string;
};

// cmeprojects: staff records access lives in the tree too; underneath it's
// still the three record areas with their own rules (and the TFN tick).
const RECORD_AREA: Record<string, "staff_details" | "payroll_tax" | "identity_docs"> = {
  "hr.records.details": "staff_details",
  "hr.records.payroll": "payroll_tax",
  "hr.records.identity": "identity_docs",
};
const AREA_MODULE = Object.fromEntries(Object.entries(RECORD_AREA).map(([m, a]) => [a, m])) as Record<string, string>;

type Live = {
  id: string;
  area: string | null;
  module_id: string | null;
  effect: string;
  actions: string[];
  scope: string;
  scope_ids: string[];
  expires_at: string | null;
  can_pass_on: boolean;
  can_reveal_tfn: boolean;
  granted_by: string | null;
  parent_id: string | null;
};
const COLS = "id, area, module_id, effect, actions, scope, scope_ids, expires_at, can_pass_on, can_reveal_tfn, granted_by, parent_id";
const keyOf = (g: Live) => (g.area ? AREA_MODULE[g.area] : (g.module_id as string));

// Save one person's access (modules and staff records): what changed is
// closed and given again (old grants stay in the history), what was taken off
// is removed. The database checks every rule again.
export async function saveModuleAccess(input: SaveModuleAccess): Promise<FormState> {
  const { profile } = await requireRole(["system_admin", "manager"]);
  const admin = profile.role === "system_admin";
  if (!UUID.test(input.userId)) return { error: "Choose a person." };
  if (!Array.isArray(input.entries) || input.entries.length > 200) return { error: "Something went wrong. Please refresh and try again." };
  for (const e of input.entries) {
    if (!MODULE.test(e.module) || !["allow", "restrict"].includes(e.effect) || !Array.isArray(e.actions) || e.actions.some((a) => !/^[a-z_]+$/.test(a))) {
      return { error: "Something went wrong. Please refresh and try again." };
    }
    if ((!admin || RECORD_AREA[e.module]) && e.effect === "restrict") return { error: "That can't be blocked, only turned off." };
  }
  const scope = input.scope === "teams" || input.scope === "people" ? input.scope : "all";
  const ids = scope === "all" ? [] : (input.ids ?? []).filter((t) => UUID.test(t));
  if (scope !== "all" && !ids.length) return { error: scope === "teams" ? "Choose at least one team." : "Choose at least one person." };
  const form = new FormData();
  form.set("expires", input.expires ?? "");
  const end = endDate(form);
  if (end.error) return { error: end.error };
  const note = String(input.note ?? "").trim().slice(0, 300);

  const supabase = await createClient();
  const [{ data: theirs }, { data: mine }, { data: mods }, { data: target }] = await Promise.all([
    supabase.from("access_grants").select(COLS).eq("user_id", input.userId).is("revoked_at", null),
    admin ? Promise.resolve({ data: [] as Live[] }) : supabase.from("access_grants").select(COLS).eq("user_id", profile.id).is("revoked_at", null).eq("can_pass_on", true),
    supabase.from("app_modules").select("id, parent_id, category, label, sensitivity, actions"),
    supabase.from("profiles").select("role, active").eq("id", input.userId).maybeSingle(),
  ]);
  if (!target?.active) return { error: "Choose an active person." };
  const passOn = admin && Boolean(input.passOn) && target.role === "manager";
  const byId = new Map((mods ?? []).map((m) => [m.id as string, m]));
  const labelOf = (id: string) => byId.get(id)?.label ?? id;
  const live = (theirs ?? []) as Live[];
  const current = live.filter((g) => admin || g.granted_by === profile.id);
  const others = live.filter((g) => !current.includes(g));
  const myLive = ((mine ?? []) as Live[]).filter((g) => g.effect === "allow" && (!g.expires_at || new Date(g.expires_at) > new Date()));

  // Which of my pass-on grants covers it (nearest first).
  const parentFor = (module: string): Live | undefined => {
    if (RECORD_AREA[module]) return myLive.find((g) => g.area === RECORD_AREA[module]);
    const m = byId.get(module);
    if (!m) return undefined;
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
      const g = myLive.find((x) => !x.area && x.module_id === c);
      if (g) return g;
    }
    return undefined;
  };
  // Revealing TFNs: payroll with "Reveal TFN" (or everything) ticked.
  const tfn = (e: ModuleEntry) => e.module === "hr.records.payroll" && (!e.actions.length || e.actions.includes("reveal_tfn"));

  if (!admin) {
    for (const e of input.entries) {
      const parent = parentFor(e.module);
      if (!parent) return { error: `You can't pass on ${labelOf(e.module)}.` };
      if (RECORD_AREA[e.module]) {
        if (tfn(e) && !parent.can_reveal_tfn) e.actions = ["view"];
        continue;
      }
      // "Everything" means everything they hold (their actions, if limited).
      if (parent.actions.length) {
        const own = (byId.get(e.module)?.actions as string[] | undefined) ?? [];
        e.actions = (e.actions.length ? e.actions : own).filter((a) => parent.actions.includes(a));
        if (!e.actions.length) return { error: `You can't pass on any of ${labelOf(e.module)}'s actions.` };
      }
    }
  }
  const sameWhen = (g: Live) =>
    g.scope === scope &&
    [...g.scope_ids].sort().join() === [...ids].sort().join() &&
    (g.expires_at ? new Date(g.expires_at).getTime() : 0) === (end.at ? new Date(end.at).getTime() : 0) &&
    g.can_pass_on === (passOn && true);
  const same = (g: Live, e: ModuleEntry) =>
    RECORD_AREA[e.module]
      ? sameWhen(g) && g.can_reveal_tfn === tfn(e)
      : g.effect === e.effect && [...g.actions].sort().join() === [...e.actions].sort().join() && sameWhen(g) && (e.effect === "restrict" ? true : g.can_pass_on === passOn);

  const wanted = new Map(input.entries.map((e) => [e.module, e]));
  if (others.some((g) => wanted.has(keyOf(g)))) return { error: "Someone else already gave them part of this. Ask them or the system admin to change it." };
  const toClose = current.filter((g) => !wanted.has(keyOf(g)) || !same(g, wanted.get(keyOf(g)) as ModuleEntry));
  const toAdd = input.entries.filter((e) => {
    const g = current.find((x) => keyOf(x) === e.module);
    return !g || !same(g, e);
  });
  if (!toClose.length && !toAdd.length) return { message: "Nothing changed." };

  const rowFor = (e: ModuleEntry) => {
    const area = RECORD_AREA[e.module];
    const base = {
      user_id: input.userId,
      scope,
      scope_ids: ids,
      expires_at: end.at,
      parent_id: admin ? null : (parentFor(e.module)?.id ?? null),
      granted_by: profile.id,
      note,
    };
    // Every row has the same columns (one insert sends them together).
    return area
      ? { ...base, area, module_id: null, effect: "allow", actions: [] as string[], can_pass_on: passOn, can_reveal_tfn: area === "payroll_tax" && tfn(e) }
      : { ...base, area: null, module_id: e.module, effect: e.effect, actions: e.actions, can_pass_on: passOn && e.effect === "allow", can_reveal_tfn: false };
  };
  const rows = toAdd.map(rowFor);
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
          toClose.map((g) => ({
            area: g.area,
            module_id: g.area ? null : g.module_id,
            effect: g.effect,
            actions: g.actions,
            user_id: input.userId,
            scope: g.scope,
            scope_ids: g.scope_ids,
            expires_at: g.expires_at,
            can_pass_on: g.can_pass_on,
            can_reveal_tfn: g.can_reveal_tfn,
            granted_by: profile.id,
            parent_id: g.parent_id,
            note: "put back after a refused change",
          })),
        );
      }
      if (error.code === "42501") {
        return {
          error: admin
            ? "That isn't allowed. Admin access to modules only goes to a Manager Administrator; payroll and identity records only to managers; protected parts never."
            : "That isn't allowed: only what you may pass on, to a staff admin, never wider or longer.",
        };
      }
      return { error: friendlyError(error) };
    }
  }
  const describe = (e: { module: string; effect: string; actions: string[]; tfn?: boolean }) =>
    RECORD_AREA[e.module]
      ? `${labelOf(e.module)}${e.module === "hr.records.payroll" ? (e.tfn ? " (can reveal TFNs)" : " (no TFNs)") : ""}`
      : `${e.module.startsWith("cat_") ? `everything in ${labelOf(e.module)}` : labelOf(e.module)}${e.effect === "restrict" ? " (blocked)" : e.actions.length ? ` (${e.actions.join(", ").replace(/_/g, " ")})` : ""}`;
  const given = toAdd.map((e) => describe({ ...e, tfn: tfn(e) }));
  const removed = toClose.filter((g) => !wanted.has(keyOf(g))).map((g) => describe({ module: keyOf(g), effect: g.effect, actions: g.actions, tfn: g.can_reveal_tfn }));
  await log(profile.id, "module_access_changed", input.userId, { given, removed, until: end.at, note });
  // Tell them (bell and email).
  await tell(
    input.userId,
    "Your access changed",
    [given.length ? `You can now use: ${given.join("; ")}.` : "", removed.length ? `Removed: ${removed.join("; ")}.` : "", end.at ? `Until ${dayText(end.at)}.` : ""].filter(Boolean).join(" "),
  );
  revalidatePath(PAGE);
  return { message: "Saved. It works straight away." };
}

// cmeprojects: a bell notice (and email) about their access.
async function tell(user: string, title: string, body: string) {
  await createAdminClient().rpc("notify", { p_user: user, p_kind: "access", p_title: title, p_body: body, p_href: "/settings/access", p_email: true });
}
const dayText = (iso: string) => new Date(iso).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "Australia/Sydney" });

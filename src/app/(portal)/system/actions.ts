// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { CHOICES } from "@/lib/setting-choices";
import { env } from "@/lib/env";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireRole, requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { areaOf, isArea } from "@/lib/delegation";
import { friendlyError } from "@/lib/db-error";
import { isRole } from "@/lib/roles";
import { slaFromForm } from "@/lib/tasks";
import { text, type FormState } from "@/lib/form";
import { draftOf, saveDraft } from "@/lib/drafts";
import { confirmIdentity } from "@/lib/reauth";
import { PRESETS, PRESET_SWITCHES } from "./options";
import { NOTIFICATION_GROUPS, asChannelMap, type Channel } from "@/lib/notification-catalogue";

// A feature switch is saved as a draft too (switching on a premium add-on
// also includes it in the plan when deployed).
export async function setFeature(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const result = await saveDraft("feature", text(form, "key"), { enabled: text(form, "enabled") === "true" });
  revalidatePath("/", "layout");
  return result;
}

// Settings are stored as JSON. The form says what kind of value each one is.
function parse(kind: string, form: FormData): { value?: unknown; error?: string } {
  const raw = text(form, "value");
  switch (kind) {
    case "color":
      return /^#[0-9a-f]{6}$/i.test(raw) ? { value: raw } : { error: "Use a colour like #134F8E." };
    case "number": {
      const n = Number(raw);
      return Number.isInteger(n) && n >= 0 && n <= 1000 ? { value: n } : { error: "Enter a whole number." };
    }
    case "sla":
      return { value: slaFromForm(form, "sla_") };
    case "note":
      return { value: raw.slice(0, 500) };
    case "longnote":
      return { value: String(form.get("value") ?? "").trim().slice(0, 2000) };
    case "lines":
      return {
        value: String(form.get("value") ?? "")
          .split(/\n+/)
          .map((l) => l.trim().slice(0, 120))
          .filter(Boolean)
          .slice(0, 30),
      };
    case "dates": {
      // One per line: YYYY-MM-DD then a name (public holidays).
      const lines = String(form.get("value") ?? "")
        .split(/\n+/)
        .map((l) => l.trim().replace(/\s+/g, " "))
        .filter(Boolean);
      const bad = lines.find((l) => !/^\d{4}-\d{2}-\d{2}( .*)?$/.test(l));
      if (bad) return { error: `Start each line with a date like 2026-12-25: "${bad}"` };
      return { value: [...new Set(lines)].sort().slice(0, 200) };
    }
    case "logo": {
      const path = text(form, "logo_path");
      if (!path.startsWith("logo/")) return { error: "Choose an image and wait for it to upload." };
      return { value: `${env.supabaseUrl}/storage/v1/object/public/branding/${path}` };
    }
    case "choice":
      return CHOICES[text(form, "key")]?.some((c) => c.value === raw) ? { value: raw } : { error: "Choose one of the options." };
    case "yesno":
      return { value: form.get("value") === "true" };
    case "roles": {
      const roles = form.getAll("value").map(String).filter(isRole);
      return { value: roles };
    }
    case "people":
      return { value: form.getAll("value").map(String).filter((v) => /^[0-9a-f-]{36}$/.test(v)) };
    default:
      if (text(form, "key") === "vehicles.app_name" && raw.length > 20) return { error: "Keep the name to 20 letters or fewer, so it fits under the icon." };
      return raw ? { value: raw } : { error: "This can't be empty." };
  }
}

// The system admin, managers for due dates, or a manager given this area.
async function mayChange(key: string) {
  const { profile } = await requireSession();
  const area = areaOf(key);
  return (
    profile.role === "system_admin" ||
    (key.startsWith("tasks.sla") && profile.role === "manager") ||
    (area !== null && (await getMyAdminAreas(profile.role)).includes(area))
  );
}

export async function saveSetting(_: FormState, form: FormData): Promise<FormState> {
  const key = text(form, "key");
  if (!(await mayChange(key))) return { error: "You don't have permission to change this setting." };
  const { value, error: problem } = parse(text(form, "kind"), form);
  if (problem) return { error: problem };

  // cmeprojects: saved as a draft; it goes live when deployed.
  const result = await saveDraft("setting", key, value);
  revalidatePath("/", "layout");
  return result;
}

// ---------------------------------------------------------------------------
// The Cars app icon (cmeprojects): pick one, upload a new one, delete an upload
// ---------------------------------------------------------------------------

type Result = { error?: string; message?: string };

// Which app's icon: the Cars app or the Staff app.
export type WhichApp = "cars" | "staff";
const ICON_KEYS: Record<WhichApp, { icon: string; uploads: string }> = {
  cars: { icon: "vehicles.app_icon", uploads: "vehicles.app_icon_uploads" },
  staff: { icon: "staff_app.icon", uploads: "staff_app.icon_uploads" },
};
const keysFor = (which: WhichApp) => ICON_KEYS[which] ?? ICON_KEYS.cars;

async function iconSettings(which: WhichApp) {
  const k = keysFor(which);
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("key, value").in("key", [k.icon, k.uploads]);
  const icon = data?.find((d) => d.key === k.icon)?.value;
  const uploads = data?.find((d) => d.key === k.uploads)?.value;
  return { supabase, icon: typeof icon === "string" ? icon : "car", uploads: Array.isArray(uploads) ? (uploads as string[]) : [] };
}

async function setIcon(which: WhichApp, icon: string, uploads?: string[]): Promise<Result> {
  const k = keysFor(which);
  const supabase = await createClient();
  if (uploads) {
    const { data, error } = await supabase.from("app_settings").update({ value: uploads }).eq("key", k.uploads).select("key");
    if (error || !data?.length) return { error: error ? friendlyError(error) : "You don't have permission to change this setting." };
  }
  // The icon in use is a setting, so it's a draft until deployed (uploads are kept straight away).
  const result = await saveDraft("setting", k.icon, icon);
  revalidatePath("/", "layout");
  return result ?? {};
}

export async function chooseAppIcon(icon: string, which: WhichApp = "cars"): Promise<Result> {
  if (!(await mayChange(keysFor(which).icon))) return { error: "You don't have permission to change this setting." };
  const { uploads } = await iconSettings(which);
  if (!["car", "mark", "logo"].includes(icon) && !uploads.includes(icon)) return { error: "Choose one of the icons." };
  const r = await setIcon(which, icon);
  return r.error ? r : { message: "Icon saved." };
}

// A newly uploaded picture joins the choices and becomes the icon.
export async function addAppIcon(path: string, which: WhichApp = "cars"): Promise<Result> {
  if (!(await mayChange(keysFor(which).icon))) return { error: "You don't have permission to change this setting." };
  if (!/^logo\/[\w.\-/]+$/.test(path)) return { error: "Choose a picture and wait for it to upload." };
  const { uploads } = await iconSettings(which);
  if (uploads.length >= 8) return { error: "Keep up to 8 uploaded icons. Delete one first." };
  const url = `${env.supabaseUrl}/storage/v1/object/public/branding/${path}`;
  const r = await setIcon(which, url, [...uploads, url]);
  return r.error ? r : { message: "Uploaded. It's now the icon." };
}

export async function deleteAppIcon(url: string, which: WhichApp = "cars"): Promise<Result> {
  if (!(await mayChange(keysFor(which).icon))) return { error: "You don't have permission to change this setting." };
  const { supabase, icon, uploads } = await iconSettings(which);
  if (!uploads.includes(url)) return { error: "That icon has already gone." };
  // Deleting the one in use goes back to the drawn icon.
  const r = await setIcon(which, icon === url ? "car" : icon, uploads.filter((u) => u !== url));
  if (r.error) return r;
  const path = url.split("/storage/v1/object/public/branding/")[1];
  if (path) await supabase.storage.from("branding").remove([path]);
  return { message: icon === url ? "Deleted. The icon is back to the drawn one." : "Deleted." };
}

// Demo data (system admin): load sample records, delete only those, or clear every task.
export async function runDemoAction(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const what = text(form, "what");
  const supabase = await createClient();
  if (what === "clear-all" && text(form, "confirm") !== "DELETE") return { error: "Type DELETE to confirm." };
  const fn = what === "load" ? "demo_load" : what === "clear" ? "demo_clear" : what === "clear-all" ? "demo_clear_all_tasks" : null;
  if (!fn) return { error: "Choose what to do." };
  const { data, error } = await supabase.rpc(fn);
  if (error) return { error: error.code === "PGRST202" ? "Run live update 43 first." : friendlyError(error) };
  revalidatePath("/", "layout");
  const n = Number(data ?? 0);
  return {
    message:
      what === "load" ? `Loaded ${n} sample records (tasks across the registers and website enquiries).` : what === "clear" ? `Deleted ${n} sample records. Real work wasn't touched.` : `Deleted all ${n} tasks.`,
  };
}

// cmeprojects: system admin only. Signs everyone out of every device except
// the admin's own; accounts stay active.
export async function signOutEveryone(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  if (text(form, "confirm") !== "SIGN OUT") return { error: "Type SIGN OUT to confirm." };
  // cmeprojects: prove it's you first (password or authenticator code).
  const check = await confirmIdentity(String(form.get("secret") ?? ""));
  if (!check.ok) return { error: check.error };
  const { data, error } = await (await createClient()).rpc("sign_out_everyone");
  if (error) return { error: error.code === "PGRST202" ? "This needs the latest database update (update 45)." : friendlyError(error) };
  const n = Number(data ?? 0);
  return { message: `Signed out ${n} device${n === 1 ? "" : "s"}. You're still signed in here.` };
}

// ---------------------------------------------------------------------------
// cmeprojects settings revamp: delegation per area, package presets, notifications
// ---------------------------------------------------------------------------

// Who looks after an area: only the system admin, all managers, or chosen people.
export async function saveDelegationRule(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const area = text(form, "area");
  if (!isArea(area)) return { error: "Something went wrong. Please refresh and try again." };
  const mode = text(form, "mode");
  const people = mode === "selected" ? form.getAll("people").map(String).filter((v) => /^[0-9a-f-]{36}$/.test(v)) : [];
  if (mode === "selected" && !people.length) return { error: "Choose at least one manager or staff admin." };
  const result = await saveDraft("delegation", area, { mode: ["admin", "managers", "selected"].includes(mode) ? mode : "admin", people });
  revalidatePath("/", "layout");
  return result;
}

// Package presets set the main switches for a budget in one go (as drafts).
export async function applyPreset(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const preset = PRESETS[text(form, "preset")];
  if (!preset) return { error: "Choose a package." };
  for (const key of PRESET_SWITCHES) {
    const r = await saveDraft("feature", key, { enabled: preset.on.includes(key) });
    if (r?.error) return r;
  }
  revalidatePath("/", "layout");
  return { message: `${preset.label} set. Not live yet: press Deploy to make it live.` };
}

// One group of the Notifications tab: bell and email for each notification.
export async function saveNotifications(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const group = NOTIFICATION_GROUPS.find((g) => g.key === text(form, "group"));
  if (!group) return { error: "Something went wrong. Please refresh and try again." };
  const supabase = await createClient();
  const draft = await draftOf("setting", "notify.channels");
  const live = draft ? null : (await supabase.from("app_settings").select("value").eq("key", "notify.channels").maybeSingle()).data?.value;
  const map = { ...asChannelMap(draft ? draft.value : live) };
  for (const item of group.items) {
    const next: Partial<Record<Channel, boolean>> = { ...map[item.code] };
    for (const c of item.channels) next[c] = form.get(`${item.code}.${c}`) === "on";
    // Keep only what's switched off; anything not listed is on.
    const off = Object.fromEntries(Object.entries(next).filter(([, v]) => v === false));
    if (Object.keys(off).length) map[item.code] = off;
    else delete map[item.code];
  }
  const result = await saveDraft("setting", "notify.channels", map);
  revalidatePath("/", "layout");
  return result;
}

// cmeprojects: a manager shares an area the system admin gave them with
// staff admins (acts straight away; the database checks it).
export async function saveShares(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  if (profile.role !== "manager") return { error: "Only managers share areas." };
  const area = text(form, "area");
  const wanted = new Set(form.getAll("people").map(String));
  const supabase = await createClient();
  const { data: now, error: readError } = await supabase.from("delegation_shares").select("user_id").eq("area", area);
  if (readError) return { error: readError.code === "42P01" || readError.code === "PGRST205" ? "This needs the latest database update (update 47)." : friendlyError(readError) };
  const current = new Set((now ?? []).map((s) => s.user_id as string));
  for (const id of new Set([...wanted, ...current])) {
    if (wanted.has(id) === current.has(id)) continue;
    const { error } = await supabase.rpc("share_area", { p_area: area, p_user: id, p_on: wanted.has(id) });
    if (error) return { error: friendlyError(error) };
  }
  revalidatePath("/system");
  revalidatePath("/settings"); // cmeprojects: also shown inside Portal settings
  return { message: "Saved. This takes effect straight away." };
}

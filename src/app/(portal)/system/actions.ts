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

export async function setFeature(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const key = text(form, "key");
  const enabled = text(form, "enabled") === "true";
  const supabase = await createClient();
  // Switching on a premium add-on also includes it in this company's plan.
  const { data: current } = await supabase.from("features").select("*").eq("key", key).maybeSingle();
  const values = enabled && current?.premium === true ? { enabled, included: true } : { enabled };
  const { data, error } = await supabase.from("features").update(values).eq("key", key).select("label").single();
  if (error) return { error: friendlyError(error) };
  revalidatePath("/", "layout");
  return { message: `${data.label} is now ${enabled ? "on" : "off"}.` };
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

  const supabase = await createClient();
  const { data, error } = await supabase.from("app_settings").update({ value }).eq("key", key).select("key");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change this setting." };
  revalidatePath("/", "layout");
  return { message: "Saved." };
}

// The system admin hands areas of System settings to a named manager.
export async function saveDelegation(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const supabase = await createClient();
  const { error } = await supabase.rpc("set_delegation", {
    p_user_id: text(form, "user_id"),
    p_areas: form.getAll("areas").map(String).filter(isArea),
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/system");
  return { message: "Saved." };
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
  const { data, error } = await supabase.from("app_settings").update({ value: icon }).eq("key", k.icon).select("key");
  if (error || !data?.length) return { error: error ? friendlyError(error) : "You don't have permission to change this setting." };
  revalidatePath("/", "layout");
  return {};
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

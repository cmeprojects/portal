// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireRole } from "@/lib/session";
import { friendlyError } from "@/lib/db-error";
import { isRole } from "@/lib/roles";
import { slaFromForm } from "@/lib/tasks";
import { text, type FormState } from "@/lib/form";

export async function setFeature(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const key = text(form, "key");
  const enabled = text(form, "enabled") === "true";
  const supabase = await createClient();
  const { data, error } = await supabase.from("features").update({ enabled }).eq("key", key).select("label").single();
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
    case "yesno":
      return { value: form.get("value") === "true" };
    case "roles": {
      const roles = form.getAll("value").map(String).filter(isRole);
      return { value: roles };
    }
    default:
      return raw ? { value: raw } : { error: "This can't be empty." };
  }
}

export async function saveSetting(_: FormState, form: FormData): Promise<FormState> {
  const key = text(form, "key");
  // Managers can change the SLA; everything else is for system admins.
  await requireRole(key.startsWith("tasks.sla") ? ["manager", "system_admin"] : ["system_admin"]);
  const { value, error: problem } = parse(text(form, "kind"), form);
  if (problem) return { error: problem };

  const supabase = await createClient();
  const { data, error } = await supabase.from("app_settings").update({ value }).eq("key", key).select("key");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have permission to change this setting." };
  revalidatePath("/", "layout");
  return { message: "Saved." };
}

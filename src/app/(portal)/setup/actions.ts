// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { env } from "@/lib/env";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";
import { PRESETS, PRESET_SWITCHES } from "../system/options";

const ZONES = ["Australia/Melbourne", "Australia/Sydney", "Australia/Brisbane", "Australia/Adelaide", "Australia/Perth", "Australia/Hobart", "Australia/Darwin"];
const COLOUR = /^#[0-9a-f]{6}$/i;

// cmeprojects: the first-time setup wizard. The system admin sets the company,
// the look, the starting registers and the package in one go. These apply
// straight away (there's nobody else in a new copy yet).
export async function finishSetup(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const supabase = await createClient();
  const company = text(form, "company_name").slice(0, 80);
  if (!company) return { error: "Enter the organisation's name (step 1)." };

  const settings: Record<string, unknown> = {
    "brand.company_name": company,
    "brand.portal_name": text(form, "portal_name").slice(0, 60) || "Staff Portal",
    "wording.client": text(form, "client_word").slice(0, 30) || "Client",
    "region.timezone": ZONES.includes(text(form, "timezone")) ? text(form, "timezone") : "Australia/Melbourne",
  };
  for (const k of ["color_primary", "color_dark", "color_accent"]) {
    const v = text(form, k);
    if (COLOUR.test(v)) settings[`brand.${k}`] = v;
  }
  const logo = text(form, "logo_path");
  if (logo.startsWith("logo/")) {
    const url = `${env.supabaseUrl}/storage/v1/object/public/branding/${logo}`;
    settings["brand.logo_url"] = url;
    settings["brand.logo_mark_url"] = url;
  }
  for (const [key, value] of Object.entries(settings)) {
    const { error } = await supabase.from("app_settings").update({ value }).eq("key", key);
    if (error) return { error: friendlyError(error) };
  }
  await supabase.from("organisation").update({ name: company }).not("id", "is", null);

  // Starting registers from the templates.
  for (const key of form.getAll("templates").map(String)) {
    const { error } = await supabase.rpc("add_register_from_template", { p_key: key });
    if (error && !/already added/i.test(error.message)) return { error: friendlyError(error) };
  }

  // The package: the main switches on or off.
  const preset = PRESETS[text(form, "package")] ?? PRESETS.essentials;
  const { data: features } = await supabase.from("features").select("key, premium");
  for (const key of PRESET_SWITCHES) {
    const on = preset.on.includes(key);
    const premium = features?.find((f) => f.key === key)?.premium === true;
    await supabase.from("features").update(on && premium ? { enabled: true, included: true } : { enabled: on }).eq("key", key);
  }

  await supabase.from("app_settings").update({ value: true }).eq("key", "setup.completed");
  revalidatePath("/", "layout");
  redirect("/?setup=done");
}

// Skip the wizard (everything can be set in Settings instead).
export async function skipSetup() {
  await requireRole(["system_admin"]);
  await (await createClient()).from("app_settings").update({ value: true }).eq("key", "setup.completed");
  revalidatePath("/", "layout");
  redirect("/");
}

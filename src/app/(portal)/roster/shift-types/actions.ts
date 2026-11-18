// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 141): shift types are managed by Manager Administrators
// (and the system admin). The database refuses anyone else; this checks first.
export async function mayManageShiftTypes(): Promise<boolean> {
  const { profile } = await requireSession();
  if (profile.role === "system_admin") return true;
  const { data } = await (await createClient()).rpc("is_manager_admin");
  return data === true;
}

export async function saveShiftType(_: FormState, form: FormData): Promise<FormState> {
  if (!(await mayManageShiftTypes())) return { error: "Only Manager Administrators can change shift types." };
  const key = String(form.get("key") ?? "");
  const label = String(form.get("label") ?? "").trim().slice(0, 60);
  if (!label) return { error: "Give the shift type a name." };
  const supabase = await createClient();
  if (key) {
    const { error } = await supabase.from("shift_types").update({ label, active: form.get("active") === "on", updated_at: new Date().toISOString() }).eq("key", key);
    if (error) return { error: friendlyError(error) };
    revalidatePath("/roster/shift-types");
    return { message: "Shift type saved." };
  }
  // A new type gets a key made from its name (kept even if it's renamed later).
  const made = label.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 40);
  const newKey = /^[a-z]/.test(made) && made.length >= 2 ? made : `type_${made}`.slice(0, 40);
  const { data: exists } = await supabase.from("shift_types").select("key").eq("key", newKey).maybeSingle();
  if (exists) return { error: "There's already a shift type with that name." };
  const { data: last } = await supabase.from("shift_types").select("sort_order").order("sort_order", { ascending: false }).limit(1).maybeSingle();
  const { error } = await supabase.from("shift_types").insert({ key: newKey, label, sort_order: (last?.sort_order ?? 0) + 10 });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/roster/shift-types");
  return { message: "Shift type added." };
}

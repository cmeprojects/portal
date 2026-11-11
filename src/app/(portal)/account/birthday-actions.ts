// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

const MAX_DAY = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

export async function saveBirthday(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const month = Number(form.get("month") || 0);
  const day = Number(form.get("day") || 0);
  if (!month && !day) {
    const { error } = await supabase.from("staff_birthdays").delete().eq("user_id", profile.id);
    if (error) return { error: friendlyError(error) };
    revalidatePath("/", "layout");
    return { message: "Birthday removed." };
  }
  if (!(month >= 1 && month <= 12) || !(day >= 1 && day <= MAX_DAY[month - 1])) return { error: "Choose a real day and month." };
  const { error } = await supabase
    .from("staff_birthdays")
    .upsert({ user_id: profile.id, month, day, show: form.get("show") === "on", updated_at: new Date().toISOString() }, { onConflict: "user_id" });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/", "layout");
  return { message: form.get("show") === "on" ? "Saved. Colleagues will see a greeting on the day." : "Saved. Only you can see it." };
}

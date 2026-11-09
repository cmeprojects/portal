// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { checkPhone } from "@/lib/phone";
import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { DAYS, SHIFTS } from "@/lib/profiles-shared";

// cmeprojects: save a staff profile. The database decides which fields this
// person may change (their own contact details and skills; employment details
// only for people who manage staff).
export async function saveProfile(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const userId = String(form.get("user_id") ?? "");
  if (!/^[0-9a-f-]{36}$/.test(userId)) return { error: "Choose a person." };
  const str = (k: string) => String(form.get(k) ?? "").trim();
  const p: Record<string, unknown> = {
    preferred_name: str("preferred_name"),
    work_phone: str("work_phone"),
    skills: str("skills")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean),
    address: str("address"),
    emergency_name: str("emergency_name"),
    emergency_phone: str("emergency_phone"),
    availability: Object.fromEntries(DAYS.map(([d]) => [d, SHIFTS.map(([s]) => s).filter((s) => form.get(`avail_${d}_${s}`) === "on")])),
  };
  if (form.get("employment") === "1") {
    p.department = str("department");
    p.start_date = str("start_date");
    p.employment_type = str("employment_type");
    p.employee_id = str("employee_id");
  }
  // cmeprojects: phone numbers checked for their country (Australia by default) and saved in one format.
  const phone = checkPhone(str("work_phone_country") || "AU", str("work_phone"));
  if (!phone.ok) return { error: `Contact phone: ${phone.error}` };
  p.work_phone = phone.value;
  const emergency = checkPhone(str("emergency_phone_country") || "AU", str("emergency_phone"));
  if (!emergency.ok) return { error: `Emergency contact's phone: ${emergency.error}` };
  p.emergency_phone = emergency.value;
  if (/^[\d\s+()-]{6,}$/.test(String(p.emergency_name))) return { error: "Emergency contact's name: that looks like a phone number. Put the name here and the number below." };
  const { error } = await (await createClient()).rpc("save_profile", { p_user: userId, p });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/people");
  revalidatePath("/account");
  return { message: "Profile saved." };
}

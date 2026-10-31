// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { text } from "@/lib/form";
import { STAGES } from "./stages";

// Managers move an enquiry along and leave a note (the database allows only
// managers and the system admin).
export async function updateEnquiry(form: FormData) {
  await requireRole(["manager", "system_admin"]);
  const status = text(form, "status");
  if (!STAGES.some((s) => s.key === status)) return;
  await (await createClient())
    .from("website_enquiries")
    .update({ status, note: text(form, "note").slice(0, 1000) })
    .eq("id", text(form, "id"));
  revalidatePath("/enquiries");
}

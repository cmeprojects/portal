// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireTaskAccess } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";

// cmeprojects: add a register from the template library (the database checks who may).
export async function addFromTemplate(_: FormState, form: FormData): Promise<FormState> {
  await requireTaskAccess();
  const { error } = await (await createClient()).rpc("add_register_from_template", { p_key: text(form, "key") });
  if (error) return { error: error.code === "PGRST202" ? "This needs the latest database update (update 51)." : friendlyError(error) };
  revalidatePath("/registers");
  return { message: "Added. You can change its fields and settings in Set up." };
}

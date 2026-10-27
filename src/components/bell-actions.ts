// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function markAllSeen() {
  const supabase = await createClient();
  await supabase.rpc("mark_all_tasks_seen");
  revalidatePath("/", "layout");
}

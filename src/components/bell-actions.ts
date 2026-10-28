// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function markAllSeen() {
  const supabase = await createClient();
  await Promise.all([
    supabase.rpc("mark_all_tasks_seen"),
    supabase.rpc("mark_request_updates_seen", {}),
    supabase.rpc("mark_all_notifications_seen"),
  ]);
  revalidatePath("/", "layout");
}

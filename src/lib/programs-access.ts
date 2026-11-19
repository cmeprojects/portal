// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (update 152): who manages programs and schemes: the system admin,
// Manager Administrators, or people given the Care settings area. The database checks too.
export const managesPrograms = cache(async (): Promise<boolean> => {
  const { profile } = await requireSession();
  if (profile.role === "system_admin") return true;
  if ((await getMyAdminAreas(profile.role)).includes("care")) return true;
  if (profile.role !== "manager") return false;
  const { data } = await (await createClient()).rpc("is_manager_admin");
  return data === true;
});

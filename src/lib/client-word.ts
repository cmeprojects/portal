// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (Care block): what the organisation calls the people it supports
// ("Participant", "Client"...), from Branding → wording.client. Schemes can
// use their own word (Care settings); this is the organisation's default.
export const getClientWord = cache(async (): Promise<string> => {
  const { data } = await (await createClient()).from("app_settings").select("value").eq("key", "wording.client").maybeSingle();
  const v = data?.value;
  return typeof v === "string" && v.trim() ? v.trim() : "Client";
});

// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";

// The company's time zone (System settings → Region).
export const getTimeZone = cache(async (): Promise<string> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("value").eq("key", "region.timezone").maybeSingle();
  const zone = typeof data?.value === "string" ? data.value : "Australia/Melbourne";
  try {
    new Intl.DateTimeFormat("en-AU", { timeZone: zone });
    return zone;
  } catch {
    return "Australia/Melbourne";
  }
});

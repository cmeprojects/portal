// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { parseSla, type Sla } from "@/lib/tasks";

export type SlaSettings = { days: Sla; weekdaysOnly: boolean };

// Default due dates by priority (System settings → Tasks).
export const getSla = cache(async (): Promise<SlaSettings> => {
  const supabase = await createClient();
  const { data } = await supabase.from("app_settings").select("key, value").in("key", ["tasks.sla_days", "tasks.sla_weekdays_only"]);
  const get = (k: string) => data?.find((r) => r.key === k)?.value;
  return { days: parseSla(get("tasks.sla_days")), weekdaysOnly: get("tasks.sla_weekdays_only") === true };
});

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

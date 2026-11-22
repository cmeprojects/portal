// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (update 161): Billing rights, asked of the database's own rule
// (billing_can): the System Administrator and Manager Administrators by
// default, anyone else only as given on the Access page; separate from Funding.
// Before update 161 runs the rule doesn't exist, so the answer is no.
export const canBill = cache(async (action: string, client?: string): Promise<boolean> => {
  const { data, error } = await (await createClient()).rpc("billing_can", { p_action: action, p_client: client ?? null });
  return !error && data === true;
});

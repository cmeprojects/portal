// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { revalidatePath } from "next/cache";
import { createAdminClient } from "@/lib/supabase/admin";

// cmeprojects (audit Stage B): bank, super, right to work and the TFN form
// count towards "onboarding complete", but they're saved outside the
// onboarding checklist. After one is saved or checked, run the same
// "finished onboarding?" check the checklist uses (it records the date and
// tells the people admins once). It only ever marks complete; never undoes.
export async function recheckOnboarding(userId: string) {
  await createAdminClient().rpc("check_onboarding_complete", { p_user: userId });
  revalidatePath("/onboarding");
  revalidatePath("/compliance", "layout");
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { DEFAULT_COOKIE } from "@/lib/compliance-report";

// Remember this person's choices; the report opens like this next time.
export async function saveDefaultView(form: FormData) {
  await requireSession();
  const query = String(form.get("query") ?? "").slice(0, 2000);
  (await cookies()).set(DEFAULT_COOKIE, query, { path: "/reports/compliance", maxAge: 31536000, sameSite: "lax", httpOnly: true });
  redirect(`/reports/compliance?${query}&saved=1`);
}

export async function clearDefaultView() {
  await requireSession();
  (await cookies()).delete({ name: DEFAULT_COOKIE, path: "/reports/compliance" });
  redirect("/reports/compliance?view=people");
}

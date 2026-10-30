// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { CAR_REPORT_COOKIE } from "@/lib/car-reports";

// Remember this person's report choices; Car reports opens like this next time.
export async function saveCarReportView(form: FormData) {
  await requireSession();
  const query = String(form.get("query") ?? "").slice(0, 2000);
  (await cookies()).set(CAR_REPORT_COOKIE, query, { path: "/reports/cars", maxAge: 31536000, sameSite: "lax", httpOnly: true });
  redirect(`/reports/cars?${query}&saved=1`);
}

export async function clearCarReportView() {
  await requireSession();
  (await cookies()).delete({ name: CAR_REPORT_COOKIE, path: "/reports/cars" });
  redirect("/reports/cars?report=mileage");
}

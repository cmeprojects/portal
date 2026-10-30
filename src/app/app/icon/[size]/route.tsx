// Staff Portal · © cmeproject. All rights reserved.
import type { NextRequest } from "next/server";
import { getBranding, getStaffAppLook } from "@/lib/branding";
import { appIcon } from "@/lib/app-icon";

// The Staff app's home-screen icon (System settings → Staff app).
export async function GET(request: NextRequest, ctx: RouteContext<"/app/icon/[size]">) {
  const [brand, look] = await Promise.all([getBranding(), getStaffAppLook()]);
  return appIcon(request, (await ctx.params).size, brand, look, "staff");
}

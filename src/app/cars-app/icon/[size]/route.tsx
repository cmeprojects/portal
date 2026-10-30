// Staff Portal · © cmeproject. All rights reserved.
import type { NextRequest } from "next/server";
import { getBranding, getCarsAppLook } from "@/lib/branding";
import { appIcon } from "@/lib/app-icon";

// The Cars app's home-screen icon (System settings → Cars).
export async function GET(request: NextRequest, ctx: RouteContext<"/cars-app/icon/[size]">) {
  const [brand, look] = await Promise.all([getBranding(), getCarsAppLook()]);
  return appIcon(request, (await ctx.params).size, brand, look, "car");
}

// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { safeNext } from "@/lib/safe-next";

// Opening a bell notice: mark it seen, then go where it points.
export async function GET(request: NextRequest, ctx: RouteContext<"/n/[id]">) {
  const { id } = await ctx.params;
  const supabase = await createClient();
  const { data } = await supabase.rpc("mark_notification_seen", { p_id: Number(id) || 0 });
  // cmeprojects (Zero Trust review): the same check as sign-in, so a notice can never send
  // someone to another website (a backslash or tab used to slip through here).
  const href = safeNext(data);
  return NextResponse.redirect(new URL(href, request.nextUrl.origin));
}

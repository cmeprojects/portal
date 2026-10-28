// Staff Portal · © cmeproject. All rights reserved.
import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { flushOutbox } from "@/lib/email/outbox";

export const dynamic = "force-dynamic";

function allowed(request: NextRequest): boolean {
  const secret = process.env.CRON_SECRET;
  if (!secret || secret.length < 32) return false;
  const given = Buffer.from(request.headers.get("authorization")?.replace(/^Bearer /, "") ?? "");
  const expected = Buffer.from(secret);
  return given.length === expected.length && timingSafeEqual(given, expected);
}

// Called every hour by the database's timer (pg_cron), or any scheduler:
// sends due date reminders, overdue alerts and escalations, then the emails.
async function run(request: NextRequest) {
  if (!allowed(request)) return NextResponse.json({ ok: false }, { status: 401 });
  const admin = createAdminClient();
  const { data, error } = await admin.rpc("run_due_alerts");
  if (error) return NextResponse.json({ ok: false, error: error.message }, { status: 500 });
  // Up to 50 emails a round; keep going while there are more.
  for (let i = 0; i < 10; i++) {
    const { count } = await admin.from("email_outbox").select("id", { count: "exact", head: true }).is("sent_at", null).lt("attempts", 5);
    if (!count) break;
    await flushOutbox();
  }
  return NextResponse.json({ ok: true, ...data }, { headers: { "Cache-Control": "no-store" } });
}

export const GET = run;
export const POST = run;

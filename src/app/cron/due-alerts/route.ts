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
// sends due date reminders, overdue alerts, escalations and document expiry
// reminders, then the emails.
async function run(request: NextRequest) {
  if (!allowed(request)) return NextResponse.json({ ok: false }, { status: 401 });
  const admin = createAdminClient();
  const result = await work(admin);
  // System health shows when this last ran and whether it worked.
  await admin
    .from("system_heartbeat")
    .upsert({ job: "hourly", ran_at: new Date().toISOString(), ok: result.status === 200, detail: result.status === 200 ? "" : String(result.body.error ?? "") });
  return NextResponse.json(result.body, { status: result.status, headers: { "Cache-Control": "no-store" } });
}

async function work(admin: ReturnType<typeof createAdminClient>): Promise<{ status: number; body: Record<string, unknown> }> {
  const { data, error } = await admin.rpc("run_due_alerts");
  if (error) return { status: 500, body: { ok: false, error: error.message } };
  // Onboarding documents that expire soon or have expired.
  const { data: documents, error: docError } = await admin.rpc("run_compliance_alerts");
  if (docError) return { status: 500, body: { ok: false, error: docError.message } };
  // Cars still out, rego and service coming up, and Monday's mileage report.
  const { data: cars, error: carError } = await admin.rpc("run_car_alerts");
  if (carError) return { status: 500, body: { ok: false, error: carError.message } };
  // Up to 50 emails a round; keep going while there are more.
  for (let i = 0; i < 10; i++) {
    const { count } = await admin.from("email_outbox").select("id", { count: "exact", head: true }).is("sent_at", null).lt("attempts", 5);
    if (!count) break;
    await flushOutbox();
  }
  return { status: 200, body: { ok: true, ...data, ...documents, ...cars } };
}

export const GET = run;
export const POST = run;

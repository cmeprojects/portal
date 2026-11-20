// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { logDownload } from "@/lib/download-log";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { addDays, mondayOf, shiftHours, sydneyInstant, sydneyParts, sydneyToday } from "@/lib/sydney-time";

// cmeprojects (rostering round 2): the week's roster as CSV (Rostering, view).
export async function GET(request: NextRequest) {
  const { features } = await requireSession();
  if (features.rostering === false || !(await canDo("ops.roster", "view"))) return new NextResponse("Not found", { status: 404 });
  const w = request.nextUrl.searchParams.get("w") ?? "";
  const monday = mondayOf(/^\d{4}-\d{2}-\d{2}$/.test(w) ? w : sydneyToday());
  const supabase = await createClient();
  const { data } = await supabase
    .from("shifts")
    .select("starts_at, ends_at, break_minutes, status, notes, worker:profiles!shifts_worker_id_fkey(full_name, email), client:car_clients(name)")
    .neq("status", "cancelled")
    .gte("starts_at", sydneyInstant(monday))
    .lt("starts_at", sydneyInstant(addDays(monday, 7)))
    .order("starts_at");
  const cell = (v: string) => `"${(/^[=+\-@]/.test(v) ? `'${v}` : v).replace(/"/g, '""')}"`;
  const lines = [["Date", "Start", "Finish", "Break (min)", "Paid hours", "Worker", "Client", "Status"].map(cell).join(",")];
  for (const s of (data ?? []) as unknown as { starts_at: string; ends_at: string; break_minutes: number; status: string; worker: { full_name: string | null; email: string } | null; client: { name: string } | null }[]) {
    const a = sydneyParts(s.starts_at);
    lines.push([a.date, a.time, sydneyParts(s.ends_at).time, String(s.break_minutes), shiftHours(s).toFixed(2), s.worker ? s.worker.full_name || s.worker.email : "Vacant", s.client?.name ?? "", s.status].map(cell).join(","));
  }
  await logDownload({ kind: "export", label: `Roster, week of ${monday}` });
  return new NextResponse(lines.join("\r\n") + "\r\n", { headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="roster-${monday}.csv"`, "Cache-Control": "no-store" } });
}

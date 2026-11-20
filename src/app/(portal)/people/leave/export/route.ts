// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { logDownload } from "@/lib/download-log";
import { requireSession } from "@/lib/session";
import { seesAllRequestsFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { LEAVE_LABEL } from "@/lib/requests-shared";

// cmeprojects (HR block step 3): approved leave in a month, for payroll, as
// CSV (weekdays counted). People who see everyone's requests only.
export async function GET(request: NextRequest) {
  const { live } = await requireSession();
  if (live.hr_requests === false || !(await seesAllRequestsFor())) return new NextResponse("Not found", { status: 404 });
  const m = request.nextUrl.searchParams.get("m") ?? "";
  if (!/^\d{4}-\d{2}$/.test(m)) return new NextResponse("Choose a month", { status: 400 });
  const [y, mo] = m.split("-").map(Number);
  const first = `${m}-01`;
  const last = `${m}-${String(new Date(y, mo, 0).getDate()).padStart(2, "0")}`;
  const supabase = await createClient();
  const { data: periods } = await supabase.from("leave_periods").select("user_id, leave_type, start_date, end_date").lte("start_date", last).gte("end_date", first).order("start_date");
  const rows = (periods ?? []) as { user_id: string; leave_type: string; start_date: string; end_date: string }[];
  const ids = [...new Set(rows.map((r) => r.user_id))];
  const [{ data: people }, { data: priv }] = ids.length
    ? await Promise.all([supabase.from("profiles").select("id, full_name, email").in("id", ids), supabase.from("staff_private").select("user_id, employee_id").in("user_id", ids)])
    : [{ data: [] }, { data: [] }];
  const name = new Map(((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const emp = new Map(((priv ?? []) as { user_id: string; employee_id: string | null }[]).map((p) => [p.user_id, p.employee_id ?? ""]));
  const weekdays = (a: string, b: string) => {
    let n = 0;
    for (let d = new Date(`${a}T00:00:00Z`); d <= new Date(`${b}T00:00:00Z`); d.setUTCDate(d.getUTCDate() + 1)) if (d.getUTCDay() % 6 !== 0) n++;
    return n;
  };
  // Cells starting with = + - @ are prefixed so a spreadsheet never runs them.
  const cell = (v: string) => `"${(/^[=+\-@]/.test(v) ? `'${v}` : v).replace(/"/g, '""')}"`;
  const lines = [["Employee ID", "Name", "Leave type", "From", "To", "Weekdays in this month"].map(cell).join(",")];
  for (const r of rows) {
    const from = r.start_date < first ? first : r.start_date;
    const to = r.end_date > last ? last : r.end_date;
    lines.push([emp.get(r.user_id) ?? "", name.get(r.user_id) ?? "", LEAVE_LABEL[r.leave_type] ?? r.leave_type, from, to, String(weekdays(from, to))].map(cell).join(","));
  }
  await logDownload({ kind: "export", label: `Leave, ${m}` });
  return new NextResponse(lines.join("\r\n") + "\r\n", {
    headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="leave-${m}.csv"`, "Cache-Control": "no-store" },
  });
}

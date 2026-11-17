// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { addDays, mondayOf, sydneyInstant, sydneyToday } from "@/lib/sydney-time";
import { PAY_COLUMNS, payColumns, type PayKey } from "@/lib/roster";

// cmeprojects (rostering round 2): approved hours for the week by pay period,
// per worker, for payroll (CSV).
export async function GET(request: NextRequest) {
  const { features } = await requireSession();
  if (features.rostering === false || !(await canDo("ops.roster", "view"))) return new NextResponse("Not found", { status: 404 });
  const w = request.nextUrl.searchParams.get("w") ?? "";
  const monday = mondayOf(/^\d{4}-\d{2}-\d{2}$/.test(w) ? w : sydneyToday());
  const supabase = await createClient();
  const { data: shifts } = await supabase.from("shifts").select("id, worker_id").eq("status", "published").not("worker_id", "is", null).gte("starts_at", sydneyInstant(monday)).lt("starts_at", sydneyInstant(addDays(monday, 7)));
  const ids = ((shifts ?? []) as { id: string; worker_id: string }[]).map((s) => s.id);
  const [{ data: sheets }, { data: people }, { data: priv }, { data: holidayRow }] = await Promise.all([
    ids.length ? supabase.from("shift_timesheets").select("shift_id, worker_id, actual_start, actual_end, break_minutes, km, expense, allowances").eq("status", "approved").in("shift_id", ids) : Promise.resolve({ data: [] }),
    supabase.from("profiles").select("id, full_name, email"),
    supabase.from("staff_private").select("user_id, employee_id"),
    supabase.from("app_settings").select("value").eq("key", "tasks.public_holidays").maybeSingle(),
  ]);
  const holidays = new Set(((Array.isArray(holidayRow?.value) ? holidayRow.value : []) as string[]).map((h) => String(h).slice(0, 10)));
  const name = new Map(((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const empId = new Map(((priv ?? []) as { user_id: string; employee_id: string | null }[]).map((p) => [p.user_id, p.employee_id ?? ""]));
  const tot = new Map<string, Record<PayKey | "km" | "expense", number> & { allow: string[] }>();
  for (const t of (sheets ?? []) as { worker_id: string; actual_start: string; actual_end: string; break_minutes: number; km: number; expense: number; allowances: string[] }[]) {
    const r = tot.get(t.worker_id) ?? { wd0: 0, wd6: 0, wd20: 0, wd22: 0, sat: 0, sun: 0, ph: 0, km: 0, expense: 0, allow: [] };
    const c = payColumns(t.actual_start, t.actual_end, t.break_minutes, holidays);
    for (const [k] of PAY_COLUMNS) r[k] += c[k];
    r.km += Number(t.km);
    r.expense += Number(t.expense);
    r.allow.push(...(t.allowances ?? []));
    tot.set(t.worker_id, r);
  }
  const cell = (v: string) => `"${(/^[=+\-@]/.test(v) ? `'${v}` : v).replace(/"/g, '""')}"`;
  const lines = [["Employee ID", "Name", ...PAY_COLUMNS.map(([, l]) => l), "Mileage (km)", "Expenses ($)", "Allowances"].map(cell).join(",")];
  for (const [w, r] of tot) lines.push([empId.get(w) ?? "", name.get(w) ?? "", ...PAY_COLUMNS.map(([k]) => r[k].toFixed(2)), r.km.toFixed(1), r.expense.toFixed(2), r.allow.join("; ")].map(cell).join(","));
  return new NextResponse(lines.join("\r\n") + "\r\n", { headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="timesheets-${monday}.csv"`, "Cache-Control": "no-store" } });
}

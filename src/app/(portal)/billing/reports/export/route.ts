// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { logDownload } from "@/lib/download-log";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { billingReports } from "@/lib/billing-reports";
import { sydneyToday } from "@/lib/sydney-time";

// cmeprojects (update 166): one financial report section (or all) as CSV, for people with the
// Billing export right. Recorded in the download trail.
// Numbers stay numbers; text that starts like a formula is made safe for spreadsheets.
const cell = (v: unknown) => {
  if (typeof v === "number") return String(v);
  let s = v === null || v === undefined ? "" : String(v);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
export async function GET(request: NextRequest) {
  await requireSession();
  if (!(await canBill("export"))) return new NextResponse("Not found", { status: 404 });
  const q = request.nextUrl.searchParams;
  const from = q.get("from") ?? "", to = q.get("to") ?? "", section = q.get("section") ?? "all";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(from) || !/^\d{4}-\d{2}-\d{2}$/.test(to) || to < from) return new NextResponse("Choose the period.", { status: 400 });
  const sections = (await billingReports(await createClient(), from, to, sydneyToday())).filter((s) => section === "all" || s.key === section);
  if (!sections.length) return new NextResponse("Not found", { status: 404 });
  const csv = sections.map((s) => [[s.title], s.head, ...s.rows].map((r) => r.map(cell).join(",")).join("\r\n")).join("\r\n\r\n");
  await logDownload({ kind: "export", label: `Financial report (${section}) ${from} to ${to}`, details: { area: "billing", section, from, to } });
  return new NextResponse(csv, { headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="financial-report-${section}-${from}-${to}.csv"`, "Cache-Control": "no-store" } });
}

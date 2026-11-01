// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { createClient } from "@/lib/supabase/server";
import { tableToXlsx } from "@/lib/excel";
import type { Table } from "@/lib/register-rows";
import { STAGES } from "../stages";

// cmeprojects: every website enquiry as an Excel file (the database only
// returns them to people allowed to see enquiries).
export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  // Excel downloads are part of Reports and exports (a premium add-on).
  if (session.features.reports === false) return new NextResponse("Reports and exports are switched off", { status: 403 });
  const supabase = await createClient();
  const { data: allowed } = await supabase.rpc("can_see_enquiries");
  if (allowed !== true) return new NextResponse("Not allowed", { status: 403 });
  const [{ data }, brand] = await Promise.all([supabase.from("website_enquiries").select("*").order("created_at", { ascending: false }).limit(5000), getBranding()]);
  const day = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeZone: "Australia/Sydney" });
  const cols: [string, string][] = [
    ["received", "Received"],
    ["name", "Name"],
    ["phone", "Phone"],
    ["email", "Email"],
    ["suburb", "Suburb"],
    ["for", "Support is for"],
    ["plan", "NDIS plan"],
    ["needs", "Looking for"],
    ["time", "Best time"],
    ["heard", "Heard about us"],
    ["source", "From"],
    ["stage", "Stage"],
    ["note", "Note"],
  ];
  const table: Table = {
    columns: cols.map(([key, label]) => ({ key, label })),
    rows: (data ?? []).map((e) => ({
      id: e.id,
      href: "",
      cells: Object.fromEntries(
        Object.entries({
          received: day.format(new Date(e.created_at)),
          name: e.full_name,
          phone: e.phone,
          email: e.email,
          suburb: e.suburb,
          for: e.support_for,
          plan: [e.has_plan, e.managed_by].filter(Boolean).join(", "),
          needs: (e.needs ?? []).join(", "),
          time: e.best_time,
          heard: e.heard_from,
          source: e.source === "chat" ? "Chat" : "Website form",
          stage: STAGES.find((s) => s.key === e.status)?.label ?? e.status,
          note: e.note,
        }).map(([k, v]) => [k, { text: String(v ?? "") }]),
      ),
    })),
  };
  const xlsx = await tableToXlsx(table, {
    companyName: brand.companyName,
    title: "Website enquiries",
    lines: [`Downloaded by ${session.profile.full_name || session.profile.email} on ${day.format(new Date())}`],
    brandColour: brand.colorPrimary,
  });
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="enquiries.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

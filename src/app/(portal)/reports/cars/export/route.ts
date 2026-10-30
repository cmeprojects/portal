// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { canSeeCarReports, canUseCars, getCarRules } from "@/lib/cars";
import { KIND_LABELS, buildCarReport, parseCarFilter } from "@/lib/car-reports";
import { pngSize, tableToXlsx, type ExcelHeader } from "@/lib/excel";

async function fetchLogo(url: string, origin: string): Promise<ExcelHeader["logo"]> {
  try {
    const res = await fetch(new URL(url, origin), { cache: "no-store" });
    const type = res.headers.get("content-type") ?? "";
    if (!res.ok || !/image\/(png|jpe?g)/.test(type)) return undefined;
    const buffer = await res.arrayBuffer();
    if (buffer.byteLength > 3_000_000) return undefined;
    const png = type.includes("png");
    const size = png ? pngSize(buffer) : null;
    return { buffer, extension: png ? "png" : "jpeg", width: size?.width ?? 4, height: size?.height ?? 3 };
  } catch {
    return undefined;
  }
}

// The chosen car report as an Excel file, with the logo, company name, dates and filters.
export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  if (!canUseCars(session.profile.role, session.features) || !canSeeCarReports(session.profile.role, await getCarRules())) {
    return new NextResponse("Not allowed", { status: 403 });
  }
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const f = parseCarFilter(Object.fromEntries(request.nextUrl.searchParams), todayIn(timeZone));
  const report = await buildCarReport(f, timeZone);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const totals = `${report.totals.trips} trips · ${report.totals.km.toLocaleString("en-AU")} km`;
  const xlsx = await tableToXlsx(report.table, {
    companyName: brand.companyName,
    title: KIND_LABELS[f.kind],
    lines: [
      `${report.filterText} · ${totals}${report.carDetails ? ` · ${report.carDetails}` : ""}`,
      `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`,
    ],
    brandColour: brand.colorPrimary,
    logo: await fetchLogo(brand.logoUrl, request.nextUrl.origin),
  });
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="car-${f.kind}-${f.period.from}-to-${f.period.to}.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

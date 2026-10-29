// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { canSeeCarReports, canUseCars, getCarRules } from "@/lib/cars";
import { buildCarReport, parseCarPeriod } from "@/lib/car-reports";
import { pngSize, tablesToXlsx, type ExcelHeader } from "@/lib/excel";

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

// The car report as one Excel file: mileage, car use log and the summaries,
// each on its own sheet with the logo and company name.
export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  if (!canUseCars(session.profile.role, session.features) || !canSeeCarReports(session.profile.role, await getCarRules())) {
    return new NextResponse("Not allowed", { status: 403 });
  }
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const params = Object.fromEntries(request.nextUrl.searchParams);
  const period = parseCarPeriod(params, todayIn(timeZone));
  const report = await buildCarReport(period, timeZone, params.car ?? "");
  const logo = await fetchLogo(brand.logoUrl, request.nextUrl.origin);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const by = `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`;
  const carLine = report.cars.map((c) => `${c.name} (${c.rego}${c.car_type ? `, ${c.car_type}` : ""}): ${c.km.toLocaleString("en-AU")} km`).join(" · ");
  const header = (title: string, line: string): ExcelHeader => ({
    companyName: brand.companyName,
    title,
    lines: [line, by],
    brandColour: brand.colorPrimary,
    logo,
  });
  const total = `${period.label} · ${report.totals.trips} trips · ${report.totals.km.toLocaleString("en-AU")} km`;
  const xlsx = await tablesToXlsx([
    { sheetName: "Summary", table: report.byCar, header: header("Mileage report: summary by car", total) },
    { sheetName: "Mileage", table: report.mileage, header: header("Mileage: every trip", carLine || total) },
    { sheetName: "Car use log", table: report.log, header: header("Car use log", total) },
    { sheetName: "By staff", table: report.byDriver, header: header("Mileage by staff member", total) },
    { sheetName: "By client", table: report.byClient, header: header("Mileage by client", total) },
  ]);
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="car-report-${period.from}-to-${period.to}.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

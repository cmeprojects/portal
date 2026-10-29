// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { canManageCompliance, canSeeReports, getPeopleRules, getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { buildReports, parsePeriod } from "@/lib/reports";
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

// One table from the Reports page as an Excel file, with the logo and header.
export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  const rules = await getPeopleRules();
  if (!canSeeReports(session.profile.role, rules) || session.features.reports === false) {
    return new NextResponse("Not allowed", { status: 403 });
  }
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const today = todayIn(timeZone);
  const params = Object.fromEntries(request.nextUrl.searchParams);
  const period = parsePeriod(params, today);
  const withCompliance = canManageCompliance(session.profile.role, rules) || session.profile.role === "manager";
  const { tables } = await buildReports(period, today, timeZone, withCompliance);
  const section = tables.find((t) => t.key === params.section);
  if (!section) return new NextResponse("Not found", { status: 404 });

  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const xlsx = await tableToXlsx(section.table, {
    companyName: brand.companyName,
    title: `Report: ${section.title}`,
    lines: [`${period.label} · ${section.intro}`, `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`],
    brandColour: brand.colorPrimary,
    logo: await fetchLogo(brand.logoUrl, request.nextUrl.origin),
  });
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="report-${section.key}-${period.from}-to-${period.to}.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

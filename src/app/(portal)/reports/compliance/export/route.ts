// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { canSeeComplianceReport, getPeopleRules, getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { SHOW_LABELS, VIEW_LABELS, buildComplianceReport, parseComplianceFilter } from "@/lib/compliance-report";
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

// The Compliance report as it's shown, as an Excel file with the logo.
export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  if (!canSeeComplianceReport(session.profile.role, await getPeopleRules()) || session.features.reports === false) {
    return new NextResponse("Not allowed", { status: 403 });
  }
  const params: Record<string, string | string[]> = {};
  request.nextUrl.searchParams.forEach((v, k) => {
    const prev = params[k];
    params[k] = prev === undefined ? v : Array.isArray(prev) ? [...prev, v] : [prev, v];
  });
  const f = parseComplianceFilter(params);
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const report = await buildComplianceReport(f, todayIn(timeZone));
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const xlsx = await tableToXlsx(report.table, {
    companyName: brand.companyName,
    title: `Compliance: ${VIEW_LABELS[f.view]}`,
    lines: [
      `${SHOW_LABELS[f.show]} · ${report.totals.people} people · ${report.totals.finished} all done · ${report.totals.expired} with something expired`,
      `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`,
    ],
    brandColour: brand.colorPrimary,
    logo: await fetchLogo(brand.logoUrl, request.nextUrl.origin),
  });
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="compliance-${f.view}-${todayIn(timeZone)}.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { loadFeature } from "@/lib/custom-features";
import { FEATURE_KIND_LABELS, buildFeatureReport, parseFeatureFilter } from "@/lib/feature-reports";
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

// A built feature's report as an Excel file, with the logo, company name, dates and filters.
export async function GET(request: NextRequest, ctx: RouteContext<"/reports/f/[slug]/export">) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  const def = await loadFeature({ slug: (await ctx.params).slug });
  if (!def || def.feature.status !== "published" || !def.feature.enabled) return new NextResponse("Not found", { status: 404 });
  const supabase = await createClient();
  const { data: allowed } = await supabase.rpc("can_see_feature", { p_feature: def.feature.id });
  if (!allowed) return new NextResponse("Not allowed", { status: 403 });
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const f = parseFeatureFilter(Object.fromEntries(request.nextUrl.searchParams), todayIn(timeZone), Boolean(def.feature.total_field && def.feature.group_field));
  const report = await buildFeatureReport(def.feature, def.fields, f, timeZone);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const xlsx = await tableToXlsx(report.table, {
    companyName: brand.companyName,
    title: `${def.feature.name}: ${FEATURE_KIND_LABELS[f.kind]}`,
    lines: [`${report.filterText} · ${report.totals.entries} entries`, `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`],
    brandColour: brand.colorPrimary,
    logo: await fetchLogo(brand.logoUrl, request.nextUrl.origin),
  });
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="${def.feature.slug}-${f.kind}-${f.period.from}-to-${f.period.to}.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

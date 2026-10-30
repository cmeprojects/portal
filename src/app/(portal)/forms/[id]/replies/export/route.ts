// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import { loadForm } from "@/lib/forms";
import { buildFormReport } from "@/lib/form-report";
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

// A form's replies as an Excel file, with the logo, company name and date.
export async function GET(request: NextRequest, ctx: RouteContext<"/forms/[id]/replies/export">) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  const def = await loadForm((await ctx.params).id);
  if (!def) return new NextResponse("Not found", { status: 404 });
  const { data: canManage } = await (await createClient()).rpc("can_manage_form", { p_form: def.form.id });
  if (!canManage) return new NextResponse("Not allowed", { status: 403 });
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const report = await buildFormReport(def.form, def.questions, timeZone);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const xlsx = await tableToXlsx(report.table, {
    companyName: brand.companyName,
    title: def.form.title,
    lines: [
      `${report.totals.replies} replies${report.totals.sent ? ` · sent to ${report.totals.sent}, ${report.totals.done} done` : ""}`,
      `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`,
    ],
    brandColour: brand.colorPrimary,
    logo: await fetchLogo(brand.logoUrl, request.nextUrl.origin),
  });
  const safe = def.form.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40) || "form";
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="${safe}-replies.xlsx"`,
      "Cache-Control": "no-store",
    },
  });
}

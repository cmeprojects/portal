// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { formatDate } from "@/lib/registers";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { parseFilter, registerTable } from "@/lib/register-rows";
import { pngSize, tableToXlsx, type ExcelHeader } from "@/lib/excel";

// The company's logo for the spreadsheet (PNG or JPEG only; Excel can't use SVG).
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

// Downloads a register as an Excel file with the company's logo and a header.
export async function GET(request: NextRequest, ctx: RouteContext<"/registers/[id]/export">) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  const { id } = await ctx.params;
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) return new NextResponse("Not found", { status: 404 });

  const filter = parseFilter(Object.fromEntries(request.nextUrl.searchParams));
  const [fields, people, assets, timeZone, brand] = await Promise.all([getFields(), getPeople(), getAssets(), getTimeZone(), getBranding()]);
  const today = todayIn(timeZone);
  const table = await registerTable(registry, fields, people, assets, filter, today);

  const records = registry.kind === "records";
  const which = records
    ? { open: "Items in the list", done: "Archived items", all: "All items" }[filter.status]
    : { open: "Open tasks", done: "Completed tasks", all: "All tasks" }[filter.status];
  const dateWord = records ? "Added" : "Date reported";
  const dates =
    filter.from && filter.to
      ? `${dateWord}: ${formatDate(filter.from)} to ${formatDate(filter.to)}`
      : filter.from
        ? `${dateWord}: from ${formatDate(filter.from)}`
        : filter.to
          ? `${dateWord}: up to ${formatDate(filter.to)}`
          : `${dateWord}: all dates`;
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());

  const xlsx = await tableToXlsx(table, {
    companyName: brand.companyName,
    title: registry.name,
    lines: [
      `${which} · ${dates}${filter.q ? ` · title contains "${filter.q}"` : ""} · ${table.rows.length} row${table.rows.length === 1 ? "" : "s"}`,
      `Downloaded by ${session.profile.full_name || session.profile.email} on ${when}`,
    ],
    brandColour: brand.colorPrimary,
    logo: await fetchLogo(brand.logoUrl, request.nextUrl.origin),
  });

  const span = filter.from || filter.to ? `${filter.from || "start"}-to-${filter.to || today}` : today;
  const file = `${registry.name.replace(/[^A-Za-z0-9]+/g, "-")}-${span}.xlsx`;
  return new NextResponse(xlsx, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="${file}"`,
      "Cache-Control": "no-store",
    },
  });
}

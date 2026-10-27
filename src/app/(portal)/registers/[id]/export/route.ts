// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { toCsv } from "@/lib/registers";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { parseFilter, registerTable } from "@/lib/register-rows";

// Downloads a register as a CSV file that opens in Excel.
export async function GET(request: NextRequest, ctx: RouteContext<"/registers/[id]/export">) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  const { id } = await ctx.params;
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) return new NextResponse("Not found", { status: 404 });

  const filter = parseFilter(Object.fromEntries(request.nextUrl.searchParams));
  const [fields, people, assets, timeZone] = await Promise.all([getFields(), getPeople(), getAssets(), getTimeZone()]);
  const today = todayIn(timeZone);
  const table = await registerTable(registry, fields, people, assets, filter, today);
  const csv = toCsv([table.columns.map((c) => c.label), ...table.rows.map((r) => table.columns.map((c) => r.cells[c.key]?.text ?? ""))]);
  const file = `${registry.name.replace(/[^A-Za-z0-9]+/g, "-")}-${today}.csv`;

  return new NextResponse(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="${file}"`,
      "Cache-Control": "no-store",
    },
  });
}

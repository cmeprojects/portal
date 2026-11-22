// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { logDownload } from "@/lib/download-log";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (update 163): the claim file exactly as made from the official
// template, for manual upload. Downloading never marks the claim submitted.
// Recorded in the download trail.
export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  await requireSession();
  if (!(await canBill("view"))) return new NextResponse("Not found", { status: 404 });
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) return new NextResponse("Not found", { status: 404 });
  const { data } = await (await createClient()).from("claims").select("file_name, file_content, file_checksum, program, period_from, period_to").eq("id", id).maybeSingle();
  if (!data?.file_content) return new NextResponse("Not found", { status: 404 });
  await logDownload({ kind: "export", label: `Claim file ${data.file_name}`, details: { area: "billing", claim: id, checksum: data.file_checksum } });
  return new NextResponse(data.file_content, {
    headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="${String(data.file_name).replace(/[^\w.\-]/g, "_")}"`, "Cache-Control": "no-store" },
  });
}

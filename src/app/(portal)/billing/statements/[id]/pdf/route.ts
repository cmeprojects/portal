// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { logDownload } from "@/lib/download-log";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (update 163): the monthly statement PDF exactly as stored when issued.
export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  await requireSession();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) return new NextResponse("Not found", { status: 404 });
  const { data } = await (await createClient()).from("client_statements").select("client_id, month, pdf_base64, pdf_checksum").eq("id", id).maybeSingle();
  if (!data?.pdf_base64 || !(await canBill("view", data.client_id))) return new NextResponse("Not found", { status: 404 });
  await logDownload({ kind: "document", label: `Monthly statement ${String(data.month).slice(0, 7)}`, clientId: data.client_id, details: { area: "billing", statement: id, checksum: data.pdf_checksum } });
  return new NextResponse(Buffer.from(data.pdf_base64, "base64"), {
    headers: { "Content-Type": "application/pdf", "Content-Disposition": `attachment; filename="statement-${String(data.month).slice(0, 7)}.pdf"`, "Cache-Control": "no-store" },
  });
}

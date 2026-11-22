// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { logDownload } from "@/lib/download-log";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (update 162): approved billing lines for a period (CSV), for
// people with the Billing export right. Recorded in the download trail.
// An export only: claims and invoices come in Phase 5.
const cell = (v: unknown) => {
  const s = v === null || v === undefined ? "" : String(v);
  return /[",\n]/.test(s) || /^[=+\-@]/.test(s) ? `"${s.replace(/^([=+\-@])/, "'$1").replace(/"/g, '""')}"` : s;
};
export async function GET(request: NextRequest) {
  await requireSession();
  if (!(await canBill("export"))) return new NextResponse("Not found", { status: 404 });
  const from = request.nextUrl.searchParams.get("from") ?? "";
  const to = request.nextUrl.searchParams.get("to") ?? "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(from) || !/^\d{4}-\d{2}-\d{2}$/.test(to) || to < from) return new NextResponse("Choose the period.", { status: 400 });
  const supabase = await createClient();
  const { data, error } = await supabase.from("billing_lines").select("*").eq("status", "approved").gte("service_date", from).lte("service_date", to).order("service_date").order("starts_at").limit(20000);
  if (error) return new NextResponse("Billing lines aren't available.", { status: 404 });
  type L = Record<string, unknown> & { client_id: string; service_id: string; terms_id: string };
  const lines = (data ?? []) as L[];
  const cIds = [...new Set(lines.map((l) => l.client_id))];
  const sIds = [...new Set(lines.map((l) => l.service_id))];
  const [{ data: cRows }, { data: sRows }] = await Promise.all([
    cIds.length ? supabase.from("car_clients").select("id, name, client_ref").in("id", cIds) : Promise.resolve({ data: [] }),
    sIds.length ? supabase.from("client_services").select("id, label").in("id", sIds) : Promise.resolve({ data: [] }),
  ]);
  const client = new Map(((cRows ?? []) as { id: string; name: string; client_ref: string | null }[]).map((c) => [c.id, c]));
  const svc = new Map(((sRows ?? []) as { id: string; label: string }[]).map((s) => [s.id, s.label]));
  const head = ["Service date", "Client", "Client ref", "Service", "Scheme", "Funding stream", "Kind", "Band", "Minutes billed", "Quantity", "Unit", "Unit price", "Amount", "GST code", "Category", "Contribution %", "Client share", "Funding share", "Over budget", "Approval note", "Line id", "Shift id", "Billing terms id", "Enrolment id", "Funding record id", "Quarter budget id", "Agreement id", "Corrects line id"];
  const rows = lines.map((l) => [
    l.service_date, client.get(l.client_id)?.name ?? "", client.get(l.client_id)?.client_ref ?? "", svc.get(l.service_id) ?? "", l.scheme, l.funding_stream, l.kind, l.band_label, l.minutes_billed, l.quantity, l.unit, l.unit_price, l.amount,
    l.gst_code, l.sah_category ?? "", l.contribution_pct ?? "", l.client_share ?? "", l.government_share ?? "", l.over_budget ? "yes" : "no", l.approve_note, l.id, l.shift_id, l.terms_id, l.enrolment_id, l.funding_id ?? "", l.quarter_budget_id ?? "", l.agreement_id ?? "", l.corrects_id ?? "",
  ]);
  const csv = [head, ...rows].map((r) => r.map(cell).join(",")).join("\r\n");
  await logDownload({ kind: "export", label: `Billing lines ${from} to ${to} (${lines.length} approved)`, details: { from, to, lines: lines.length, area: "billing" } });
  return new NextResponse(`﻿${csv}`, { headers: { "content-type": "text/csv; charset=utf-8", "content-disposition": `attachment; filename="billing-lines-${from}-to-${to}.csv"` } });
}

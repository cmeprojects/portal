// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { creditNotePdf, invoicePdf, receiptPdf, statementPdf } from "@/lib/billing-pdf";
import { loadDocTheme, type DocKind } from "@/lib/document-theme";
import { sydneyToday } from "@/lib/sydney-time";

// cmeprojects (update 168): a sample PDF of a document kind with its saved template, the business
// details and the portal's logo and colours. Sample client and amounts only (nothing is issued).
export async function GET(request: NextRequest) {
  await requireSession();
  if (!(await canBill("view"))) return new NextResponse("Not found", { status: 404 });
  const kind = (request.nextUrl.searchParams.get("kind") ?? "statement") as DocKind;
  if (!["invoice", "statement", "receipt", "credit_note"].includes(kind)) return new NextResponse("Not found", { status: 404 });
  const supabase = await createClient();
  const { theme } = await loadDocTheme(supabase, kind);
  const { data: biz } = await supabase.from("business_current").select("*").maybeSingle();
  const business = (biz ?? { legal_name: "Your business name", abn: "51824753556", address: "1 Example Street", suburb: "Suburb", state: "NSW", postcode: "2000" }) as Record<string, unknown>;
  const today = sydneyToday();
  const client = { name: "Sample Client", client_ref: "CL-00001", aged_care_id: "AC-SAMPLE", ndis_number: "430000000", address: "1 Sample Street, Suburb NSW 2000" };
  const items = [
    { description: "Domestic assistance (Weekday day), your contribution 17.5% of $160.00", service_date: today, quantity: 1, unit_price: 28, amount: 28, gst_code: "gst_free", gst_amount: 0 },
    { description: "Personal care (Weekday day), your contribution 0% (clinical)", service_date: today, quantity: 1, unit_price: 0, amount: 0, gst_code: "gst_free", gst_amount: 0 },
  ];
  let pdf: { bytes: Uint8Array };
  if (kind === "invoice") {
    pdf = await invoicePdf({ number: "INV-SAMPLE", tax_invoice: false, issue_date: today, due_date: today, period_from: today, period_to: today, subtotal: 28, gst: 0, total: 28, kind: "sah_contribution",
      snapshot: { business, client, payer: { name: "Sample Client", email: "client@example.com" }, items } }, theme, { [`${today}|${items[0].description}`]: "SERV-0003" });
  } else if (kind === "statement") {
    const m = `${today.slice(0, 7)}-01`;
    pdf = await statementPdf({ month: m, snapshot: { business, client, month_end: today, period_days: 30, quarter: { start: m, end: today, quarterly_amount: 9200, carryover_in: 49.94, care_management: 920, spendable: 8280 },
      carried_in: { rollover: 49.94, unspent_hcp: 0 }, quarter_months: [{ month: m, subsidy: 3066.67, expenditure: 2810.5 }], month_income: { subsidy: 3066.67 },
      month_expenditure: { services: 2400, other_charges: 104.83, care_management: 306.67 }, contributions_in_month: 56,
      service_lines: [{ date: today, code: "SERV-0003", service: "Domestic assistance", category: "everyday_living", pct: 17.5, quantity: 2, rate: 80, band: "Weekday day", amount: 160, client_share: 28 }],
      charge_lines: [{ date: today, description: "Taxi service", stream: "ongoing", category: "independence", pct: 0, amount: 104.83, client_share: 0 }] } }, theme);
  } else if (kind === "receipt") {
    pdf = await receiptPdf({ receipt_number: "RCT-SAMPLE", received_on: today, amount: 28, method: "eft", reference: "SAMPLE", business, payer: { name: "Sample Client" }, client, allocations: [{ amount: 28, invoice: "INV-SAMPLE" }] }, theme);
  } else {
    pdf = await creditNotePdf({ number: "CN-SAMPLE", issue_date: today, amount: 28, gst: 0, snapshot: { business, client, payer: { name: "Sample Client" }, invoice: { number: "INV-SAMPLE", issue_date: today, tax_invoice: false }, reason: "Sample credit", items: [{ service_date: today, description: items[0].description, amount: 28 }] } }, theme);
  }
  return new NextResponse(Buffer.from(pdf.bytes), { headers: { "Content-Type": "application/pdf", "Content-Disposition": `inline; filename="${kind}-sample.pdf"`, "Cache-Control": "no-store" } });
}

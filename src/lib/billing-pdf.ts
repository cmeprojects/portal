// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createHash } from "node:crypto";
import { PDFDocument, StandardFonts, rgb, type PDFFont, type PDFPage } from "pdf-lib";

// cmeprojects (update 163): client invoices and monthly Support at Home
// statements as PDFs, drawn only from the snapshot saved when the document was
// issued (business details, payer, client and lines as they were then), so the
// document never changes. Customer-facing wording uses the business's own name.
type Snap = Record<string, unknown>;
const safe = (s: unknown) =>
  String(s ?? "")
    .replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/[–—]/g, "-").replace(/…/g, "...")
    .replace(/[^\x20-\x7E\xA0-\xFF]/g, "?");
const aud = (n: unknown) => Number(n ?? 0).toLocaleString("en-AU", { style: "currency", currency: "AUD" });
const dmy = (d: unknown) => (d ? String(d).slice(0, 10).split("-").reverse().join("/") : "");
const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

class Writer {
  page!: PDFPage;
  y = 0;
  constructor(public doc: PDFDocument, public font: PDFFont, public bold: PDFFont) { this.newPage(); }
  newPage() { this.page = this.doc.addPage([595.28, 841.89]); this.y = 800; }
  need(h: number) { if (this.y - h < 60) this.newPage(); }
  text(s: unknown, x: number, size = 10, b = false, color = rgb(0.1, 0.1, 0.1)) { this.page.drawText(safe(s), { x, y: this.y, size, font: b ? this.bold : this.font, color }); }
  right(s: unknown, xRight: number, size = 10, b = false) { const t = safe(s); this.page.drawText(t, { x: xRight - (b ? this.bold : this.font).widthOfTextAtSize(t, size), y: this.y, size, font: b ? this.bold : this.font }); }
  line() { this.page.drawLine({ start: { x: 40, y: this.y + 4 }, end: { x: 555, y: this.y + 4 }, thickness: 0.5, color: rgb(0.7, 0.7, 0.7) }); }
  fit(s: unknown, width: number, size = 9) { let t = safe(s); while (t.length > 3 && this.font.widthOfTextAtSize(t, size) > width) t = t.slice(0, -4) + "..."; return t; }
}

function header(w: Writer, b: Snap, title: string) {
  w.text(b.trading_name || b.legal_name, 40, 16, true);
  w.right(title, 555, 16, true);
  w.y -= 16;
  if (b.trading_name && b.trading_name !== b.legal_name) { w.text(b.legal_name, 40, 9); w.y -= 12; }
  w.text(`ABN ${String(b.abn ?? "").replace(/^(\d{2})(\d{3})(\d{3})(\d{3})$/, "$1 $2 $3 $4")}`, 40, 9); w.y -= 12;
  w.text(`${b.address ?? ""}, ${b.suburb ?? ""} ${b.state ?? ""} ${b.postcode ?? ""}`, 40, 9); w.y -= 12;
  const contact = [b.phone, b.email].filter(Boolean).join(" · ");
  if (contact) { w.text(contact, 40, 9); w.y -= 12; }
  w.y -= 8;
}

export async function invoicePdf(inv: { number: string; tax_invoice: boolean; issue_date: string; due_date: string; period_from: string; period_to: string; subtotal: number; gst: number; total: number; kind: string; snapshot: Snap }) {
  const doc = await PDFDocument.create();
  const w = new Writer(doc, await doc.embedFont(StandardFonts.Helvetica), await doc.embedFont(StandardFonts.HelveticaBold));
  const s = inv.snapshot;
  const b = (s.business ?? {}) as Snap;
  const p = (s.payer ?? {}) as Snap;
  const c = (s.client ?? {}) as Snap;
  doc.setTitle(`${inv.tax_invoice ? "Tax invoice" : "Invoice"} ${inv.number}`);
  header(w, b, inv.tax_invoice ? "TAX INVOICE" : "INVOICE");
  const top = w.y;
  w.text("Bill to", 40, 9, true); w.y -= 12;
  w.text(p.name, 40, 10); w.y -= 12;
  if (p.address) { w.text(w.fit(p.address, 260), 40, 9); w.y -= 12; }
  if (p.email) { w.text(p.email, 40, 9); w.y -= 12; }
  if (p.abn) { w.text(`ABN ${p.abn}`, 40, 9); w.y -= 12; }
  w.y -= 4;
  w.text("For", 40, 9, true); w.y -= 12;
  w.text(`${c.name ?? ""}${c.client_ref ? ` (ref ${c.client_ref})` : ""}`, 40, 10); w.y -= 12;
  if (inv.kind.startsWith("ndis") && c.ndis_number) { w.text(`NDIS number ${c.ndis_number}`, 40, 9); w.y -= 12; }
  if (inv.kind === "sah_contribution" && c.aged_care_id) { w.text(`Aged care ID ${c.aged_care_id}`, 40, 9); w.y -= 12; }
  const left = w.y;
  w.y = top;
  for (const [k, v] of [["Invoice number", inv.number], ["Issue date", dmy(inv.issue_date)], ["Due date", dmy(inv.due_date)], ["Service period", `${dmy(inv.period_from)} to ${dmy(inv.period_to)}`]]) {
    w.text(k, 340, 9, true); w.right(v, 555, 9); w.y -= 13;
  }
  w.y = Math.min(left, w.y) - 14;
  w.text("Date", 40, 9, true); w.text("Description", 100, 9, true); w.right("Qty", 400, 9, true); w.right("Unit price", 470, 9, true); w.right("Amount", 555, 9, true);
  w.y -= 6; w.line(); w.y -= 10;
  for (const it of (s.items ?? []) as Snap[]) {
    w.need(14);
    w.text(dmy(it.service_date), 40, 9);
    w.text(w.fit(`${it.description}${inv.tax_invoice && it.gst_code === "taxable" ? " *" : ""}`, 250), 100, 9);
    w.right(Number(it.quantity).toFixed(2), 400, 9); w.right(aud(it.unit_price), 470, 9); w.right(aud(it.amount), 555, 9);
    w.y -= 13;
  }
  w.line(); w.y -= 12;
  w.need(60);
  if (inv.tax_invoice) {
    w.text("Subtotal", 380, 10); w.right(aud(inv.subtotal), 555, 10); w.y -= 13;
    w.text(b.prices_include_gst ? "GST included" : "GST", 380, 10); w.right(aud(inv.gst), 555, 10); w.y -= 13;
  }
  w.text("Total due", 380, 11, true); w.right(aud(inv.total), 555, 11, true); w.y -= 18;
  if (inv.tax_invoice) { w.text("* GST applies to this item. Items without * are GST-free.", 40, 8); w.y -= 12; }
  else if (b.gst_registered) { w.text("All items are GST-free.", 40, 8); w.y -= 12; }
  w.y -= 8;
  w.need(70);
  w.text("How to pay", 40, 10, true); w.y -= 13;
  if (b.payment_bsb) { w.text(`Bank transfer: ${b.payment_account_name || b.legal_name}, BSB ${b.payment_bsb}, account ${b.payment_account_number}. Reference: ${inv.number}`, 40, 9); w.y -= 12; }
  if (b.payment_other) { for (const ln of String(b.payment_other).split(/\r?\n/).slice(0, 4)) { w.text(w.fit(ln, 515), 40, 9); w.y -= 12; } }
  w.text(`Please pay by ${dmy(inv.due_date)}. Questions about this invoice: ${b.email || b.phone || "contact us"}.`, 40, 9);
  const bytes = await doc.save();
  return { bytes, checksum: createHash("sha256").update(bytes).digest("hex") };
}

export async function statementPdf(st: { month: string; snapshot: Snap }) {
  const doc = await PDFDocument.create();
  const w = new Writer(doc, await doc.embedFont(StandardFonts.Helvetica), await doc.embedFont(StandardFonts.HelveticaBold));
  const s = st.snapshot;
  const b = (s.business ?? {}) as Snap;
  const c = (s.client ?? {}) as Snap;
  const q = (s.quarter ?? null) as Snap | null;
  const [y, m] = st.month.split("-");
  const label = `${MONTHS[Number(m) - 1]} ${y}`;
  doc.setTitle(`Monthly statement ${label}`);
  header(w, b, "MONTHLY STATEMENT");
  w.text(`Support at Home statement for ${label}`, 40, 12, true); w.y -= 16;
  w.text(`${c.name ?? ""}${c.aged_care_id ? ` · Aged care ID ${c.aged_care_id}` : ""}${c.client_ref ? ` · ref ${c.client_ref}` : ""}`, 40, 10); w.y -= 20;
  if (q) {
    for (const [k, v] of [
      ["Quarter", `${dmy(q.start)} to ${dmy(q.end)}`], ["Quarterly budget", aud(q.quarterly_amount)], ["Carried over from last quarter", aud(q.carryover_in)],
      ["Care management (held separately)", aud(q.care_management)], ["Available for services this quarter", aud(q.spendable)],
      ["Services this month (full price)", aud(s.spent_in_month)], ["Your contributions this month", aud(s.contributions_in_month)], ["Available now", aud(s.available_now)],
    ]) { w.text(k, 40, 10); w.right(v, 555, 10); w.y -= 14; }
  } else { w.text("No approved quarter budget covers this month.", 40, 10); w.y -= 14; }
  if (s.fee_reduction_in_month) { w.text("A fee reduction supplement applied this month: those contributions aren't charged.", 40, 9); w.y -= 14; }
  w.y -= 8;
  w.text("Date", 40, 9, true); w.text("Service", 110, 9, true); w.right("Qty", 380, 9, true); w.right("Price", 465, 9, true); w.right("Your share", 555, 9, true);
  w.y -= 6; w.line(); w.y -= 10;
  for (const l of (s.lines ?? []) as Snap[]) {
    w.need(14);
    w.text(dmy(l.date), 40, 9); w.text(w.fit(l.band, 230), 110, 9); w.right(Number(l.quantity).toFixed(2), 380, 9); w.right(aud(l.amount), 465, 9); w.right(aud(l.client_share), 555, 9);
    w.y -= 13;
  }
  w.y -= 10;
  w.text("Your contribution is set by Services Australia. Contributions are invoiced separately.", 40, 8);
  const bytes = await doc.save();
  return { bytes, checksum: createHash("sha256").update(bytes).digest("hex") };
}

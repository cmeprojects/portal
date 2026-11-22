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

// cmeprojects (update 166, owner's sample statement 23 Nov 2026): the monthly Support at Home
// statement laid out like a full package statement: funds carried in, the quarter month by month,
// this month's income and expenditure, then each service and charge with its contribution.
// Statements issued before update 166 (less detail in their snapshot) still print.
export async function statementPdf(st: { month: string; snapshot: Snap }) {
  const doc = await PDFDocument.create();
  const w = new Writer(doc, await doc.embedFont(StandardFonts.Helvetica), await doc.embedFont(StandardFonts.HelveticaBold));
  const s = st.snapshot;
  const b = (s.business ?? {}) as Snap;
  const c = (s.client ?? {}) as Snap;
  const q = (s.quarter ?? null) as Snap | null;
  const [y, m] = st.month.split("-");
  const label = `${MONTHS[Number(m) - 1]} ${y}`;
  const endDay = new Date(Number(y), Number(m), 0).getDate();
  const days = Number(s.period_days ?? endDay);
  const dd = (iso: unknown) => { const t = String(iso ?? "").slice(0, 10).split("-"); return t.length === 3 ? `${t[2]} ${MONTHS[Number(t[1]) - 1].slice(0, 3)} ${t[0]}` : ""; };
  const CAT: Record<string, string> = { clinical: "Clinical", independence: "Independence", everyday_living: "Everyday living" };
  const STREAM: Record<string, string> = { ongoing: "Quarterly budget", at_hm: "AT-HM", restorative: "Restorative Care", end_of_life: "End-of-Life", hcp_unspent: "Unspent HCP funds" };
  const grey = rgb(0.32, 0.36, 0.4);
  const light = rgb(0.93, 0.94, 0.95);
  doc.setTitle(`Support at Home statement ${label}`);

  const bar = (title: string) => {
    w.need(40);
    w.page.drawRectangle({ x: 40, y: w.y - 6, width: 515, height: 20, color: grey });
    w.page.drawText(safe(title).toUpperCase(), { x: 46, y: w.y, size: 9.5, font: w.bold, color: rgb(1, 1, 1) });
    w.y -= 24;
  };
  const row = (left: string, right: string, opts: { bold?: boolean; shade?: boolean; red?: boolean; mid?: string } = {}) => {
    w.need(16);
    if (opts.shade) w.page.drawRectangle({ x: 40, y: w.y - 4, width: 515, height: 16, color: light });
    w.text(left, 46, 9.5, !!opts.bold);
    if (opts.mid !== undefined) w.right(opts.mid, 400, 9.5, !!opts.bold);
    const t = safe(right);
    w.page.drawText(t, { x: 549 - (opts.bold ? w.bold : w.font).widthOfTextAtSize(t, 9.5), y: w.y, size: 9.5, font: opts.bold ? w.bold : w.font, color: opts.red ? rgb(0.75, 0.1, 0.1) : rgb(0.1, 0.1, 0.1) });
    w.y -= 16;
  };
  type Col = { h: string; x: number; wd: number; right?: boolean };
  const table = (cols: Col[], rows: string[][], total?: string[]) => {
    const head = () => {
      w.need(30);
      w.page.drawRectangle({ x: 40, y: w.y - 4, width: 515, height: 16, color: light });
      for (const k of cols) { if (k.right) w.right(k.h, k.x + k.wd, 8, true); else w.text(k.h, k.x, 8, true); }
      w.y -= 16;
    };
    head();
    for (const r of rows) {
      if (w.y < 80) { w.newPage(); head(); }
      r.forEach((v, i) => { const k = cols[i]; const t = w.fit(v, k.wd, 8.5); if (k.right) w.right(t, k.x + k.wd, 8.5); else w.text(t, k.x, 8.5); });
      w.y -= 13;
    }
    if (total) { w.line(); w.y -= 11; total.forEach((v, i) => { if (!v) return; const k = cols[i]; if (k.right) w.right(v, k.x + k.wd, 8.5, true); else w.text(v, k.x, 8.5, true); }); w.y -= 16; }
  };

  // Page 1: summary.
  w.text(b.trading_name || b.legal_name, 40, 11, true);
  w.y -= 26;
  const title = "Support at Home Statement";
  w.page.drawText(title, { x: 297.6 - w.bold.widthOfTextAtSize(title, 17) / 2, y: w.y, size: 17, font: w.bold });
  w.y -= 16;
  const per = `Statement period ${dd(st.month)} to ${dd(s.month_end ?? `${y}-${m}-${endDay}`)} (${days} days)`;
  w.page.drawText(safe(per), { x: 297.6 - w.font.widthOfTextAtSize(safe(per), 9.5) / 2, y: w.y, size: 9.5, font: w.font });
  w.y -= 22;
  w.page.drawRectangle({ x: 40, y: w.y - 34, width: 515, height: 46, borderColor: rgb(0.75, 0.75, 0.75), borderWidth: 0.6 });
  w.text(c.name, 50, 10, true); w.right(c.aged_care_id ? `Aged care recipient ID: ${c.aged_care_id}` : "", 545, 9, true); w.y -= 13;
  w.text(w.fit(c.address ?? "", 330, 9), 50, 9); w.y -= 13;
  if (c.client_ref) { w.text(`Client reference ${c.client_ref}`, 50, 8.5); }
  w.y -= 26;

  const carried = (s.carried_in ?? null) as Snap | null;
  bar(q ? `Funds carried into this quarter (from ${dd(q.start)})` : "Funds carried into this quarter");
  row("Unspent Home Care Package funds", aud(carried?.unspent_hcp ?? 0));
  row("Quarterly rollover funds", aud(carried?.rollover ?? q?.carryover_in ?? 0), { shade: true });
  w.y -= 8;

  const months = (s.quarter_months ?? []) as Snap[];
  if (q) {
    bar(`Quarterly budget remaining as of ${dd(s.month_end ?? `${y}-${m}-${endDay}`)}`);
    row("Month", "Expenditure", { bold: true, shade: true, mid: "Subsidy" });
    let ts = 0, te = 0;
    for (const mm of months) {
      ts += Number(mm.subsidy); te += Number(mm.expenditure);
      row(MONTHS[Number(String(mm.month).slice(5, 7)) - 1], aud(mm.expenditure), { mid: aud(mm.subsidy) });
    }
    row("Total", aud(te), { bold: true, mid: aud(ts) });
    const carriedIn = Number(q.carryover_in ?? 0);
    if (carriedIn) row("Plus rollover funds carried in", aud(carriedIn));
    const remaining = ts + carriedIn - te;
    row("Quarterly budget remaining", aud(remaining), { bold: true, shade: true, red: remaining < 0 });
    w.y -= 8;
  }

  const inc = (s.month_income ?? {}) as Snap;
  const ex = (s.month_expenditure ?? {}) as Snap;
  const services = Number(ex.services ?? s.spent_in_month ?? 0);
  const other = Number(ex.other_charges ?? 0);
  const cm = Number(ex.care_management ?? 0);
  const income = Number(inc.subsidy ?? 0);
  bar(`Income and expenditure for ${label}`);
  row("Income", "", { bold: true, shade: true });
  row("Government subsidy (Support at Home quarterly budget)", aud(income));
  row("Total income", aud(income), { bold: true });
  row("Expenditure", "", { bold: true, shade: true });
  row("Services", aud(services));
  row("AT-HM and other charges (quarterly budget)", aud(other));
  row("Care management (10%, held for care management)", aud(cm));
  const totalEx = services + other + cm;
  row("Total expenditure", aud(totalEx), { bold: true });
  row(`Balance for ${label} (income less expenditure)`, aud(income - totalEx), { bold: true, shade: true, red: income - totalEx < 0 });
  w.y -= 6;
  w.text(`Your contributions this month: ${aud(s.contributions_in_month)} (invoiced separately; the rate is set by Services Australia).`, 46, 8.5); w.y -= 12;
  if (s.fee_reduction_in_month) { w.text("A fee reduction supplement applied this month: those contributions aren't charged.", 46, 8.5); w.y -= 12; }
  const pathways = (s.pathways ?? []) as Snap[];
  if (pathways.length) {
    w.y -= 6;
    bar("Other funding (pathways)");
    for (const p of pathways) row(`${STREAM[String(p.stream)] ?? p.stream} (to ${dd(p.ends_on)}): ${aud(p.amount)}, used ${aud(p.used)}`, `${aud(p.available)} left`, { red: Number(p.available) < 0 });
  }

  // Detail pages.
  w.newPage();
  bar("Service provision");
  const svc = ((s.service_lines ?? s.lines ?? []) as Snap[]);
  let sa = 0, sc = 0;
  table(
    [{ h: "Date", x: 44, wd: 48 }, { h: "Service", x: 94, wd: 106 }, { h: "Category (rate)", x: 202, wd: 108 }, { h: "Hours", x: 312, wd: 30, right: true }, { h: "Rate", x: 346, wd: 44, right: true },
     { h: "Rate type", x: 394, wd: 64 }, { h: "Amount", x: 460, wd: 44, right: true }, { h: "Your share", x: 506, wd: 46, right: true }],
    svc.map((l) => {
      sa += Number(l.amount); sc += Number(l.client_share ?? 0);
      return [dmy(l.date), `${l.code ? `${l.code} ` : ""}${l.service ?? l.band}${l.kind === "cancellation" ? " (late cancellation)" : ""}`, l.category ? `${CAT[String(l.category)] ?? l.category} (${Number(l.pct ?? 0).toFixed(2)}%)` : "",
        Number(l.quantity).toFixed(2), l.rate !== undefined ? aud(l.rate) : "", String(l.band ?? ""), aud(l.amount), aud(l.client_share ?? 0)];
    }),
    ["", "", "", "", "", "Subtotal", aud(sa), aud(sc)],
  );
  if (!svc.length) { w.text("No services this period.", 46, 9); w.y -= 16; }
  w.y -= 6;
  bar("AT-HM and other charges");
  const chg = ((s.charge_lines ?? s.charges ?? []) as Snap[]);
  if (chg.length) {
    let ca = 0, cc = 0;
    table(
      [{ h: "Date", x: 44, wd: 50 }, { h: "Description", x: 96, wd: 170 }, { h: "Funding", x: 270, wd: 80 }, { h: "Category (rate)", x: 352, wd: 90 }, { h: "Amount", x: 446, wd: 52, right: true }, { h: "Your share", x: 500, wd: 52, right: true }],
      chg.map((x) => { ca += Number(x.amount); cc += Number(x.client_share ?? 0); return [dmy(x.date), String(x.description ?? ""), STREAM[String(x.stream)] ?? String(x.stream ?? ""), x.category ? `${CAT[String(x.category)] ?? x.category} (${Number(x.pct ?? 0).toFixed(2)}%)` : "", aud(x.amount), aud(x.client_share ?? 0)]; }),
      ["", "", "", "Subtotal", aud(ca), aud(cc)],
    );
  } else { w.text("No other charges this period.", 46, 9); w.y -= 16; }
  w.y -= 6;
  bar("Care management");
  table([{ h: "Description", x: 44, wd: 360 }, { h: "Amount", x: 460, wd: 92, right: true }], [["Care management: 10% of the quarterly budget, for this month", aud(cm)]]);
  w.y -= 10;
  w.need(40);
  w.page.drawRectangle({ x: 80, y: w.y - 18, width: 435, height: 30, borderColor: rgb(0.2, 0.2, 0.2), borderWidth: 0.8 });
  const note = "Please tell your care partner and our office if you'll be away (holiday, hospital or respite).";
  w.page.drawText(safe(note), { x: 297.6 - w.bold.widthOfTextAtSize(safe(note), 8.5) / 2, y: w.y - 6, size: 8.5, font: w.bold });

  // Footer with the business's contact details and page numbers on every page.
  const pages = doc.getPages();
  const contact = safe([b.trading_name || b.legal_name, b.email, b.phone].filter(Boolean).join("  |  "));
  const addr = safe(`${b.address ?? ""}, ${b.suburb ?? ""} ${b.state ?? ""} ${b.postcode ?? ""}`);
  pages.forEach((pg, i) => {
    pg.drawLine({ start: { x: 40, y: 52 }, end: { x: 555, y: 52 }, thickness: 0.5, color: rgb(0.7, 0.7, 0.7) });
    pg.drawText(contact, { x: 297.6 - w.font.widthOfTextAtSize(contact, 8) / 2, y: 40, size: 8, font: w.font });
    pg.drawText(addr, { x: 297.6 - w.font.widthOfTextAtSize(addr, 8) / 2, y: 30, size: 8, font: w.font });
    const pn = `Page ${i + 1} of ${pages.length}`;
    pg.drawText(pn, { x: 297.6 - w.font.widthOfTextAtSize(pn, 8) / 2, y: 18, size: 8, font: w.font });
  });
  const bytes = await doc.save();
  return { bytes, checksum: createHash("sha256").update(bytes).digest("hex") };
}

// cmeprojects (update 164): credit notes and payment receipts.
export async function creditNotePdf(n: { number: string; issue_date: string; amount: number; gst: number; snapshot: Snap }) {
  const doc = await PDFDocument.create();
  const w = new Writer(doc, await doc.embedFont(StandardFonts.Helvetica), await doc.embedFont(StandardFonts.HelveticaBold));
  const s = n.snapshot;
  const b = (s.business ?? {}) as Snap;
  const p = (s.payer ?? {}) as Snap;
  const c = (s.client ?? {}) as Snap;
  const inv = (s.invoice ?? {}) as Snap;
  doc.setTitle(`Credit note ${n.number}`);
  header(w, b, inv.tax_invoice ? "ADJUSTMENT NOTE" : "CREDIT NOTE");
  for (const [k, v] of [["Credit note", n.number], ["Date", dmy(n.issue_date)], ["For invoice", `${inv.number ?? ""} of ${dmy(inv.issue_date)}`], ["To", p.name], ["Client", c.name]]) {
    w.text(k, 40, 9, true); w.text(v, 160, 9); w.y -= 13;
  }
  w.y -= 6;
  w.text("Reason", 40, 9, true); w.y -= 12;
  for (const ln of String(s.reason ?? "").split(/\r?\n/).slice(0, 6)) { w.text(w.fit(ln, 515), 40, 9); w.y -= 12; }
  w.y -= 8;
  w.text("Date", 40, 9, true); w.text("Description", 100, 9, true); w.right("Credit", 555, 9, true);
  w.y -= 6; w.line(); w.y -= 10;
  for (const it of (s.items ?? []) as Snap[]) {
    w.need(14);
    w.text(dmy(it.service_date), 40, 9); w.text(w.fit(it.description, 350), 100, 9); w.right(aud(it.amount), 555, 9);
    w.y -= 13;
  }
  w.line(); w.y -= 12;
  if (inv.tax_invoice) { w.text("GST included in the credit", 340, 10); w.right(aud(n.gst), 555, 10); w.y -= 13; }
  w.text("Total credit", 340, 11, true); w.right(aud(n.amount), 555, 11, true); w.y -= 18;
  w.text("This credit reduces the amount owing on the invoice above. Any credit left over is refunded on request.", 40, 8);
  const bytes = await doc.save();
  return { bytes, checksum: createHash("sha256").update(bytes).digest("hex") };
}

export async function receiptPdf(r: { receipt_number: string; received_on: string; amount: number; method: string; reference: string; business: Snap; payer: Snap; client: Snap | null; allocations: { amount: number; invoice: string }[] }) {
  const doc = await PDFDocument.create();
  const w = new Writer(doc, await doc.embedFont(StandardFonts.Helvetica), await doc.embedFont(StandardFonts.HelveticaBold));
  const METHOD: Record<string, string> = { eft: "Bank transfer", bpay: "BPAY", card: "Card", cash: "Cash", cheque: "Cheque", government_remittance: "Remittance", other: "Other" };
  doc.setTitle(`Receipt ${r.receipt_number}`);
  header(w, r.business, "RECEIPT");
  for (const [k, v] of [["Receipt", r.receipt_number], ["Received", dmy(r.received_on)], ["From", r.payer.name], ["Client", r.client?.name ?? ""], ["How paid", `${METHOD[r.method] ?? r.method}${r.reference ? `, reference ${r.reference}` : ""}`]]) {
    w.text(k, 40, 9, true); w.text(v, 160, 9); w.y -= 13;
  }
  w.y -= 8;
  w.text("Applied to", 40, 9, true); w.right("Amount", 555, 9, true); w.y -= 6; w.line(); w.y -= 10;
  let applied = 0;
  for (const a of r.allocations) { w.need(14); w.text(a.invoice ? `Invoice ${a.invoice}` : "Account", 40, 9); w.right(aud(a.amount), 555, 9); w.y -= 13; applied += Number(a.amount); }
  if (Number(r.amount) - applied > 0.004) { w.text("Held as credit", 40, 9); w.right(aud(Number(r.amount) - applied), 555, 9); w.y -= 13; }
  w.line(); w.y -= 12;
  w.text("Total received", 340, 11, true); w.right(aud(r.amount), 555, 11, true); w.y -= 18;
  w.text("Thank you for your payment.", 40, 9);
  const bytes = await doc.save();
  return { bytes, checksum: createHash("sha256").update(bytes).digest("hex") };
}

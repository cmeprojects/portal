// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createHash } from "node:crypto";
import { PDFDocument, StandardFonts, rgb, type PDFFont, type PDFPage } from "pdf-lib";
import type { Contract, Signature } from "@/lib/contracts";

// cmeprojects Phase 4: the final signed copy. The contract wording exactly as
// signed, both signatures, and an audit page (who, when, how their identity
// was checked, IP, device, and the SHA-256 of the wording). The SHA-256 of the
// finished PDF is stored separately so it can be checked later.

// The standard PDF fonts only cover Western European characters.
const safe = (s: string) =>
  s
    .replace(/[‘’]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/[–—]/g, "-")
    .replace(/…/g, "...")
    .replace(/•/g, "-")
    .replace(/[^\x09\x0A\x0D\x20-\x7E\xA0-\xFF]/g, "?");

function wrap(text: string, font: PDFFont, size: number, width: number): string[] {
  const out: string[] = [];
  for (const para of safe(text).split(/\r?\n/)) {
    if (!para.trim()) {
      out.push("");
      continue;
    }
    let line = "";
    for (const word of para.split(/\s+/)) {
      const next = line ? `${line} ${word}` : word;
      if (font.widthOfTextAtSize(next, size) <= width) line = next;
      else {
        if (line) out.push(line);
        line = word;
      }
    }
    out.push(line);
  }
  return out;
}

export const sha256 = (bytes: Uint8Array | string) => createHash("sha256").update(bytes).digest("hex");

// cmeprojects: the company logo as PNG for the letterhead (PNG and JPEG are
// used as they are; SVG and WebP are converted). Null if it can't be read.
export async function logoForPdf(url: string, site: string): Promise<{ bytes: Uint8Array; png: boolean } | null> {
  try {
    const res = await fetch(new URL(url, site), { cache: "no-store" });
    if (!res.ok) return null;
    const bytes = new Uint8Array(await res.arrayBuffer());
    if (bytes[0] === 0x89 && bytes[1] === 0x50) return { bytes, png: true };
    if (bytes[0] === 0xff && bytes[1] === 0xd8) return { bytes, png: false };
    const sharp = (await import("sharp")).default;
    return { bytes: new Uint8Array(await sharp(Buffer.from(bytes), { density: 300 }).resize({ height: 240, withoutEnlargement: false }).png().toBuffer()), png: true };
  } catch {
    return null;
  }
}

export async function buildSignedPdf(opts: {
  logo?: { bytes: Uint8Array; png: boolean } | null;
  brandColour?: string;
  company: string;
  contract: Contract;
  employeeName: string;
  signatures: (Signature & { signerName: string; image: Uint8Array })[];
  timeZone: string;
}): Promise<Uint8Array> {
  const { contract, signatures } = opts;
  const pdf = await PDFDocument.create();
  pdf.setTitle(`${contract.title} (version ${contract.version})`);
  pdf.setAuthor(opts.company);
  pdf.setSubject(`Signed contract for ${opts.employeeName}`);
  pdf.setProducer("Staff Portal (cmeproject)");
  const font = await pdf.embedFont(StandardFonts.Helvetica);
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold);
  const W = 595.28;
  const H = 841.89;
  const M = 56;
  // cmeprojects: letterhead (logo, company name, a line in the brand colour) on every page, when chosen.
  const head = contract.letterhead !== false;
  const logo = head && opts.logo ? await (opts.logo.png ? pdf.embedPng(opts.logo.bytes) : pdf.embedJpg(opts.logo.bytes)).catch(() => null) : null;
  const hex = /^#?([0-9a-f]{6})$/i.exec(opts.brandColour ?? "")?.[1] ?? "134f8e";
  const brand = rgb(parseInt(hex.slice(0, 2), 16) / 255, parseInt(hex.slice(2, 4), 16) / 255, parseInt(hex.slice(4, 6), 16) / 255);
  const TOP = head ? H - M - 66 : H - M;
  const newPage = () => {
    const pg = pdf.addPage([W, H]);
    if (head) {
      if (logo) {
        const s = Math.min(130 / logo.width, 38 / logo.height);
        pg.drawImage(logo, { x: M, y: H - M - 38 + (38 - logo.height * s) / 2, width: logo.width * s, height: logo.height * s });
      }
      const name = safe(opts.company);
      const nw = bold.widthOfTextAtSize(name, 11);
      pg.drawText(name, { x: logo ? W - M - nw : M, y: H - M - 24, size: 11, font: bold, color: brand });
      pg.drawLine({ start: { x: M, y: H - M - 48 }, end: { x: W - M, y: H - M - 48 }, thickness: 1.2, color: brand });
    }
    return pg;
  };
  let page: PDFPage = newPage();
  let y = TOP - 10;
  const line = (text: string, f = font, size = 10.5, gap = 15) => {
    if (y < M + gap) {
      page = newPage();
      y = TOP - 10;
    }
    page.drawText(text, { x: M, y, size, font: f, color: rgb(0.1, 0.12, 0.16) });
    y -= gap;
  };
  const when = (iso: string) => new Intl.DateTimeFormat("en-AU", { dateStyle: "long", timeStyle: "long", timeZone: opts.timeZone }).format(new Date(iso));

  // The contract, exactly as signed.
  if (!head) for (const l of wrap(opts.company, bold, 11, W - 2 * M)) line(l, bold, 11);
  for (const l of wrap(contract.title, bold, 16, W - 2 * M)) line(l, bold, 16, 22);
  line(`Employee: ${safe(opts.employeeName)}   ·   Version ${contract.version}`, font, 9.5);
  y -= 8;
  for (const l of wrap(contract.body, font, 10.5, W - 2 * M)) line(l);

  // Signatures.
  y -= 12;
  line("Signatures", bold, 13, 20);
  for (const s of signatures) {
    if (y < M + 120) {
      page = newPage();
      y = TOP - 10;
    }
    line(s.party === "employee" ? "Employee" : "For the employer", bold, 10.5);
    const img = await pdf.embedPng(s.image);
    const scale = Math.min(200 / img.width, 70 / img.height);
    page.drawImage(img, { x: M, y: y - img.height * scale, width: img.width * scale, height: img.height * scale });
    y -= img.height * scale + 8;
    line(`${safe(s.signed_name)} · ${when(s.signed_at)}`, font, 9.5);
    y -= 8;
  }

  // Audit page.
  page = newPage();
  y = TOP - 10;
  line("Signing record", bold, 16, 24);
  const facts: [string, string][] = [
    ["Document", `${contract.title} (version ${contract.version})`],
    ["Document ID", contract.id],
    ["SHA-256 of the wording signed", contract.content_hash],
    ["Sent", contract.sent_at ? when(contract.sent_at) : ""],
  ];
  for (const [k, v] of facts) {
    line(k, bold, 9.5, 13);
    for (const l of wrap(v, font, 9.5, W - 2 * M)) line(l, font, 9.5, 13);
    y -= 4;
  }
  for (const s of signatures) {
    y -= 6;
    line(s.party === "employee" ? "Employee signature" : "Employer signature", bold, 11, 16);
    const rows: [string, string][] = [
      ["Signed by (account)", s.signerName],
      ["Name typed", s.signed_name],
      ["Signed at (server time)", when(s.signed_at)],
      ["Identity checked by", s.identity_check === "authenticator" ? "Signed in, plus an authenticator app code at signing" : "Signed in, plus their password again at signing"],
      ["Consent given", s.consent_text],
      ["SHA-256 of the wording they signed", s.content_hash],
      ["IP address", s.ip || "Not recorded"],
      ["Device", s.user_agent || "Not recorded"],
    ];
    for (const [k, v] of rows) {
      line(k, bold, 9, 12);
      for (const l of wrap(v, font, 9, W - 2 * M)) line(l, font, 9, 12);
      y -= 3;
    }
  }
  y -= 8;
  for (const l of wrap(
    "This page was added when the contract was fully signed. The SHA-256 of this whole PDF is kept with the contract in the Staff Portal; use Check this copy there to confirm it hasn't been changed.",
    font,
    8.5,
    W - 2 * M,
  ))
    line(l, font, 8.5, 11);
  // Footer on every page: the document and page number.
  const pages = pdf.getPages();
  pages.forEach((pg, i) => {
    const text = safe(`${contract.title} · version ${contract.version} · page ${i + 1} of ${pages.length}`);
    pg.drawText(text, { x: M, y: M / 2, size: 8, font, color: rgb(0.45, 0.47, 0.5) });
  });
  return pdf.save({ useObjectStreams: false });
}

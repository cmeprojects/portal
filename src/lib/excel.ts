// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import ExcelJS from "exceljs";
import type { ChoiceColour } from "@/lib/registers";
import type { Table } from "@/lib/register-rows";

// Cell colours for colour-coded choices (fill, text).
const FILL: Record<ChoiceColour, [string, string]> = {
  green: ["E3F3E9", "1D6B3A"],
  yellow: ["FDF3C8", "7A5C00"],
  orange: ["FBEEDD", "9A4A0B"],
  red: ["FBE6E4", "A11B1B"],
  blue: ["E5EDF6", "134F8E"],
  grey: ["EEF1F5", "4A5468"],
};

export type ExcelHeader = {
  companyName: string;
  title: string;
  lines: string[];
  brandColour: string;
  logo?: { buffer: ArrayBuffer; extension: "png" | "jpeg"; width: number; height: number };
};

const hex = (c: string) => c.replace("#", "").toUpperCase().padStart(6, "0").slice(-6);

// Width and height of a PNG (from its header), to keep the logo's shape.
export function pngSize(buf: ArrayBuffer): { width: number; height: number } | null {
  const b = new DataView(buf);
  if (buf.byteLength < 24 || b.getUint32(0) !== 0x89504e47) return null;
  return { width: b.getUint32(16), height: b.getUint32(20) };
}

// A spreadsheet with the company's logo and a header above the table, ready
// to print: A4 landscape, fitted to the page width, the column headings
// repeated on every page and page numbers in the footer.
export async function tableToXlsx(table: Table, header: ExcelHeader): Promise<ArrayBuffer> {
  return tablesToXlsx([{ table, header }]);
}

// Several tables, one sheet each (for example the weekly mileage report).
export async function tablesToXlsx(sheets: { table: Table; header: ExcelHeader; sheetName?: string }[]): Promise<ArrayBuffer> {
  const wb = new ExcelJS.Workbook();
  wb.creator = "cmeproject Staff Portal";
  wb.created = new Date();
  for (const s of sheets) addSheet(wb, s.table, s.header, s.sheetName);
  return wb.xlsx.writeBuffer();
}

function addSheet(wb: ExcelJS.Workbook, table: Table, header: ExcelHeader, sheetName?: string) {
  const ws = wb.addWorksheet((sheetName ?? header.title).replace(/[\\/?*[\]:]/g, " ").slice(0, 31) || "Register", {
    views: [{ state: "frozen", ySplit: 6 }],
    pageSetup: {
      paperSize: 9,
      orientation: "landscape",
      fitToPage: true,
      fitToWidth: 1,
      fitToHeight: 0,
      printTitlesRow: "6:6",
      margins: { left: 0.4, right: 0.4, top: 0.5, bottom: 0.6, header: 0.3, footer: 0.3 },
    },
    headerFooter: {
      oddFooter: `&L&8${header.companyName} · ${header.title}&R&8Page &P of &N`,
    },
  });

  const cols = table.columns.length;
  const firstTextCol = header.logo ? 3 : 1;

  // Logo in the top-left corner, about 4 rows tall.
  if (header.logo) {
    const id = wb.addImage({ buffer: header.logo.buffer, extension: header.logo.extension });
    const h = 76;
    const w = Math.round((header.logo.width / header.logo.height) * h) || 96;
    ws.addImage(id, { tl: { col: 0.15, row: 0.2 }, ext: { width: Math.min(w, 170), height: h } });
  }

  const put = (row: number, text: string, font: Partial<ExcelJS.Font>) => {
    const cell = ws.getCell(row, firstTextCol);
    cell.value = text;
    cell.font = { name: "Calibri", ...font };
  };
  put(1, header.companyName, { size: 16, bold: true, color: { argb: `FF${hex(header.brandColour)}` } });
  put(2, header.title, { size: 13, bold: true });
  header.lines.slice(0, 2).forEach((line, i) => put(3 + i, line, { size: 10, color: { argb: "FF5A6478" } }));
  for (let r = 1; r <= 4; r++) ws.getRow(r).height = 20;

  // Column headings on row 6.
  const head = ws.getRow(6);
  table.columns.forEach((c, i) => {
    const cell = head.getCell(i + 1);
    cell.value = c.label;
    cell.font = { bold: true, color: { argb: "FFFFFFFF" } };
    cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: `FF${hex(header.brandColour)}` } };
    cell.alignment = { vertical: "middle", wrapText: true };
    cell.border = { bottom: { style: "thin", color: { argb: "FFB4C0D0" } } };
  });
  head.height = 22;

  table.rows.forEach((row, r) => {
    const xr = ws.getRow(7 + r);
    table.columns.forEach((c, i) => {
      const cellData = row.cells[c.key];
      const cell = xr.getCell(i + 1);
      // Numbers stay numbers in Excel, so they can be added up.
      if (cellData?.num != null) {
        cell.value = cellData.num;
        cell.numFmt = "#,##0";
        cell.alignment = { vertical: "top", horizontal: "right" };
      } else {
        cell.value = cellData?.text ?? "";
        cell.alignment = { vertical: "top", wrapText: Boolean(c.wide) };
      }
      cell.border = { bottom: { style: "hair", color: { argb: "FFD3DBE6" } } };
      if (cellData?.badge && cellData.text) {
        const [fill, font] = FILL[cellData.badge];
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: `FF${fill}` } };
        cell.font = { bold: true, color: { argb: `FF${font}` } };
      } else if (cellData?.tone === "danger") {
        cell.font = { bold: true, color: { argb: "FFA11B1B" } };
      }
    });
  });

  // Sensible widths: wide text columns get more room.
  table.columns.forEach((c, i) => {
    const longest = Math.max(c.label.length, ...table.rows.slice(0, 300).map((r) => (r.cells[c.key]?.text ?? "").length));
    ws.getColumn(i + 1).width = c.wide ? Math.min(60, Math.max(28, longest * 0.6)) : Math.min(32, Math.max(10, longest + 2));
  });
  if (table.rows.length) {
    ws.autoFilter = { from: { row: 6, column: 1 }, to: { row: 6 + table.rows.length, column: cols } };
  }
}

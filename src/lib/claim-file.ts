// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";

// cmeprojects (update 163): the claim file for manual upload to the government
// portal, built from the verified official template: its header row exactly, its
// columns in order, CSV (comma), its date format, and a file name no longer than
// its limit. Making the file never marks the claim submitted.
type Template = { id: string; program: string; headers: string[]; mapping: Record<string, string>; date_format: string; file_name_max: number | null; status: string };

const cell = (v: string) => (/[",\r\n]/.test(v) ? `"${v.replace(/"/g, '""')}"` : v);
function fmtDate(iso: string | null | undefined, f: string) {
  if (!iso) return "";
  const [y, m, d] = iso.slice(0, 10).split("-");
  return f === "DD/MM/YYYY" ? `${d}/${m}/${y}` : f === "YYYY/MM/DD" ? `${y}/${m}/${d}` : `${y}-${m}-${d}`;
}
const num = (n: number | null | undefined) => (n === null || n === undefined ? "" : Number(n).toFixed(2));
const NDIS_GST: Record<string, string> = { taxable: "P1", gst_free: "P2", input_taxed: "P5" };

export async function buildClaimFile(supabase: SupabaseClient, claimId: string): Promise<{ name: string; content: string; checksum: string } | { error: string }> {
  const { data: claim } = await supabase.from("claims").select("id, program, template_id, period_from, period_to, status").eq("id", claimId).maybeSingle();
  if (!claim) return { error: "That claim isn't available." };
  if (claim.status !== "approved") return { error: "The file is made after the claim is approved." };
  const { data: tpl } = await supabase.from("claim_templates").select("id, program, headers, mapping, date_format, file_name_max, status").eq("id", claim.template_id).maybeSingle();
  const t = tpl as Template | null;
  if (!t || t.status !== "verified") return { error: "The claim's official template isn't verified." };
  const [{ data: items }, { data: biz }] = await Promise.all([
    supabase.from("claim_items").select("id, line_id, quarter_budget_id, client_id, claimed_value").eq("claim_id", claimId).eq("status", "live").order("created_at"),
    supabase.from("business_current").select("*").maybeSingle(),
  ]);
  const its = (items ?? []) as { id: string; line_id: string | null; quarter_budget_id: string | null; client_id: string; claimed_value: number }[];
  const lineIds = its.map((i) => i.line_id).filter(Boolean) as string[];
  const qbIds = its.map((i) => i.quarter_budget_id).filter(Boolean) as string[];
  const cIds = [...new Set(its.map((i) => i.client_id))];
  const [{ data: lines }, { data: qbs }, { data: clients }, { data: details }] = await Promise.all([
    lineIds.length ? supabase.from("billing_lines").select("id, service_date, band_label, quantity, unit, unit_price, amount, gst_code, sah_category, kind, price_item_id").in("id", lineIds) : Promise.resolve({ data: [] }),
    qbIds.length ? supabase.from("client_quarter_budgets").select("id, quarter_start, quarter_end, care_management").in("id", qbIds) : Promise.resolve({ data: [] }),
    cIds.length ? supabase.from("car_clients").select("id, name, client_ref").in("id", cIds) : Promise.resolve({ data: [] }),
    cIds.length ? supabase.from("client_details").select("client_id, ndis_number, aged_care_id").in("client_id", cIds) : Promise.resolve({ data: [] }),
  ]);
  type Line = { id: string; service_date: string; band_label: string; quantity: number; unit: string; unit_price: number; amount: number; gst_code: string; sah_category: string | null; kind: string; price_item_id: string };
  const L = new Map(((lines ?? []) as Line[]).map((l) => [l.id, l]));
  const piIds = [...new Set([...L.values()].map((l) => l.price_item_id))];
  const { data: pis } = piIds.length ? await supabase.from("price_items").select("id, ndis_item").in("id", piIds) : { data: [] };
  const item = new Map(((pis ?? []) as { id: string; ndis_item: string }[]).map((p) => [p.id, p.ndis_item]));
  const Q = new Map(((qbs ?? []) as { id: string; quarter_start: string; quarter_end: string; care_management: number }[]).map((q) => [q.id, q]));
  const C = new Map(((clients ?? []) as { id: string; name: string; client_ref: string | null }[]).map((c) => [c.id, c]));
  const D = new Map(((details ?? []) as { client_id: string; ndis_number: string | null; aged_care_id: string | null }[]).map((d) => [d.client_id, d]));
  const b = (biz ?? {}) as Record<string, string>;
  const short = claimId.replace(/-/g, "").slice(0, 8).toUpperCase();

  const value = (field: string, i: (typeof its)[number], n: number): string => {
    if (field.startsWith("=")) return field.slice(1);
    const l = i.line_id ? L.get(i.line_id) : undefined;
    const q = i.quarter_budget_id ? Q.get(i.quarter_budget_id) : undefined;
    const c = C.get(i.client_id);
    const d = D.get(i.client_id);
    switch (field) {
      case "provider_registration": return b.ndis_registration_number ?? "";
      case "provider_abn": return b.abn ?? "";
      case "sah_provider_id": return b.sah_provider_id ?? "";
      case "sah_service_branch": return b.sah_service_branch ?? "";
      case "ndis_number": return d?.ndis_number ?? "";
      case "aged_care_id": return d?.aged_care_id ?? "";
      case "client_ref": return c?.client_ref ?? "";
      case "client_name": return c?.name ?? "";
      case "date_from": return fmtDate(l?.service_date ?? q?.quarter_start, t.date_format);
      case "date_to": return fmtDate(l?.service_date ?? q?.quarter_end, t.date_format);
      case "support_item": return l ? item.get(l.price_item_id) ?? "" : "";
      case "service_type": return l ? l.band_label : "Care management";
      case "sah_category": return l ? l.sah_category ?? "" : "clinical";
      case "claim_reference": return `${short}-${String(n).padStart(4, "0")}`;
      case "quantity": return l ? Number(l.quantity).toFixed(2) : "1.00";
      case "hours": return l && l.unit === "hour" ? Number(l.quantity).toFixed(2) : "";
      case "unit_price": return l ? num(l.unit_price) : num(q?.care_management);
      case "amount": return num(i.claimed_value);
      case "gst_code": return l ? l.gst_code : "gst_free";
      case "ndis_gst_code": return NDIS_GST[l?.gst_code ?? "gst_free"] ?? "";
      case "cancellation": return l?.kind === "cancellation" ? "CANC" : "";
      default: return "";
    }
  };
  const rows = its.map((i, n) => t.headers.map((h) => cell(value(t.mapping[h] ?? "", i, n + 1))).join(","));
  const content = [t.headers.map(cell).join(","), ...rows].join("\r\n") + "\r\n";
  let name = `${t.program === "ndis" ? "NDIS" : "SAH"}_${claim.period_from.replace(/-/g, "")}_${claim.period_to.replace(/-/g, "")}_${short}.csv`;
  if (t.file_name_max && name.length > t.file_name_max) name = `${short}.csv`.slice(-t.file_name_max);
  return { name, content, checksum: createHash("sha256").update(content).digest("hex") };
}

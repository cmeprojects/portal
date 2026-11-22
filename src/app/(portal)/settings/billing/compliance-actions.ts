// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { EMAIL, type FormState } from "@/lib/form";
import { checkPhone } from "@/lib/phone";
import { abnValid } from "@/lib/abn";
import type { Business } from "@/lib/business";

// cmeprojects (update 163): business details, the compliance register (official
// link, document version, effective and review dates), official claim templates
// and NDIS catalogue imports. Verifying is for the Billing approve right (the
// owner's nominee); the database refuses anyone else and never lets a verified
// record change.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const url = (v: unknown) => {
  const s = clip(v, 500);
  return s === "" || /^https:\/\/[^\s]+\.[^\s]+$/.test(s) ? s : null;
};
const done = () => {
  revalidatePath("/settings/billing");
  revalidatePath("/billing");
};

export async function saveBusiness(b: Business): Promise<FormState> {
  await requireSession();
  const abn = clip(b.abn, 20).replace(/\s/g, "");
  if (!clip(b.legal_name, 200)) return { error: "Enter the legal name." };
  if (!abnValid(abn)) return { error: "That ABN isn't valid (check the 11 digits)." };
  if (!clip(b.address, 300) || !clip(b.suburb, 100)) return { error: "Enter the street address and suburb." };
  if (!["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"].includes(b.state)) return { error: "Choose the state." };
  if (!/^\d{4}$/.test(clip(b.postcode, 4))) return { error: "A postcode has 4 digits." };
  const email = clip(b.email, 200);
  if (email && !EMAIL.test(email)) return { error: "Enter a valid email address." };
  const ph = checkPhone("AU", clip(b.phone, 30));
  if (!ph.ok) return { error: ph.error };
  const bsb = clip(b.payment_bsb, 7);
  if (bsb && !/^\d{3}-?\d{3}$/.test(bsb)) return { error: "A BSB has 6 digits (for example 062-000)." };
  const acct = clip(b.payment_account_number, 10).replace(/\s/g, "");
  if (acct && !/^\d{5,10}$/.test(acct)) return { error: "An account number has 5 to 10 digits." };
  const terms = Number(b.payment_terms_days || 14);
  if (!Number.isInteger(terms) || terms < 0 || terms > 120) return { error: "Payment terms are 0 to 120 days." };
  const gstBy = clip(b.gst_verified_by_name, 120);
  const gstOn = ymd(b.gst_verified_on);
  if (!!gstBy !== !!gstOn) return { error: "Record both who verified the GST position (your accountant) and the date, or neither." };
  const { error } = await (await createClient()).from("business_details").insert({
    legal_name: clip(b.legal_name, 200), trading_name: clip(b.trading_name, 200), abn, address: clip(b.address, 300), suburb: clip(b.suburb, 100), state: b.state, postcode: clip(b.postcode, 4),
    phone: ph.value, email, gst_registered: !!b.gst_registered, prices_include_gst: !!b.prices_include_gst, gst_verified_by_name: gstBy, gst_verified_on: gstOn, gst_evidence: clip(b.gst_evidence, 500),
    ndis_registration_number: clip(b.ndis_registration_number, 40), sah_provider_id: clip(b.sah_provider_id, 60), sah_service_branch: clip(b.sah_service_branch, 120),
    payment_account_name: clip(b.payment_account_name, 120), payment_bsb: bsb, payment_account_number: acct, payment_other: clip(b.payment_other, 500), payment_terms_days: terms, note: clip(b.note, 500),
  });
  if (error) return { error: friendlyError(error) };
  done();
  revalidatePath("/setup");
  return { message: "Business details saved as a new version. Issued invoices keep the version they were issued with." };
}

export async function saveReview(kind: "check" | "figure", id: string, v: { url: string; version: string; effective_from: string; review_by: string }): Promise<FormState> {
  await requireSession();
  if (!isId(id) || !["check", "figure"].includes(kind)) return { error: "Something went wrong." };
  const u = url(v.url);
  if (u === null) return { error: "The official link must start with https://." };
  if (v.review_by && !ymd(v.review_by)) return { error: "Choose the review date." };
  const row: Record<string, unknown> = { official_url: u, document_version: clip(v.version, 100), review_by: ymd(v.review_by) };
  if (kind === "check") row.effective_from = ymd(v.effective_from);
  const { data, error } = await (await createClient()).from(kind === "check" ? "billing_rule_checks" : "billing_parameters").update(row).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this." };
  done();
  return { message: "Saved." };
}

export async function addTemplate(t: { program: string; name: string; headers: string[]; mapping: Record<string, string>; date_format: string; file_name_max: string; file_name: string; checksum: string }): Promise<FormState> {
  await requireSession();
  if (!["support_at_home", "ndis"].includes(t.program)) return { error: "Choose the program." };
  if (!clip(t.name, 200)) return { error: "Name the template." };
  const headers = (Array.isArray(t.headers) ? t.headers : []).map((h) => String(h).slice(0, 200));
  if (!headers.length || headers.length > 80) return { error: "Upload the official file: its first row must hold the column names." };
  if (!["YYYY-MM-DD", "YYYY/MM/DD", "DD/MM/YYYY"].includes(t.date_format)) return { error: "Choose the date format the official guide sets." };
  const max = t.file_name_max ? Number(t.file_name_max) : null;
  if (max !== null && (!Number.isInteger(max) || max < 5 || max > 200)) return { error: "The file name limit is 5 to 200 characters." };
  const mapping = Object.fromEntries(headers.map((h) => [h, clip(t.mapping?.[h] ?? "", 200)]));
  const { error } = await (await createClient()).from("claim_templates").insert({ program: t.program, name: clip(t.name, 200), headers, mapping, date_format: t.date_format, file_name_max: max, file_name: clip(t.file_name, 200), file_checksum: clip(t.checksum, 64) });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Template saved as a draft. The owner's nominee checks every column and verifies it." };
}

export async function verifyTemplate(id: string, v: { url: string; version: string; review_by: string }): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const u = url(v.url);
  if (!u) return { error: "Record the official link (https://) where the template came from." };
  const supabase = await createClient();
  const { error: e1 } = await supabase.from("claim_templates").update({ official_url: u, document_version: clip(v.version, 100), review_by: ymd(v.review_by) }).eq("id", id).eq("status", "draft");
  if (e1) return { error: friendlyError(e1) };
  const { data, error } = await supabase.from("claim_templates").update({ status: "verified" }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't verify this." };
  done();
  return { message: "Template verified. Claims for this program now use it (the previous verified one is retired)." };
}

export async function removeDraft(kind: "template" | "catalogue", id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  if (kind === "catalogue") {
    const { error: e1 } = await supabase.from("ndis_support_items").delete().eq("version_id", id);
    if (e1) return { error: friendlyError(e1) };
  }
  const { data, error } = await supabase.from(kind === "template" ? "claim_templates" : "ndis_catalogue_versions").delete().eq("id", id).eq("status", "draft").select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a draft can be removed." };
  done();
  return { message: "Draft removed." };
}

type Item = { item_number: string; item_name: string; category: string; registration_group: string; unit: string; limit_national: number | null; limit_remote: number | null; limit_very_remote: number | null; quotable: boolean };
export async function importCatalogue(c: { name: string; effective_from: string; effective_to: string; url: string; version: string; review_by: string; file_name: string; checksum: string; items: Item[] }): Promise<FormState> {
  await requireSession();
  if (!clip(c.name, 200) || !ymd(c.effective_from)) return { error: "Name the catalogue and enter the date it takes effect." };
  const u = url(c.url);
  if (u === null) return { error: "The official link must start with https://." };
  const items = (Array.isArray(c.items) ? c.items : []).filter((i) => i && /^[\w.\-]{1,40}$/.test(String(i.item_number ?? "")));
  if (!items.length) return { error: "No support items were found in the file (look for a \"Support Item Number\" column)." };
  if (items.length > 20000) return { error: "That file has too many rows." };
  const supabase = await createClient();
  const { data: v, error } = await supabase.from("ndis_catalogue_versions").insert({
    name: clip(c.name, 200), effective_from: c.effective_from, effective_to: ymd(c.effective_to), official_url: u, document_version: clip(c.version, 100), review_by: ymd(c.review_by), file_name: clip(c.file_name, 200), file_checksum: clip(c.checksum, 64),
  }).select("id").single();
  if (error) return { error: friendlyError(error) };
  const n = (x: unknown) => (x === null || x === undefined || x === "" || !Number.isFinite(Number(x)) ? null : Math.round(Number(x) * 100) / 100);
  const seen = new Set<string>();
  const rows = items.filter((i) => !seen.has(i.item_number) && seen.add(i.item_number)).map((i) => ({
    version_id: v.id, item_number: clip(i.item_number, 40), item_name: clip(i.item_name, 500), category: clip(i.category, 200), registration_group: clip(i.registration_group, 200), unit: clip(i.unit, 20),
    limit_national: n(i.limit_national), limit_remote: n(i.limit_remote), limit_very_remote: n(i.limit_very_remote), quotable: !!i.quotable,
  }));
  for (let k = 0; k < rows.length; k += 500) {
    const { error: e2 } = await supabase.from("ndis_support_items").insert(rows.slice(k, k + 500));
    if (e2) return { error: `Imported ${k} items, then: ${friendlyError(e2)} Remove the draft and try again.` };
  }
  await supabase.from("ndis_catalogue_versions").update({ item_count: rows.length }).eq("id", v.id);
  done();
  return { message: `Imported ${rows.length} support items as a draft. Check them, then the owner's nominee verifies the catalogue.` };
}

export async function verifyCatalogue(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("ndis_catalogue_versions").update({ status: "verified" }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't verify this." };
  done();
  return { message: "Catalogue verified. Prices on support dates it covers are checked against it." };
}

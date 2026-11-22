// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { EMAIL, type FormState } from "@/lib/form";
import { checkPhone } from "@/lib/phone";
import { abnValid } from "@/lib/abn";

// cmeprojects (update 165): suppliers and their invoices, client charges (with markup), markup
// rules and pathway budgets. The database decides who may do each step (prepare, approve by
// someone else, prices for markup rules) and works out every amount.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const money = (v: unknown, allowZero = false) => {
  const n = Number(String(v ?? "").replace(/[$,\s]/g, ""));
  return Number.isFinite(n) && (allowZero ? n >= 0 : n > 0) ? Math.round(n * 100) / 100 : null;
};
const done = () => revalidatePath("/billing");
async function upd(table: string, id: string, values: Record<string, unknown>, nothing: string): Promise<FormState> {
  const { data, error } = await (await createClient()).from(table).update(values).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: nothing };
  done();
  return null;
}

export async function addSupplier(f: { name: string; kind: string; abn: string; gst_registered: boolean; email: string; phone: string; address: string; bsb: string; account: string; account_name: string }): Promise<FormState> {
  await requireSession();
  if (!clip(f.name, 200)) return { error: "Enter the supplier's name." };
  if (!["subcontractor", "equipment", "home_modifications", "other"].includes(f.kind)) return { error: "Choose the kind of supplier." };
  const abn = clip(f.abn, 20).replace(/\s/g, "");
  if (abn && !abnValid(abn)) return { error: "That ABN isn't valid (check the 11 digits)." };
  const email = clip(f.email, 200);
  if (email && !EMAIL.test(email)) return { error: "Enter a valid email address." };
  const ph = checkPhone("AU", clip(f.phone, 30));
  if (!ph.ok) return { error: ph.error };
  const bsb = clip(f.bsb, 7);
  if (bsb && !/^\d{3}-?\d{3}$/.test(bsb)) return { error: "A BSB has 6 digits." };
  const acct = clip(f.account, 10).replace(/\s/g, "");
  if (acct && !/^\d{5,10}$/.test(acct)) return { error: "An account number has 5 to 10 digits." };
  const { error } = await (await createClient()).from("suppliers").insert({
    name: clip(f.name, 200), kind: f.kind, abn, gst_registered: !!f.gst_registered, email, phone: ph.value, address: clip(f.address, 400), payment_bsb: bsb, payment_account_number: acct, payment_account_name: clip(f.account_name, 120),
  });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Supplier added." };
}

export async function recordSupplierInvoice(f: { supplier_id: string; ref: string; invoice_date: string; due_date: string; note: string; lines: { description: string; client_id: string; service_date: string; amount: string; gst: string }[] }): Promise<FormState> {
  await requireSession();
  if (!isId(f.supplier_id)) return { error: "Choose the supplier." };
  if (!clip(f.ref, 60)) return { error: "Enter the supplier's invoice number." };
  if (!ymd(f.invoice_date)) return { error: "Enter the invoice date." };
  const lines = (f.lines ?? []).filter((l) => clip(l.description, 300) && money(l.amount, true) !== null);
  if (!lines.length) return { error: "Add at least one line with a description and amount." };
  const supabase = await createClient();
  const { data: inv, error } = await supabase.from("supplier_invoices").insert({ supplier_id: f.supplier_id, supplier_ref: clip(f.ref, 60), invoice_date: f.invoice_date, due_date: ymd(f.due_date), document_note: clip(f.note, 500) }).select("id").single();
  if (error) return { error: friendlyError(error) };
  const { error: e2 } = await supabase.from("supplier_invoice_lines").insert(lines.map((l) => ({
    supplier_invoice_id: inv.id, description: clip(l.description, 300), client_id: isId(l.client_id) ? l.client_id : null, service_date: ymd(l.service_date), amount: money(l.amount, true), gst_amount: money(l.gst, true) ?? 0,
  })));
  if (e2) {
    await supabase.from("supplier_invoices").update({ status: "rejected", reject_reason: "Recorded with an error; record it again" }).eq("id", inv.id);
    return { error: friendlyError(e2) };
  }
  done();
  return { message: "Supplier invoice recorded. Someone else approves it before any charge is made from it." };
}

export async function supplierInvoiceStep(id: string, step: "approved" | "paid" | "rejected", f: { paid_on?: string; reference?: string; reason?: string } = {}): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const values = step === "paid" ? { status: step, paid_on: ymd(f.paid_on), paid_reference: clip(f.reference, 120) } : step === "rejected" ? { status: step, reject_reason: clip(f.reason, 500) } : { status: step };
  const r = await upd("supplier_invoices", id, values, "You can't do that to this supplier invoice.");
  return r ?? { message: step === "approved" ? "Approved. Charges to clients can now be made from its lines." : step === "paid" ? "Recorded as paid." : "Rejected (kept)." };
}

export async function makeCharge(f: {
  client_id: string; scheme: string; enrolment_id: string; funding_stream: string; pathway_budget_id: string; funding_id: string; location_id: string; supplier_line_id: string;
  description: string; service_date: string; sah_category: string; ndis_item: string; amount: string; markup_pct: string; markup_note: string; gst_code: string;
}): Promise<FormState> {
  await requireSession();
  if (!isId(f.client_id)) return { error: "Choose the client." };
  if (!clip(f.description, 300)) return { error: "Describe the charge." };
  const fromSupplier = isId(f.supplier_line_id);
  if (!fromSupplier && !ymd(f.service_date)) return { error: "Enter the date of the service or purchase." };
  const amount = fromSupplier ? 1 : money(f.amount);
  if (amount === null) return { error: "Enter the amount." };
  const markup = Number(f.markup_pct || 0);
  if (!Number.isFinite(markup) || markup < 0 || markup > 100) return { error: "The markup is 0 to 100 per cent." };
  const { error } = await (await createClient()).from("client_charges").insert({
    client_id: f.client_id, scheme: f.scheme, enrolment_id: isId(f.enrolment_id) ? f.enrolment_id : null, funding_stream: f.funding_stream,
    pathway_budget_id: isId(f.pathway_budget_id) ? f.pathway_budget_id : null, funding_id: isId(f.funding_id) ? f.funding_id : null, location_id: isId(f.location_id) ? f.location_id : null,
    supplier_line_id: fromSupplier ? f.supplier_line_id : null, description: clip(f.description, 300), service_date: ymd(f.service_date) ?? new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" }),
    sah_category: ["clinical", "independence", "everyday_living"].includes(f.sah_category) ? f.sah_category : null, ndis_item: clip(f.ndis_item, 40), amount, markup_pct: markup, markup_note: clip(f.markup_note, 500),
    gst_code: ["gst_free", "taxable", "input_taxed"].includes(f.gst_code) ? f.gst_code : "gst_free",
  });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Draft charge made. Someone else with Billing approve approves it." };
}

export async function chargeStep(id: string, step: "approved" | "voided", note: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("client_charges", id, step === "approved" ? { status: step, approve_note: clip(note, 1000) } : { status: step, void_reason: clip(note, 500) }, "You can't do that to this charge.");
  return r ?? { message: step === "approved" ? "Charge approved." : "Charge voided (kept)." };
}

export async function addPathwayBudget(f: { client_id: string; enrolment_id: string; stream: string; detail: string; amount: string; starts_on: string; ends_on: string; source: string }): Promise<FormState> {
  await requireSession();
  if (!isId(f.client_id) || !isId(f.enrolment_id)) return { error: "Choose the client's Support at Home program." };
  if (!["at_hm", "restorative", "end_of_life", "hcp_unspent"].includes(f.stream)) return { error: "Choose the pathway or fund." };
  const amount = money(f.amount);
  if (amount === null) return { error: "Enter the amount from the notice." };
  if (!ymd(f.starts_on) || !ymd(f.ends_on)) return { error: "Enter the period from the notice." };
  if (!clip(f.source, 500)) return { error: "Record the source (the Services Australia notice and its date)." };
  const { error } = await (await createClient()).from("client_pathway_budgets").insert({ client_id: f.client_id, enrolment_id: f.enrolment_id, stream: f.stream, detail: clip(f.detail, 200), amount, starts_on: f.starts_on, ends_on: f.ends_on, source: clip(f.source, 500) });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Draft pathway budget added. Someone else approves it." };
}

export async function pathwayStep(id: string, step: "approved" | "closed", note = ""): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("client_pathway_budgets", id, step === "closed" ? { status: step, close_note: clip(note, 500) } : { status: step }, "You can't do that to this pathway budget.");
  return r ?? { message: step === "approved" ? "Pathway budget approved." : "Pathway budget closed." };
}

export async function addMarkupRule(f: { stream: string; pct: string; max: string; from: string; note: string }): Promise<FormState> {
  await requireSession();
  const pct = Number(f.pct);
  if (!Number.isFinite(pct) || pct < 0 || pct > 100 || f.pct === "") return { error: "The markup is 0 to 100 per cent." };
  if (!ymd(f.from)) return { error: "Choose the date it applies from." };
  const { error } = await (await createClient()).from("billing_markup_rules").insert({ funding_stream: f.stream, markup_pct: pct, max_markup: money(f.max), effective_from: f.from, note: clip(f.note, 500) });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/settings/billing");
  return { message: "Markup rule added." };
}

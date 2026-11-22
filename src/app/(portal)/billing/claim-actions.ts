// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import { EMAIL, type FormState } from "@/lib/form";
import { buildClaimFile } from "@/lib/claim-file";
import { invoicePdf, statementPdf } from "@/lib/billing-pdf";
import { checkPhone } from "@/lib/phone";
import { abnValid } from "@/lib/abn";

// cmeprojects (update 163): claims, client invoices, statements and client billing
// details. The database decides who may do each step (claim prepare / approve /
// submit, invoice prepare / approve / issue; the approver is never the preparer),
// works out every amount, and never lets a claim be marked submitted except by
// recording the manual upload to the government portal.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const done = (path?: string) => {
  revalidatePath("/billing");
  if (path) revalidatePath(path);
};
async function upd(table: string, id: string, values: Record<string, unknown>, nothing = "You can't change this."): Promise<FormState> {
  const { data, error } = await (await createClient()).from(table).update(values).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: nothing };
  return null;
}

// ---- Claims ----
export async function prepareClaim(program: string, from: string, to: string): Promise<FormState & { id?: string }> {
  await requireSession();
  if (!["support_at_home", "ndis"].includes(program)) return { error: "Choose the program." };
  if (!ymd(from) || !ymd(to)) return { error: "Choose the period." };
  const { data, error } = await (await createClient()).rpc("claim_prepare", { p_program: program, p_from: from, p_to: to });
  if (error) return { error: friendlyError(error) };
  const r = data as { claim: string; lines: number; excluded: number };
  done();
  return { id: r.claim, message: `Draft claim prepared: ${r.lines} line(s) included, ${r.excluded} listed as not claimable (with the reason). Someone else approves it.` };
}

export async function approveClaim(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("claims", id, { status: "approved" }, "You can't approve this claim.");
  if (r) return r;
  done(`/billing/claims/${id}`);
  return { message: "Approved. Make the file, upload it in the government portal, then record the submission here." };
}

export async function cancelClaim(id: string, reason: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("claims", id, { status: "cancelled", cancel_reason: clip(reason, 500) }, "You can't cancel this claim.");
  if (r) return r;
  done(`/billing/claims/${id}`);
  return { message: "Claim cancelled (kept). Its lines can be claimed again." };
}

export async function removeClaimItem(itemId: string, claimId: string): Promise<FormState> {
  await requireSession();
  if (!isId(itemId) || !isId(claimId)) return { error: "Something went wrong." };
  const r = await upd("claim_items", itemId, { status: "removed" }, "Only a draft claim's lines can be removed.");
  if (r) return r;
  const supabase = await createClient();
  const { data: items } = await supabase.from("claim_items").select("claimed_value, expected_amount").eq("claim_id", claimId).eq("status", "live");
  const live = (items ?? []) as { claimed_value: number; expected_amount: number }[];
  await supabase.from("claims").update({ item_count: live.length, total_claimed: live.reduce((a, i) => a + Number(i.claimed_value), 0), total_expected: live.reduce((a, i) => a + Number(i.expected_amount), 0) }).eq("id", claimId);
  done(`/billing/claims/${claimId}`);
  return { message: "Line removed from the draft (it can go in a later claim)." };
}

export async function makeClaimFile(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const f = await buildClaimFile(supabase, id);
  if ("error" in f) return { error: f.error };
  const r = await upd("claims", id, { file_name: f.name, file_content: f.content, file_checksum: f.checksum }, "The file can't be made for this claim.");
  if (r) return r;
  done(`/billing/claims/${id}`);
  return { message: `File made (${f.name}). Download it, upload it in the government portal, then record the submission. Making or downloading the file doesn't mark the claim submitted.` };
}

const CHANNELS = ["aged_care_provider_portal", "ndis_provider_portal", "other"];
export async function recordSubmission(claimId: string, f: { submitted_at: string; channel: string; reference: string; notes: string }): Promise<FormState> {
  await requireSession();
  if (!isId(claimId)) return { error: "Something went wrong." };
  if (!CHANNELS.includes(f.channel)) return { error: "Choose where it was uploaded." };
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(f.submitted_at)) return { error: "Enter the date and time it was uploaded." };
  // The time is entered in Sydney time.
  const at = new Date(`${f.submitted_at}:00${sydneyOffset(f.submitted_at)}`);
  if (Number.isNaN(at.getTime())) return { error: "Enter the date and time it was uploaded." };
  if (!clip(f.reference, 120)) return { error: "Enter the reference the government portal gave." };
  const { error } = await (await createClient()).from("claim_submissions").insert({ claim_id: claimId, submitted_at: at.toISOString(), channel: f.channel, external_reference: clip(f.reference, 120), notes: clip(f.notes, 1000) });
  if (error) return { error: friendlyError(error) };
  done(`/billing/claims/${claimId}`);
  return { message: "Submission recorded. The claim is now Submitted." };
}
function sydneyOffset(local: string) {
  const guess = new Date(`${local}:00Z`);
  const parts = new Intl.DateTimeFormat("en-AU", { timeZone: "Australia/Sydney", timeZoneName: "longOffset" }).formatToParts(guess);
  const tz = parts.find((p) => p.type === "timeZoneName")?.value ?? "GMT+10:00";
  const m = tz.match(/GMT([+-]\d{2}):?(\d{2})?/);
  return m ? `${m[1]}:${m[2] ?? "00"}` : "+10:00";
}

export async function recordAcknowledgement(claimId: string, text: string): Promise<FormState> {
  await requireSession();
  if (!isId(claimId)) return { error: "Something went wrong." };
  if (!clip(text, 1000)) return { error: "Enter the acknowledgement (for example, accepted in full, or the processing result)." };
  const { data, error } = await (await createClient()).from("claim_submissions").update({ acknowledgement: clip(text, 1000) }).eq("claim_id", claimId).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't record this." };
  done(`/billing/claims/${claimId}`);
  return { message: "Acknowledgement recorded." };
}

// ---- Invoices ----
const KINDS = ["sah_contribution", "private", "ndis_plan_managed", "ndis_self_managed"];
export async function prepareInvoices(kind: string, from: string, to: string): Promise<FormState> {
  await requireSession();
  if (!KINDS.includes(kind)) return { error: "Choose the kind of invoice." };
  if (!ymd(from) || !ymd(to)) return { error: "Choose the period." };
  const { data, error } = await (await createClient()).rpc("invoice_prepare", { p_kind: kind, p_from: from, p_to: to });
  if (error) return { error: friendlyError(error) };
  const r = data as { invoices_made: number; lines: number; excluded: { reason: string }[] };
  done();
  const why = [...new Set(r.excluded.map((e) => e.reason))];
  return { message: `${r.invoices_made} draft invoice(s), ${r.lines} line(s).${r.excluded.length ? ` ${r.excluded.length} line(s) not invoiced: ${why.join(" ")}` : ""} Someone else approves them.` };
}

export async function approveInvoice(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("invoices", id, { status: "approved" }, "You can't approve this invoice.");
  if (r) return r;
  done(`/billing/invoices/${id}`);
  return { message: "Approved. Issue it to give it a number and make the PDF." };
}

export async function issueInvoice(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const r = await upd("invoices", id, { status: "issued" }, "You can't issue this invoice.");
  if (r) return r;
  const { data: inv } = await supabase.from("invoices").select("number, tax_invoice, issue_date, due_date, period_from, period_to, subtotal, gst, total, kind, snapshot").eq("id", id).single();
  if (inv) {
    const pdf = await invoicePdf(inv as Parameters<typeof invoicePdf>[0]);
    await supabase.from("invoices").update({ pdf_base64: Buffer.from(pdf.bytes).toString("base64"), pdf_checksum: pdf.checksum }).eq("id", id).is("pdf_base64", null);
  }
  done(`/billing/invoices/${id}`);
  return { message: `Issued as ${inv?.number ?? "a numbered invoice"}. Download the PDF, send it, then mark it sent.` };
}

export async function markInvoiceSent(id: string, note: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("invoices", id, { status: "sent", sent_note: clip(note, 500) }, "You can't mark this invoice sent.");
  if (r) return r;
  done(`/billing/invoices/${id}`);
  return { message: "Marked sent." };
}

export async function cancelInvoice(id: string, reason: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const r = await upd("invoices", id, { status: "cancelled", cancel_reason: clip(reason, 500) }, "You can't cancel this invoice.");
  if (r) return r;
  done(`/billing/invoices/${id}`);
  return { message: "Invoice cancelled (kept, never numbered). Its lines can be invoiced again." };
}

export async function removeInvoiceItem(itemId: string, invoiceId: string): Promise<FormState> {
  await requireSession();
  if (!isId(itemId) || !isId(invoiceId)) return { error: "Something went wrong." };
  const r = await upd("invoice_items", itemId, { status: "removed" }, "Only a draft invoice's lines can be removed.");
  if (r) return r;
  const supabase = await createClient();
  const { data: items } = await supabase.from("invoice_items").select("amount").eq("invoice_id", invoiceId).eq("status", "live");
  const total = ((items ?? []) as { amount: number }[]).reduce((a, i) => a + Number(i.amount), 0);
  await supabase.from("invoices").update({ subtotal: total, total }).eq("id", invoiceId);
  done(`/billing/invoices/${invoiceId}`);
  return { message: "Line removed from the draft." };
}

export async function issueStatement(clientId: string, enrolmentId: string, month: string): Promise<FormState> {
  await requireSession();
  if (!isId(clientId) || !isId(enrolmentId) || !/^\d{4}-\d{2}$/.test(month)) return { error: "Choose the client and month." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("client_statements").insert({ client_id: clientId, enrolment_id: enrolmentId, month: `${month}-01` }).select("id, month, snapshot").single();
  if (error) return { error: friendlyError(error) };
  const pdf = await statementPdf({ month: data.month, snapshot: data.snapshot });
  await supabase.from("client_statements").update({ pdf_base64: Buffer.from(pdf.bytes).toString("base64"), pdf_checksum: pdf.checksum }).eq("id", data.id).is("pdf_base64", null);
  done();
  return { message: "Statement issued. Download the PDF from the list." };
}

// ---- Client billing details ----
const PAYER_KINDS = ["plan_manager", "participant", "client", "other"];
export async function addPayer(f: { kind: string; client_id: string; person_id: string; name: string; abn: string; email: string; phone: string; address: string; reference: string }): Promise<FormState> {
  await requireSession();
  if (!PAYER_KINDS.includes(f.kind)) return { error: "Choose the kind of payer." };
  const name = clip(f.name, 200);
  if (!name) return { error: "Enter the payer's name." };
  const email = clip(f.email, 200);
  if (email && !EMAIL.test(email)) return { error: "Enter a valid email address." };
  const ph = checkPhone("AU", clip(f.phone, 30));
  if (!ph.ok) return { error: ph.error };
  const phone = ph.value;
  const abn = clip(f.abn, 20).replace(/\s/g, "");
  if (abn && !abnValid(abn)) return { error: "That ABN isn't valid (check the 11 digits)." };
  const needsClient = f.kind === "participant" || f.kind === "client";
  if (needsClient && !isId(f.client_id)) return { error: "Choose the client." };
  const { error } = await (await createClient()).from("billing_payers").insert({
    kind: f.kind, client_id: needsClient ? f.client_id : null, person_id: isId(f.person_id) ? f.person_id : null, name, abn, email, phone, address: clip(f.address, 400), reference: clip(f.reference, 100),
  });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Payer added. Link it to the client below." };
}

export async function linkPayer(f: { client_id: string; role: string; funding_id: string; payer_id: string; starts_on: string }): Promise<FormState> {
  await requireSession();
  if (!isId(f.client_id) || !isId(f.payer_id)) return { error: "Choose the client and payer." };
  if (!["funding", "client"].includes(f.role)) return { error: "Choose what the payer pays." };
  if (f.role === "funding" && !isId(f.funding_id)) return { error: "Choose the NDIS plan (funding record)." };
  if (!ymd(f.starts_on)) return { error: "Choose the start date." };
  const { error } = await (await createClient()).from("client_payer_links").insert({ client_id: f.client_id, role: f.role, funding_id: f.role === "funding" ? f.funding_id : null, payer_id: f.payer_id, starts_on: f.starts_on });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Payer linked." };
}

export async function endRecord(table: "client_payer_links" | "client_fee_reductions", id: string, endsOn: string): Promise<FormState> {
  await requireSession();
  if (!["client_payer_links", "client_fee_reductions"].includes(table) || !isId(id) || !ymd(endsOn)) return { error: "Choose the end date." };
  const r = await upd(table, id, { ends_on: endsOn });
  if (r) return r;
  done();
  return { message: "End date saved." };
}

export async function addFeeReduction(f: { client_id: string; enrolment_id: string; starts_on: string; ends_on: string; source: string }): Promise<FormState> {
  await requireSession();
  if (!isId(f.client_id) || !isId(f.enrolment_id)) return { error: "Choose the client's Support at Home program." };
  if (!ymd(f.starts_on)) return { error: "Choose the start date." };
  if (!clip(f.source, 300)) return { error: "Record the source (for example, the Services Australia notice and its date)." };
  const { error } = await (await createClient()).from("client_fee_reductions").insert({ client_id: f.client_id, enrolment_id: f.enrolment_id, starts_on: f.starts_on, ends_on: ymd(f.ends_on), source: clip(f.source, 300) });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Fee reduction supplement recorded. Contributions in those dates aren't invoiced." };
}

export async function setZone(f: { location_id: string; zone: string; mmm: string; source: string }): Promise<FormState> {
  await requireSession();
  if (!isId(f.location_id) || !["national", "remote", "very_remote"].includes(f.zone)) return { error: "Choose the location and zone." };
  if (!clip(f.source, 300)) return { error: "Record how the zone was worked out (for example, the Modified Monash Model locator)." };
  const supabase = await createClient();
  const row = { location_id: f.location_id, ndis_zone: f.zone, mmm: clip(f.mmm, 10), source: clip(f.source, 300) };
  const { data: existing } = await supabase.from("client_location_pricing").select("location_id").eq("location_id", f.location_id).maybeSingle();
  const { error } = existing ? await supabase.from("client_location_pricing").update(row).eq("location_id", f.location_id) : await supabase.from("client_location_pricing").insert(row);
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Pricing zone saved." };
}

export async function setPlanDetails(f: { funding_id: string; my_provider: boolean; recorded_on: string; note: string }): Promise<FormState> {
  await requireSession();
  if (!isId(f.funding_id) || !ymd(f.recorded_on)) return { error: "Choose the plan and date." };
  const supabase = await createClient();
  const row = { funding_id: f.funding_id, my_provider: !!f.my_provider, recorded_on: f.recorded_on, note: clip(f.note, 300) };
  const { data: existing } = await supabase.from("ndis_plan_details").select("funding_id").eq("funding_id", f.funding_id).maybeSingle();
  const { error } = existing ? await supabase.from("ndis_plan_details").update(row).eq("funding_id", f.funding_id) : await supabase.from("ndis_plan_details").insert(row);
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Plan details saved." };
}

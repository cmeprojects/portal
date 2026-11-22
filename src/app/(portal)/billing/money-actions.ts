// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { creditNotePdf, receiptPdf } from "@/lib/billing-pdf";

// cmeprojects (update 164): claim results, payments, receipts, credit notes, refunds,
// write-offs and bank reconciliation. The database decides who may do each step (payments,
// refund, write-off and reconcile rights; approvers are never the proposer; a second approver
// above the write-off threshold) and never lets more be allocated, credited, refunded or
// written off than is there.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const money = (v: unknown) => {
  const n = Number(String(v ?? "").replace(/[$,\s]/g, ""));
  return Number.isFinite(n) && n > 0 ? Math.round(n * 100) / 100 : null;
};
const done = (...paths: string[]) => {
  revalidatePath("/billing");
  for (const p of paths) revalidatePath(p);
};

// ---- Claim results ----
const OUTCOMES = ["accepted", "partly_accepted", "rejected"];
export async function recordResult(claimId: string, itemId: string, f: { outcome: string; accepted: string; code: string; reason: string; reference: string; correctsId: string }): Promise<FormState> {
  await requireSession();
  if (!isId(claimId) || !isId(itemId) || !OUTCOMES.includes(f.outcome)) return { error: "Choose the result." };
  const supabase = await createClient();
  const { data: item } = await supabase.from("claim_items").select("claimed_value").eq("id", itemId).maybeSingle();
  if (!item) return { error: "That claim line isn't available." };
  const accepted = f.outcome === "accepted" ? Number(item.claimed_value) : f.outcome === "rejected" ? 0 : money(f.accepted);
  if (accepted === null) return { error: "Enter the amount accepted." };
  const { error } = await supabase.from("claim_item_results").insert({
    claim_item_id: itemId, outcome: f.outcome, accepted_amount: accepted, reason_code: clip(f.code, 60), reason: clip(f.reason, 1000), source_reference: clip(f.reference, 120), corrects_id: isId(f.correctsId) ? f.correctsId : null,
  });
  if (error) return { error: friendlyError(error) };
  done(`/billing/claims/${claimId}`);
  return { message: f.correctsId ? "Correction recorded (the earlier result is kept)." : "Result recorded." };
}

export async function acceptRemaining(claimId: string, reference: string): Promise<FormState> {
  await requireSession();
  if (!isId(claimId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const [{ data: items }, { data: outs }] = await Promise.all([
    supabase.from("claim_items").select("id, claimed_value").eq("claim_id", claimId).eq("status", "live"),
    supabase.from("claim_item_outcomes").select("claim_item_id").eq("claim_id", claimId),
  ]);
  const done_ = new Set(((outs ?? []) as { claim_item_id: string }[]).map((o) => o.claim_item_id));
  const todo = ((items ?? []) as { id: string; claimed_value: number }[]).filter((i) => !done_.has(i.id));
  if (!todo.length) return { error: "Every line already has a result." };
  const { error } = await supabase.from("claim_item_results").insert(todo.map((i) => ({ claim_item_id: i.id, outcome: "accepted", accepted_amount: i.claimed_value, source_reference: clip(reference, 120) })));
  if (error) return { error: friendlyError(error) };
  done(`/billing/claims/${claimId}`);
  return { message: `${todo.length} line(s) recorded as accepted in full.` };
}

export async function resubmitClaim(claimId: string): Promise<FormState & { id?: string }> {
  await requireSession();
  if (!isId(claimId)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).rpc("claim_resubmit", { p_claim: claimId });
  if (error) return { error: friendlyError(error) };
  const r = data as { claim: string; lines: number };
  done(`/billing/claims/${claimId}`);
  return { id: r.claim, message: `Replacement claim prepared with ${r.lines} rejected line(s), linked to this claim. Someone else approves it.` };
}

// ---- Payments ----
const METHODS = ["eft", "bpay", "card", "cash", "cheque", "government_remittance", "other"];
export async function recordPayment(f: { payer_id: string; client_id: string; received_on: string; amount: string; method: string; reference: string; notes: string }): Promise<FormState & { id?: string }> {
  await requireSession();
  if (!isId(f.payer_id)) return { error: "Choose who paid." };
  if (!ymd(f.received_on)) return { error: "Enter the date received." };
  const amount = money(f.amount);
  if (amount === null) return { error: "Enter the amount received." };
  if (!METHODS.includes(f.method)) return { error: "Choose how it was paid." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("payments").insert({
    payer_id: f.payer_id, client_id: isId(f.client_id) ? f.client_id : null, received_on: f.received_on, amount, method: f.method, reference: clip(f.reference, 120), notes: clip(f.notes, 1000),
  }).select("id, receipt_number").single();
  if (error) return { error: friendlyError(error) };
  done();
  return { id: data.id, message: `Payment recorded${data.receipt_number ? ` (receipt ${data.receipt_number}; the receipt PDF is made when it's allocated)` : ""}. Now allocate it.` };
}

async function makeReceipt(paymentId: string) {
  const supabase = await createClient();
  const { data: p } = await supabase.from("payments").select("id, receipt_number, received_on, amount, method, reference, payer_id, client_id").eq("id", paymentId).single();
  if (!p?.receipt_number) return;
  const [{ data: biz }, { data: payer }, { data: client }, { data: allocs }] = await Promise.all([
    supabase.from("business_current").select("*").maybeSingle(),
    supabase.from("billing_payers").select("name, email, address").eq("id", p.payer_id).maybeSingle(),
    p.client_id ? supabase.from("car_clients").select("name, client_ref").eq("id", p.client_id).maybeSingle() : Promise.resolve({ data: null }),
    supabase.from("payment_allocations").select("amount, invoices(number)").eq("payment_id", paymentId),
  ]);
  const pdf = await receiptPdf({ ...p, business: biz ?? {}, payer: payer ?? {}, client: client ?? null, allocations: ((allocs ?? []) as { amount: number; invoices: { number: string } | { number: string }[] | null }[]).map((a) => ({ amount: a.amount, invoice: (Array.isArray(a.invoices) ? a.invoices[0] : a.invoices)?.number ?? "" })) });
  await supabase.from("payments").update({ receipt_pdf_base64: Buffer.from(pdf.bytes).toString("base64"), receipt_pdf_checksum: pdf.checksum }).eq("id", paymentId).is("receipt_pdf_base64", null);
}

export async function allocate(paymentId: string, rows: { kind: "invoice" | "claim_item"; id: string; amount: string }[]): Promise<FormState> {
  await requireSession();
  if (!isId(paymentId)) return { error: "Something went wrong." };
  const list = rows.map((r) => ({ ...r, n: money(r.amount) })).filter((r) => isId(r.id) && r.n !== null);
  if (!list.length) return { error: "Enter an amount against at least one invoice or claim line." };
  const supabase = await createClient();
  const { data: p } = await supabase.from("payments").select("receipt_number, receipt_pdf_base64").eq("id", paymentId).maybeSingle();
  let ok = 0;
  for (const r of list) {
    const { error } = await supabase.from("payment_allocations").insert({ payment_id: paymentId, invoice_id: r.kind === "invoice" ? r.id : null, claim_item_id: r.kind === "claim_item" ? r.id : null, amount: r.n });
    if (error) {
      done(`/billing/payments/${paymentId}`);
      return { error: `${ok} allocated, then: ${friendlyError(error)}` };
    }
    ok++;
  }
  // The receipt lists what it paid: made once the client payment is allocated (never changes after).
  if (p?.receipt_number && !p.receipt_pdf_base64) await makeReceipt(paymentId);
  done(`/billing/payments/${paymentId}`);
  return { message: `${ok} allocation(s) saved.` };
}

export async function issueReceipt(paymentId: string): Promise<FormState> {
  await requireSession();
  if (!isId(paymentId)) return { error: "Something went wrong." };
  await makeReceipt(paymentId);
  done(`/billing/payments/${paymentId}`);
  return { message: "Receipt made. Download it from this page." };
}

export async function reversePayment(id: string, reason: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("payments").update({ status: "reversed", reversal_reason: clip(reason, 500) }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't reverse this payment." };
  done(`/billing/payments/${id}`);
  return { message: "Payment reversed (kept); its allocations no longer count." };
}

// ---- Credit notes ----
export async function prepareCreditNote(invoiceId: string, reason: string, lines: { id: string; amount: string }[]): Promise<FormState> {
  await requireSession();
  if (!isId(invoiceId)) return { error: "Something went wrong." };
  if (!clip(reason, 1000)) return { error: "Say why the credit is given." };
  const list = lines.map((l) => ({ id: l.id, n: money(l.amount) })).filter((l) => isId(l.id) && l.n !== null);
  if (!list.length) return { error: "Enter an amount to credit on at least one line." };
  const supabase = await createClient();
  const { data: cn, error } = await supabase.from("credit_notes").insert({ invoice_id: invoiceId, reason: clip(reason, 1000) }).select("id").single();
  if (error) return { error: friendlyError(error) };
  for (const l of list) {
    const { error: e2 } = await supabase.from("credit_note_items").insert({ credit_note_id: cn.id, invoice_item_id: l.id, amount: l.n });
    if (e2) {
      await supabase.from("credit_notes").update({ status: "cancelled", cancel_reason: "Couldn't add its lines" }).eq("id", cn.id);
      done(`/billing/invoices/${invoiceId}`);
      return { error: friendlyError(e2) };
    }
  }
  await supabase.from("credit_notes").update({ reason: clip(reason, 1000) }).eq("id", cn.id); // works out the total
  done(`/billing/invoices/${invoiceId}`);
  return { message: "Draft credit note prepared. Someone else approves it." };
}

export async function creditNoteStep(id: string, invoiceId: string, step: "approved" | "issued" | "cancelled", reason = ""): Promise<FormState> {
  await requireSession();
  if (!isId(id) || !isId(invoiceId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("credit_notes").update(step === "cancelled" ? { status: step, cancel_reason: clip(reason, 500) } : { status: step }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't do that to this credit note." };
  if (step === "issued") {
    const { data: n } = await supabase.from("credit_notes").select("number, issue_date, amount, gst, snapshot").eq("id", id).single();
    if (n) {
      const pdf = await creditNotePdf(n as Parameters<typeof creditNotePdf>[0]);
      await supabase.from("credit_notes").update({ pdf_base64: Buffer.from(pdf.bytes).toString("base64"), pdf_checksum: pdf.checksum }).eq("id", id).is("pdf_base64", null);
    }
  }
  done(`/billing/invoices/${invoiceId}`);
  return { message: step === "approved" ? "Credit note approved. Issue it to number it." : step === "issued" ? "Credit note issued. Download the PDF and send it." : "Credit note cancelled (kept)." };
}

// ---- Write-offs and refunds ----
export async function proposeWriteOff(target: { invoice_id?: string; claim_item_id?: string }, amount: string, reason: string, back: string): Promise<FormState> {
  await requireSession();
  const n = money(amount);
  if (n === null) return { error: "Enter the amount." };
  if (!clip(reason, 1000)) return { error: "Say why it's written off." };
  const row = { invoice_id: isId(target.invoice_id) ? target.invoice_id : null, claim_item_id: isId(target.claim_item_id) ? target.claim_item_id : null, amount: n, reason: clip(reason, 1000) };
  if (!row.invoice_id === !row.claim_item_id) return { error: "Something went wrong." };
  const { error } = await (await createClient()).from("write_offs").insert(row);
  if (error) return { error: friendlyError(error) };
  done(back);
  return { message: "Write-off proposed. Someone else with the write-off right approves it (two people above the threshold)." };
}

export async function decideWriteOff(id: string, approve: boolean, reason = ""): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("write_offs").update(approve ? { status: "approved" } : { status: "rejected", reject_reason: clip(reason, 500) }).eq("id", id).select("status");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't decide this write-off." };
  done();
  return { message: !approve ? "Rejected." : data[0].status === "first_approved" ? "First approval recorded. Above the threshold, a second person approves." : "Write-off approved." };
}

export async function proposeRefund(source: { payment_id?: string; invoice_id?: string }, amount: string, reason: string, back: string): Promise<FormState> {
  await requireSession();
  const n = money(amount);
  if (n === null) return { error: "Enter the amount." };
  if (!clip(reason, 1000)) return { error: "Say why it's refunded." };
  const row = { payment_id: isId(source.payment_id) ? source.payment_id : null, invoice_id: isId(source.invoice_id) ? source.invoice_id : null, amount: n, reason: clip(reason, 1000) };
  if (!row.payment_id === !row.invoice_id) return { error: "Something went wrong." };
  const { error } = await (await createClient()).from("refunds").insert(row);
  if (error) return { error: friendlyError(error) };
  done(back);
  return { message: "Refund proposed. Someone else with the refund right approves it." };
}

export async function refundStep(id: string, step: "approved" | "paid" | "rejected", f: { paid_on?: string; reference?: string; reason?: string } = {}): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const values = step === "paid" ? { status: step, paid_on: ymd(f.paid_on), paid_reference: clip(f.reference, 120) } : step === "rejected" ? { status: step, reject_reason: clip(f.reason, 500) } : { status: step };
  const { data, error } = await (await createClient()).from("refunds").update(values).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't do that to this refund." };
  done();
  return { message: step === "approved" ? "Refund approved. Record it as paid once the money is sent." : step === "paid" ? "Refund recorded as paid." : "Refund rejected." };
}

// ---- Bank reconciliation ----
export async function importBankLines(batch: string, lines: { date: string; amount: number; description: string; reference: string }[]): Promise<FormState> {
  await requireSession();
  const rows = (Array.isArray(lines) ? lines : []).filter((l) => ymd(l.date) && Number.isFinite(Number(l.amount)) && Number(l.amount) !== 0).slice(0, 5000);
  if (!rows.length) return { error: "No lines with a date and an amount were found." };
  const supabase = await createClient();
  const seen = new Map<string, number>();
  const payload = rows.map((l) => {
    const base = `${l.date}|${Number(l.amount).toFixed(2)}|${clip(l.description, 500)}|${clip(l.reference, 200)}`;
    const n = (seen.get(base) ?? 0) + 1;
    seen.set(base, n);
    return { statement_date: l.date, amount: Math.round(Number(l.amount) * 100) / 100, description: clip(l.description, 500), reference: clip(l.reference, 200), import_batch: clip(batch, 200), import_key: `${base}|${n}` };
  });
  const { data: existing } = await supabase.from("bank_statement_lines").select("import_key").in("import_key", payload.map((p) => p.import_key));
  const have = new Set(((existing ?? []) as { import_key: string }[]).map((e) => e.import_key));
  const fresh = payload.filter((p) => !have.has(p.import_key));
  if (fresh.length) {
    const { error } = await supabase.from("bank_statement_lines").insert(fresh);
    if (error) return { error: friendlyError(error) };
  }
  done();
  return { message: `${fresh.length} bank line(s) imported${payload.length - fresh.length ? `; ${payload.length - fresh.length} already imported were skipped` : ""}.` };
}

export async function matchBankLine(id: string, f: { status: "matched" | "excluded" | "unmatched"; payment_id?: string; refund_id?: string; reason?: string }): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const values = f.status === "matched" ? { status: f.status, payment_id: isId(f.payment_id) ? f.payment_id : null, refund_id: isId(f.refund_id) ? f.refund_id : null }
    : f.status === "excluded" ? { status: f.status, exclude_reason: clip(f.reason, 500) } : { status: f.status };
  const { data, error } = await (await createClient()).from("bank_statement_lines").update(values).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this bank line." };
  done();
  return { message: f.status === "matched" ? "Matched." : f.status === "excluded" ? "Excluded." : "Unmatched." };
}

export async function saveReconciliation(f: { period_from: string; period_to: string; opening: string; closing: string; notes: string }): Promise<FormState> {
  await requireSession();
  if (!ymd(f.period_from) || !ymd(f.period_to)) return { error: "Choose the period." };
  const opening = Number(String(f.opening).replace(/[$,\s]/g, ""));
  const closing = Number(String(f.closing).replace(/[$,\s]/g, ""));
  if (!Number.isFinite(opening) || !Number.isFinite(closing) || f.opening === "" || f.closing === "") return { error: "Enter the opening and closing balances from the bank statement." };
  const { error } = await (await createClient()).from("bank_reconciliations").insert({ period_from: f.period_from, period_to: f.period_to, opening_balance: opening, closing_balance: closing, notes: clip(f.notes, 1000) });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: "Reconciliation started. Complete it once every line is matched or excluded and the balances agree." };
}

export async function completeReconciliation(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("bank_reconciliations").update({ status: "completed" }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't complete this reconciliation." };
  done();
  return { message: "Reconciliation completed. Its bank lines and matches no longer change." };
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 162): Billing module actions. The database decides who may
// (Billing prepare to make lines and propose; Billing approve, not the maker, to
// approve, void, decide delivery, approve budgets and ledger entries, close a
// quarter), calculates every amount and keeps everything traceable.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const done = () => {
  revalidatePath("/billing");
};
const VOID_REASONS = ["data_entry", "wrong_rate", "not_delivered", "wrong_client", "grounds_accepted", "wrong_terms", "other"];

export async function makeLines(from: string, to: string, clientId?: string): Promise<FormState> {
  await requireSession();
  if (!ymd(from) || !ymd(to)) return { error: "Choose the period." };
  const { data, error } = await (await createClient()).rpc("billing_generate", { p_from: from, p_to: to, p_client: isId(clientId) ? clientId : null });
  if (error) return { error: friendlyError(error) };
  const r = data as { made: number; already_made: number; with_problems: number };
  done();
  return { message: `Made ${r.made} line(s). ${r.already_made} already made. ${r.with_problems} shift(s) can't be billed yet (see Exceptions).` };
}

export async function approveLines(ids: string[], note = ""): Promise<FormState> {
  await requireSession();
  const list = ids.filter(isId);
  if (!list.length) return { error: "Choose the lines to approve." };
  const supabase = await createClient();
  let ok = 0;
  const problems: string[] = [];
  for (const id of list) {
    const { data, error } = await supabase.from("billing_lines").update({ status: "approved", approve_note: clip(note, 1000) }).eq("id", id).eq("status", "draft").select("id");
    if (error) problems.push(friendlyError(error));
    else if (data?.length) ok++;
  }
  done();
  if (problems.length) return { error: `${ok} approved. ${problems.length} not approved: ${[...new Set(problems)].join(" ")}` };
  return { message: `${ok} line(s) approved and charged to their funding.` };
}

export async function voidLine(id: string, reason: string, note: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  if (!VOID_REASONS.includes(reason)) return { error: "Choose why it's voided." };
  const { data, error } = await (await createClient()).from("billing_lines").update({ status: "voided", void_reason: reason, void_note: clip(note, 1000) }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't void this line." };
  done();
  return { message: "Voided (kept). Fix the cause, then make lines again for a corrected line." };
}

export async function decideDelivery(shiftId: string, decision: "delivered" | "not_delivered", reason: string): Promise<FormState> {
  await requireSession();
  if (!isId(shiftId)) return { error: "Something went wrong." };
  if (!reason.trim()) return { error: "Give the reason." };
  const { error } = await (await createClient()).from("billing_delivery_overrides").insert({ shift_id: shiftId, decision, reason: clip(reason, 1000) });
  if (error) return { error: friendlyError(error) };
  done();
  return { message: decision === "delivered" ? "Recorded as delivered. Make lines again to bill it." : "Recorded as not delivered." };
}

export async function addQuarterBudget(v: Record<string, string>): Promise<FormState> {
  await requireSession();
  if (!isId(v.client_id) || !isId(v.enrolment_id)) return { error: "Choose the client's Support at Home program." };
  if (!ymd(v.quarter_start)) return { error: "Choose the quarter." };
  const amount = Number(v.quarterly_amount);
  if (!v.quarterly_amount?.trim() || !Number.isFinite(amount) || amount < 0) return { error: "Give the quarterly amount from the Services Australia notice." };
  if (!v.source?.trim()) return { error: "Say where the amount comes from." };
  const { error } = await (await createClient()).from("client_quarter_budgets").insert({
    client_id: v.client_id, enrolment_id: v.enrolment_id, funding_id: isId(v.funding_id) ? v.funding_id : null, quarter_start: v.quarter_start, quarter_end: v.quarter_start,
    classification: v.classification ? Number(v.classification) : null, quarterly_amount: Math.round(amount * 100) / 100, start_date: ymd(v.start_date), source: clip(v.source, 300),
  });
  if (error) return { error: error.code === "23505" ? "There's already a budget for that program and quarter." : friendlyError(error) };
  done();
  return { message: "Draft quarter budget added. Someone else with the Billing approve right approves it." };
}

export async function approveQuarterBudget(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("client_quarter_budgets").update({ status: "approved" }).eq("id", id).eq("status", "draft").select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a draft budget is approved." };
  done();
  return { message: "Quarter budget approved." };
}

export async function closeQuarter(id: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).rpc("billing_close_quarter", { p_budget: id });
  if (error) return { error: friendlyError(error) };
  const r = data as { spent: number; carryover: number; lapsed: number };
  done();
  const aud = (n: number) => Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" });
  return { message: `Quarter closed: spent ${aud(r.spent)}, ${aud(r.carryover)} carried over, ${aud(r.lapsed)} lapsed.` };
}

export async function proposeLedgerEntry(v: Record<string, string>): Promise<FormState> {
  await requireSession();
  if (!isId(v.client_id)) return { error: "Choose the client." };
  const amount = Number(v.amount);
  if (!v.amount?.trim() || !Number.isFinite(amount)) return { error: "Give the amount (AUD)." };
  if (!ymd(v.entry_date)) return { error: "Give the date." };
  if (!v.reason?.trim()) return { error: "Say where the amount comes from, or why." };
  const account = v.account ?? "";
  const [kind, accountId] = account.split(":");
  if (!isId(accountId)) return { error: "Choose the funding account." };
  const { error } = await (await createClient()).from("funding_ledger").insert({
    client_id: v.client_id, entry_kind: v.entry_kind === "opening_balance" ? "opening_balance" : "adjustment", amount: Math.round(amount * 100) / 100,
    entry_date: v.entry_date, reason: clip(v.reason, 1000), quarter_budget_id: kind === "q" ? accountId : null, funding_id: kind === "f" ? accountId : null,
  });
  if (error) return { error: error.code === "23505" ? "That funding record already has an opening balance." : friendlyError(error) };
  done();
  return { message: "Proposed. Someone else with the Billing approve right approves it before it counts." };
}

export async function decideLedgerEntry(id: string, approve: boolean): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("funding_ledger").update({ status: approve ? "approved" : "rejected" }).eq("id", id).eq("status", "proposed").select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a proposed entry is decided." };
  done();
  return { message: approve ? "Approved: it now counts in the balance." : "Rejected (kept, not counted)." };
}

export async function verifyFigure(id: string, v: { verified: boolean; source: string; asAt: string }): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("billing_parameters").update({ status: v.verified ? "verified" : "unverified", source: clip(v.source, 1000), as_at: ymd(v.asAt) }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change billing figures." };
  revalidatePath("/settings/billing");
  revalidatePath("/settings");
  return { message: v.verified ? "Figure verified." : "Marked unverified." };
}

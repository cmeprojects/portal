// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 161): billing terms for approved services, contribution
// rates and cancellation details. The database checks who may (the Billing
// part, separate from Funding and care plans), what belongs together, and keeps
// approved and recorded versions fixed.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const refresh = (clientId: string) => revalidatePath(`/settings/clients/${clientId}`);

export async function saveServiceTerms(clientId: string, serviceId: string, v: Record<string, string>, termsId?: string): Promise<FormState> {
  await requireSession();
  if (!isId(clientId) || !isId(serviceId) || (termsId && !isId(termsId))) return { error: "Something went wrong." };
  const from = ymd(v.effective_from);
  if (!from) return { error: "Give the date these terms start." };
  if (!isId(v.enrolment_id)) return { error: "Choose the program enrolment." };
  const qty = v.quantity?.trim() ? Number(v.quantity) : null;
  if (qty !== null && (!Number.isFinite(qty) || qty < 0 || qty > 10000)) return { error: "The approved quantity is a number from 0 to 10,000." };
  const row = {
    effective_from: from,
    enrolment_id: v.enrolment_id,
    funding_id: isId(v.funding_id) ? v.funding_id : null,
    agreement_id: isId(v.agreement_id) ? v.agreement_id : null,
    price_list_id: isId(v.price_list_id) ? v.price_list_id : null,
    quantity: qty,
    unit: v.unit || "hour",
    frequency: v.frequency || "week",
    sah_category: v.sah_category || null,
    personal_care: v.personal_care === "true",
    funding_stream: v.funding_stream || "ongoing",
    source_support_line_id: isId(v.source_support_line_id) ? v.source_support_line_id : null,
    notes: clip(v.notes, 2000),
  };
  const supabase = await createClient();
  const { data, error } = termsId
    ? await supabase.from("client_service_terms").update(row).eq("id", termsId).select("id")
    : await supabase.from("client_service_terms").insert({ ...row, client_id: clientId, service_id: serviceId }).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "These terms can only change while they're a draft or need changes." };
  refresh(clientId);
  return { message: termsId ? "Saved." : "Draft billing terms added." };
}

export async function serviceTermsStep(id: string, step: "submit" | "take_back" | "approve" | "changes", note = ""): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const row: Record<string, string> =
    step === "submit" ? { status: "pending_review" } : step === "take_back" ? { status: "draft" } : step === "approve" ? { status: "approved" } : { status: "changes_required", review_note: clip(note, 1000) };
  if (step === "changes" && !row.review_note) return { error: "Say what needs changing." };
  const { data, error } = await (await createClient()).from("client_service_terms").update(row).eq("id", id).select("client_id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't do that on these terms." };
  refresh((data[0] as { client_id: string }).client_id);
  return { message: { submit: "Sent for review.", take_back: "Taken back to draft.", approve: "Approved. Earlier terms now end the day before (kept).", changes: "Sent back with what needs changing." }[step] };
}

export async function removeDraftTerms(id: string, clientId: string): Promise<FormState> {
  await requireSession();
  if (!isId(id) || !isId(clientId)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("client_service_terms").delete().eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only an unsent draft can be removed." };
  refresh(clientId);
  return { message: "Draft removed." };
}

export async function addContributionRate(clientId: string, v: Record<string, string>): Promise<FormState> {
  await requireSession();
  if (!isId(clientId) || !isId(v.enrolment_id)) return { error: "Choose the Support at Home program." };
  const pct = Number(v.rate_pct);
  if (!v.rate_pct?.trim() || !Number.isFinite(pct) || pct < 0 || pct > 100) return { error: "The rate is a percentage from 0 to 100." };
  const from = ymd(v.effective_from);
  if (!from) return { error: "Give the date the rate applies from." };
  if (!v.source?.trim()) return { error: "Say where the rate comes from (e.g. the Services Australia letter and its date)." };
  const { error } = await (await createClient()).from("client_contribution_rates").insert({
    client_id: clientId, enrolment_id: v.enrolment_id, category: v.category, rate_pct: Math.round(pct * 100) / 100,
    contribution_group: v.contribution_group || "", effective_from: from, source: clip(v.source, 300), document_id: isId(v.document_id) ? v.document_id : null,
  });
  if (error) return { error: friendlyError(error) };
  refresh(clientId);
  return { message: "Contribution rate recorded." };
}

export async function endContributionRate(id: string, clientId: string, endOn: string): Promise<FormState> {
  await requireSession();
  if (!isId(id) || !isId(clientId) || !ymd(endOn)) return { error: "Give the last day the rate applies." };
  const { data, error } = await (await createClient()).from("client_contribution_rates").update({ effective_to: endOn }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this rate." };
  refresh(clientId);
  return { message: "Rate ended. Add the new rate from the next day." };
}

export async function saveCancellation(shiftId: string, v: Record<string, string>, exists: boolean): Promise<FormState> {
  await requireSession();
  if (!isId(shiftId)) return { error: "Something went wrong." };
  if (!v.notified_at) return { error: "Say when the cancellation was given." };
  if (!v.reason?.trim()) return { error: "Give the reason." };
  const notified = new Date(v.notified_at);
  if (Number.isNaN(notified.getTime())) return { error: "Say when the cancellation was given." };
  const row = {
    notified_at: notified.toISOString(),
    cancelled_by: v.cancelled_by,
    reason: clip(v.reason, 1000),
    reasonable_grounds: v.reasonable_grounds === "yes" ? true : v.reasonable_grounds === "no" ? false : null,
    charge: v.charge || "undecided",
    charge_note: clip(v.charge_note, 1000),
  };
  const supabase = await createClient();
  const { error } = exists ? await supabase.from("shift_cancellations").update(row).eq("shift_id", shiftId) : await supabase.from("shift_cancellations").insert({ ...row, shift_id: shiftId });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/roster/timesheets");
  return { message: "Cancellation details saved." };
}

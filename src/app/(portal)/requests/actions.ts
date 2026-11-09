// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireRole, requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { DAYS, SHIFTS } from "@/lib/profiles-shared";

const DATE = /^\d{4}-\d{2}-\d{2}$/;
// "22 Dec" for titles (Australian date order).
const short = (iso: string | null) => (iso ? new Date(`${iso}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

// cmeprojects: send a request. Each type has its own fields; the database
// checks the type is switched on and works out who approves it.
export async function submitRequest(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const str = (k: string) => String(form.get(k) ?? "").trim();
  const type = str("type");
  const date = (k: string) => (DATE.test(str(k)) ? str(k) : null);
  const details: Record<string, unknown> = {};
  let subject = str("subject");
  let start: string | null = null;
  let end: string | null = null;
  let swapWith: string | null = null;
  switch (type) {
    case "leave":
      details.leave_type = str("leave_type") || "annual";
      details.part_day = form.get("part_day") === "on";
      details.reason = str("reason");
      start = date("start_date");
      end = date("end_date") ?? start;
      if (!start) return { error: "Choose the first day of leave." };
      subject ||= `${str("leave_label") || "Leave"} ${short(start)}${end && end !== start ? ` to ${short(end)}` : ""}`;
      break;
    case "swap":
      details.my_shift = str("my_shift");
      details.reason = str("reason");
      start = date("start_date");
      swapWith = /^[0-9a-f-]{36}$/.test(str("swap_with")) ? str("swap_with") : null;
      if (!start || !details.my_shift) return { error: "Say which shift (date and times)." };
      if (!swapWith) return { error: "Choose who you're swapping with." };
      subject ||= `Shift swap ${short(start)}`;
      break;
    case "shift":
      details.current_shift = str("current_shift");
      details.new_shift = str("new_shift");
      details.reason = str("reason");
      start = date("start_date");
      if (!start || !details.current_shift || !details.new_shift) return { error: "Fill in the date, your current shift and what you'd like instead." };
      subject ||= `Shift change ${short(start)}`;
      break;
    case "availability":
      details.availability = Object.fromEntries(DAYS.map(([d]) => [d, SHIFTS.map(([s]) => s).filter((s) => form.get(`avail_${d}_${s}`) === "on")]));
      details.reason = str("reason");
      start = date("start_date");
      if (!start) return { error: "Choose the date it starts from." };
      subject ||= `New availability from ${short(start)}`;
      break;
    case "timesheet":
      details.date = date("work_date");
      details.wrong = str("wrong");
      details.correct = str("correct");
      if (!details.date || !details.correct) return { error: "Fill in the date and the correct times." };
      subject ||= `Timesheet ${short(details.date as string)}`;
      break;
    case "hr":
    case "other":
      details.message = str("message");
      if (!subject) return { error: "Give it a short subject." };
      if (!details.message) return { error: "Write the details." };
      break;
    default:
      return { error: "Choose a request type." };
  }
  const { data: id, error } = await (await createClient()).rpc("submit_request", {
    p_type: type,
    p_subject: subject,
    p_details: details,
    p_start: start,
    p_end: end,
    p_swap_with: swapWith,
  });
  if (error || !id) return { error: friendlyError(error, "That request didn't send. Please try again.") };
  revalidatePath("/requests");
  redirect(`/requests/${id}?sent=1`);
}

// Approve, decline, ask for info, comment, withdraw, or answer a swap.
export async function actOnRequest(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = String(form.get("request_id") ?? "");
  const action = String(form.get("action") ?? "");
  if (!/^[0-9a-f-]{36}$/.test(id)) return { error: "That request doesn't exist." };
  const { data, error } = await (await createClient()).rpc("request_action", { p_request: id, p_action: action, p_comment: String(form.get("comment") ?? "") });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/requests/${id}`);
  revalidatePath("/requests");
  return { message: String(data ?? "Done.") };
}

// System admin: who approves each request type.
export async function saveRequestType(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(["system_admin"]);
  const key = String(form.get("key") ?? "");
  const list = (name: string) => [...form.getAll(`${name}_roles`).map(String), ...form.getAll(`${name}_people`).map((p) => `user:${p}`)].filter((x) => /^(team_leader|staff_admin|manager|user:[0-9a-f-]{36})$/.test(x));
  const days = Number(form.get("escalate_days") ?? 3);
  const first = list("first");
  if (!first.length) return { error: "Choose at least one first approver." };
  const { error } = await (await createClient())
    .from("request_types")
    .update({ first_approvers: first, second_approvers: list("second"), notify: list("notify"), escalate_days: Number.isFinite(days) ? Math.max(0, Math.min(60, Math.round(days))) : 3, escalate_to: list("escalate") })
    .eq("key", key);
  if (error) return { error: friendlyError(error) };
  revalidatePath("/settings/requests");
  return { message: "Saved." };
}

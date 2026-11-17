// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { sydneyInstant } from "@/lib/sydney-time";

// cmeprojects (update 122): rostering. The database checks who may
// (Rostering, change), refuses leave and double-booking, and never deletes.
async function requireRoster() {
  await requireSession();
  if (!(await canDo("ops.roster", "edit"))) throw new Error("You can't change the roster.");
}
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const sydney = (date: string, time: string) => (/^\d{4}-\d{2}-\d{2}$/.test(date) && /^\d{2}:\d{2}$/.test(time) ? sydneyInstant(date, time) : null);
// Tell workers straight away (the same server-only job the hourly timer runs).
async function tellWorkers() {
  const { error } = await createAdminClient().rpc("run_roster_alerts");
  if (error && error.code !== "PGRST202") console.error("roster alerts", error.message);
}

export async function saveShift(_: FormState, form: FormData): Promise<FormState> {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const date = String(form.get("date") ?? "");
  const start = sydney(date, String(form.get("start") ?? ""));
  let end = sydney(date, String(form.get("end") ?? ""));
  if (!start || !end) return { error: "Choose the date, start and finish." };
  // Finishing after midnight: the next day.
  if (end <= start) end = new Date(new Date(end).getTime() + 86_400_000).toISOString();
  const worker = String(form.get("worker_id") ?? "");
  const client = String(form.get("client_id") ?? "");
  const location = String(form.get("location_id") ?? "");
  const service = String(form.get("service_id") ?? "");
  const status = String(form.get("status") ?? "draft");
  const values = {
    worker_id: isId(worker) ? worker : null,
    client_id: isId(client) ? client : null,
    location_id: isId(client) && isId(location) ? location : null,
    service_id: isId(client) && isId(service) ? service : null,
    starts_at: start,
    ends_at: end,
    break_minutes: Math.max(0, Math.min(240, Number(form.get("break_minutes") ?? 0) || 0)),
    notes: String(form.get("notes") ?? "").trim().slice(0, 500),
    status: ["draft", "published"].includes(status) ? status : "draft",
  };
  const supabase = await createClient();
  const { error } = id && isId(id) ? await supabase.from("shifts").update(values).eq("id", id) : await supabase.from("shifts").insert(values);
  if (error) return { error: friendlyError(error) };
  if (values.status === "published") await tellWorkers();
  revalidatePath("/roster");
  return { message: id ? "Shift saved." : "Shift added." };
}

export async function cancelShift(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shifts").update({ status: "cancelled" }).eq("id", id);
  revalidatePath("/roster");
}

export async function giveOpenShift(form: FormData) {
  await requireRoster();
  const id = String(form.get("id") ?? "");
  const worker = String(form.get("worker_id") ?? "");
  if (!isId(id) || !isId(worker)) return;
  const { error } = await (await createClient()).from("shifts").update({ worker_id: worker }).eq("id", id).is("worker_id", null);
  if (!error) await tellWorkers();
  revalidatePath("/roster");
}

// Publish every draft in the week shown.
export async function publishWeek(form: FormData) {
  await requireRoster();
  const from = String(form.get("from") ?? "");
  const to = String(form.get("to") ?? "");
  if (!from || !to) return;
  await (await createClient()).from("shifts").update({ status: "published" }).eq("status", "draft").gte("starts_at", from).lt("starts_at", to);
  await tellWorkers();
  revalidatePath("/roster");
}

// Copy last week's shifts into this week as drafts (anything that would clash
// or fall on leave is skipped; the database refuses it).
export async function copyLastWeek(_: FormState, form: FormData): Promise<FormState> {
  await requireRoster();
  const from = String(form.get("from") ?? "");
  if (!from) return { error: "Choose a week." };
  const supabase = await createClient();
  const prevFrom = new Date(new Date(from).getTime() - 7 * 86_400_000).toISOString();
  const { data } = await supabase.from("shifts").select("worker_id, starts_at, ends_at, break_minutes, client_id, service_id, location_id, notes").neq("status", "cancelled").gte("starts_at", prevFrom).lt("starts_at", from);
  let added = 0;
  let skipped = 0;
  for (const s of (data ?? []) as { worker_id: string | null; starts_at: string; ends_at: string; break_minutes: number; client_id: string | null; service_id: string | null; location_id: string | null; notes: string }[]) {
    const week = 7 * 86_400_000;
    const { error } = await supabase.from("shifts").insert({ ...s, starts_at: new Date(new Date(s.starts_at).getTime() + week).toISOString(), ends_at: new Date(new Date(s.ends_at).getTime() + week).toISOString(), status: "draft" });
    if (error) skipped++;
    else added++;
  }
  revalidatePath("/roster");
  return { message: `${added} shift${added === 1 ? "" : "s"} copied as drafts${skipped ? `; ${skipped} skipped (leave, a clash or someone no longer active)` : ""}.` };
}

// Staff: put your hand up for an open shift.
export async function putHandUp(form: FormData) {
  await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return;
  await (await createClient()).from("shift_interest").insert({ shift_id: id });
  revalidatePath("/my-shifts");
}

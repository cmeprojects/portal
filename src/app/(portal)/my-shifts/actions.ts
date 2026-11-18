// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { after } from "next/server";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { saveTimesheet } from "../roster/actions";

const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);

// cmeprojects (update 128): the worker accepts or declines a published shift.
// The database checks it's their shift, published and not finished.
export async function answerShift(form: FormData) {
  const { profile } = await requireSession();
  const id = String(form.get("id") ?? "");
  const response = form.get("response") === "declined" ? "declined" : "accepted";
  if (!isId(id)) return;
  await (await createClient())
    .from("shift_responses")
    .upsert({ shift_id: id, worker_id: profile.id, response, note: String(form.get("note") ?? "").trim().slice(0, 500) }, { onConflict: "shift_id" });
  // A decline reaches the people who roster straight away (the server-only reminder run).
  if (response === "declined") await createAdminClient().rpc("run_roster_alerts");
  revalidatePath("/my-shifts");
}

// cmeprojects (update 128): a signature on a shift (worker clock in/out, client, representative).
export async function addSignature(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const shiftId = String(form.get("shift_id") ?? "");
  const kind = String(form.get("kind") ?? "");
  const signature = String(form.get("signature") ?? "");
  const name = String(form.get("signer_name") ?? "").trim().slice(0, 100);
  if (!isId(shiftId) || !["worker_in", "worker_out", "client", "representative"].includes(kind)) return { error: "That didn't save. Please reload the page." };
  if (!signature.startsWith("data:image/png;base64,")) return { error: "Sign in the box first." };
  if (signature.length > 200_000) return { error: "That signature is too large. Clear it and sign again." };
  if (!name) return { error: "Type the name of the person signing." };
  const { error } = await (await createClient()).from("shift_signatures").insert({
    shift_id: shiftId,
    kind,
    signer_name: name,
    signer_role: String(form.get("signer_role") ?? "").trim().slice(0, 60),
    signature,
  });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/my-shifts");
  return { message: "Signature saved." };
}

// cmeprojects (update 134): the worker's service record for a shift. A concern is passed on straight away.
export async function saveServiceRecord(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const shiftId = String(form.get("shift_id") ?? "");
  const delivered = String(form.get("delivered") ?? "").trim().slice(0, 4000);
  const wellbeing = String(form.get("client_wellbeing") ?? "settled");
  const concern = form.get("concern") === "on";
  const concernNote = String(form.get("concern_note") ?? "").trim().slice(0, 2000);
  if (!isId(shiftId)) return { error: "That didn't save. Please reload the page." };
  if (!delivered) return { error: "Write what you did on this shift." };
  if (concern && !concernNote) return { error: "Say what the concern is." };
  const row = { delivered, client_wellbeing: ["settled", "some_concerns", "unwell_or_distressed"].includes(wellbeing) ? wellbeing : "settled", concern, concern_note: concernNote };
  const supabase = await createClient();
  const { data: had } = await supabase.from("shift_service_records").select("shift_id").eq("shift_id", shiftId).maybeSingle();
  const { error } = had
    ? await supabase.from("shift_service_records").update(row).eq("shift_id", shiftId)
    : await supabase.from("shift_service_records").insert({ shift_id: shiftId, worker_id: profile.id, ...row });
  if (error) return { error: friendlyError(error) };
  if (concern) after(() => createAdminClient().rpc("run_service_record_alerts"));
  revalidatePath("/my-shifts");
  return { message: concern ? "Saved. The case manager has been told about the concern." : "Saved." };
}

// cmeprojects: finish a shift: times (timesheet) and shift notes (service record) together.
export async function endShift(_: FormState, form: FormData): Promise<FormState> {
  const times = await saveTimesheet(null, form);
  if (times?.error) return times;
  const notes = await saveServiceRecord(null, form);
  if (notes?.error) return { error: `Your times are saved, but not the notes: ${notes.error}` };
  return { message: form.get("concern") === "on" ? "Shift finished. The managers and case manager have been told about the incident or issue." : "Shift finished. Thank you." };
}

// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

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

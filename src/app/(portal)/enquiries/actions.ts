// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { text } from "@/lib/form";
import { STAGES } from "./stages";

// Whoever the system admin chose moves an enquiry along and leaves a note
// (the database checks who that is).
export async function updateEnquiry(form: FormData) {
  await requireSession();
  const status = text(form, "status");
  if (!STAGES.some((s) => s.key === status)) return;
  await (await createClient())
    .from("website_enquiries")
    .update({ status, note: text(form, "note").slice(0, 1000) })
    .eq("id", text(form, "id"));
  revalidatePath("/enquiries");
}

// A follow-up task for the person following it up (General tasks, due today).
export async function enquiryTask(form: FormData) {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const id = text(form, "id");
  const [{ data: e }, { data: general }] = await Promise.all([
    supabase.from("website_enquiries").select("*").eq("id", id).maybeSingle(),
    supabase.from("registries").select("id").eq("is_default", true).maybeSingle(),
  ]);
  if (!e || !general) return;
  const lines = [
    `Phone: ${e.phone}`,
    e.email && `Email: ${e.email}`,
    e.suburb && `Suburb: ${e.suburb}`,
    e.support_for && `Support is for: ${e.support_for}`,
    (e.has_plan || e.managed_by) && `NDIS plan: ${[e.has_plan, e.managed_by].filter(Boolean).join(", ")}`,
    e.needs?.length && `Looking for: ${e.needs.join(", ")}`,
    e.best_time && `Best time to call: ${e.best_time}`,
    e.asked && `They asked the assistant: ${e.asked}`,
    e.message && `Message: ${e.message}`,
  ].filter(Boolean);
  const today = new Intl.DateTimeFormat("en-CA", { timeZone: "Australia/Sydney" }).format(new Date());
  const { error } = await supabase.rpc("create_task", {
    p_title: `Call back: ${e.full_name}`.slice(0, 200),
    p_registry_id: general.id,
    p_assigned_to: profile.id,
    p_description: `New enquiry from the website.\n\n${lines.join("\n")}`,
    p_priority: "high",
    p_due_date: today,
  });
  if (!error) {
    const note = [e.note, "Follow-up task made."].filter(Boolean).join(" ");
    await supabase.from("website_enquiries").update({ note: note.slice(0, 1000) }).eq("id", id);
  }
  revalidatePath("/enquiries");
  revalidatePath("/my-tasks");
}

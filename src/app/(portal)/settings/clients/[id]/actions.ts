// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireRole, PEOPLE_MANAGERS } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { SECTION_FIELDS, type SectionTable } from "@/lib/client-sections";

const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);

// cmeprojects (Clients & Care steps 2 to 5): saves one item in a client's
// profile (a location, their details, a person, an alert or a service). Only
// the fields listed for that section are accepted; the database checks the
// rest (who may save, approvals, readiness) and logs the change.
export async function saveClientSection(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const table = String(form.get("table") ?? "") as SectionTable;
  const fields = SECTION_FIELDS[table];
  const clientId = String(form.get("client_id") ?? "");
  const id = String(form.get("id") ?? "");
  if (!fields || !isId(clientId) || (id && !isId(id))) return { error: "That didn't save. Please reload the page." };

  const values: Record<string, unknown> = {};
  let notes: string | null = null;
  for (const f of fields) {
    const raw = String(form.get(f.name) ?? "").trim();
    if (f.name === "notes") {
      notes = raw.slice(0, f.max ?? 5000);
      continue;
    }
    if (f.type === "checkbox") values[f.name] = form.get(f.name) === "on";
    else if (f.type === "date") values[f.name] = /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : null;
    else if (f.type === "select" && f.options) values[f.name] = f.options.some(([k]) => k === raw) ? raw : f.options[0][0];
    else if (f.type === "select") values[f.name] = isId(raw) ? raw : null;
    else values[f.name] = raw.slice(0, f.max ?? 200);
    if (f.required && !values[f.name]) return { error: `Fill in ${f.label.toLowerCase()}.` };
  }

  const supabase = await createClient();
  let error;
  let savedId = id;
  if (table === "client_details") {
    ({ error } = await supabase.from("client_details").upsert({ client_id: clientId, ...values }, { onConflict: "client_id" }));
  } else if (id) {
    ({ error } = await supabase.from(table).update(values).eq("id", id).eq("client_id", clientId));
  } else {
    const res = await supabase.from(table).insert({ client_id: clientId, ...values }).select("id").single();
    error = res.error;
    savedId = (res.data?.id as string) ?? "";
  }
  if (!error && table === "client_alerts" && savedId && notes !== null) {
    ({ error } = await supabase.from("client_alert_notes").upsert({ alert_id: savedId, client_id: clientId, details: notes }, { onConflict: "alert_id" }));
  }
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: id || table === "client_details" ? "Saved." : "Added." };
}

// "No known safety alerts": answers the safety step when there's nothing to record.
export async function recordNoAlerts(_: FormState, form: FormData): Promise<FormState> {
  await requireRole(PEOPLE_MANAGERS);
  const clientId = String(form.get("client_id") ?? "");
  if (!isId(clientId)) return { error: "Choose a client." };
  const supabase = await createClient();
  const { error } = await supabase
    .from("client_alerts")
    .insert({ client_id: clientId, kind: "no_known_alerts", severity: "low", title: "No known safety alerts", worker_instructions: "" });
  if (error) return { error: friendlyError(error) };
  revalidatePath(`/settings/clients/${clientId}`);
  return { message: "Recorded: no known safety alerts." };
}

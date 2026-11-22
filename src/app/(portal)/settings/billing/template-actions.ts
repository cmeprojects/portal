// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 168): save a document template as a new version (the database refuses anyone
// without the Billing prices or approve right, and checks the values).
export async function saveTemplate(kind: string, s: { layout: string; logo_position: string; colour_source: string; primary: string; accent: string; sections: Record<string, boolean>; header_note: string; footer_text: string; payment_note: string; note: string }): Promise<FormState> {
  await requireSession();
  if (!["invoice", "statement", "receipt", "credit_note"].includes(kind)) return { error: "Choose the document." };
  const hex = (v: string) => (/^#[0-9A-Fa-f]{6}$/.test(v) ? v : undefined);
  const settings = {
    layout: s.layout === "compact" ? "compact" : "full",
    logo_position: ["left", "centre", "right", "none"].includes(s.logo_position) ? s.logo_position : "left",
    colour_source: s.colour_source === "custom" ? "custom" : "theme",
    ...(s.colour_source === "custom" ? { primary: hex(s.primary) ?? "#134F8E", accent: hex(s.accent) ?? "#6497C8" } : {}),
    sections: Object.fromEntries(Object.entries(s.sections ?? {}).filter(([k]) => /^[a-z_]{1,40}$/.test(k)).map(([k, v]) => [k, !!v])),
    header_note: String(s.header_note ?? "").slice(0, 300), footer_text: String(s.footer_text ?? "").slice(0, 300), payment_note: String(s.payment_note ?? "").slice(0, 500),
  };
  const { error } = await (await createClient()).from("document_templates").insert({ kind, settings, note: String(s.note ?? "").slice(0, 300) });
  if (error) return { error: friendlyError(error) };
  revalidatePath("/settings/billing");
  return { message: "Saved as a new template version. Documents issued from now on use it; issued ones never change." };
}

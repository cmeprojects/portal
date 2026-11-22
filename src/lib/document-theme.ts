// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";
import { rgb } from "pdf-lib";
import { env } from "@/lib/env";
import { logoForPdf } from "@/lib/contract-pdf";
import { PLAIN_THEME, hexRgb, type DocTheme } from "@/lib/billing-pdf";

// cmeprojects (update 168): the template for a document kind (its latest version), with the
// portal's logo and theme colours, ready for the PDF. Before update 168 runs: the portal theme
// with the full layout.
export type DocKind = "invoice" | "statement" | "receipt" | "credit_note";
export async function loadDocTheme(supabase: SupabaseClient, kind: DocKind): Promise<{ theme: DocTheme; templateId: string | null }> {
  const [{ data: tpl }, { data: brand }] = await Promise.all([
    supabase.from("document_templates").select("id, settings").eq("kind", kind).order("version", { ascending: false }).limit(1).maybeSingle(),
    supabase.from("app_settings").select("key, value").in("key", ["brand.logo_url", "brand.color_primary", "brand.color_accent"]),
  ]);
  const get = (k: string) => { const v = ((brand ?? []) as { key: string; value: unknown }[]).find((b) => b.key === k)?.value; return typeof v === "string" ? v : ""; };
  const s = ((tpl as { settings?: Record<string, unknown> } | null)?.settings ?? {}) as Record<string, unknown>;
  const custom = s.colour_source === "custom";
  const logoPosition = (["left", "centre", "right", "none"].includes(String(s.logo_position)) ? s.logo_position : "left") as DocTheme["logoPosition"];
  const logoUrl = get("brand.logo_url");
  const logo = logoPosition !== "none" && logoUrl ? await logoForPdf(logoUrl, env.siteUrl) : null;
  return {
    templateId: (tpl as { id?: string } | null)?.id ?? null,
    theme: {
      ...PLAIN_THEME,
      primary: hexRgb(custom ? String(s.primary ?? "") : get("brand.color_primary"), rgb(0.32, 0.36, 0.4)),
      accent: hexRgb(custom ? String(s.accent ?? "") : get("brand.color_accent"), rgb(0.93, 0.94, 0.95)),
      logo, logoPosition,
      layout: s.layout === "compact" ? "compact" : "full",
      sections: (typeof s.sections === "object" && s.sections ? s.sections : {}) as Record<string, boolean>,
      headerNote: String(s.header_note ?? ""), footerText: String(s.footer_text ?? ""), paymentNote: String(s.payment_note ?? ""),
    },
  };
}

// Records which template version an issued document used (once; never changed).
export async function recordDocIssue(supabase: SupabaseClient, kind: DocKind, documentId: string, templateId: string | null, checksum: string) {
  await supabase.from("document_issues").insert({ kind, document_id: documentId, template_id: templateId, checksum });
}

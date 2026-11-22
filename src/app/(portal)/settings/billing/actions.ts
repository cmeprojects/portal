// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";

// cmeprojects (update 161): billing set-up. The database decides who may
// (Billing "prices" for prices and holidays, "approve" for rules), checks every
// value, and keeps published versions fixed; these shape the request.
const isId = (v: unknown): v is string => typeof v === "string" && /^[0-9a-f-]{36}$/.test(v);
const ymd = (v: unknown) => (/^\d{4}-\d{2}-\d{2}$/.test(String(v ?? "")) ? String(v) : null);
const clip = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);
const done = (listId?: string) => {
  revalidatePath("/settings/billing");
  revalidatePath("/settings");
  if (listId) revalidatePath(`/settings/billing/prices/${listId}`);
};

export async function saveSchemeRules(scheme: string, v: { confirmed: boolean; summary: string; source: string; asAt: string }): Promise<FormState> {
  await requireSession();
  const { data, error } = await (await createClient())
    .from("billing_scheme_rules")
    .update({ status: v.confirmed ? "confirmed" : "not_confirmed", rules_summary: clip(v.summary, 4000), source: clip(v.source, 1000), as_at: ymd(v.asAt) })
    .eq("scheme", scheme)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change billing rules." };
  done();
  return { message: v.confirmed ? "Rules confirmed. Billing for this scheme can be switched on in Phase 4B." : "Saved as not confirmed. Billing stays off for this scheme." };
}

export async function saveRuleCheck(id: string, v: { verified: boolean; value: string; source: string; asAt: string }): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient())
    .from("billing_rule_checks")
    .update({ status: v.verified ? "verified" : "unverified", value: clip(v.value, 1000), source: clip(v.source, 1000), as_at: ymd(v.asAt) })
    .eq("id", id)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change this check." };
  done();
  return { message: v.verified ? "Marked verified." : "Saved." };
}

export async function addPriceList(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const scheme = clip(form.get("scheme"), 40);
  const name = clip(form.get("name"), 120);
  if (!scheme) return { error: "Choose the scheme." };
  if (!name) return { error: "Give the price list a name." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("price_lists").insert({ scheme, name, description: clip(form.get("description"), 1000) }).select("id").single();
  if (error || !data) return { error: friendlyError(error) };
  const { error: vErr } = await supabase.from("price_list_versions").insert({ price_list_id: data.id });
  if (vErr) return { error: friendlyError(vErr) };
  done();
  redirect(`/settings/billing/prices/${data.id}`);
}

export async function saveVersion(id: string, listId: string, v: { effective_from: string; unit_minutes: string; rounding: string; minimum_minutes: string; crossing: string; notes: string }): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const unit = Number(v.unit_minutes);
  const min = Number(v.minimum_minutes || 0);
  if (!Number.isInteger(unit) || unit < 1 || unit > 60) return { error: "Units are 1 to 60 minutes." };
  if (!Number.isInteger(min) || min < 0 || min > 480) return { error: "The minimum is 0 to 480 minutes." };
  const { data, error } = await (await createClient())
    .from("price_list_versions")
    .update({ effective_from: ymd(v.effective_from), unit_minutes: unit, rounding: v.rounding, minimum_minutes: min, crossing: v.crossing, notes: clip(v.notes, 2000) })
    .eq("id", id)
    .select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a draft version can be changed." };
  done(listId);
  return { message: "Saved." };
}

export async function publishVersion(id: string, listId: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("price_list_versions").update({ status: "published" }).eq("id", id).eq("status", "draft").select("version");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a draft can be published." };
  done(listId);
  return { message: "Published. It never changes now; the previous version is retired and kept." };
}

export async function newVersion(listId: string): Promise<FormState> {
  await requireSession();
  if (!isId(listId)) return { error: "Something went wrong." };
  const { error } = await (await createClient()).rpc("price_list_new_version", { p_list: listId });
  if (error) return { error: friendlyError(error) };
  done(listId);
  return { message: "New draft version made from the latest one." };
}

export async function saveBand(versionId: string, listId: string, v: { key: string; label: string; day_kind: string; starts_at: string; ends_at: string }): Promise<FormState> {
  await requireSession();
  if (!isId(versionId)) return { error: "Something went wrong." };
  const key = v.key.trim().toLowerCase().replace(/[^a-z0-9_]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 40);
  if (!/^[a-z]/.test(key)) return { error: "Give the band a short code starting with a letter, e.g. weekday_day." };
  if (!v.label.trim()) return { error: "Give the band a name." };
  const weekday = v.day_kind === "weekday";
  if (weekday && (!/^\d{2}:\d{2}$/.test(v.starts_at) || !/^\d{2}:\d{2}$/.test(v.ends_at))) return { error: "Give the weekday band's start and end times." };
  const { error } = await (await createClient())
    .from("price_list_bands")
    .insert({ version_id: versionId, key, label: clip(v.label, 80), day_kind: v.day_kind, starts_at: weekday ? v.starts_at : null, ends_at: weekday ? v.ends_at : null });
  if (error) return { error: error.code === "23505" ? "That code is already used in this version." : friendlyError(error) };
  done(listId);
  return { message: "Band added." };
}

export async function saveItem(versionId: string, listId: string, v: Record<string, string>): Promise<FormState> {
  await requireSession();
  if (!isId(versionId)) return { error: "Something went wrong." };
  const price = Number(v.price);
  if (!v.label?.trim()) return { error: "Name the price." };
  if (!Number.isFinite(price) || price < 0 || price > 100000) return { error: "The price is an amount from $0 to $100,000." };
  const { error } = await (await createClient()).from("price_items").insert({
    version_id: versionId,
    label: clip(v.label, 160),
    catalogue_id: isId(v.catalogue_id) ? v.catalogue_id : null,
    unit: v.unit || "hour",
    band_key: v.band_key || null,
    price: Math.round(price * 100) / 100,
    gst_code: v.gst_code || "gst_free",
    sah_category: v.sah_category || null,
    personal_care: v.personal_care === "true",
    ndis_item: clip(v.ndis_item, 40),
  });
  if (error) return { error: error.code === "23505" ? "There's already a price for that service and band." : friendlyError(error) };
  done(listId);
  return { message: "Price added." };
}

export async function removePart(kind: "band" | "item", id: string, listId: string): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from(kind === "band" ? "price_list_bands" : "price_items").delete().eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only a draft version can be changed." };
  done(listId);
  return { message: "Removed." };
}

export async function addHoliday(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const state = clip(form.get("state"), 3);
  const onDate = ymd(form.get("on_date"));
  const name = clip(form.get("name"), 120);
  if (!state) return { error: "Choose the state." };
  if (!onDate) return { error: "Give the date." };
  if (!name) return { error: "Name the holiday." };
  const { error } = await (await createClient()).from("public_holidays").insert({ state, on_date: onDate, name });
  if (error) return { error: error.code === "23505" ? "That state already has a holiday on that date." : friendlyError(error) };
  done();
  return { message: "Holiday added." };
}

export async function setHolidayActive(id: string, active: boolean): Promise<FormState> {
  await requireSession();
  if (!isId(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("public_holidays").update({ active }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't change public holidays." };
  done();
  return { message: active ? "Switched on." : "Switched off." };
}

// cmeprojects (update 167): the price grid. One row per catalogue service (or client service not in
// the catalogue, priced by name) and a price per rate band; new prices are added, changed ones
// updated, all in the draft version (published versions never change).
type GridRow = { catalogue_id: string; label: string; unit: string; gst_code: string; sah_category: string; ndis_item: string; prices: Record<string, string>; ids: Record<string, string> };
export async function savePriceGrid(versionId: string, listId: string, rows: GridRow[]): Promise<FormState> {
  await requireSession();
  if (!isId(versionId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data: list } = await supabase.from("price_lists").select("scheme").eq("id", listId).maybeSingle();
  // Client services decide how a catalogue service's price must be saved for billing to find it:
  // linked to the catalogue (client services linked to it) and/or by name (same-named client
  // services not linked yet). Until every client service is linked, both can be needed.
  const { data: svc } = await supabase.from("client_services").select("label, catalogue_id, client_programs!inner(scheme)").neq("status", "ended").eq("client_programs.scheme", list?.scheme ?? "");
  const svcs = (svc ?? []) as { label: string; catalogue_id: string | null }[];
  const { data: existing } = await supabase.from("price_items").select("id, catalogue_id, label, band_key").eq("version_id", versionId);
  const ex = (existing ?? []) as { id: string; catalogue_id: string | null; label: string; band_key: string | null }[];
  let added = 0, changed = 0;
  for (const r of (Array.isArray(rows) ? rows : []).slice(0, 500)) {
    const catId = isId(r.catalogue_id) ? r.catalogue_id : null;
    const name = clip(r.label, 160);
    const byName = !catId || svcs.some((v) => !v.catalogue_id && v.label.trim().toLowerCase() === name.toLowerCase());
    const linked = !!catId && (svcs.some((v) => v.catalogue_id === catId) || !byName);
    for (const [band, raw] of Object.entries(r.prices ?? {})) {
      const txt = String(raw ?? "").trim();
      const bandKey = band === "_any" ? null : band;
      const mineLinked = catId ? ex.find((i) => i.catalogue_id === catId && (i.band_key ?? null) === bandKey) : undefined;
      const mineName = ex.find((i) => !i.catalogue_id && i.label.toLowerCase() === name.toLowerCase() && (i.band_key ?? null) === bandKey);
      if (!txt) continue;
      const price = Number(txt.replace(/[$,\s]/g, ""));
      if (!Number.isFinite(price) || price < 0 || price > 100000) return { error: `Check the price for ${name}: an amount from $0 to $100,000.` };
      const values = { price: Math.round(price * 100) / 100, unit: ["hour", "visit", "each", "km", "day"].includes(r.unit) ? r.unit : "hour", gst_code: ["gst_free", "taxable", "input_taxed"].includes(r.gst_code) ? r.gst_code : "gst_free",
        sah_category: ["clinical", "independence", "everyday_living"].includes(r.sah_category) ? r.sah_category : null, ndis_item: clip(r.ndis_item, 40) };
      const targets: { id?: string; catalogue_id: string | null }[] = [];
      if (linked || mineLinked) targets.push({ id: mineLinked?.id, catalogue_id: catId });
      if (byName || mineName) targets.push({ id: mineName?.id, catalogue_id: null });
      for (const t of targets) {
        const { error } = t.id
          ? await supabase.from("price_items").update(values).eq("id", t.id)
          : await supabase.from("price_items").insert({ ...values, version_id: versionId, catalogue_id: t.catalogue_id, label: name, band_key: bandKey });
        if (error) return { error: `${added} added, ${changed} changed, then ${name}: ${friendlyError(error)}` };
        if (t.id) changed++; else added++;
      }
    }
  }
  done(listId);
  return { message: `${added} price(s) added, ${changed} updated.` };
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { BandForm, ItemForm, RemovePart, VersionButtons, VersionSettings, type Version } from "../../forms";

export const metadata: Metadata = { title: "Price list" };

const DAY: Record<string, string> = { weekday: "Weekday", saturday: "Saturday", sunday: "Sunday", public_holiday: "Public holiday" };
const GST: Record<string, string> = { gst_free: "GST-free", taxable: "Taxable", input_taxed: "Input-taxed" };
const CAT: Record<string, string> = { clinical: "Clinical", independence: "Independence", everyday_living: "Everyday living" };
const aud = (n: number) => Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" });

// cmeprojects (update 161): one price list. The draft version is edited;
// published and retired versions are shown as they are (they never change).
export default async function PriceListPage({ params, searchParams }: PageProps<"/settings/billing/prices/[id]">) {
  await requireSession();
  if (!(await canDo("clients.billing", "view"))) notFound();
  const { id } = await params;
  const sp = await searchParams;
  const supabase = await createClient();
  const [{ data: list }, { data: verRows }, { data: catRows }, { data: schemeRows }, canPrices] = await Promise.all([
    supabase.from("price_lists").select("id, scheme, name, description").eq("id", id).maybeSingle(),
    supabase.from("price_list_versions").select("id, version, status, effective_from, unit_minutes, rounding, minimum_minutes, crossing, notes, published_by, published_at").eq("price_list_id", id).order("version", { ascending: false }),
    supabase.from("service_catalogue").select("id, name").eq("active", true).order("name"),
    supabase.from("client_schemes").select("key, label"),
    canDo("clients.billing", "prices"),
  ]);
  if (!list) notFound();
  const versions = (verRows ?? []) as (Version & { published_by: string | null; published_at: string | null })[];
  const wanted = typeof sp.v === "string" ? versions.find((v) => String(v.version) === sp.v) : undefined;
  const shown = wanted ?? versions.find((v) => v.status === "draft") ?? versions.find((v) => v.status === "published") ?? versions[0];
  const prev = shown ? versions.find((v) => v.version === shown.version - 1) : undefined;
  const ids = [shown?.id, prev?.id].filter(Boolean) as string[];
  const [{ data: bandRows }, { data: itemRows }] = ids.length
    ? await Promise.all([
        supabase.from("price_list_bands").select("id, version_id, key, label, day_kind, starts_at, ends_at").in("version_id", ids).order("day_kind").order("starts_at"),
        supabase.from("price_items").select("id, version_id, catalogue_id, label, unit, band_key, price, gst_code, sah_category, personal_care, ndis_item").in("version_id", ids).order("label"),
      ])
    : [{ data: [] }, { data: [] }];
  type Band = { id: string; version_id: string; key: string; label: string; day_kind: string; starts_at: string | null; ends_at: string | null };
  type Item = { id: string; version_id: string; catalogue_id: string | null; label: string; unit: string; band_key: string | null; price: number; gst_code: string; sah_category: string | null; personal_care: boolean; ndis_item: string };
  const bands = ((bandRows ?? []) as Band[]).filter((b) => b.version_id === shown?.id);
  const items = ((itemRows ?? []) as Item[]).filter((i) => i.version_id === shown?.id);
  const editable = !!shown && shown.status === "draft" && canPrices;
  const schemeLabel = ((schemeRows ?? []) as { key: string; label: string }[]).find((s) => s.key === list.scheme)?.label ?? list.scheme;
  const bandName = new Map(bands.map((b) => [b.key, b.label]));
  // What changed from the version before (prices by service and band).
  const keyOf = (i: Item) => `${i.catalogue_id ?? i.label}|${i.band_key ?? ""}`;
  const before = new Map(((itemRows ?? []) as Item[]).filter((i) => i.version_id === prev?.id).map((i) => [keyOf(i), i]));
  const changes: string[] = [];
  if (prev && shown) {
    for (const i of items) {
      const p = before.get(keyOf(i));
      if (!p) changes.push(`Added: ${i.label}${i.band_key ? ` (${bandName.get(i.band_key) ?? i.band_key})` : ""} ${aud(i.price)}`);
      else if (Number(p.price) !== Number(i.price) || p.gst_code !== i.gst_code || p.sah_category !== i.sah_category || p.unit !== i.unit) changes.push(`Changed: ${i.label}${i.band_key ? ` (${bandName.get(i.band_key) ?? i.band_key})` : ""} ${aud(p.price)} → ${aud(i.price)}`);
      before.delete(keyOf(i));
    }
    for (const p of before.values()) changes.push(`Removed: ${p.label} ${aud(p.price)}`);
    const pb = ((bandRows ?? []) as Band[]).filter((b) => b.version_id === prev.id);
    const sig = (b: Band) => `${b.key}|${b.day_kind}|${b.starts_at}|${b.ends_at}`;
    if (pb.map(sig).sort().join() !== bands.map(sig).sort().join()) changes.push("Rate bands changed");
    if (prev.rounding !== shown.rounding || prev.unit_minutes !== shown.unit_minutes || prev.minimum_minutes !== shown.minimum_minutes || prev.crossing !== shown.crossing) changes.push("Rounding, unit, minimum or band-crossing rule changed");
  }
  const t = (x: string | null) => (x ? x.slice(0, 5) : "");
  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow={`Billing set-up · ${schemeLabel}`} title={list.name} intro={list.description || undefined} action={<Link href="/settings/billing" className="text-sm font-semibold text-brand underline">Billing set-up</Link>} />
      <Card className="flex flex-col gap-3 p-4">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="heading-sm flex-1">Versions</h2>
          {canPrices ? <VersionButtons listId={list.id} draftId={versions.find((v) => v.status === "draft")?.id ?? null} canNew={!versions.some((v) => v.status === "draft")} /> : null}
        </div>
        <nav aria-label="Versions" className="flex flex-wrap gap-1.5">
          {versions.map((v) => (
            <Link key={v.id} href={`/settings/billing/prices/${list.id}?v=${v.version}`} aria-current={shown?.id === v.id ? "page" : undefined}
              className={`rounded-full px-3 py-1 text-xs font-semibold ring-1 ${shown?.id === v.id ? "bg-brand text-brand-fg ring-brand" : "bg-surface text-muted ring-line hover:text-ink"}`}>
              v{v.version} · {v.status === "draft" ? "Draft" : v.status === "published" ? `In use from ${v.effective_from?.split("-").reverse().join("/")}` : `Retired (from ${v.effective_from?.split("-").reverse().join("/")})`}
            </Link>
          ))}
        </nav>
        {prev && shown ? (
          <div className="rounded-md border border-line p-3 text-sm">
            <h3 className="font-semibold">What changed from v{prev.version} to v{shown.version}</h3>
            {changes.length ? <ul className="list-disc pl-5">{changes.map((c, i) => <li key={i}>{c}</li>)}</ul> : <p className="text-muted">No changes.</p>}
          </div>
        ) : null}
      </Card>
      {shown ? (
        <>
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="heading-sm">Units, rounding and start date</h2>
            <VersionSettings key={shown.id} v={shown} listId={list.id} editable={editable} />
          </Card>
          <Card className="flex flex-col gap-3 p-4">
            <div>
              <h2 className="heading-sm">Rate bands</h2>
              <p className="text-sm text-muted">This price list&apos;s own time bands (separate from payroll). Weekday bands cover the whole day once; Saturday, Sunday and public holiday are whole days.</p>
            </div>
            {bands.length ? (
              <ul className="divide-y divide-line rounded-md border border-line text-sm">
                {bands.map((b) => (
                  <li key={b.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                    <span className="min-w-32 flex-1 font-semibold">{b.label}</span>
                    <span className="text-xs text-muted">{DAY[b.day_kind]}{b.day_kind === "weekday" ? ` ${t(b.starts_at)}–${t(b.ends_at) === "00:00" ? "midnight" : t(b.ends_at)}` : ", all day"} · code {b.key}</span>
                    {editable ? <RemovePart kind="band" id={b.id} listId={list.id} label={b.label} /> : null}
                  </li>
                ))}
              </ul>
            ) : <p className="text-sm text-muted">No bands yet.</p>}
            {editable ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Add a band</summary><div className="mt-2"><BandForm versionId={shown.id} listId={list.id} /></div></details> : null}
          </Card>
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="heading-sm">Prices</h2>
            {items.length ? (
              <div className="overflow-x-auto">
                <table className="w-full min-w-[36rem] text-left text-sm">
                  <thead className="text-xs text-muted"><tr><th className="py-1 pr-2">Service</th><th className="py-1 pr-2">Band</th><th className="py-1 pr-2 text-right">Price</th><th className="py-1 pr-2">GST</th><th className="py-1 pr-2">{list.scheme === "support_at_home" ? "Category" : list.scheme === "ndis" ? "Item" : ""}</th>{editable ? <th><span className="sr-only">Remove</span></th> : null}</tr></thead>
                  <tbody className="divide-y divide-line">
                    {items.map((i) => (
                      <tr key={i.id}>
                        <td className="py-1 pr-2">{i.label}</td>
                        <td className="py-1 pr-2 text-xs">{i.band_key ? bandName.get(i.band_key) ?? i.band_key : "Any time"}</td>
                        <td className="py-1 pr-2 text-right font-semibold">{aud(i.price)} <span className="text-xs font-normal text-muted">/{i.unit}</span></td>
                        <td className="py-1 pr-2 text-xs">{GST[i.gst_code]}</td>
                        <td className="py-1 pr-2 text-xs">{list.scheme === "support_at_home" ? `${CAT[i.sah_category ?? ""] ?? "Not set"}${i.personal_care ? " · personal care" : ""}` : i.ndis_item}</td>
                        {editable ? <td className="py-1 text-right"><RemovePart kind="item" id={i.id} listId={list.id} label={i.label} /></td> : null}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : <p className="text-sm text-muted">No prices yet.</p>}
            {editable ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Add a price</summary><div className="mt-2"><ItemForm versionId={shown.id} listId={list.id} bands={bands.map((b) => [b.key, b.label])} catalogue={((catRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name])} scheme={list.scheme} /></div></details> : null}
          </Card>
        </>
      ) : null}
    </div>
  );
}

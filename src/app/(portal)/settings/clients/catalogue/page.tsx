// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { seesClientsFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader } from "@/components/ui";
import { mayManageCatalogue } from "./actions";
import { CatalogueForm, CodePrefixForm, type CatalogueRow } from "./forms";

export const metadata: Metadata = { title: "Service catalogue" };

// cmeprojects (update 143): the services clients can be approved for, each a
// separate entry with its description, programs and the shift types it
// covers. Manager Administrators manage it; services are switched off, never
// deleted, and clients keep the services they already have.
export default async function ServiceCataloguePage() {
  await requireSession();
  if (!(await seesClientsFor())) notFound();
  const supabase = await createClient();
  const [{ data, error }, manage, { data: schemeRows }, { data: typeRows }, { data: used }] = await Promise.all([
    supabase.from("service_catalogue").select("*").order("active", { ascending: false }).order("sort_order").order("name"),
    mayManageCatalogue(),
    supabase.from("client_schemes").select("key, label").order("sort_order"),
    supabase.from("shift_types").select("*").eq("active", true).order("sort_order"),
    supabase.from("client_services").select("catalogue_id").not("catalogue_id", "is", null).neq("status", "ended"),
  ]);
  // cmeprojects (update 167): codes, the prefix, what's billed (code locked) and what isn't priced yet.
  const [{ data: prefixRow }, { data: unpriced }, { data: billedRows }] = await Promise.all([
    supabase.from("app_settings").select("value").eq("key", "billing.service_code_prefix").maybeSingle(),
    supabase.from("services_not_priced").select("service_id, price_list").eq("kind", "catalogue"),
    supabase.from("price_items").select("catalogue_id, billing_lines(id)").not("catalogue_id", "is", null).limit(5000),
  ]);
  const notPriced = new Map<string, string[]>();
  for (const u of (unpriced ?? []) as { service_id: string; price_list: string }[]) notPriced.set(u.service_id, [...(notPriced.get(u.service_id) ?? []), u.price_list]);
  const billed = new Set(((billedRows ?? []) as { catalogue_id: string; billing_lines: unknown[] | null }[]).filter((r) => (r.billing_lines ?? []).length).map((r) => r.catalogue_id));
  const items = ((data ?? []) as CatalogueRow[]).map((c) => ({ ...c, billed: billed.has(c.id) }));
  const schemes = ((schemeRows ?? []) as { key: string; label: string }[]).map((s) => [s.key, s.label] as [string, string]);
  const types = ((typeRows ?? []) as { key: string; label: string; used_for?: string }[]).filter((t) => t.used_for !== "internal").map((t) => [t.key, t.label] as [string, string]);
  const typeName = new Map(types);
  const count = new Map<string, number>();
  for (const r of (used ?? []) as { catalogue_id: string }[]) count.set(r.catalogue_id, (count.get(r.catalogue_id) ?? 0) + 1);
  return (
    <div className="flex flex-col gap-5">
      <PageHeader eyebrow="Clients" title="Service catalogue" intro="The services a client can be approved for. Each is a separate entry. Rostering offers only the shift types a client's services cover." action={<Link href="/settings/clients" className="text-sm font-semibold text-brand underline">Back to clients</Link>} />
      {error ? <Notice tone="info">The service catalogue arrives with update 143.</Notice> : null}
      {!manage ? <Notice tone="info">Only Manager Administrators can change the catalogue.</Notice> : null}
      {manage && !error && prefixRow ? (
        <Card className="flex flex-col gap-2 p-4">
          <CodePrefixForm prefix={String((prefixRow as { value: unknown }).value ?? "SERV")} />
          <p className="text-xs text-muted">Each service has a code, shown on statements, invoices and reports. New services get the next code automatically; a code can be changed until the service is first billed.</p>
        </Card>
      ) : null}
      {manage && !error ? (
        <Card className="p-4">
          <details>
            <summary className="cursor-pointer text-sm font-semibold text-brand">+ Add a service to the catalogue</summary>
            <div className="mt-3">
              <CatalogueForm schemes={schemes} shiftTypes={types} />
            </div>
          </details>
        </Card>
      ) : null}
      <div className="flex flex-col gap-2">
        {items.map((c) => (
          <Card key={c.id} className={`p-4 ${c.active ? "" : "opacity-70"}`}>
            <div className="flex flex-wrap items-start gap-2">
              <div className="min-w-48 flex-1">
                <p className="font-semibold">
                  {c.code ? <span className="mr-2 rounded bg-brand-soft px-1.5 py-0.5 font-mono text-xs">{c.code}</span> : null}
                  {c.name}
                  {c.active ? null : <span className="ml-2 rounded-full bg-line px-2 py-0.5 text-[11px] font-semibold text-muted">Switched off</span>}
                </p>
                <p className="text-sm text-muted">{c.description || "No description yet."}</p>
                <p className="mt-1 text-xs text-muted">
                  Covers {c.shift_types.map((k) => typeName.get(k) ?? k).join(", ") || "no shift types"} · {c.schemes.length ? `offered under ${c.schemes.map((k) => schemes.find(([s]) => s === k)?.[1] ?? k).join(", ")}` : "every program"}
                  {c.classification ? ` · ${c.classification}` : ""} · {count.get(c.id) ?? 0} client service{count.get(c.id) === 1 ? "" : "s"}
                  {c.sah_service_type ? ` · Support at Home type: ${c.sah_service_type}` : ""}
                </p>
                {c.active && notPriced.get(c.id)?.length ? <p className="mt-1 text-xs font-semibold text-warn">Not priced yet in: {notPriced.get(c.id)!.join(", ")} (Billing set-up)</p> : null}
              </div>
            </div>
            {manage ? (
              <details className="mt-2">
                <summary className="cursor-pointer text-sm font-semibold text-brand">Edit</summary>
                <div className="mt-3">
                  <CatalogueForm item={c} schemes={schemes} shiftTypes={types} />
                </div>
              </details>
            ) : null}
          </Card>
        ))}
      </div>
    </div>
  );
}

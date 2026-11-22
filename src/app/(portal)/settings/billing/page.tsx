// Staff Portal · © cmeproject. All rights reserved.
import { canBill } from "@/lib/billing-access";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { HolidayForm, HolidayToggle, NewPriceListForm, SchemeRuleCard, type SchemeRule } from "./forms";
import { FigureRow } from "../../billing/forms";
import { BusinessForm, CatalogueImport, CatalogueRow, ReviewRow, TemplateRow, TemplateUpload } from "./compliance-forms";
import { businessForForm } from "@/lib/business";
import { MarkupRuleForm } from "../../billing/supplier-forms";
import { TemplateForm, type TemplateSettings } from "./template-forms";

export const metadata: Metadata = { title: "Billing set-up" };

// cmeprojects (update 161): billing set-up. Each scheme's rules (off until
// confirmed, with verified figures), price lists with versions, and public
// holidays by state. Nothing is billed from here.
export default async function BillingSetupPage() {
  await requireSession();
  if (!(await canBill("view"))) notFound();
  const supabase = await createClient();
  const [rulesRes, checksRes, schemesRes, listsRes, versRes, holRes, figRes, canPrices, canApprove] = await Promise.all([
    supabase.from("billing_scheme_rules").select("scheme, status, rules_summary, source, as_at, confirmed_by, confirmed_at"),
    supabase.from("billing_rule_checks").select("id, scheme, item, value, source, as_at, status, checked_by, checked_at").order("created_at"),
    supabase.from("client_schemes").select("key, label").order("sort_order"),
    supabase.from("price_lists").select("id, scheme, name, description, active").order("name"),
    supabase.from("price_list_versions").select("id, price_list_id, version, status, effective_from"),
    supabase.from("public_holidays").select("id, state, on_date, name, active").order("on_date", { ascending: false }).limit(200),
    supabase.from("billing_parameters").select("id, key, value, effective_from, status, source, as_at, verified_by, verified_at").order("key").order("effective_from"),
    canBill("prices"),
    canBill("approve"),
  ]);
  if (rulesRes.error) return <Card className="p-5 text-sm text-muted">Billing set-up isn&apos;t in place yet (update 161).</Card>;
  const schemes = ((schemesRes.data ?? []) as { key: string; label: string }[]).map((s) => [s.key, s.label] as [string, string]);
  const label = (k: string) => schemes.find(([x]) => x === k)?.[1] ?? k;
  const people = [...new Set([...(rulesRes.data ?? []).map((r) => r.confirmed_by), ...(checksRes.data ?? []).map((c) => c.checked_by), ...(figRes.data ?? []).map((f) => f.verified_by)].filter(Boolean))] as string[];
  const { data: names } = people.length ? await supabase.from("profiles").select("id, full_name, email").in("id", people) : { data: [] };
  const who = (id: string | null) => ((names ?? []) as { id: string; full_name: string | null; email: string }[]).find((p) => p.id === id)?.full_name ?? "someone";
  const day = (t: string | null) => (t ? new Date(t).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric" }) : "");
  const rules: SchemeRule[] = schemes.map(([key, l]) => {
    const r = (rulesRes.data ?? []).find((x) => x.scheme === key);
    return {
      scheme: key, label: l, status: r?.status ?? "not_confirmed", rules_summary: r?.rules_summary ?? "", source: r?.source ?? "", as_at: r?.as_at ?? null,
      confirmed: r?.confirmed_by ? `Confirmed by ${who(r.confirmed_by)} ${day(r.confirmed_at)}` : "",
      checks: (checksRes.data ?? []).filter((c) => c.scheme === key).map((c) => ({ id: c.id, item: c.item, value: c.value, source: c.source, as_at: c.as_at, status: c.status, checked: c.checked_by ? `checked by ${who(c.checked_by)} ${day(c.checked_at)}` : "" })),
    };
  });
  const lists = (listsRes.data ?? []) as { id: string; scheme: string; name: string; description: string; active: boolean }[];
  const vers = (versRes.data ?? []) as { id: string; price_list_id: string; version: number; status: string; effective_from: string | null }[];
  const holidays = (holRes.data ?? []) as { id: string; state: string; on_date: string; name: string; active: boolean }[];
  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Portal settings" title="Billing set-up" intro="Each scheme's billing rules with their official sources and review dates, business details, official claim templates, the NDIS Support Catalogue, price lists and public holidays. Billing for a scheme stays off until its rules are confirmed. Nothing is billed from this page." />
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Scheme billing rules</h2>
          <p className="text-sm text-muted">Write each scheme&apos;s rules down with their source. Regulatory figures are verified one by one with the official source and an &quot;as at&quot; date. {canApprove ? "" : "Only people with the Billing approve right can confirm them."}</p>
        </div>
        {rules.map((r) => <SchemeRuleCard key={r.scheme} rule={r} canApprove={canApprove} />)}
      </Card>
      {figRes.data?.length ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Support at Home figures used in calculations</h2>
            <p className="text-sm text-muted">Quarter budgets (care management, carryover and lapse) only use figures verified with their official source and &quot;as at&quot; date. {canApprove ? "" : "Only people with the Billing approve right verify them."}</p>
          </div>
          {(figRes.data ?? []).map((f) => (
            <FigureRow key={f.id} canApprove={canApprove}
              f={{ id: f.id, value: f.value, effective_from: f.effective_from, status: f.status, source: f.source, as_at: f.as_at, checked: f.verified_by ? `by ${who(f.verified_by)} ${day(f.verified_at)}` : "",
                   label: f.key === "sah_care_management_pct" ? "Care management (% of the quarterly budget)" : f.key === "sah_rollover_floor" ? "Rollover floor (AUD)" : "Rollover cap (% of the quarterly budget)" }} />
          ))}
        </Card>
      ) : null}
      <ComplianceSections />
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Price lists</h2>
          <p className="text-sm text-muted">Your prices for each scheme, with their own rate bands and rounding. A published version never changes: changes go into a new version with a later start date. These are provider prices, not funding.</p>
        </div>
        {lists.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {lists.map((l) => {
              const pub = vers.find((v) => v.price_list_id === l.id && v.status === "published");
              const draft = vers.find((v) => v.price_list_id === l.id && v.status === "draft");
              return (
                <li key={l.id} className="flex flex-wrap items-center gap-2 px-3 py-2">
                  <Link href={`/settings/billing/prices/${l.id}`} className="min-w-40 flex-1 font-semibold text-brand underline">{l.name}</Link>
                  <span className="text-xs text-muted">{label(l.scheme)}</span>
                  <span className="text-xs">{pub ? `v${pub.version} in use from ${pub.effective_from?.split("-").reverse().join("/")}` : "Not published yet"}{draft ? ` · draft v${draft.version}` : ""}</span>
                </li>
              );
            })}
          </ul>
        ) : <p className="text-sm text-muted">No price lists yet.</p>}
        {canPrices ? (
          <details className="rounded-md border border-dashed border-line px-3 py-2">
            <summary className="cursor-pointer text-xs font-semibold text-brand">Add a price list</summary>
            <div className="mt-2"><NewPriceListForm schemes={schemes} /></div>
          </details>
        ) : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Public holidays by state</h2>
          <p className="text-sm text-muted">Billing uses the holidays of the state where the service happens (the service location). Holidays are switched off, never deleted.</p>
        </div>
        {holidays.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {holidays.map((h) => (
              <li key={h.id} className={`flex flex-wrap items-center gap-2 px-3 py-1.5 ${h.active ? "" : "text-muted line-through"}`}>
                <span className="w-12 font-semibold">{h.state}</span>
                <span className="w-28">{h.on_date.split("-").reverse().join("/")}</span>
                <span className="min-w-32 flex-1">{h.name}</span>
                {canPrices ? <HolidayToggle id={h.id} active={h.active} /> : null}
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No public holidays yet.</p>}
        {canPrices ? (
          <details className="rounded-md border border-dashed border-line px-3 py-2">
            <summary className="cursor-pointer text-xs font-semibold text-brand">Add a public holiday</summary>
            <div className="mt-2"><HolidayForm /></div>
          </details>
        ) : null}
      </Card>
    </div>
  );
}

// cmeprojects (update 163): business details, the compliance register (official link,
// document version, effective and review dates), claim templates and the NDIS catalogue.
async function ComplianceSections() {
  const supabase = await createClient();
  const [bizRes, checksRes, figRes, tplRes, catRes, canPrices, canApprove, isAdmin] = await Promise.all([
    supabase.from("business_current").select("*").maybeSingle(),
    supabase.from("billing_rule_checks").select("id, scheme, item, status, official_url, document_version, effective_from, review_by").order("scheme").order("created_at"),
    supabase.from("billing_parameters").select("id, key, effective_from, status, official_url, document_version, review_by").order("key"),
    supabase.from("claim_templates").select("id, program, name, version, status, headers, mapping, date_format, file_name_max, official_url, document_version, review_by, verified_by, verified_at").order("program").order("version", { ascending: false }),
    supabase.from("ndis_catalogue_versions").select("id, name, document_version, effective_from, effective_to, review_by, item_count, status, official_url, verified_by, verified_at").order("effective_from", { ascending: false }),
    canBill("prices"), canBill("approve"),
    supabase.rpc("is_system_admin").then((r) => r.data === true),
  ]);
  if (tplRes.error) return null;
  const b = bizRes.data as { version: number; created_at: string; gst_verified: boolean; gst_verified_on: string | null } | null;
  const initial = businessForForm(bizRes.data as Record<string, unknown> | null);
  const people = [...new Set([...(tplRes.data ?? []).map((t) => t.verified_by), ...(catRes.data ?? []).map((c) => c.verified_by)].filter(Boolean))] as string[];
  const { data: names } = people.length ? await supabase.from("profiles").select("id, full_name, email").in("id", people) : { data: [] };
  const who = (id: string | null) => ((names ?? []) as { id: string; full_name: string | null }[]).find((p) => p.id === id)?.full_name ?? "someone";
  const day = (t: string | null) => (t ? new Date(t).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric" }) : "");
  const SCHEME: Record<string, string> = { support_at_home: "Support at Home", ndis: "NDIS", chsp: "CHSP", private: "Private", other: "Other" };
  const FIG: Record<string, string> = { sah_care_management_pct: "Care management %", sah_rollover_floor: "Rollover floor", sah_rollover_pct: "Rollover cap %" };
  return (
    <>
      <Card id="business" className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Business details</h2>
          <p className="text-sm text-muted">Shown on invoices and statements and used in claim files. Each save is a new version; issued documents keep the version they were issued with.{b ? ` Current: version ${b.version}, saved ${day(b.created_at)}. GST position ${b.gst_verified ? `verified ${b.gst_verified_on?.split("-").reverse().join("/")}` : "not verified yet"}.` : " Not entered yet."}</p>
        </div>
        <BusinessForm initial={initial} canEdit={canApprove || isAdmin} />
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Compliance register: official sources and review dates</h2>
          <p className="text-sm text-muted">For every rule and figure: the official link, the document version, when it takes effect and when to review it. Claims and invoices need all of these; past a review date, claims, invoices and line approval pause for that scheme. Government rules change: review them when new versions are published.</p>
        </div>
        <ul className="divide-y divide-line rounded-md border border-line">
          {(checksRes.data ?? []).map((c) => <ReviewRow key={c.id} kind="check" canEdit={canApprove} r={{ id: c.id, label: `${SCHEME[c.scheme] ?? c.scheme}: ${c.item}`, status: c.status, official_url: c.official_url, document_version: c.document_version, effective_from: c.effective_from, review_by: c.review_by }} />)}
          {(figRes.data ?? []).map((f) => <ReviewRow key={f.id} kind="figure" canEdit={canApprove} r={{ id: f.id, label: `Support at Home figure: ${FIG[f.key] ?? f.key} (from ${f.effective_from.split("-").reverse().join("/")})`, status: f.status, official_url: f.official_url, document_version: f.document_version, effective_from: null, review_by: f.review_by }} />)}
        </ul>
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Official claim templates</h2>
          <p className="text-sm text-muted">Upload the official file (the NDIS Bulk Upload template from the provider portal; Services Australia&apos;s claim format) saved as CSV. Its header row is kept exactly. The owner&apos;s nominee checks each column and verifies it; no claim file is made until then. Claims are always uploaded by a person.</p>
        </div>
        {(tplRes.data ?? []).length ? (
          <ul className="divide-y divide-line rounded-md border border-line">
            {(tplRes.data ?? []).map((t) => <TemplateRow key={t.id} canPrices={canPrices} canApprove={canApprove} t={{ ...t, headers: t.headers as string[], mapping: (t.mapping ?? {}) as Record<string, string>, verified: t.verified_by ? `by ${who(t.verified_by)} ${day(t.verified_at)}` : "" }} />)}
          </ul>
        ) : <p className="text-sm text-muted">No templates yet.</p>}
        {canPrices ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Upload an official template</summary><div className="mt-2"><TemplateUpload /></div></details> : null}
      </Card>
      <MarkupRules canPrices={canPrices} />
      <NotPriced />
      <DocumentTemplates canEdit={canPrices || canApprove} />
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">NDIS Support Catalogue</h2>
          <p className="text-sm text-muted">Import each release of the official Support Catalogue (saved as CSV). Prices on NDIS lines are checked against the verified catalogue in force on the support date, for the pricing zone of the service delivery location.</p>
        </div>
        {(catRes.data ?? []).length ? (
          <ul className="divide-y divide-line rounded-md border border-line">
            {(catRes.data ?? []).map((v) => <CatalogueRow key={v.id} canPrices={canPrices} canApprove={canApprove} v={{ ...v, verified: v.verified_by ? `by ${who(v.verified_by)} ${day(v.verified_at)}` : "" }} />)}
          </ul>
        ) : <p className="text-sm text-muted">No catalogue imported yet.</p>}
        {canPrices ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Import a catalogue release</summary><div className="mt-2"><CatalogueImport /></div></details> : null}
      </Card>
    </>
  );
}

// cmeprojects (update 165): markup rules for third-party charges (the provider's own pricing policy).
async function MarkupRules({ canPrices }: { canPrices: boolean }) {
  const { data, error } = await (await createClient()).from("billing_markup_rules").select("id, funding_stream, markup_pct, max_markup, effective_from, note").order("funding_stream").order("effective_from", { ascending: false });
  if (error) return null;
  const L: Record<string, string> = { all: "All streams", ongoing: "Support at Home quarterly", at_hm: "AT-HM", restorative: "Restorative Care", end_of_life: "End-of-Life", hcp_unspent: "Unspent HCP funds", ndis_plan: "NDIS", private: "Private" };
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div>
        <h2 className="heading-sm">Markup on third-party costs</h2>
        <p className="text-sm text-muted">The markup added to supplier costs when they&apos;re charged to a client, by funding stream, from a date. Rules never change (add a new one). NDIS charges are still checked against the price limit; Support at Home pricing of third-party services is a rule for the nominee to verify.</p>
      </div>
      {(data ?? []).length ? (
        <ul className="divide-y divide-line rounded-md border border-line text-sm">
          {((data ?? []) as { id: string; funding_stream: string; markup_pct: number; max_markup: number | null; effective_from: string; note: string }[]).map((r) => (
            <li key={r.id} className="flex flex-wrap gap-2 px-3 py-1.5"><span className="min-w-48 flex-1 font-semibold">{L[r.funding_stream]}</span><span>{Number(r.markup_pct)}%{r.max_markup !== null ? `, at most $${Number(r.max_markup).toFixed(2)}` : ""}</span><span className="text-xs text-muted">from {r.effective_from.split("-").reverse().join("/")}{r.note ? ` · ${r.note}` : ""}</span></li>
          ))}
        </ul>
      ) : <p className="text-sm text-muted">No markup rules yet (charges from supplier costs then have no markup unless a reason is given).</p>}
      {canPrices ? <MarkupRuleForm /> : null}
    </Card>
  );
}

// cmeprojects (update 167): services that have no price yet in an active price list.
async function NotPriced() {
  const { data, error } = await (await createClient()).from("services_not_priced").select("price_list_id, price_list, version, status, kind, code, service").order("price_list").order("service");
  if (error) return null;
  const rows = (data ?? []) as { price_list_id: string; price_list: string; version: number; status: string; kind: string; code: string | null; service: string }[];
  const lists = [...new Set(rows.map((r) => r.price_list_id))];
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div>
        <h2 className="heading-sm">Not priced yet</h2>
        <p className="text-sm text-muted">Catalogue services offered under a price list&apos;s scheme with no price in its latest version, and client services not in the catalogue with no price of their name. Lines for them can&apos;t be billed until they&apos;re priced.</p>
      </div>
      {lists.length ? lists.map((id) => {
        const mine = rows.filter((r) => r.price_list_id === id);
        return (
          <div key={id} className="text-sm">
            <Link href={`/settings/billing/prices/${id}`} className="font-semibold text-brand underline">{mine[0].price_list}</Link> <span className="text-xs text-muted">(version {mine[0].version}, {mine[0].status})</span>
            <p className="text-xs">{mine.map((r) => `${r.code ? `${r.code} ` : ""}${r.service}${r.kind === "client_service" ? " (client service, not in the catalogue)" : ""}`).join(" · ")}</p>
          </div>
        );
      }) : <p className="text-sm text-muted">Every service is priced.</p>}
    </Card>
  );
}

// cmeprojects (update 168): document templates (invoice, statement, receipt, credit note).
async function DocumentTemplates({ canEdit }: { canEdit: boolean }) {
  const supabase = await createClient();
  const [{ data, error }, { data: brand }] = await Promise.all([
    supabase.from("document_templates").select("kind, version, settings").order("version", { ascending: false }),
    supabase.from("app_settings").select("key, value").in("key", ["brand.color_primary", "brand.color_accent"]),
  ]);
  if (error) return null;
  const get = (k: string) => String(((brand ?? []) as { key: string; value: unknown }[]).find((b) => b.key === k)?.value ?? "");
  const theme = { primary: get("brand.color_primary") || "#134F8E", accent: get("brand.color_accent") || "#6497C8" };
  const KINDS: [string, string][] = [["statement", "Monthly statement"], ["invoice", "Invoice"], ["receipt", "Receipt"], ["credit_note", "Credit note"]];
  return (
    <Card className="flex flex-col gap-3 p-4">
      <div>
        <h2 className="heading-sm">Document templates</h2>
        <p className="text-sm text-muted">How statements, invoices, receipts and credit notes look: the portal&apos;s logo and colours (or your own), the layout, which sections show, and your header, footer and payment text. Each save is a new version; issued documents keep the version they were made with.</p>
      </div>
      {KINDS.map(([k, l]) => {
        const row = ((data ?? []) as { kind: string; version: number; settings: Record<string, unknown> }[]).find((r) => r.kind === k);
        const st = (row?.settings ?? {}) as Record<string, unknown>;
        const initial: TemplateSettings = { layout: String(st.layout ?? "full"), logo_position: String(st.logo_position ?? "left"), colour_source: String(st.colour_source ?? "theme"), primary: String(st.primary ?? ""), accent: String(st.accent ?? ""),
          sections: (st.sections ?? {}) as Record<string, boolean>, header_note: String(st.header_note ?? ""), footer_text: String(st.footer_text ?? ""), payment_note: String(st.payment_note ?? "") };
        return (
          <details key={k} className="rounded-md border border-line px-3 py-2">
            <summary className="cursor-pointer text-sm font-semibold text-brand">{l} <span className="text-xs font-normal text-muted">version {row?.version ?? 1}</span></summary>
            <div className="mt-2"><TemplateForm kind={k} initial={initial} version={row?.version ?? 1} theme={theme} canEdit={canEdit} /></div>
          </details>
        );
      })}
    </Card>
  );
}

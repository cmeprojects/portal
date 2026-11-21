// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { HolidayForm, HolidayToggle, NewPriceListForm, SchemeRuleCard, type SchemeRule } from "./forms";

export const metadata: Metadata = { title: "Billing set-up" };

// cmeprojects (update 161): billing set-up. Each scheme's rules (off until
// confirmed, with verified figures), price lists with versions, and public
// holidays by state. Nothing is billed from here.
export default async function BillingSetupPage() {
  await requireSession();
  if (!(await canDo("clients.billing", "view"))) notFound();
  const supabase = await createClient();
  const [rulesRes, checksRes, schemesRes, listsRes, versRes, holRes, canPrices, canApprove] = await Promise.all([
    supabase.from("billing_scheme_rules").select("scheme, status, rules_summary, source, as_at, confirmed_by, confirmed_at"),
    supabase.from("billing_rule_checks").select("id, scheme, item, value, source, as_at, status, checked_by, checked_at").order("created_at"),
    supabase.from("client_schemes").select("key, label").order("sort_order"),
    supabase.from("price_lists").select("id, scheme, name, description, active").order("name"),
    supabase.from("price_list_versions").select("id, price_list_id, version, status, effective_from"),
    supabase.from("public_holidays").select("id, state, on_date, name, active").order("on_date", { ascending: false }).limit(200),
    canDo("clients.billing", "prices"),
    canDo("clients.billing", "approve"),
  ]);
  if (rulesRes.error) return <Card className="p-5 text-sm text-muted">Billing set-up isn&apos;t in place yet (update 161).</Card>;
  const schemes = ((schemesRes.data ?? []) as { key: string; label: string }[]).map((s) => [s.key, s.label] as [string, string]);
  const label = (k: string) => schemes.find(([x]) => x === k)?.[1] ?? k;
  const people = [...new Set([...(rulesRes.data ?? []).map((r) => r.confirmed_by), ...(checksRes.data ?? []).map((c) => c.checked_by)].filter(Boolean))] as string[];
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
      <PageHeader eyebrow="Portal settings" title="Billing set-up" intro="Each scheme's billing rules, price lists and public holidays. Billing for a scheme stays off until its rules are confirmed. Nothing is billed from this page." />
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Scheme billing rules</h2>
          <p className="text-sm text-muted">Write each scheme&apos;s rules down with their source. Regulatory figures are verified one by one with the official source and an &quot;as at&quot; date. {canApprove ? "" : "Only people with the Billing approve right can confirm them."}</p>
        </div>
        {rules.map((r) => <SchemeRuleCard key={r.scheme} rule={r} canApprove={canApprove} />)}
      </Card>
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

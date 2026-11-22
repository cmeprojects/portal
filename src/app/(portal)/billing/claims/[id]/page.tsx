// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { ClaimActions, RemoveItem } from "../../claim-forms";
import { CLAIM_STATUS } from "../../claims-tabs";

export const metadata: Metadata = { title: "Claim" };

// cmeprojects (update 163): one claim. Its lines, the lines left out (with the
// reason), approval by someone other than the preparer, the file built from the
// verified official template, and the manual submission record. Nothing here
// sends anything to a government portal.
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const when = (t: string | null | undefined) => (t ? new Date(t).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" }) : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));

export default async function ClaimPage({ params }: PageProps<"/billing/claims/[id]">) {
  const { profile } = await requireSession();
  if (!(await canBill("view"))) notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: c } = await supabase.from("claims").select("*").eq("id", id).maybeSingle();
  if (!c) notFound();
  const [{ data: items }, { data: sub }, { data: tpl }, canApprove, canPrepare, canSubmit] = await Promise.all([
    supabase.from("claim_items").select("id, line_id, quarter_budget_id, client_id, claimed_value, expected_amount, status").eq("claim_id", id).order("created_at"),
    supabase.from("claim_submissions").select("*").eq("claim_id", id).maybeSingle(),
    c.template_id ? supabase.from("claim_templates").select("name, version, document_version, official_url").eq("id", c.template_id).maybeSingle() : Promise.resolve({ data: null }),
    canBill("claim_approve"), canBill("claim_prepare"), canBill("claim_submit"),
  ]);
  type I = { id: string; line_id: string | null; quarter_budget_id: string | null; client_id: string; claimed_value: number; expected_amount: number; status: string };
  const its = (items ?? []) as I[];
  const excluded = (c.excluded ?? []) as { line: string; reason: string }[];
  const lineIds = [...new Set([...its.map((i) => i.line_id), ...excluded.map((e) => e.line)].filter(Boolean))] as string[];
  const { data: lines } = lineIds.length ? await supabase.from("billing_lines").select("id, client_id, service_date, band_label, quantity, unit, amount").in("id", lineIds) : { data: [] };
  const L = new Map(((lines ?? []) as { id: string; client_id: string; service_date: string; band_label: string; quantity: number; unit: string; amount: number }[]).map((l) => [l.id, l]));
  const cIds = [...new Set([...its.map((i) => i.client_id), ...[...L.values()].map((l) => l.client_id)])];
  const people = [c.prepared_by, c.approved_by, c.file_generated_by, c.cancelled_by, sub?.submitted_by].filter(Boolean) as string[];
  const [{ data: cRows }, { data: pRows }] = await Promise.all([
    cIds.length ? supabase.from("car_clients").select("id, name").in("id", cIds) : Promise.resolve({ data: [] }),
    people.length ? supabase.from("profiles").select("id, full_name, email").in("id", people) : Promise.resolve({ data: [] }),
  ]);
  const cName = new Map(((cRows ?? []) as { id: string; name: string }[]).map((x) => [x.id, x.name]));
  const who = (pid: string | null) => ((pRows ?? []) as { id: string; full_name: string | null; email: string }[]).find((p) => p.id === pid)?.full_name ?? "someone";
  const t = tpl as { name: string; version: number; document_version: string; official_url: string } | null;
  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Billing · Claim" title={`${c.program === "ndis" ? "NDIS" : "Support at Home"} claim, ${dmy(c.period_from)} to ${dmy(c.period_to)}`}
        intro={`${CLAIM_STATUS[c.status] ?? c.status}. Claimed ${aud(c.total_claimed)} (full service value); expected from the payer ${aud(c.total_expected)}.`}
        action={<Link href="/billing?tab=claims" className={buttonClass("outline")}>All claims</Link>} />
      <Card className="flex flex-col gap-2 p-4 text-sm">
        <p>Prepared by {who(c.prepared_by)} {when(c.prepared_at)}{c.approved_by ? ` · approved by ${who(c.approved_by)} ${when(c.approved_at)}` : ""}{c.file_generated_by ? ` · file made by ${who(c.file_generated_by)} ${when(c.file_generated_at)}` : ""}</p>
        {t ? <p className="text-xs text-muted">Template: {t.name} (version {t.version}, official document {t.document_version}){t.official_url ? <> · <a href={t.official_url} target="_blank" rel="noreferrer" className="text-brand underline">official source</a></> : null}</p> : null}
        {c.file_checksum ? <p className="text-xs text-muted">File {c.file_name} · SHA-256 {c.file_checksum.slice(0, 16)}…</p> : null}
        {sub ? <p className="rounded-md bg-success-soft px-3 py-2">Submitted {when(sub.submitted_at)} by {who(sub.submitted_by)} via {sub.channel === "aged_care_provider_portal" ? "the Aged Care Provider Portal" : sub.channel === "ndis_provider_portal" ? "the my NDIS provider portal" : "another channel"}, reference <span className="font-semibold">{sub.external_reference}</span>{sub.acknowledged_at ? `. Acknowledged ${when(sub.acknowledged_at)}: ${sub.acknowledgement}` : ". Awaiting acknowledgement."}</p> : null}
        {c.status === "cancelled" ? <p className="rounded-md bg-danger-soft px-3 py-2">Cancelled by {who(c.cancelled_by)} {when(c.cancelled_at)}: {c.cancel_reason}</p> : null}
        <ClaimActions id={id} status={c.status} hasFile={!!c.file_content} canApprove={canApprove} canCancel={canPrepare || canApprove} canSubmit={canSubmit} mine={c.prepared_by === profile.id}
          channel={c.program === "ndis" ? "ndis_provider_portal" : "aged_care_provider_portal"} />
      </Card>
      <Card className="flex flex-col gap-2 p-4">
        <h2 className="heading-sm">Lines in this claim</h2>
        {its.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[640px] text-sm">
              <thead className="text-left text-xs text-muted"><tr><th className="py-1">Client</th><th>Date</th><th>Service</th><th className="text-right">Claimed</th><th className="text-right">Expected</th><th></th></tr></thead>
              <tbody className="divide-y divide-line">
                {its.map((i) => {
                  const l = i.line_id ? L.get(i.line_id) : undefined;
                  return (
                    <tr key={i.id} className={i.status === "removed" ? "text-muted line-through" : ""}>
                      <td className="py-1.5">{cName.get(i.client_id) ?? "Client"}</td>
                      <td>{l ? dmy(l.service_date) : "Quarter"}</td>
                      <td>{l ? `${l.band_label} · ${Number(l.quantity)} ${l.unit}` : "Care management (clinical, no contribution)"}</td>
                      <td className="text-right">{aud(i.claimed_value)}</td>
                      <td className="text-right">{aud(i.expected_amount)}</td>
                      <td>{c.status === "draft" && i.status === "live" && canPrepare ? <RemoveItem id={i.id} parent={id} kind="claim" /> : null}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No lines.</p>}
      </Card>
      {excluded.length ? (
        <Card className="flex flex-col gap-2 p-4">
          <h2 className="heading-sm">Left out of this claim ({excluded.length})</h2>
          <p className="text-sm text-muted">Fix the cause, then prepare another claim for the same period: these lines are picked up then.</p>
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {excluded.map((e) => {
              const l = L.get(e.line);
              return <li key={e.line} className="px-3 py-1.5"><span className="font-semibold">{l ? `${cName.get(l.client_id) ?? "Client"} · ${dmy(l.service_date)} · ${aud(l.amount)}` : "Line"}</span>: {e.reason}</li>;
            })}
          </ul>
        </Card>
      ) : null}
    </div>
  );
}

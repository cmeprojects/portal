// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { InvoiceActions, RemoveItem } from "../../claim-forms";
import { INVOICE_KIND, INVOICE_STATUS } from "../../claims-tabs";

export const metadata: Metadata = { title: "Invoice" };

// cmeprojects (update 163): one client invoice: lines, approval by someone other
// than the preparer, issue (number, GST from the verified business position,
// snapshot and PDF), then marked sent. An issued invoice never changes.
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const when = (t: string | null | undefined) => (t ? new Date(t).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" }) : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));

export default async function InvoicePage({ params }: PageProps<"/billing/invoices/[id]">) {
  const { profile } = await requireSession();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: v } = await supabase.from("invoices").select("*").eq("id", id).maybeSingle();
  if (!v || !(await canBill("view", v.client_id))) notFound();
  const [{ data: items }, { data: client }, { data: payer }, canApprove, canPrepare, canIssue] = await Promise.all([
    supabase.from("invoice_items").select("id, description, service_date, quantity, unit_price, amount, gst_code, gst_amount, status").eq("invoice_id", id).order("service_date"),
    supabase.from("car_clients").select("name").eq("id", v.client_id).maybeSingle(),
    supabase.from("billing_payers").select("name, email").eq("id", v.payer_id).maybeSingle(),
    canBill("invoice_approve", v.client_id), canBill("invoice_prepare", v.client_id), canBill("invoice_issue", v.client_id),
  ]);
  const people = [v.prepared_by, v.approved_by, v.issued_by, v.sent_by, v.cancelled_by].filter(Boolean) as string[];
  const { data: pRows } = people.length ? await supabase.from("profiles").select("id, full_name, email").in("id", people) : { data: [] };
  const who = (pid: string | null) => ((pRows ?? []) as { id: string; full_name: string | null; email: string }[]).find((p) => p.id === pid)?.full_name ?? "someone";
  const its = (items ?? []) as { id: string; description: string; service_date: string; quantity: number; unit_price: number; amount: number; gst_code: string; gst_amount: number; status: string }[];
  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Billing · Invoice" title={v.number ? `${v.tax_invoice ? "Tax invoice" : "Invoice"} ${v.number}` : `Draft invoice, ${dmy(v.period_from)} to ${dmy(v.period_to)}`}
        intro={`${INVOICE_KIND[v.kind]} for ${client?.name ?? "the client"}, to ${payer?.name ?? "the payer"}${payer?.email ? ` (${payer.email})` : ""}. ${INVOICE_STATUS[v.status]}. Total ${aud(v.total)}.`}
        action={<Link href="/billing?tab=invoices" className={buttonClass("outline")}>All invoices</Link>} />
      <Card className="flex flex-col gap-2 p-4 text-sm">
        <p>Prepared by {who(v.prepared_by)} {when(v.prepared_at)}{v.approved_by ? ` · approved by ${who(v.approved_by)} ${when(v.approved_at)}` : ""}{v.issued_by ? ` · issued by ${who(v.issued_by)} ${when(v.issued_at)}` : ""}{v.sent_by ? ` · sent ${when(v.sent_at)} by ${who(v.sent_by)}${v.sent_note ? ` (${v.sent_note})` : ""}` : ""}</p>
        {v.issue_date ? <p>Issued {dmy(v.issue_date)}, due {dmy(v.due_date)} ({v.terms_days} days). Business details version {v.business_version}. {v.tax_invoice ? `GST ${aud(v.gst)}.` : "Not a tax invoice (no taxable items or not registered for GST)."}</p> : null}
        {v.pdf_checksum ? <p className="text-xs text-muted">PDF SHA-256 {String(v.pdf_checksum).slice(0, 16)}…</p> : null}
        {v.status === "cancelled" ? <p className="rounded-md bg-danger-soft px-3 py-2">Cancelled by {who(v.cancelled_by)} {when(v.cancelled_at)}: {v.cancel_reason}</p> : null}
        <InvoiceActions id={id} status={v.status} canApprove={canApprove} canIssue={canIssue} canCancel={canPrepare || canApprove} mine={v.prepared_by === profile.id} hasPdf={!!v.pdf_checksum} />
      </Card>
      <Card className="flex flex-col gap-2 p-4">
        <h2 className="heading-sm">Lines</h2>
        <div className="relative overflow-x-auto">
          <table className="w-full min-w-[640px] text-sm">
            <thead className="text-left text-xs text-muted"><tr><th className="py-1">Date</th><th>Description</th><th className="text-right">Qty</th><th className="text-right">Unit price</th><th className="text-right">Amount</th><th>GST</th><th></th></tr></thead>
            <tbody className="divide-y divide-line">
              {its.map((i) => (
                <tr key={i.id} className={i.status === "removed" ? "text-muted line-through" : ""}>
                  <td className="py-1.5">{dmy(i.service_date)}</td>
                  <td>{i.description}</td>
                  <td className="text-right">{Number(i.quantity).toFixed(2)}</td>
                  <td className="text-right">{aud(i.unit_price)}</td>
                  <td className="text-right">{aud(i.amount)}</td>
                  <td className="text-xs">{i.gst_code === "taxable" ? `Taxable${v.issue_date ? ` (${aud(i.gst_amount)})` : ""}` : i.gst_code === "gst_free" ? "GST-free" : "Input taxed"}</td>
                  <td>{v.status === "draft" && i.status === "live" && canPrepare ? <RemoveItem id={i.id} parent={id} kind="invoice" /> : null}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}

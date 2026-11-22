// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { AllocateForm, PaymentActions } from "../../money-forms";
import { METHOD } from "../../money-tabs";

export const metadata: Metadata = { title: "Payment" };

// cmeprojects (update 164): one payment received: what it paid (allocations), what's left,
// its receipt, refunds of any credit and reversal.
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));

export default async function PaymentPage({ params }: PageProps<"/billing/payments/[id]">) {
  await requireSession();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: p } = await supabase.from("payments").select("*").eq("id", id).maybeSingle();
  if (!p || !(await canBill("view", p.client_id ?? undefined))) notFound();
  const [{ data: bal }, { data: allocs }, { data: payer }, canPay, canRefund] = await Promise.all([
    supabase.from("payment_balances").select("unallocated, allocated, refunded").eq("payment_id", id).single(),
    supabase.from("payment_allocations").select("id, invoice_id, claim_item_id, client_id, amount, created_at").eq("payment_id", id).order("created_at"),
    supabase.from("billing_payers").select("name, kind").eq("id", p.payer_id).maybeSingle(),
    canBill("payment_record"), canBill("refund"),
  ]);
  const left = Number(bal?.unallocated ?? 0);
  // What this payer is owed against: their open invoices, or accepted claim lines not yet paid.
  const [{ data: inv }, { data: claimLines }] = await Promise.all([
    supabase.from("invoice_balances").select("invoice_id, number, balance, due_date, client_id").eq("payer_id", p.payer_id).gt("balance", 0).order("due_date"),
    supabase.from("claim_item_balances").select("claim_item_id, claim_id, client_id, accepted, paid, written_off").gt("accepted", 0),
  ]);
  const claimIds = [...new Set(((claimLines ?? []) as { claim_id: string }[]).map((c) => c.claim_id))];
  const { data: claims } = claimIds.length ? await supabase.from("claims").select("id, payer_id, period_from, period_to").in("id", claimIds) : { data: [] };
  const mine = new Map(((claims ?? []) as { id: string; payer_id: string; period_from: string; period_to: string }[]).filter((c) => c.payer_id === p.payer_id).map((c) => [c.id, c]));
  const cIds = [...new Set([...((inv ?? []) as { client_id: string }[]).map((i) => i.client_id), ...((claimLines ?? []) as { client_id: string }[]).map((c) => c.client_id), ...((allocs ?? []) as { client_id: string }[]).map((a) => a.client_id)])];
  const { data: cRows } = cIds.length ? await supabase.from("car_clients").select("id, name").in("id", cIds) : { data: [] };
  const C = new Map(((cRows ?? []) as { id: string; name: string }[]).map((c) => [c.id, c.name]));
  const targets = [
    ...((inv ?? []) as { invoice_id: string; number: string; balance: number; due_date: string; client_id: string }[]).filter((i) => !p.client_id || i.client_id === p.client_id)
      .map((i) => ({ kind: "invoice" as const, id: i.invoice_id, label: `Invoice ${i.number} · ${C.get(i.client_id) ?? ""} · due ${dmy(i.due_date)}`, owed: Number(i.balance) })),
    ...((claimLines ?? []) as { claim_item_id: string; claim_id: string; client_id: string; accepted: number; paid: number; written_off: number }[])
      .filter((c) => mine.has(c.claim_id) && Number(c.accepted) - Number(c.paid) - Number(c.written_off) > 0 && (!p.client_id || c.client_id === p.client_id))
      .map((c) => ({ kind: "claim_item" as const, id: c.claim_item_id, label: `Claim ${dmy(mine.get(c.claim_id)?.period_from)}–${dmy(mine.get(c.claim_id)?.period_to)} · ${C.get(c.client_id) ?? ""}`, owed: Math.round((Number(c.accepted) - Number(c.paid) - Number(c.written_off)) * 100) / 100 })),
  ];
  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Billing · Payment" title={`${aud(p.amount)} from ${payer?.name ?? "payer"}`}
        intro={`Received ${dmy(p.received_on)} by ${METHOD[p.method] ?? p.method}${p.reference ? `, reference ${p.reference}` : ""}. ${p.status === "reversed" ? `Reversed: ${p.reversal_reason}.` : `Allocated ${aud(bal?.allocated)}, refunded ${aud(bal?.refunded)}, left ${aud(left)}.`}`}
        action={<Link href="/billing?tab=payments" className={buttonClass("outline")}>All payments</Link>} />
      <Card className="flex flex-col gap-3 p-4">
        <PaymentActions id={id} canReverse={canPay && p.status === "recorded"} canRefund={(canPay || canRefund) && p.status === "recorded"} unallocated={left} receipt={p.receipt_number} hasReceiptPdf={!!p.receipt_pdf_checksum} />
      </Card>
      {(allocs ?? []).length ? (
        <Card className="flex flex-col gap-2 p-4">
          <h2 className="heading-sm">What it paid</h2>
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {((allocs ?? []) as { id: string; invoice_id: string | null; claim_item_id: string | null; client_id: string; amount: number }[]).map((a) => (
              <li key={a.id} className="flex flex-wrap gap-2 px-3 py-1.5">
                <span className="min-w-48 flex-1">{a.invoice_id ? <Link href={`/billing/invoices/${a.invoice_id}`} className="text-brand underline">Invoice</Link> : "Claim line"} · {C.get(a.client_id) ?? "Client"}</span>
                <span className="font-semibold">{aud(a.amount)}</span>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}
      {canPay && p.status === "recorded" && left > 0 ? (
        <Card className="flex flex-col gap-3 p-4">
          <div>
            <h2 className="heading-sm">Allocate</h2>
            <p className="text-sm text-muted">Against this payer&apos;s open invoices, or claim lines the government accepted and hasn&apos;t paid yet. Never more than is owed.</p>
          </div>
          {targets.length ? <AllocateForm paymentId={id} left={left} targets={targets} /> : <p className="text-sm text-muted">Nothing is owed by this payer right now. The amount stays as credit (it can be refunded).</p>}
        </Card>
      ) : null}
    </div>
  );
}

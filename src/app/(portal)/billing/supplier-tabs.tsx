// Staff Portal · © cmeproject. All rights reserved.
import { requireSession } from "@/lib/session";
import { canBill } from "@/lib/billing-access";
import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui";
import { ChargeActions, ChargeForm, PathwayActions, PathwayForm, SupplierForm, SupplierInvoiceActions, SupplierInvoiceForm } from "./supplier-forms";

// cmeprojects (update 165): the Suppliers and charges tab: pathway budgets, client charges,
// supplier invoices and suppliers. Supplier costs are kept apart from client revenue.
const dmy = (d: string | null | undefined) => (d ? d.slice(0, 10).split("-").reverse().join("/") : "");
const aud = (n: number | null | undefined) => (n === null || n === undefined ? "–" : Number(n).toLocaleString("en-AU", { style: "currency", currency: "AUD" }));
const STREAM: Record<string, string> = { ongoing: "Quarterly budget", at_hm: "AT-HM", restorative: "Restorative Care", end_of_life: "End-of-Life", hcp_unspent: "Unspent HCP funds", ndis_plan: "NDIS plan", private: "Private" };

export async function SuppliersTab() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const [{ data: sups, error }, { data: sinv }, { data: slines }, { data: charges }, { data: pbs }, { data: pbal }, { data: rules }, canPrepare, canApprove, canPay] = await Promise.all([
    supabase.from("suppliers").select("id, name, kind, abn, gst_registered, active").order("name"),
    supabase.from("supplier_invoices").select("id, supplier_id, supplier_ref, invoice_date, due_date, total, gst, status, recorded_by, paid_on").order("invoice_date", { ascending: false }).limit(200),
    supabase.from("supplier_invoice_lines").select("id, supplier_invoice_id, description, client_id, service_date, amount, gst_amount"),
    supabase.from("client_charges").select("id, client_id, scheme, funding_stream, description, service_date, cost, markup_amount, amount, client_share, status, created_by, over_budget, supplier_line_id").order("service_date", { ascending: false }).limit(300),
    supabase.from("client_pathway_budgets").select("id, client_id, stream, detail, amount, starts_on, ends_on, status, created_by, source").order("starts_on", { ascending: false }),
    supabase.from("pathway_balances").select("pathway_budget_id, used, available"),
    supabase.from("billing_markup_rules").select("funding_stream, markup_pct, effective_from").order("effective_from"),
    canBill("prepare"), canBill("approve"), canBill("payment_record"),
  ]);
  if (error) return <Card className="p-5 text-sm text-muted">Suppliers and charges aren&apos;t set up yet (update 165).</Card>;
  const [{ data: clients }, { data: enrols }, { data: funding }, { data: locs }] = await Promise.all([
    supabase.from("car_clients").select("id, name").eq("status", "active").order("name").limit(2000),
    supabase.from("client_enrolments").select("id, client_id").eq("scheme", "support_at_home").neq("status", "ended"),
    supabase.from("client_funding").select("id, client_id, period_start, period_end").eq("scheme", "ndis"),
    supabase.from("client_locations").select("id, client_id, label").eq("approved", true),
  ]);
  const C = (clients ?? []) as { id: string; name: string }[];
  const cName = new Map(C.map((c) => [c.id, c.name]));
  const S = new Map(((sups ?? []) as { id: string; name: string }[]).map((s) => [s.id, s.name]));
  const SI = (sinv ?? []) as { id: string; supplier_id: string; supplier_ref: string; invoice_date: string; due_date: string | null; total: number; gst: number; status: string; recorded_by: string; paid_on: string | null }[];
  const SL = (slines ?? []) as { id: string; supplier_invoice_id: string; description: string; client_id: string | null; service_date: string | null; amount: number; gst_amount: number }[];
  const CH = (charges ?? []) as { id: string; client_id: string; scheme: string; funding_stream: string; description: string; service_date: string; cost: number; markup_amount: number; amount: number; client_share: number | null; status: string; created_by: string; over_budget: boolean; supplier_line_id: string | null }[];
  const usedLines = new Set(CH.filter((c) => c.status !== "voided").map((c) => c.supplier_line_id).filter(Boolean));
  const approvedInv = new Set(SI.filter((i) => i.status === "approved" || i.status === "paid").map((i) => i.id));
  const PB = (pbs ?? []) as { id: string; client_id: string; stream: string; detail: string; amount: number; starts_on: string; ends_on: string; status: string; created_by: string; source: string }[];
  const BAL = new Map(((pbal ?? []) as { pathway_budget_id: string; used: number; available: number }[]).map((b) => [b.pathway_budget_id, b]));
  const enrolOf = new Map(((enrols ?? []) as { id: string; client_id: string }[]).map((e) => [e.client_id, e.id]));
  const markups: Record<string, number> = {};
  for (const r of (rules ?? []) as { funding_stream: string; markup_pct: number }[]) markups[r.funding_stream] = Number(r.markup_pct);
  const formClients = C.map((c) => ({
    id: c.id, name: c.name, sah: enrolOf.get(c.id) ?? null,
    ndisFunding: ((funding ?? []) as { id: string; client_id: string; period_start: string; period_end: string }[]).filter((f) => f.client_id === c.id).map((f) => [f.id, `${dmy(f.period_start)} to ${dmy(f.period_end)}`] as [string, string]),
    locations: ((locs ?? []) as { id: string; client_id: string; label: string }[]).filter((l) => l.client_id === c.id).map((l) => [l.id, l.label] as [string, string]),
    pathways: PB.filter((b) => b.client_id === c.id && b.status === "approved").map((b) => [b.id, `${STREAM[b.stream]} ${aud(b.amount)} (${dmy(b.starts_on)}–${dmy(b.ends_on)}), ${aud(BAL.get(b.id)?.available)} left`] as [string, string]),
  }));
  return (
    <div className="flex flex-col gap-4">
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Pathway budgets (Support at Home)</h2>
          <p className="text-sm text-muted">AT-HM, Restorative Care, End-of-Life and unspent Home Care Package funds, typed in from the Services Australia notice (amount and period), approved by someone else. Charges in these streams use them, never the quarterly budget.</p>
        </div>
        {PB.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {PB.map((b) => (
              <li key={b.id} className="flex flex-wrap items-center gap-2 px-3 py-1.5">
                <span className="min-w-40 flex-1 font-semibold">{cName.get(b.client_id) ?? "Client"} · {STREAM[b.stream]}{b.detail ? ` (${b.detail})` : ""}</span>
                <span className="text-xs">{aud(b.amount)} · {dmy(b.starts_on)} to {dmy(b.ends_on)}{BAL.get(b.id) ? ` · used ${aud(BAL.get(b.id)!.used)}, ${Number(BAL.get(b.id)!.available) < 0 ? `over by ${aud(-Number(BAL.get(b.id)!.available))}` : `${aud(BAL.get(b.id)!.available)} left`}` : ""}</span>
                <span className="text-xs font-semibold">{b.status === "draft" ? "Draft" : b.status === "approved" ? "Approved" : "Closed"}</span>
                <PathwayActions id={b.id} status={b.status} mine={b.created_by === profile.id} canApprove={canApprove} />
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No pathway budgets yet.</p>}
        {canPrepare ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Add a pathway budget</summary><div className="mt-2"><PathwayForm clients={C.filter((c) => enrolOf.has(c.id)).map((c) => ({ id: c.id, name: c.name, enrolment: enrolOf.get(c.id)! }))} /></div></details> : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Client charges</h2>
          <p className="text-sm text-muted">Charges that don&apos;t come from shifts: third-party services (supplier cost plus markup), equipment and home modifications. Approved charges are claimed and invoiced with billing lines, never twice.</p>
        </div>
        {CH.length ? (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[760px] text-sm">
              <thead className="text-left text-xs text-muted"><tr><th className="py-1">Date</th><th>Client</th><th>Charge</th><th>Funding</th><th className="text-right">Cost + markup</th><th className="text-right">Charge</th><th className="text-right">Client pays</th><th>Status</th><th></th></tr></thead>
              <tbody className="divide-y divide-line">
                {CH.map((c) => (
                  <tr key={c.id} className={c.status === "voided" ? "text-muted line-through" : ""}>
                    <td className="py-1.5">{dmy(c.service_date)}</td>
                    <td>{cName.get(c.client_id) ?? "Client"}</td>
                    <td>{c.description}{c.over_budget ? <span className="text-xs text-warn"> (over budget)</span> : null}</td>
                    <td className="text-xs">{STREAM[c.funding_stream]}</td>
                    <td className="text-right text-xs">{c.supplier_line_id ? `${aud(c.cost)} + ${aud(c.markup_amount)}` : ""}</td>
                    <td className="text-right">{aud(c.amount)}</td>
                    <td className="text-right">{aud(c.client_share)}</td>
                    <td className="text-xs">{c.status === "draft" ? "Draft" : c.status === "approved" ? "Approved" : "Voided"}</td>
                    <td><ChargeActions id={c.id} status={c.status} mine={c.created_by === profile.id} canApprove={canApprove} canVoid={canApprove || (c.status === "draft" && canPrepare)} overBudget={c.over_budget || ["at_hm", "restorative", "end_of_life", "hcp_unspent"].includes(c.funding_stream)} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <p className="text-sm text-muted">No charges yet.</p>}
        {canPrepare ? (
          <details className="rounded-md border border-dashed border-line px-3 py-2">
            <summary className="cursor-pointer text-xs font-semibold text-brand">Make a charge</summary>
            <div className="mt-2">
              <ChargeForm clients={formClients} markups={markups}
                supplierLines={SL.filter((l) => l.client_id && approvedInv.has(l.supplier_invoice_id) && !usedLines.has(l.id)).map((l) => {
                  const inv = SI.find((i) => i.id === l.supplier_invoice_id);
                  return { id: l.id, client_id: l.client_id!, date: l.service_date, label: `${l.description} · ${S.get(inv?.supplier_id ?? "") ?? ""} ${inv?.supplier_ref ?? ""} · ${aud(l.amount)}` };
                })} />
            </div>
          </details>
        ) : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <div>
          <h2 className="heading-sm">Supplier invoices</h2>
          <p className="text-sm text-muted">Bills from suppliers: recorded, approved by someone else, then recorded as paid. The same invoice number from the same supplier can&apos;t be recorded twice.</p>
        </div>
        {SI.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {SI.map((i) => (
              <li key={i.id} className="flex flex-col gap-1 px-3 py-2">
                <p className="flex flex-wrap gap-2"><span className="min-w-40 flex-1 font-semibold">{S.get(i.supplier_id) ?? "Supplier"} · {i.supplier_ref}</span>
                  <span className="text-xs">{dmy(i.invoice_date)}{i.due_date ? `, due ${dmy(i.due_date)}` : ""} · {aud(i.total)}{Number(i.gst) ? ` (GST ${aud(i.gst)})` : ""} · {i.status === "paid" ? `Paid ${dmy(i.paid_on)}` : i.status.charAt(0).toUpperCase() + i.status.slice(1)}</span></p>
                <ul className="pl-3 text-xs text-muted">{SL.filter((l) => l.supplier_invoice_id === i.id).map((l) => <li key={l.id}>{l.description}{l.client_id ? ` · ${cName.get(l.client_id) ?? "client"}` : ""} · {aud(l.amount)}{usedLines.has(l.id) ? " · charged to the client" : ""}</li>)}</ul>
                <SupplierInvoiceActions id={i.id} status={i.status} mine={i.recorded_by === profile.id} canApprove={canApprove} canPay={canPay || canApprove} />
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No supplier invoices yet.</p>}
        {canPrepare && (sups ?? []).length ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Record a supplier invoice</summary><div className="mt-2"><SupplierInvoiceForm suppliers={((sups ?? []) as { id: string; name: string; active: boolean }[]).filter((s) => s.active).map((s) => [s.id, s.name])} clients={C.map((c) => [c.id, c.name])} /></div></details> : null}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <h2 className="heading-sm">Suppliers</h2>
        {(sups ?? []).length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {((sups ?? []) as { id: string; name: string; kind: string; abn: string; gst_registered: boolean }[]).map((s) => (
              <li key={s.id} className="flex flex-wrap gap-2 px-3 py-1.5"><span className="min-w-40 flex-1 font-semibold">{s.name}</span><span className="text-xs text-muted">{s.kind.replace("_", " ")}{s.abn ? ` · ABN ${s.abn}` : ""}{s.gst_registered ? " · GST registered" : ""}</span></li>
            ))}
          </ul>
        ) : <p className="text-sm text-muted">No suppliers yet.</p>}
        {canPrepare ? <details className="rounded-md border border-dashed border-line px-3 py-2"><summary className="cursor-pointer text-xs font-semibold text-brand">Add a supplier</summary><div className="mt-2"><SupplierForm /></div></details> : null}
      </Card>
    </div>
  );
}

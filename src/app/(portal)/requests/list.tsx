// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { Inbox } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { REQUEST_STATUS, TYPE_LABEL, refOf, type RequestStatus } from "@/lib/requests-shared";
import { Card, EmptyState } from "@/components/ui";

export type RequestRow = { id: string; ref_number: number; type: string; subject: string; status: RequestStatus; stage: number; requester: string; created_at: string; partner_ok: boolean | null; swap_with: string | null };

// cmeprojects: requests this person can see (null when update 56 isn't run yet).
export async function loadRequests(): Promise<RequestRow[] | null> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("requests").select("id, ref_number, type, subject, status, stage, requester, created_at, partner_ok, swap_with").order("created_at", { ascending: false }).limit(300);
  return error ? null : ((data ?? []) as RequestRow[]);
}

// Open requests waiting for this person (or a swap they've been asked to accept).
export async function waitingFor(all: RequestRow[], me: string): Promise<RequestRow[]> {
  const supabase = await createClient();
  const open = all.filter((r) => r.status === "pending" || r.status === "info_needed");
  const checks = await Promise.all(open.map(async (r) => [r.id, (await supabase.rpc("can_act_on_request", { p_request: r.id })).data === true] as const));
  const canAct = new Map(checks);
  return open.filter((r) => (canAct.get(r.id) && r.requester !== me && (r.type !== "swap" || r.partner_ok === true)) || (r.swap_with === me && r.partner_ok === null));
}

export async function RequestList({ rows, me, empty }: { rows: RequestRow[]; me: string; empty: { title: string; text?: string; action?: { href: string; label: string } } }) {
  const ids = [...new Set(rows.map((r) => r.requester))];
  const { data: names } = ids.length ? await (await createClient()).from("profiles").select("id, full_name, email").in("id", ids) : { data: [] };
  const nameOf = new Map((names ?? []).map((n) => [n.id, n.full_name || n.email]));
  return (
    <Card className="overflow-hidden">
      {rows.length === 0 ? (
        <EmptyState icon={Inbox} {...empty} />
      ) : (
        <ul className="divide-y divide-line">
          {rows.map((r) => (
            <li key={r.id}>
              <Link href={`/requests/${r.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3 hover:bg-page">
                <span className="min-w-0 flex-1 basis-56">
                  <span className="block text-xs text-muted">
                    {refOf(r.ref_number)} · {TYPE_LABEL[r.type] ?? r.type}
                    {r.requester !== me ? ` · ${nameOf.get(r.requester) ?? ""}` : ""}
                  </span>
                  <span className="block font-semibold">{r.subject || TYPE_LABEL[r.type]}</span>
                </span>
                <span className="text-xs text-muted">{new Date(r.created_at).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "Australia/Sydney" })}</span>
                <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${REQUEST_STATUS[r.status].cls}`}>
                  {REQUEST_STATUS[r.status].label}
                  {r.status === "pending" && r.stage === 2 ? " (final approval)" : ""}
                  {r.status === "pending" && r.type === "swap" && r.partner_ok === null ? " (colleague to accept)" : ""}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}

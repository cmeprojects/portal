// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Inbox } from "lucide-react";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { REQUEST_STATUS, TYPE_LABEL, refOf, type RequestStatus } from "@/lib/requests-shared";
import { Card, EmptyState, PageHeader, Tabs, buttonClass } from "@/components/ui";

export const metadata: Metadata = { title: "My requests" };

type Row = { id: string; ref_number: number; type: string; subject: string; status: RequestStatus; stage: number; requester: string; created_at: string; partner_ok: boolean | null; swap_with: string | null };

// cmeprojects: My requests (HR Pack): what I've asked for, what's waiting for
// me to approve, and (for people who manage staff) everyone's requests.
export default async function RequestsPage({ searchParams }: PageProps<"/requests">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false) notFound();
  const supabase = await createClient();
  const tab = String((await searchParams).tab ?? (profile.role === "system_admin" ? "all" : "mine"));
  const peopleManager = ["manager", "staff_admin", "system_admin"].includes(profile.role);
  const { data, error } = await supabase.from("requests").select("id, ref_number, type, subject, status, stage, requester, created_at, partner_ok, swap_with").order("created_at", { ascending: false }).limit(300);
  if (error) notFound(); // before live update 56
  const all = (data ?? []) as Row[];
  // Waiting for me: open requests I can act on (or a swap I've been asked to accept).
  const open = all.filter((r) => r.status === "pending" || r.status === "info_needed");
  const checks = await Promise.all(open.map(async (r) => [r.id, (await supabase.rpc("can_act_on_request", { p_request: r.id })).data === true] as const));
  const canAct = new Map(checks);
  const waiting = open.filter((r) => (canAct.get(r.id) && r.requester !== profile.id && (r.type !== "swap" || r.partner_ok === true)) || (r.swap_with === profile.id && r.partner_ok === null));
  const rows = tab === "approve" ? waiting : tab === "all" && peopleManager ? all : all.filter((r) => r.requester === profile.id);
  const ids = [...new Set(rows.map((r) => r.requester))];
  const { data: names } = ids.length ? await supabase.from("profiles").select("id, full_name, email").in("id", ids) : { data: [] };
  const nameOf = new Map((names ?? []).map((n) => [n.id, n.full_name || n.email]));
  const tabs = [
    ...(profile.role !== "system_admin" ? [{ href: "/requests", text: "My requests", current: tab === "mine" }] : []),
    { href: "/requests?tab=approve", text: `Waiting for me${waiting.length ? ` · ${waiting.length}` : ""}`, current: tab === "approve" },
    ...(peopleManager ? [{ href: "/requests?tab=all", text: "All requests", current: tab === "all" }] : []),
  ];
  return (
    <>
      <PageHeader
        title="My requests"
        intro="Leave, shift swaps, availability and other requests, and where each one is up to."
        action={
          profile.role !== "system_admin" ? (
            <Link href="/requests/new" className={buttonClass("primary")}>
              + New request
            </Link>
          ) : undefined
        }
      />
      <Tabs label="Requests" items={tabs} />
      <Card className="overflow-hidden">
        {rows.length === 0 ? (
          <EmptyState
            icon={Inbox}
            title={tab === "approve" ? "Nothing waiting for you" : "No requests yet"}
            text={tab === "mine" ? "Requests you send show here with their status." : undefined}
            action={tab === "mine" ? { href: "/requests/new", label: "+ New request" } : undefined}
          />
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((r) => (
              <li key={r.id}>
                <Link href={`/requests/${r.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3 hover:bg-page">
                  <span className="min-w-56 flex-1">
                    <span className="block text-xs text-muted">
                      {refOf(r.ref_number)} · {TYPE_LABEL[r.type] ?? r.type}
                      {r.requester !== profile.id ? ` · ${nameOf.get(r.requester) ?? ""}` : ""}
                    </span>
                    <span className="block font-semibold">{r.subject || TYPE_LABEL[r.type]}</span>
                  </span>
                  <span className="text-xs text-muted">{new Date(r.created_at).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" })}</span>
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
    </>
  );
}

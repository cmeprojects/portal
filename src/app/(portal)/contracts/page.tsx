// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { FilePlus2, FileSignature } from "lucide-react";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { SectionTabs } from "@/components/section-tabs";
import { Card, EmptyState, PageHeader, buttonClass } from "@/components/ui";
import { CONTRACT_STATUS, type Contract, type ContractStatus } from "@/lib/contracts";
import { fmtDateTime } from "@/lib/contract-data";
import { StatusChip } from "./status-chip";

export const metadata: Metadata = { title: "Contracts" };

// cmeprojects Phase 4: People → Contracts, for people with Staff details access
// (and the system admin). The database shows only the people their access covers.
export default async function ContractsPage({ searchParams }: PageProps<"/contracts">) {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const { count } = await supabase.from("access_grants").select("id", { count: "exact", head: true }).eq("user_id", profile.id).eq("area", "staff_details").is("revoked_at", null);
  if (profile.role !== "system_admin" && !count) notFound();
  const show = String((await searchParams).show ?? "open");
  const { data, error } = await supabase.from("contracts").select("id, user_id, title, version, status, sign_by, sent_at, completed_at, created_at").order("created_at", { ascending: false }).limit(500);
  if (error) notFound();
  const rows = (data ?? []) as Contract[];
  const { data: people } = await supabase.from("profiles").select("id, full_name, email").in("id", [...new Set(rows.map((r) => r.user_id))]);
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const open: ContractStatus[] = ["draft", "awaiting_employee", "awaiting_employer"];
  const list = rows.filter((r) => (show === "open" ? open.includes(r.status) : show === "all" ? true : r.status === show));
  const count_ = (s: ContractStatus) => rows.filter((r) => r.status === s).length;
  const filters: [string, string][] = [
    ["open", `In progress · ${rows.filter((r) => open.includes(r.status)).length}`],
    ["fully_signed", `Fully signed · ${count_("fully_signed")}`],
    ["all", `All · ${rows.length}`],
  ];
  return (
    <>
      <SectionTabs section="people" current="/contracts" />
      <PageHeader
        title="Contracts"
        intro="Employment contracts: prepare, send to sign, countersign, and keep the signed copy. Signed contracts never change; a revision is a new version."
        action={
          <Link href="/contracts/new" className={buttonClass("primary")}>
            <FilePlus2 aria-hidden="true" className="size-4" /> New contract
          </Link>
        }
      />
      <nav aria-label="Filter contracts" className="flex flex-wrap gap-2">
        {filters.map(([k, label]) => (
          <Link key={k} href={`/contracts?show=${k}`} aria-current={show === k ? "page" : undefined} className={buttonClass(show === k ? "primary" : "outline", "", "sm")}>
            {label}
          </Link>
        ))}
      </nav>
      <Card className="overflow-hidden">
        {list.length === 0 ? (
          <EmptyState icon={FileSignature} title="No contracts here" text="Start one with New contract." />
        ) : (
          <ul className="divide-y divide-line">
            {list.map((r) => (
              <li key={r.id}>
                <Link href={`/contracts/${r.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3 hover:bg-page">
                  <span className="min-w-0 flex-1 basis-56">
                    <span className="block font-semibold">{nameOf.get(r.user_id) ?? "Someone"}</span>
                    <span className="block text-sm text-muted">
                      {r.title} · version {r.version}
                    </span>
                  </span>
                  <span className="text-xs text-muted">
                    {r.completed_at ? `Signed ${fmtDateTime(r.completed_at)}` : r.sent_at ? `Sent ${fmtDateTime(r.sent_at)}` : `Started ${fmtDateTime(r.created_at)}`}
                  </span>
                  <StatusChip status={r.status} />
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>
      <p className="text-xs text-muted">Statuses: {Object.values(CONTRACT_STATUS).map((s) => s.label).join(" · ")}.</p>
    </>
  );
}

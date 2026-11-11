// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { FileSignature } from "lucide-react";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader } from "@/components/ui";
import type { Contract } from "@/lib/contracts";
import { fmtDateTime } from "@/lib/contract-data";
import { StatusChip } from "../../contracts/status-chip";

export const metadata: Metadata = { title: "My contracts" };

export default async function MyContractsPage() {
  const { profile } = await requireSession();
  const { data } = await (await createClient()).from("contracts").select("id, title, version, status, sent_at, completed_at").eq("user_id", profile.id).order("created_at", { ascending: false });
  const rows = (data ?? []) as Contract[];
  return (
    <>
      <PageHeader title="My contracts" intro="Read and sign your employment contract, and download your signed copy." />
      <Card className="overflow-hidden">
        {rows.length === 0 ? (
          <EmptyState icon={FileSignature} title="No contracts yet" text="When the office sends you a contract to sign, it shows here and in your notifications." />
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((r) => (
              <li key={r.id}>
                <Link href={`/account/contracts/${r.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3 hover:bg-page">
                  <span className="min-w-0 flex-1 basis-56 font-semibold">
                    {r.title} <span className="font-normal text-muted">· version {r.version}</span>
                  </span>
                  <span className="text-xs text-muted">{r.completed_at ? `Signed ${fmtDateTime(r.completed_at)}` : `Sent ${fmtDateTime(r.sent_at)}`}</span>
                  <StatusChip status={r.status} />
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </>
  );
}

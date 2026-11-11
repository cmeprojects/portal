// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui";
import { loadContract } from "@/lib/contract-data";
import { ContractView } from "../contract-view";

export const metadata: Metadata = { title: "Contract" };

export default async function ContractPage({ params }: PageProps<"/contracts/[id]">) {
  const { profile } = await requireSession();
  const { id } = await params;
  const data = await loadContract(id);
  if (!data) notFound();
  if (data.contract.user_id === profile.id) redirect(`/account/contracts/${id}`);
  const { data: holder } = await (await createClient()).rpc("has_access", { p_area: "staff_details", p_person: data.contract.user_id });
  return (
    <>
      <PageHeader title={data.contract.title} intro={`For ${data.nameOf(data.contract.user_id)} · version ${data.contract.version}`} />
      <p className="text-sm">
        <Link href="/contracts" className="font-semibold text-brand underline">
          Back to Contracts
        </Link>
      </p>
      <ContractView data={data} viewer={profile.id} viewerName={profile.full_name} holder={holder === true} />
    </>
  );
}

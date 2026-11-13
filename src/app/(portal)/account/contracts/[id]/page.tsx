// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { PageHeader } from "@/components/ui";
import { loadContract } from "@/lib/contract-data";
import { ContractView } from "../../../contracts/contract-view";

export const metadata: Metadata = { title: "My contract" };

export default async function MyContractPage({ params }: PageProps<"/account/contracts/[id]">) {
  const { profile } = await requireSession();
  const { id } = await params;
  const data = await loadContract(id);
  if (!data) notFound();
  if (data.contract.user_id !== profile.id) redirect(`/contracts/${id}`);
  return (
    <>
      <PageHeader title={data.contract.title} intro={`Version ${data.contract.version}`} />
      <p className="text-sm">
        <Link href="/account/contracts" className="font-semibold text-brand underline">
          Back to My contracts
        </Link>
      </p>
      <ContractView data={data} viewer={profile.id} viewerName={profile.full_name} />
    </>
  );
}

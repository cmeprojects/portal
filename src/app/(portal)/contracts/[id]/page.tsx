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
  // cmeprojects step 4: each ability on its own (Staff details access gives all three).
  const supabase = await createClient();
  const person = data.contract.user_id;
  const check = async (action: string) => {
    const r = await supabase.rpc("contract_access", { p_action: action, p_person: person });
    if (!r.error) return r.data === true;
    const old = await supabase.rpc("has_access", { p_area: "staff_details", p_person: person }); // before live update 78
    return old.data === true;
  };
  const [prepare, sign, download] = await Promise.all([check("create"), check("sign_for_employer"), check("download")]);
  return (
    <>
      <PageHeader title={data.contract.title} intro={`For ${data.nameOf(data.contract.user_id)} · version ${data.contract.version}`} />
      <p className="text-sm">
        <Link href="/contracts" className="font-semibold text-brand underline">
          Back to Contracts
        </Link>
      </p>
      <ContractView data={data} viewer={profile.id} viewerName={profile.full_name} access={{ prepare, sign, download }} />
    </>
  );
}

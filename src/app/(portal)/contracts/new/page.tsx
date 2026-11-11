// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { loadContract } from "@/lib/contract-data";
import { DraftForm } from "../forms";

export const metadata: Metadata = { title: "New contract" };

// A new contract, or a new version of an earlier one (?from=id).
export default async function NewContractPage({ searchParams }: PageProps<"/contracts/new">) {
  const { profile } = await requireSession();
  const from = String((await searchParams).from ?? "");
  const prev = from ? await loadContract(from) : null;
  const { data: people } = await (await createClient()).from("profiles").select("id, full_name, email, role").eq("active", true).neq("id", profile.id).order("full_name");
  return (
    <>
      <PageHeader
        title={prev ? `New version: ${prev.contract.title}` : "New contract"}
        intro={prev ? `For ${prev.nameOf(prev.contract.user_id)}. It starts as a draft; signing it replaces version ${prev.contract.version}.` : "It starts as a draft. Nothing is sent until you press Send to sign."}
      />
      <p className="text-sm">
        <Link href={prev ? `/contracts/${prev.contract.id}` : "/contracts"} className="font-semibold text-brand underline">
          Back
        </Link>
      </p>
      <Card className="p-5 sm:p-6">
        <DraftForm
          people={(people ?? []).filter((p) => p.role !== "system_admin").map((p) => ({ id: p.id, name: p.full_name || p.email }))}
          supersedes={prev ? { id: prev.contract.id, userId: prev.contract.user_id } : undefined}
          defaults={prev ? { title: prev.contract.title, body: prev.contract.body } : undefined}
        />
      </Card>
    </>
  );
}

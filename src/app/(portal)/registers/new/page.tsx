// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { redirect } from "next/navigation";
import { Card, PageHeader } from "@/components/ui";
import { CreateRegistryForm } from "../setup-forms";

export const metadata: Metadata = { title: "New register" };

export default async function NewRegisterPage() {
  const { profile } = await requireSession();
  if (profile.role !== "system_admin" && !(await getMyAdminAreas(profile.role)).includes("registers")) redirect("/registers");
  return (
    <>
      <Link href="/registers" className="text-sm font-semibold text-brand">
        ← Registers
      </Link>
      <PageHeader title="New register" intro="If you're a manager, you'll be this register's manager. You can add others after." />
      <Card className="max-w-3xl p-5 sm:p-7">
        <CreateRegistryForm />
      </Card>
    </>
  );
}

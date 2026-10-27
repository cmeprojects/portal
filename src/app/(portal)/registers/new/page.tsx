// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { Card, PageHeader } from "@/components/ui";
import { CreateRegistryForm } from "../setup-forms";

export const metadata: Metadata = { title: "New register" };

export default async function NewRegisterPage() {
  await requireRole(["manager", "staff_admin", "system_admin"]);
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

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader } from "@/components/ui";
import type { Bank, Super, WorkRights } from "@/lib/staff-records";
import { BankForm, SuperForm, WorkRightsForm } from "./forms";
import { TaxFormCard, type Tax } from "../../people/tax-forms";

export const metadata: Metadata = { title: "Pay and work rights" };

// cmeprojects Phase 3: the person's own bank, super and work-rights records.
// Only they and people with the matching access see them (the database
// enforces it). Never shown in the directory, dashboards or reports.
export default async function MyRecordsPage() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const [bank, sup, wr, tax] = await Promise.all([
    supabase.from("staff_bank").select("*").eq("user_id", profile.id).maybeSingle(),
    supabase.from("staff_super").select("*").eq("user_id", profile.id).maybeSingle(),
    supabase.from("staff_work_rights").select("*").eq("user_id", profile.id).maybeSingle(),
    supabase.from("staff_tax").select("*").eq("user_id", profile.id).maybeSingle(),
  ]);
  if (bank.error && bank.error.code === "42P01") {
    return (
      <>
        <PageHeader title="Pay and work rights" />
        <Notice>This needs the latest database update (update 62).</Notice>
      </>
    );
  }
  return (
    <>
      <PageHeader
        title="Pay and work rights"
        intro="Private: only you and the people who look after payroll or work rights can see these. Every look at them is recorded."
      />
      <p className="text-sm">
        <Link href="/account" className="font-semibold text-brand underline">
          Back to My account
        </Link>
      </p>
      <Card className="p-5 sm:p-6">
        <BankForm bank={(bank.data as Bank | null) ?? null} />
      </Card>
      <Card className="p-5 sm:p-6">
        <SuperForm sup={(sup.data as Super | null) ?? null} userId={profile.id} />
      </Card>
      <Card className="p-5 sm:p-6">
        <WorkRightsForm wr={(wr.data as WorkRights | null) ?? null} userId={profile.id} />
      </Card>
      {tax.error ? null : (
        <Card className="p-5 sm:p-6">
          <TaxFormCard tax={(tax.data as Tax | null) ?? null} userId={profile.id} />
        </Card>
      )}
    </>
  );
}

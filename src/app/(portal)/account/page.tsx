// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { ROLE_LABELS } from "@/lib/roles";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { NameForm, PasswordForm } from "./forms";

export const metadata: Metadata = { title: "My account" };

export default async function AccountPage() {
  const { profile } = await requireSession();
  const supabase = await createClient();
  const { data: factors } = await supabase.auth.mfa.listFactors();
  const hasMfa = (factors?.totp.length ?? 0) > 0;

  return (
    <>
      <PageHeader title="My account" intro={`${profile.email} · ${ROLE_LABELS[profile.role]}`} />
      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="p-5">
          <NameForm name={profile.full_name} />
        </Card>
        <Card className="flex flex-col gap-3 p-5">
          <div className="flex items-center justify-between gap-2">
            <h2 className="text-lg font-bold">Two-factor login</h2>
            {hasMfa ? <Badge tone="good">On</Badge> : <Badge tone="grey">Off</Badge>}
          </div>
          <p className="text-[15px] text-muted">
            {hasMfa
              ? "You'll be asked for a code from your authenticator app when you sign in."
              : "Optional for your role. It adds a code from your phone when you sign in."}
          </p>
          {!hasMfa ? (
            <Link href="/mfa" className={buttonClass("outline", "self-start")}>Set up two-factor login</Link>
          ) : null}
        </Card>
        <Card className="p-5 lg:col-span-2">
          <h2 className="mb-3 text-lg font-bold">Change password</h2>
          <PasswordForm />
        </Card>
      </div>
    </>
  );
}

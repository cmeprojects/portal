// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { ROLE_LABELS } from "@/lib/roles";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { NameForm, PasswordForm } from "./forms";
import { TurnOffTwoFactor } from "./two-factor";

export const metadata: Metadata = { title: "My account" };

export default async function AccountPage() {
  const { profile, features, mfaRequired } = await requireSession();
  const supabase = await createClient();
  const { data: factors } = await supabase.auth.mfa.listFactors();
  const factorIds = (factors?.totp ?? []).map((f) => f.id);
  const hasMfa = factorIds.length > 0;
  const switchedOff = features.two_factor === false;

  let help: string;
  if (switchedOff) help = "Two-factor login is switched off for everyone at the moment.";
  else if (hasMfa) help = "You'll be asked for a code from your authenticator app when you sign in.";
  else help = "Optional for your role. It adds a code from your phone when you sign in.";

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
            {hasMfa && !switchedOff ? <Badge tone="good">On</Badge> : <Badge tone="grey">Off</Badge>}
          </div>
          <p className="text-[15px] text-muted">{help}</p>
          {!switchedOff && !hasMfa ? (
            <Link href="/mfa" className={buttonClass("outline", "self-start")}>Set up two-factor login</Link>
          ) : null}
          {!switchedOff && hasMfa && mfaRequired ? (
            <p className="text-sm text-muted">Your role needs two-factor login, so it can&apos;t be turned off here.</p>
          ) : null}
          {hasMfa && (!mfaRequired || switchedOff) ? <TurnOffTwoFactor factorIds={factorIds} /> : null}
        </Card>
        <Card className="p-5 lg:col-span-2">
          <h2 className="mb-3 text-lg font-bold">Change password</h2>
          <PasswordForm />
        </Card>
      </div>
    </>
  );
}

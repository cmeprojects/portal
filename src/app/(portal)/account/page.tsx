// Staff Portal · © cmeproject. All rights reserved.
import { ProfileForm } from "@/components/profile-form";
import { loadPerson, profilesReady } from "@/lib/profiles";
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { ROLE_LABELS } from "@/lib/roles";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { NameForm, PasswordForm, PhotoForm } from "./forms";
import { photoLinks } from "@/lib/avatars";
import { TurnOffTwoFactor } from "./two-factor";
import { OtherDevices } from "./devices";

export const metadata: Metadata = { title: "My account" };

export default async function AccountPage() {
  const { profile, features, mfaRequired } = await requireSession();
  const supabase = await createClient();
  const { data: factors } = await supabase.auth.mfa.listFactors();
  const factorIds = (factors?.totp ?? []).map((f) => f.id);
  const hasMfa = factorIds.length > 0;
  const switchedOff = features.two_factor === false;
  const { data: mine } = await supabase.from("profiles").select("id, avatar_ref").eq("id", profile.id).maybeSingle();
  const photo = mine ? (await photoLinks([mine]))[profile.id] : undefined;

  let help: string;
  if (switchedOff) help = "Two-factor login is switched off for everyone at the moment.";
  else if (hasMfa) help = "You'll be asked for a code from your authenticator app when you sign in.";
  else help = "Optional for your role. It adds a code from your phone when you sign in.";

  // cmeprojects: my staff profile (HR Pack → Staff profiles); not for the system admin.
  const showProfile = profile.role !== "system_admin" && features.hr_profiles !== false && (await profilesReady());
  const me = showProfile ? await loadPerson(profile.id) : null;
  return (
    <>
      <PageHeader title="My account" intro={`${profile.email} · ${ROLE_LABELS[profile.role]}`} />
      {/* cmeprojects: my photo and name on top, then my details. Your business
          card shows in the Directory; there's no need to repeat it here. */}
      <Card className="grid grid-cols-[minmax(0,1fr)] gap-6 p-5 sm:p-6 lg:grid-cols-2">
        {/* Only once this copy has staff photos (live update 53). */}
        {mine ? <PhotoForm userId={profile.id} name={profile.full_name || profile.email} src={photo} /> : null}
        <NameForm name={profile.full_name} canEdit={profile.role === "system_admin"} />
      </Card>
      {/* cmeprojects Phase 3: private pay and work-rights records. */}
      <Card className="flex flex-wrap items-center justify-between gap-3 p-5 sm:p-6">
        <div>
          <h2 className="heading-sm">Pay and work rights</h2>
          <p className="text-sm text-muted">Your bank account, super and right to work. Private to you and payroll.</p>
        </div>
        <Link href="/account/records" className={buttonClass("outline")}>
          Open
        </Link>
      </Card>
      {me ? (
        <Card className="p-5 sm:p-6">
          <h2 className="heading-sm mb-4">My details</h2>
          <ProfileForm person={me} employment={false} />
        </Card>
      ) : null}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="flex flex-col gap-3 p-5">
          <div className="flex items-center justify-between gap-2">
            <h2 className="heading-sm">Two-factor login</h2>
            {hasMfa && !switchedOff ? <Badge tone="good">On</Badge> : <Badge tone="grey">Off</Badge>}
          </div>
          <p className="text-sm text-muted">{help}</p>
          {!switchedOff && !hasMfa ? (
            <Link href="/mfa" className={buttonClass("outline", "self-start")}>Set up two-factor login</Link>
          ) : null}
          {!switchedOff && hasMfa && mfaRequired ? (
            <p className="text-sm text-muted">Your role needs two-factor login, so it can&apos;t be turned off here.</p>
          ) : null}
          {hasMfa && (!mfaRequired || switchedOff) ? <TurnOffTwoFactor factorIds={factorIds} /> : null}
        </Card>
        <Card className="p-5">
          <h2 className="mb-3 heading-sm">Change password</h2>
          <PasswordForm />
        </Card>
        <Card className="p-5">
          <OtherDevices />
        </Card>
      </div>
    </>
  );
}

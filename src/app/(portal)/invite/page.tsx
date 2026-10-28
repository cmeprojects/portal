// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { requireSession, PEOPLE_MANAGERS } from "@/lib/session";
import { canInvite, getPeopleRules } from "@/lib/settings";
import { Card, PageHeader } from "@/components/ui";
import { InviteForm } from "../settings/staff/forms";

export const metadata: Metadata = { title: "Invite staff" };

// For people allowed to invite who don't manage staff (for example team
// leaders, if the system admin allows it). Invites are always general.
export default async function InvitePage() {
  const { profile: me } = await requireSession();
  if (PEOPLE_MANAGERS.includes(me.role)) redirect("/settings/staff");
  if (!canInvite(me.role, await getPeopleRules())) redirect("/");
  return (
    <>
      <PageHeader
        title="Invite staff"
        intro="They'll get a welcome email to set up their account and start onboarding. A staff admin sets their role and team afterwards."
      />
      <Card className="p-5">
        <InviteForm roles={["new_starter"]} titles={[]} teams={null} />
      </Card>
    </>
  );
}

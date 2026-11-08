// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { Session } from "@/lib/session";

// cmeprojects: the system admin is never locked out by a switch, so they can
// see a module everyone else can't. Say so, so nothing is sent to staff who
// can't open it.
export function OffForStaff({ session, feature, name }: { session: Session; feature: string; name: string }) {
  if (session.profile.role !== "system_admin" || session.live[feature] !== false) return null;
  return (
    <p role="note" className="rounded-md border border-warn/40 bg-warn-soft px-4 py-3 text-sm text-ink print:hidden">
      <strong>{name} is switched off for everyone else.</strong> You can see it because you&apos;re the system admin.{" "}
      <Link href="/system?tab=features" className="font-semibold text-brand underline">
        Turn it on in Settings → Features
      </Link>{" "}
      when it&apos;s ready for staff.
    </p>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { SettingForm } from "../../system/forms";
import { withSettingDrafts } from "@/lib/drafts";
import { SLA_KEYS } from "@/lib/sla";
import { getMyAdminAreas } from "@/lib/settings";
import { notFound } from "next/navigation";

export const metadata: Metadata = { title: "SLA settings" };

const KEYS = SLA_KEYS;

// Managers, the system admin, and anyone looking after Task settings set the
// company's default due dates (the database checks this too).
export default async function SlaPage() {
  const { profile } = await requireRole(["manager", "system_admin", "staff_admin"]);
  if (profile.role === "staff_admin" && !(await getMyAdminAreas(profile.role)).includes("tasks")) notFound();
  const supabase = await createClient();
  const { data: settings } = await supabase
    .from("app_settings")
    .select("key, label, description, value")
    .in("key", KEYS);
  // Saved but not deployed: shown as they'll be (cmeprojects).
  const withDrafts = await withSettingDrafts(settings ?? []);
  const ordered = KEYS.flatMap((k) => withDrafts.filter((s) => s.key === k));

  return (
    <>
      <PageHeader
        title="SLA settings"
        intro="Due dates for new tasks, set by priority, with reminders and escalation. People can still choose another date."
      />
      <Card className="max-w-3xl px-5 py-2">
        {ordered.map((s) => (
          <SettingForm key={s.key} setting={s} />
        ))}
      </Card>
      <p className="text-sm text-muted">
        To give one register different due dates, open it from <Link href="/registers" className="text-brand underline">Registers</Link> and choose Set up.
      </p>
    </>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { SettingForm } from "../../system/forms";
import { withSettingDrafts } from "@/lib/drafts";

export const metadata: Metadata = { title: "Due dates (SLA)" };

const KEYS = [
  "tasks.sla_days",
  "tasks.sla_weekdays_only",
  "tasks.sla_remind_days",
  "tasks.sla_escalate_days",
  "tasks.sla_manager_summary",
];

// Managers and system admins set the company's default due dates.
export default async function SlaPage() {
  await requireRole(["manager", "system_admin"]);
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
      <SectionTabs section="settings" current="/settings/sla" />
      <PageHeader
        title="Due dates (SLA)"
        intro="Due dates for new tasks, set by priority. People can still choose another date."
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

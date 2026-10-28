// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader } from "@/components/ui";
import { FeatureSwitch, SettingForm } from "./forms";

export const metadata: Metadata = { title: "System settings" };

const SECTIONS = [
  { prefix: "brand.", title: "Branding", intro: "Company name, logo and colours, shown on every page and in emails." },
  { prefix: "wording.", title: "Wording", intro: "The words your company uses." },
  {
    prefix: "security.",
    title: "Security",
    intro: "Which roles need two-factor login while it's switched on. System admins always need it.",
  },
  {
    prefix: "people.",
    title: "People rules",
    intro: "Who needs a manager's approval, how people are invited, and what new starters can do.",
  },
  { prefix: "tasks.", title: "Tasks", intro: "Default due dates by priority. A register can set its own in its Set up page." },
  { prefix: "region.", title: "Region", intro: "" },
  { prefix: "records.", title: "Records", intro: "Records are never deleted when a feature is switched off." },
];

export default async function SystemPage() {
  await requireRole(["system_admin"]);
  const supabase = await createClient();
  const [{ data: features }, { data: settings }] = await Promise.all([
    supabase.from("features").select("key, label, description, enabled").order("sort_order"),
    supabase.from("app_settings").select("key, label, description, value").order("key"),
  ]);

  return (
    <>
      <PageHeader
        eyebrow="System"
        title="System settings"
        intro="Only system admins can see this page. Every change is recorded in the change log."
        action={<Link href="/system/audit" className="font-semibold text-brand">View change log</Link>}
      />

      {features?.find((f) => f.key === "two_factor")?.enabled === false ? (
        <Notice tone="error">
          Two-factor login is switched off. Nobody is asked for a code when signing in, including system admins. Turn it
          back on below before real staff start using the portal.
        </Notice>
      ) : null}

      <Card className="px-5 py-2">
        <h2 className="pt-3 heading-sm">Features</h2>
        <p className="text-sm text-muted">
          Switching a feature off hides it and blocks it in the database. Its records stay and can still be read.
        </p>
        <div className="mt-2">
          {(features ?? []).map((f) => (
            <FeatureSwitch key={f.key} feature={f} />
          ))}
        </div>
      </Card>

      {SECTIONS.map((section) => {
        const rows = (settings ?? []).filter((s) => s.key.startsWith(section.prefix));
        if (!rows.length) return null;
        return (
          <Card key={section.prefix} className="px-5 py-2">
            <h2 className="pt-3 heading-sm">{section.title}</h2>
            {section.intro ? <p className="text-sm text-muted">{section.intro}</p> : null}
            <div className="mt-2">
              {rows.map((s) => (
                <SettingForm key={s.key} setting={s} />
              ))}
            </div>
          </Card>
        );
      })}
    </>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader, Tabs } from "@/components/ui";
import { FeatureSwitch, SettingForm, type SettingRow } from "./forms";

export const metadata: Metadata = { title: "System settings" };

type Section = { title: string; intro?: string; keys: (key: string) => boolean };
type Tab = { key: string; label: string; sections: Section[] };

// Invites are always general now, so that switch isn't shown.
const HIDDEN = ["people.general_invites_only"];
const MESSAGES = ["brand.support_contact", "brand.announcement", "people.invite_message"];
// Settings that read best in a set order (others follow, A to Z).
const ORDER = [
  "brand.company_name",
  "brand.portal_name",
  "brand.logo_url",
  "brand.logo_mark_url",
  "brand.color_primary",
  "brand.color_dark",
  "brand.color_accent",
  "brand.support_contact",
  "brand.announcement",
  "people.invite_message",
  "security.mfa_required_roles",
  "security.mfa_app_enabled",
  "security.mfa_sms_enabled",
  "security.idle_minutes",
];
const rank = (k: string) => (ORDER.includes(k) ? ORDER.indexOf(k) : ORDER.length);

const TABS: Tab[] = [
  {
    key: "branding",
    label: "Branding",
    sections: [
      { title: "Name and logo", intro: "Shown on every page, the sign-in page and in emails.", keys: (k) => /^brand\.(company_name|portal_name|logo_url|logo_mark_url)$/.test(k) },
      { title: "Colours", keys: (k) => k.startsWith("brand.color_") },
      { title: "Wording", intro: "The words your company uses.", keys: (k) => k.startsWith("wording.") },
    ],
  },
  {
    key: "messages",
    label: "Messages",
    sections: [{ title: "Messages to staff", intro: "Leave any of these blank to hide them.", keys: (k) => MESSAGES.includes(k) }],
  },
  {
    key: "people",
    label: "People",
    sections: [
      { title: "People rules", intro: "Who needs a manager's approval, who can invite, and what new starters can do.", keys: (k) => k.startsWith("people.") && !MESSAGES.includes(k) },
      { title: "Compliance", intro: "Onboarding documents, trainings and uploads. Staff admins always manage them; you can add other roles.", keys: (k) => k.startsWith("compliance.") },
    ],
  },
  {
    key: "tasks",
    label: "Tasks",
    sections: [
      { title: "Tasks", intro: "Due dates, reminders, escalation and required fields. Managers can also change due dates on the Due dates (SLA) page.", keys: (k) => k.startsWith("tasks.") },
      { title: "Reports", keys: (k) => k.startsWith("reports.") },
    ],
  },
  {
    key: "security",
    label: "Security",
    sections: [
      { title: "Two-factor login", intro: "Which roles need it while it's switched on (system admins always do), and which methods people can use.", keys: (k) => k.startsWith("security.mfa") },
      { title: "Signing out", keys: (k) => k === "security.idle_minutes" },
    ],
  },
  { key: "features", label: "Features", sections: [] },
  {
    key: "general",
    label: "General",
    sections: [
      { title: "Region", keys: (k) => k.startsWith("region.") },
      { title: "Records", intro: "Records are never deleted when a feature is switched off.", keys: (k) => k.startsWith("records.") },
    ],
  },
];

export default async function SystemPage({ searchParams }: PageProps<"/system">) {
  await requireRole(["system_admin"]);
  const { tab: asked } = await searchParams;
  const tab = TABS.find((t) => t.key === asked) ?? TABS[0];
  const supabase = await createClient();
  const [{ data: features }, { data: settings }] = await Promise.all([
    supabase.from("features").select("key, label, description, enabled").order("sort_order"),
    supabase.from("app_settings").select("key, label, description, value").order("key"),
  ]);
  const rows = ((settings ?? []) as SettingRow[]).filter((s) => !HIDDEN.includes(s.key));

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
          Two-factor login is switched off. Nobody is asked for a code when signing in, including system admins. Turn it back on
          under Features before real staff start using the portal.
        </Notice>
      ) : null}

      <Tabs label="Settings" items={TABS.map((t) => ({ href: `/system?tab=${t.key}`, text: t.label, current: t.key === tab.key }))} />

      {tab.key === "features" ? (
        <Card className="px-5 py-2">
          <h2 className="pt-3 heading-sm">Features</h2>
          <p className="text-sm text-muted">Switching a feature off hides it and blocks it in the database. Its records stay and can still be read.</p>
          <div className="mt-2">
            {(features ?? []).map((f) => (
              <FeatureSwitch key={f.key} feature={f} />
            ))}
          </div>
        </Card>
      ) : (
        tab.sections.map((section) => {
          const list = rows.filter((s) => section.keys(s.key)).sort((x, y) => rank(x.key) - rank(y.key) || x.key.localeCompare(y.key));
          if (!list.length) return null;
          return (
            <Card key={section.title} className="px-5 py-2">
              <h2 className="pt-3 heading-sm">{section.title}</h2>
              {section.intro ? <p className="text-sm text-muted">{section.intro}</p> : null}
              <div className="mt-2">
                {list.map((s) => (
                  <SettingForm key={s.key} setting={s} />
                ))}
              </div>
            </Card>
          );
        })
      )}
    </>
  );
}

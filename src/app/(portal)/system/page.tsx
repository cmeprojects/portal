// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { redirect } from "next/navigation";
import { getMyAdminAreas } from "@/lib/settings";
import { AREAS, AREA_LABELS, type Area } from "@/lib/delegation";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader, Tabs } from "@/components/ui";
import { DelegationForm, FeatureSwitch, SettingForm, type SettingRow } from "./forms";

export const metadata: Metadata = { title: "System settings" };

// area: who can open it besides the system admin (none = system admin only).
type Section = { title: string; intro?: string; area?: Area; keys: (key: string) => boolean };
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
  "vehicles.manager_roles",
  "vehicles.report_roles",
  "vehicles.client_field",
  "vehicles.odo_photo",
  "vehicles.undo_minutes",
  "vehicles.reminder_hour",
  "vehicles.app_days",
];
const rank = (k: string) => (ORDER.includes(k) ? ORDER.indexOf(k) : ORDER.length);

const TABS: Tab[] = [
  {
    key: "branding",
    label: "Branding",
    sections: [
      { title: "Name and logo", intro: "Shown on every page, the sign-in page and in emails.", area: "branding", keys: (k) => /^brand\.(company_name|portal_name|logo_url|logo_mark_url)$/.test(k) },
      { title: "Colours", area: "branding", keys: (k) => k.startsWith("brand.color_") },
      { title: "Wording", intro: "The words your company uses.", area: "branding", keys: (k) => k.startsWith("wording.") },
    ],
  },
  {
    key: "messages",
    label: "Messages",
    sections: [{ title: "Messages to staff", intro: "Leave any of these blank to hide them.", area: "messages", keys: (k) => MESSAGES.includes(k) }],
  },
  {
    key: "people",
    label: "People",
    sections: [
      { title: "People rules", intro: "Who needs a manager's approval, who can invite, and what new starters can do.", area: "people", keys: (k) => k.startsWith("people.") && !MESSAGES.includes(k) },
      { title: "Compliance", intro: "Onboarding documents, trainings and uploads. Staff admins always manage them; you can add other roles.", area: "compliance", keys: (k) => k.startsWith("compliance.") },
    ],
  },
  {
    key: "tasks",
    label: "Tasks",
    sections: [
      { title: "Tasks", intro: "Due dates, reminders, escalation and required fields. Managers can also change due dates on the Due dates (SLA) page.", area: "tasks", keys: (k) => k.startsWith("tasks.") },
      { title: "Reports", area: "reports", keys: (k) => k.startsWith("reports.") },
    ],
  },
  {
    key: "cars",
    label: "Cars",
    sections: [
      {
        title: "Cars",
        intro: "Company cars and trips. Car managers add cars, clients and purposes of use, and choose whether trips have a client, on Manage cars. You can give these settings to a manager on the Delegation tab.",
        area: "vehicles",
        keys: (k) => k.startsWith("vehicles."),
      },
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
  { key: "delegation", label: "Delegation", sections: [] },
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
  const { profile } = await requireSession();
  const isAdmin = profile.role === "system_admin";
  const areas = await getMyAdminAreas(profile.role);
  // Delegated managers see only the sections they were given.
  const canSee = (sec: Section) => isAdmin || (sec.area !== undefined && areas.includes(sec.area));
  const tabs = TABS.filter((t) => (t.sections.length ? t.sections.some(canSee) : isAdmin));
  if (!tabs.length) redirect("/");
  const { tab: asked } = await searchParams;
  const tab = tabs.find((t) => t.key === asked) ?? tabs[0];
  const supabase = await createClient();
  const [{ data: features }, { data: settings }, { data: managers }, { data: delegations }] = await Promise.all([
    supabase.from("features").select("key, label, description, enabled").order("sort_order"),
    supabase.from("app_settings").select("key, label, description, value").order("key"),
    isAdmin ? supabase.from("profiles").select("id, full_name, email").eq("role", "manager").eq("active", true).order("full_name") : Promise.resolve({ data: [] }),
    isAdmin ? supabase.from("admin_delegations").select("user_id, areas") : Promise.resolve({ data: [] }),
  ]);
  const rows = ((settings ?? []) as SettingRow[]).filter((s) => !HIDDEN.includes(s.key));

  return (
    <>
      <PageHeader
        eyebrow="System"
        title="System settings"
        intro={
          isAdmin
            ? "Only system admins can see this page (and managers you delegate areas to). Every change is recorded in the change log."
            : "The areas the system admin has asked you to look after. Every change is recorded in the change log."
        }
        action={isAdmin || areas.includes("audit") ? <Link href="/system/audit" className="font-semibold text-brand">View change log</Link> : undefined}
      />

      {isAdmin && features?.find((f) => f.key === "two_factor")?.enabled === false ? (
        <Notice tone="error">
          Two-factor login is switched off. Nobody is asked for a code when signing in, including system admins. Turn it back on
          under Features before real staff start using the portal.
        </Notice>
      ) : null}

      <Tabs label="Settings" items={tabs.map((t) => ({ href: `/system?tab=${t.key}`, text: t.label, current: t.key === tab.key }))} />

      {tab.key === "delegation" ? (
        <Card className="flex flex-col gap-4 p-5">
          <div>
            <h2 className="heading-sm">Delegation</h2>
            <p className="text-sm text-muted">
              Let a named manager look after parts of System settings. Security, Features, General and Delegation always stay
              with you, and so does making system admins. Their changes show in the change log under their name.
            </p>
          </div>
          {(managers ?? []).length === 0 ? (
            <p className="text-sm text-muted">There are no active managers yet.</p>
          ) : (
            (managers ?? []).map((m) => (
              <DelegationForm
                key={m.id}
                manager={{ id: m.id, name: m.full_name || m.email }}
                areas={AREAS.map((a) => ({ key: a, label: AREA_LABELS[a] }))}
                current={((delegations ?? []).find((d) => d.user_id === m.id)?.areas ?? []) as string[]}
              />
            ))
          )}
        </Card>
      ) : tab.key === "features" ? (
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
        tab.sections.filter(canSee).map((section) => {
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

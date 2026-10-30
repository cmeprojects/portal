// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { redirect } from "next/navigation";
import { getMyAdminAreas } from "@/lib/settings";
import { AREAS, AREA_HINTS, AREA_LABELS, type Area } from "@/lib/delegation";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader, Tabs } from "@/components/ui";
import { IncludedSwitch } from "./builder/forms";
import { AppIconPicker, DelegationForm, FeatureSwitch, SettingForm, type SettingRow } from "./forms";

export const metadata: Metadata = { title: "System settings" };

// area: who can open it besides the system admin (none = system admin only).
type Section = { title: string; intro?: string; area?: Area; keys: (key: string) => boolean };
type Tab = { key: string; label: string; sections: Section[] };

// Invites are always general now, so that switch isn't shown.
const HIDDEN = ["people.general_invites_only", "vehicles.app_icon_uploads", "staff_app.icon_uploads", "vehicles.separate_app"];
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
  "reports.roles",
  "reports.compliance_roles",
  "security.mfa_required_roles",
  "security.mfa_app_enabled",
  "security.mfa_sms_enabled",
  "security.idle_minutes",
  "vehicles.manager_roles",
  "vehicles.report_roles",
  "vehicles.weekly_recipients",
  "vehicles.client_field",
  "vehicles.odo_photo",
  "vehicles.undo_minutes",
  "vehicles.reminder_hour",
  "vehicles.app_days",
  "vehicles.app_name",
  "vehicles.app_icon",
  "vehicles.separate_app",
  "staff_app.name",
  "staff_app.icon",
  "staff_app.cars",
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
      {
        title: "Compliance",
        intro: "Onboarding documents, trainings and uploads. Staff admins always manage them; you can add other roles. Who sees the Compliance report is here too (and on the Reports tab).",
        area: "compliance",
        keys: (k) => k.startsWith("compliance.") || k === "reports.compliance_roles",
      },
    ],
  },
  {
    key: "tasks",
    label: "Tasks",
    sections: [
      { title: "Tasks", intro: "Due dates, reminders, escalation and required fields. Managers can also change due dates on the Due dates (SLA) page.", area: "tasks", keys: (k) => k.startsWith("tasks.") },
    ],
  },
  {
    key: "reports",
    label: "Reports",
    sections: [
      {
        title: "Who sees which reports",
        intro: "The system admin always sees every report. Car reports are set on the Cars tab.",
        area: "reports",
        keys: (k) => k.startsWith("reports."),
      },
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
        keys: (k) => k.startsWith("vehicles.") && !k.startsWith("vehicles.app_"),
      },
      {
        title: "Cars app on the phone",
        intro: "What staff see on their home screen after adding the Cars app. Changes show on phones that add the app from now on.",
        area: "vehicles",
        keys: (k) => k.startsWith("vehicles.app_") || k === "vehicles.separate_app",
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
  {
    key: "staff-app",
    label: "Staff app",
    sections: [
      {
        title: "Staff app",
        intro: "One phone app for staff with the features you choose. Tick Show in the staff app on each feature in the Feature builder. Staff get it from the Apps page in the menu. With Cars in the Staff app, staff are only offered this one app (phones that already have the Cars app keep it working).",
        keys: (k) => k.startsWith("staff_app."),
      },
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
  const { features: on } = await requireSession();
  // Car settings only while Cars is switched on (and in the plan).
  const tabs = TABS.filter(
    (t) => (t.key !== "cars" || on.vehicles === true) && (t.key !== "staff-app" || on.staff_app === true) && (t.sections.length ? t.sections.some(canSee) : isAdmin),
  );
  if (!tabs.length) redirect("/");
  const { tab: asked } = await searchParams;
  const tab = tabs.find((t) => t.key === asked) ?? tabs[0];
  const supabase = await createClient();
  const [{ data: features }, { data: settings }, { data: managers }, { data: delegations }, { data: built }] = await Promise.all([
    supabase.from("features").select("*").order("sort_order"),
    supabase.from("app_settings").select("key, label, description, value").order("key"),
    supabase.from("profiles").select("id, full_name, email").eq("role", "manager").eq("active", true).order("full_name"),
    isAdmin ? supabase.from("admin_delegations").select("user_id, areas") : Promise.resolve({ data: [] }),
    isAdmin ? supabase.from("custom_features").select("id, name, status, enabled").order("sort_order").order("name") : Promise.resolve({ data: [] }),
  ]);
  const rows = ((settings ?? []) as SettingRow[]).filter((s) => !HIDDEN.includes(s.key));
  const uploadsOf = (key: string) => {
    const v = (settings ?? []).find((s) => s.key === key)?.value;
    return Array.isArray(v) ? (v as string[]) : [];
  };

  return (
    <>
      <SectionTabs section="settings" current="/system" />
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
                areas={AREAS.filter((a) => a !== "vehicles" || on.vehicles === true).map((a) => ({ key: a, label: AREA_LABELS[a], hint: AREA_HINTS[a] }))}
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
              <FeatureSwitch
                key={f.key}
                feature={{ key: f.key, label: f.label, description: f.description, enabled: f.enabled, premium: f.premium === true, included: f.included !== false }}
              />
            ))}
          </div>
          <div className="flex flex-wrap items-center justify-between gap-2 border-t border-line pt-4">
            <h3 className="font-semibold">Features you built</h3>
            <Link href="/system/builder" className="text-sm font-semibold text-brand underline">
              Open the Feature builder
            </Link>
          </div>
          <p className="text-sm text-muted">Premium add-ons made in the Feature builder. A new feature is a draft until you publish it; then switch it on or off here.</p>
          {(built ?? []).length === 0 ? <p className="py-3 text-sm text-muted">None yet. Make one, like Fluid intake, in the Feature builder.</p> : null}
          <ul className="mt-1 mb-2">
            {(built ?? []).map((f) => (
              <li key={f.id} className="flex flex-wrap items-center gap-3 border-t border-line py-3 first:border-t-0">
                <span className="min-w-48 flex-1">
                  <span className="flex flex-wrap items-center gap-2 font-semibold">
                    {f.name}
                    <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Premium</span>
                    {f.status === "published" ? null : <span className="rounded-full bg-page px-2 py-0.5 text-xs font-semibold text-muted">Draft</span>}
                  </span>
                  <span className="block text-sm text-muted">{f.status === "published" ? "Off hides it everywhere; entries are kept." : "Publish it in the Feature builder to switch it on."}</span>
                </span>
                <Link href={`/system/builder/${f.id}`} className="text-sm font-semibold text-brand underline">
                  Edit
                </Link>
                {f.status === "published" ? <IncludedSwitch id={f.id} enabled={f.enabled} /> : null}
              </li>
            ))}
          </ul>
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
                {list.map((s) =>
                  s.key === "vehicles.app_icon" || s.key === "staff_app.icon" ? (
                    <AppIconPicker
                      key={s.key}
                      setting={s}
                      which={s.key === "staff_app.icon" ? "staff" : "cars"}
                      uploads={uploadsOf(s.key === "staff_app.icon" ? "staff_app.icon_uploads" : "vehicles.app_icon_uploads")}
                    />
                  ) : (
                    <SettingForm key={s.key} setting={s} people={(managers ?? []).map((m) => ({ id: m.id, name: m.full_name || m.email }))} />
                  ),
                )}
              </div>
            </Card>
          );
        })
      )}
    </>
  );
}

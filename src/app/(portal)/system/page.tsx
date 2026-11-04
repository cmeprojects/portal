// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { redirect } from "next/navigation";
import { getMyAdminAreas } from "@/lib/settings";
import { AREAS, AREA_HINTS, AREA_LABELS, type Area } from "@/lib/delegation";
import { createClient } from "@/lib/supabase/server";
import { getDrafts, withSettingDrafts, type Draft } from "@/lib/drafts";
import { NOTIFICATION_GROUPS, asChannelMap, channelOn } from "@/lib/notification-catalogue";
import { ROLE_LABELS, isRole } from "@/lib/roles";
import { Card, Notice, PageHeader, Tabs } from "@/components/ui";
import { IncludedSwitch } from "./builder/forms";
import { PRESETS } from "./options";
import {
  AppIconPicker,
  DelegationPicker,
  DemoDataPanel,
  FeatureSwitch,
  LookedAfterBy,
  NotLiveBadge,
  NotificationGroupForm,
  PresetButtons,
  SettingForm,
  ShareAreaForm,
  SignOutEveryone,
  type DelegationValue,
  type PersonChoice,
  type SettingRow,
} from "./forms";

export const metadata: Metadata = { title: "System settings" };

// cmeprojects settings revamp. Tabs for the system admin: Features (one row
// per feature, with its parts and settings), Notifications, Delegation,
// General and Demo data. People given an area see only those settings.

// area: who can open it besides the system admin (none = system admin only).
type Section = { title: string; intro?: string; area?: Area; keys: (key: string) => boolean };

// One row on the Features tab. switches[0] is the main switch (unless always on); the rest are its parts.
type Row = {
  id: string;
  label: string;
  intro: string;
  always?: boolean;
  switches: string[];
  sections: Section[];
  areas: Area[];
  links?: { href: string; text: string }[];
};

// Settings shown elsewhere or not at all.
const HIDDEN = ["people.general_invites_only", "vehicles.app_icon_uploads", "staff_app.icon_uploads", "vehicles.separate_app", "notify.channels"];
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
  "vehicles.weekly_day",
  "vehicles.weekly_hour",
  "vehicles.weekly_period",
  "vehicles.client_field",
  "vehicles.odo_photo",
  "vehicles.undo_minutes",
  "vehicles.reminder_hour",
  "vehicles.app_days",
  "vehicles.app_name",
  "vehicles.app_icon",
  "staff_app.name",
  "staff_app.icon",
  "staff_app.cars",
];
const rank = (k: string) => (ORDER.includes(k) ? ORDER.indexOf(k) : ORDER.length);

const ROWS: Row[] = [
  {
    id: "tasks",
    label: "Tasks and registers",
    intro: "Always on. Due dates, reminders, escalation and required fields. Managers also set due dates on the Due dates (SLA) page.",
    always: true,
    switches: ["auto_escalation", "attachments"],
    sections: [{ title: "Task settings", area: "tasks", keys: (k) => k.startsWith("tasks.") }],
    areas: ["tasks", "registers"],
    links: [
      { href: "/settings/sla", text: "Due dates (SLA)" },
      { href: "/registers", text: "Registers" },
    ],
  },
  {
    id: "people",
    label: "People, clients and scoreboard",
    intro:
      "Always on: invite, give a role, change names, reset links, two-factor reset, Cars PIN, sign out of all devices, deactivate. Clients and the scoreboard are always on. Teams and Roles can be switched off; you can still manage them while they're off.",
    always: true,
    switches: ["teams", "roles"],
    sections: [{ title: "People rules", intro: "Approvals, who can invite, what new starters can do, who sees the scoreboard.", area: "people", keys: (k) => k.startsWith("people.") && !MESSAGES.includes(k) }],
    areas: ["people", "roles"],
  },
  {
    id: "compliance",
    label: "Compliance and onboarding",
    intro: "Each part can be switched off. My onboarding only shows while at least one part is on. A part that's off never holds up anyone's onboarding.",
    switches: ["compliance", "compliance_read", "compliance_training", "compliance_upload", "compliance_forms"],
    sections: [{ title: "Compliance settings", area: "compliance", keys: (k) => k.startsWith("compliance.") || k === "reports.compliance_roles" }],
    areas: ["compliance"],
    links: [{ href: "/compliance", text: "Compliance" }],
  },
  {
    id: "forms",
    label: "Forms",
    intro: "With the Form builder off, forms already published still work, and staff fill them in from the Forms menu.",
    switches: ["forms", "form_builder"],
    sections: [{ title: "Who can make and manage forms", intro: "The system admin always can.", keys: (k) => k.startsWith("forms.") }],
    areas: [],
    links: [{ href: "/forms", text: "Forms" }],
  },
  {
    id: "cars",
    label: "Cars and Cars app",
    intro: "Company cars and trips. Car managers add cars, clients and purposes on Manage cars.",
    switches: ["vehicles"],
    sections: [
      { title: "Cars", area: "vehicles", keys: (k) => k.startsWith("vehicles.") && !k.startsWith("vehicles.app_") && !k.startsWith("vehicles.weekly_") },
      { title: "Weekly mileage report", intro: "Who gets it, which day, from what hour, and what it covers.", area: "vehicles", keys: (k) => k.startsWith("vehicles.weekly_") },
    ],
    areas: ["vehicles"],
  },
  {
    id: "staff-app",
    label: "Staff app",
    intro: "One phone app for staff with the features you choose. Tick Show in the staff app on each built feature.",
    switches: ["staff_app"],
    sections: [
      { title: "Staff app", keys: (k) => k.startsWith("staff_app.") },
      // The Cars app's settings live with the phone apps (cmeprojects).
      { title: "Cars app on the phone", area: "vehicles", keys: (k) => k.startsWith("vehicles.app_") },
    ],
    areas: [],
  },
  {
    id: "assistant",
    label: "Website, Assistant and enquiries",
    intro: "They go together. Off: the sign-in page is the front page, and enquiries stop. Website settings stay open to you either way.",
    switches: ["assistant"],
    sections: [],
    areas: ["website"],
    links: [{ href: "/assistant", text: "Website settings" }],
  },
  {
    id: "reports",
    label: "Reports and exports",
    intro: "Each report only shows while its feature is on (car reports with Cars, the compliance report with Compliance).",
    switches: ["reports"],
    sections: [{ title: "Who sees which reports", area: "reports", keys: (k) => k.startsWith("reports.") && k !== "reports.compliance_roles" }],
    areas: ["reports"],
  },
  {
    id: "sign-in",
    label: "Sign-in",
    intro: "Two-factor login and the ways people can sign in.",
    switches: ["two_factor", "sign_in_magic_link", "sign_in_google"],
    sections: [{ title: "Two-factor login", intro: "Which roles need it (system admins always do) and which methods people can use.", keys: (k) => k.startsWith("security.mfa") }],
    areas: [],
  },
];

// Settings that aren't about one feature.
const GENERAL: Section[] = [
  { title: "Name and logo", intro: "Shown on every page, the sign-in page and in emails.", area: "branding", keys: (k) => /^brand\.(company_name|portal_name|logo_url|logo_mark_url)$/.test(k) },
  { title: "Colours", area: "branding", keys: (k) => k.startsWith("brand.color_") },
  { title: "Wording", intro: "The words your company uses.", area: "branding", keys: (k) => k.startsWith("wording.") },
  { title: "Messages to staff", intro: "Leave any of these blank to hide them.", area: "messages", keys: (k) => MESSAGES.includes(k) },
  { title: "Signing out", keys: (k) => k === "security.idle_minutes" },
  { title: "Region", keys: (k) => k.startsWith("region.") },
  { title: "Records", intro: "Records are never deleted when a feature is switched off.", keys: (k) => k.startsWith("records.") },
];

const ADMIN_TABS = [
  { key: "features", label: "Features" },
  { key: "notifications", label: "Notifications" },
  { key: "delegation", label: "Delegation" },
  { key: "general", label: "General" },
  { key: "demo", label: "Demo data" },
];

type FeatureRowData = { key: string; label: string; description: string | null; enabled: boolean; included?: boolean; premium?: boolean };

export default async function SystemPage({ searchParams }: PageProps<"/system">) {
  const { profile } = await requireSession();
  const isAdmin = profile.role === "system_admin";
  const areas = await getMyAdminAreas(profile.role);
  const canSee = (sec: Section) => isAdmin || (sec.area !== undefined && areas.includes(sec.area));
  const allSections = [...ROWS.flatMap((r) => r.sections), ...GENERAL];
  if (!isAdmin && !allSections.some(canSee) && !(profile.role === "manager" && areas.length)) redirect("/");

  const { tab: asked } = await searchParams;
  const tab = isAdmin ? (ADMIN_TABS.find((t) => t.key === asked) ?? ADMIN_TABS[0]).key : "mine";
  const supabase = await createClient();
  const [{ data: features }, { data: settings }, { data: people }, rulesResult, { data: built }, drafts] = await Promise.all([
    supabase.from("features").select("*").order("sort_order"),
    supabase.from("app_settings").select("key, label, description, value").order("key"),
    supabase.from("profiles").select("id, full_name, email, role").in("role", ["manager", "staff_admin"]).eq("active", true).order("full_name"),
    isAdmin ? supabase.from("delegation_rules").select("area, mode, people") : Promise.resolve({ data: [], error: null }),
    isAdmin ? supabase.from("custom_features").select("id, name, status, enabled").order("sort_order").order("name") : Promise.resolve({ data: [] }),
    getDrafts(),
  ]);
  const rows = (await withSettingDrafts((settings ?? []) as SettingRow[])).filter((s) => !HIDDEN.includes(s.key));
  const uploadsOf = (key: string) => {
    const v = (settings ?? []).find((s) => s.key === key)?.value;
    return Array.isArray(v) ? (v as string[]) : [];
  };
  const draftOf = (kind: Draft["kind"], key: string) => drafts.find((d) => d.kind === kind && d.key === key);

  // A feature as it will be once deployed.
  const featureState = (key: string) => {
    const f = (features ?? []).find((x) => x.key === key) as FeatureRowData | undefined;
    if (!f) return null;
    const d = draftOf("feature", key);
    const on = d ? (d.value as { enabled?: boolean }).enabled === true : f.enabled && f.included !== false;
    return { key, label: f.label, description: f.description, on, pending: Boolean(d), premium: f.premium === true };
  };

  const choices: PersonChoice[] = (people ?? []).map((p) => ({ id: p.id, name: p.full_name || p.email, role: isRole(p.role) ? ROLE_LABELS[p.role] : p.role }));
  const rulesMissing = isAdmin && Boolean(rulesResult.error);
  const delegation = (area: Area): { value: DelegationValue; pending: boolean } => {
    const d = draftOf("delegation", area);
    const live = (rulesResult.data ?? []).find((r: { area: string }) => r.area === area) as { mode: DelegationValue["mode"]; people: string[] } | undefined;
    const v = (d?.value ?? live ?? { mode: "admin", people: [] }) as DelegationValue;
    return { value: { mode: v.mode ?? "admin", people: v.people ?? [] }, pending: Boolean(d) };
  };

  const settingsFor = (sec: Section, scope: string) => {
    const list = rows.filter((s) => sec.keys(s.key)).sort((x, y) => rank(x.key) - rank(y.key) || x.key.localeCompare(y.key));
    if (!list.length) return null;
    return (
      <div key={`${scope}-${sec.title}`} className="flex flex-col">
        <h3 className="pt-3 font-semibold">{sec.title}</h3>
        {sec.intro ? <p className="text-sm text-muted">{sec.intro}</p> : null}
        <div className="mt-1">
          {list.map((s) =>
            s.key === "vehicles.app_icon" || s.key === "staff_app.icon" ? (
              <AppIconPicker
                key={s.key}
                setting={s}
                which={s.key === "staff_app.icon" ? "staff" : "cars"}
                uploads={uploadsOf(s.key === "staff_app.icon" ? "staff_app.icon_uploads" : "vehicles.app_icon_uploads")}
              />
            ) : (
              <SettingForm key={s.key} setting={s} people={choices.filter((c) => c.role === ROLE_LABELS.manager)} />
            ),
          )}
        </div>
      </div>
    );
  };

  // Managers can share their areas with staff admins (cmeprojects).
  const SHAREABLE: Area[] = ["branding", "messages", "people", "compliance", "tasks", "reports", "vehicles", "website", "registers"];
  const myShareable = profile.role === "manager" ? areas.filter((a) => SHAREABLE.includes(a)) : [];
  const { data: shares } = myShareable.length ? await supabase.from("delegation_shares").select("area, user_id") : { data: [] };
  const staffAdmins = choices.filter((c) => c.role === ROLE_LABELS.staff_admin);

  const two = featureState("two_factor");
  const tabs = ADMIN_TABS.map((t) => ({ href: `/system?tab=${t.key}`, text: t.label, current: t.key === tab }));

  return (
    <>
      <SectionTabs section="settings" current="/system" />
      <PageHeader
        eyebrow="System"
        title="System settings"
        intro={
          isAdmin
            ? "Saving keeps a change as a draft. Press Deploy (in the yellow bar) to make saved changes live together. Every change is in the change log."
            : "The areas the system admin has asked you to look after. Saved changes go live when you deploy them."
        }
      />

      {isAdmin && two && !two.on ? (
        <Notice tone="error">
          Two-factor login is switched off. Nobody is asked for a code when signing in, including system admins. Turn it back on under
          Features → Sign-in before real staff start using the portal.
        </Notice>
      ) : null}
      {rulesMissing ? <Notice tone="error">Run the latest database update (update 46) to use Delegation and Deploy.</Notice> : null}

      {isAdmin ? <Tabs label="Settings" items={tabs} /> : null}

      {tab === "features" ? (
        <>
          <Card className="flex flex-col gap-3 px-5 py-4">
            <div>
              <h2 className="heading-sm">Packages</h2>
              <p className="text-sm text-muted">One press sets the main switches to match a budget. You can still change them one by one below.</p>
            </div>
            <PresetButtons presets={Object.entries(PRESETS).map(([key, p]) => ({ key, label: p.label, hint: p.hint }))} />
          </Card>
          <div className="flex flex-col gap-3">
            {ROWS.map((row) => {
              const states = row.switches.map(featureState).filter((f): f is NonNullable<ReturnType<typeof featureState>> => Boolean(f));
              const main = row.always ? null : states[0];
              const parts = row.always ? states : states.slice(1);
              const rowPending =
                states.some((s) => s.pending) ||
                row.sections.some((sec) => rows.some((r) => sec.keys(r.key) && r.pending)) ||
                row.areas.some((a) => delegation(a).pending);
              return (
                <Card key={row.id} className="p-0">
                  <details name="feature-row" className="group">
                    <summary className="flex min-h-16 cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 [&::-webkit-details-marker]:hidden">
                      <span className="min-w-48 flex-1">
                        <span className="flex flex-wrap items-center gap-2 font-semibold">
                          {row.label}
                          {main?.premium ? <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Premium</span> : null}
                          {rowPending ? <NotLiveBadge /> : null}
                        </span>
                        <span className="block text-sm text-muted">{row.intro}</span>
                      </span>
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-semibold ${row.always || main?.on ? "bg-good-soft text-ink" : "bg-page text-muted"}`}
                      >
                        {row.always ? "Always on" : main?.on ? "On" : "Off"}
                      </span>
                      <span className="text-sm font-semibold text-brand group-open:hidden">Open</span>
                      <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                    </summary>
                    <div className="flex flex-col gap-1 border-t border-line px-5 pb-5">
                      {main ? <FeatureSwitch feature={main} /> : null}
                      {parts.length ? (
                        <div className="divide-y divide-line rounded-md border border-line px-3">
                          {parts.map((p) => (
                            <FeatureSwitch key={p.key} feature={p} part={Boolean(main)} />
                          ))}
                        </div>
                      ) : null}
                      {row.id === "assistant" || row.id === "tasks" || row.links ? (
                        <p className="flex flex-wrap gap-x-4 pt-2 text-sm">
                          {(row.links ?? []).map((l) => (
                            <Link key={l.href} href={l.href} className="font-semibold text-brand underline">
                              Open {l.text}
                            </Link>
                          ))}
                        </p>
                      ) : null}
                      {row.areas.length && !rulesMissing ? (
                        <div className="flex flex-col gap-1 pt-2">
                          {row.areas.map((a) => (
                            <LookedAfterBy key={a} area={a} label={AREA_LABELS[a]} hint={AREA_HINTS[a]} {...delegation(a)} choices={choices} />
                          ))}
                        </div>
                      ) : null}
                      {row.sections.map((sec) => settingsFor(sec, row.id))}
                    </div>
                  </details>
                </Card>
              );
            })}
            <Card className="p-0">
              <details name="feature-row" className="group">
                <summary className="flex min-h-16 cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 [&::-webkit-details-marker]:hidden">
                  <span className="min-w-48 flex-1">
                    <span className="flex flex-wrap items-center gap-2 font-semibold">
                      Built features
                      <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Premium</span>
                    </span>
                    <span className="block text-sm text-muted">
                      Made in the Feature builder. Only you build them; what managers may manage is set on each feature. These switches act straight away.
                    </span>
                  </span>
                  <span className="text-sm font-semibold text-brand group-open:hidden">Open</span>
                  <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                </summary>
                <div className="border-t border-line px-5 pb-4">
                  <p className="pt-3 text-sm">
                    <Link href="/system/builder" className="font-semibold text-brand underline">
                      Open the Feature builder
                    </Link>
                  </p>
                  {(built ?? []).length === 0 ? <p className="py-3 text-sm text-muted">None yet. Make one, like Fluid intake, in the Feature builder.</p> : null}
                  <ul className="mt-1">
                    {(built ?? []).map((f) => (
                      <li key={f.id} className="flex flex-wrap items-center gap-3 border-t border-line py-3 first:border-t-0">
                        <span className="min-w-48 flex-1 font-semibold">
                          {f.name} {f.status === "published" ? null : <span className="rounded-full bg-page px-2 py-0.5 text-xs font-semibold text-muted">Draft</span>}
                        </span>
                        <Link href={`/system/builder/${f.id}`} className="text-sm font-semibold text-brand underline">
                          Edit
                        </Link>
                        {f.status === "published" ? <IncludedSwitch id={f.id} enabled={f.enabled} /> : null}
                      </li>
                    ))}
                  </ul>
                </div>
              </details>
            </Card>
          </div>
        </>
      ) : tab === "notifications" ? (
        <>
          {(() => {
            const email = featureState("email_notifications");
            return email ? (
              <Card className="px-5 py-2">
                <FeatureSwitch feature={{ ...email, label: "Emails", description: "Main switch for every email the portal sends. The bell still works when it's off." }} />
              </Card>
            ) : null;
          })()}
          <div className="flex flex-col gap-3">
            {NOTIFICATION_GROUPS.filter((g) => !g.feature || featureState(g.feature)?.on).map((g) => {
              const setting = rows.find((r) => r.key === "notify.channels") ?? (settings ?? []).find((r) => r.key === "notify.channels");
              const d = draftOf("setting", "notify.channels");
              const map = asChannelMap(d ? d.value : setting?.value);
              return (
                <Card key={g.key} className="p-0">
                  <details name="notification-group" className="group">
                    <summary className="flex min-h-14 cursor-pointer list-none flex-wrap items-center gap-3 px-5 py-3 [&::-webkit-details-marker]:hidden">
                      <span className="min-w-48 flex-1 font-semibold">{g.label}</span>
                      {d ? <NotLiveBadge /> : null}
                      <span className="text-sm text-muted">
                        {g.items.filter((i) => i.channels.some((c) => channelOn(map, i.code, c))).length} of {g.items.length} on
                      </span>
                      <span className="text-sm font-semibold text-brand group-open:hidden">Open</span>
                      <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                    </summary>
                    <div className="border-t border-line px-5 pb-4">
                      <NotificationGroupForm
                        group={g.key}
                        items={g.items.map((i) => ({ ...i, bell: channelOn(map, i.code, "bell"), email: channelOn(map, i.code, "email") }))}
                      />
                    </div>
                  </details>
                </Card>
              );
            })}
          </div>
          <p className="text-sm text-muted">Groups for features that are off aren&apos;t shown: nothing is sent for them.</p>
        </>
      ) : tab === "delegation" ? (
        <Card className="flex flex-col gap-1 px-5 py-4">
          <h2 className="heading-sm">Delegation</h2>
          <p className="text-sm text-muted">
            Who looks after each area besides you: all managers, or the managers and staff admins you choose. Security, Features,
            Notifications, Demo data and General always stay with you, and so does making system admins.
          </p>
          {rulesMissing ? null : (
            <div className="mt-2 flex flex-col divide-y divide-line">
              {AREAS.filter((a) => a !== "vehicles" || featureState("vehicles")?.on).map((a) => (
                <div key={a} className="py-4">
                  <DelegationPicker area={a} label={AREA_LABELS[a]} hint={AREA_HINTS[a]} {...delegation(a)} choices={choices} />
                </div>
              ))}
            </div>
          )}
        </Card>
      ) : tab === "demo" ? (
        <Card className="px-5 py-4">
          <h2 className="mb-1 heading-sm">Demo data</h2>
          <p className="mb-4 text-sm text-muted">For showing the portal to someone. Sample records are tracked, so they can be removed without touching real work. These act straight away.</p>
          <DemoDataPanel />
        </Card>
      ) : (
        // General (system admin), or everything a delegated person looks after.
        <>
          {(tab === "general" ? GENERAL : allSections)
            .filter(canSee)
            .map((sec) => {
              const body = settingsFor(sec, tab);
              return body ? (
                <Card key={sec.title} className="px-5 py-2">
                  {body}
                </Card>
              ) : null;
            })}
          {tab === "mine" && myShareable.length ? (
            <Card className="px-5 py-4">
              <h2 className="mb-1 heading-sm">Share with staff admins</h2>
              <p className="mb-2 text-sm text-muted">
                Staff admins you tick also look after that area, for as long as you do. Roles and the change log can&apos;t be shared. This acts
                straight away.
              </p>
              {staffAdmins.length === 0 ? (
                <p className="text-sm text-muted">There are no active staff admins.</p>
              ) : (
                myShareable.map((a) => (
                  <ShareAreaForm
                    key={a}
                    area={a}
                    label={AREA_LABELS[a]}
                    staff={staffAdmins.map((p) => ({ id: p.id, name: p.name }))}
                    current={(shares ?? []).filter((x) => x.area === a).map((x) => x.user_id as string)}
                  />
                ))
              )}
            </Card>
          ) : null}
          {tab === "general" ? (
            <Card className="px-5 py-4">
              <h2 className="mb-1 heading-sm">Sign everyone out</h2>
              <p className="mb-4 text-sm text-muted">
                For a security worry, like a lost phone or a shared password. Everyone is signed out of every device within a minute, except you
                on this device. Accounts stay active. This acts straight away.
              </p>
              <SignOutEveryone />
            </Card>
          ) : null}
        </>
      )}
    </>
  );
}

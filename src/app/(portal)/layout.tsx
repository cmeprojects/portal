// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getPeople, getRegistries } from "@/lib/register-data";
import { refLabel } from "@/lib/registers";
import { getIdleMinutes, getTimeZone } from "@/lib/settings";
import { IdleLogout } from "@/components/idle-logout";
import { formatDue, todayIn } from "@/lib/tasks";
import { Bell, type BellItem } from "@/components/bell";
import { getBranding } from "@/lib/branding";
import { ROLE_LABELS } from "@/lib/roles";
import { BrandMark } from "@/components/brand-mark";
import { Sidebar } from "@/components/sidebar";
import { ThemeSwitch } from "@/components/theme-switch";
import { navFor } from "@/components/nav";
import { getNavAccess } from "@/lib/nav-access";
import { signOut } from "@/app/login/actions";
import { LiveRefresh } from "@/components/live-refresh";
import { DeployBar } from "@/components/deploy-bar";
import { describeDrafts, getDrafts } from "@/lib/drafts";
import { asChannelMap, channelOn, type ChannelMap } from "@/lib/notification-catalogue";

// Frame for every page after sign-in: the company's sidebar on desktop, a top
// bar with a drop-down menu on phones.
export default async function PortalLayout({ children }: LayoutProps<"/">) {
  const [{ profile, features }, brand, idleMinutes, { data: claims }] = await Promise.all([
    requireSession(),
    getBranding(),
    getIdleMinutes(),
    (await createClient()).auth.getClaims(),
  ]);
  // When they last signed in (password, link or code): the inactivity timer never starts earlier than this.
  const signedInAt = Math.max(0, ...((claims?.claims?.amr ?? []) as { timestamp?: number }[]).map((a) => (a.timestamp ?? 0) * 1000));
  // Which bell notifications are switched on (Settings → Notifications, cmeprojects).
  const channels = await getChannels();
  const bellOn = (code: string) => channelOn(channels, code, "bell");
  const [taskItems, requestItems, notices] = await Promise.all([
    features.tasks !== false ? newTasksForMe(bellOn) : Promise.resolve([]),
    bellOn("people_request") ? requestUpdatesForMe() : Promise.resolve([]),
    noticesForMe(),
  ]);
  const bellItems = [...notices, ...requestItems, ...taskItems];
  // Settings saved but not deployed yet (only people who can change settings have any).
  const draftLines = ["system_admin", "manager", "staff_admin"].includes(profile.role) ? await describeDrafts(await getDrafts()) : [];
  // Their role changed (while signed in): a banner until they've seen it.
  const roleChange = notices.find((n) => n.kind === "role_changed" && !n.read);

  const footer = (
    <div className="flex flex-wrap items-center justify-between gap-3 md:flex-col md:items-start">
      <div className="min-w-0 text-sm">
        <p className="truncate font-medium text-side-fg">{profile.full_name || profile.email}</p>
        <p className="text-xs text-side-muted">{ROLE_LABELS[profile.role]}</p>
      </div>
      <form action={signOut}>
        <button className="min-h-9 text-xs text-side-muted underline hover:text-side-fg">Sign out</button>
      </form>
      <ThemeSwitch />
      <p className="text-[11px] text-side-muted">
        Built by cmeproject ·{" "}
        <Link href="/about" className="underline hover:text-side-fg">
          About
        </Link>
      </p>
    </div>
  );

  return (
    <div className="min-h-screen md:grid md:grid-cols-[230px_minmax(0,1fr)] print:block">
      <Sidebar
        groups={navFor(profile.role, features, await getNavAccess(profile.role))}
        brandMark={<BrandMark brand={brand} />}
        bell={<Bell items={bellItems} />}
        footer={footer}
      />
      <IdleLogout minutes={idleMinutes} signedInAt={signedInAt} />
      {/* Menus, settings, the bell and task lists stay current; pages refresh when you come back to them. */}
      <LiveRefresh tables={["app_settings", "features", "live_signals", "notifications", "tasks", "people_change_requests", "profiles"]} onShow />
      <main className="mx-auto flex w-full max-w-6xl min-w-0 flex-col gap-6 px-4 py-6 md:px-8 md:py-8 print:max-w-none print:gap-4 print:p-0">
        {/* cmeprojects: which copy this is (set NEXT_PUBLIC_ENV_LABEL in Vercel, e.g. DEVELOPMENT or DEMO). */}
        {process.env.NEXT_PUBLIC_ENV_LABEL ? (
          <div role="note" className="rounded-md bg-warn-soft px-3 py-1.5 text-center text-xs font-semibold tracking-widest text-warn uppercase print:hidden">
            {process.env.NEXT_PUBLIC_ENV_LABEL} copy · not for real client data
          </div>
        ) : null}
        {roleChange ? (
          <div role="status" className="flex flex-wrap items-center gap-3 rounded-lg border border-good/40 bg-good-soft px-4 py-3 text-sm text-ink print:hidden">
            <span className="min-w-0 flex-1">
              <strong>{roleChange.title}.</strong> Your menu has been updated to show what you can use now.
            </span>
            <Link href={roleChange.href} className="font-semibold text-brand underline">
              Got it
            </Link>
          </div>
        ) : null}
        {brand.announcement ? (
          <div role="status" className="rounded-lg border border-brand/30 bg-brand-soft px-4 py-3 text-sm whitespace-pre-line text-ink print:hidden">
            {brand.announcement}
          </div>
        ) : null}
        <DeployBar items={draftLines} />
        {children}
      </main>
    </div>
  );
}

const ALERT_WORDS: Record<string, string> = {
  reminder: "Due soon",
  due_today: "Due today",
  overdue: "Overdue",
  escalated: "Escalated",
};

// Tasks newly given to the signed-in person, and due date alerts, newest
// first, for the bell.
const ALERT_CODES: Record<string, string> = { reminder: "task_reminder", due_today: "task_due_today", overdue: "task_overdue", escalated: "task_escalated" };

async function newTasksForMe(bellOn: (code: string) => boolean): Promise<BellItem[]> {
  const supabase = await createClient();
  const [{ data }, { data: alertRows }] = await Promise.all([supabase.rpc("my_new_tasks"), supabase.rpc("my_due_alerts")]);
  const fresh = ((data ?? []) as { task_id: string; kind: "assigned" | "helping"; actor_id: string | null; at: string }[]).filter((f) =>
    bellOn(f.kind === "helping" ? "helper_added" : "task_assigned"),
  );
  const alerts = ((alertRows ?? []) as { task_id: string; step: string; at: string }[]).filter((a) => bellOn(ALERT_CODES[a.step] ?? "task_reminder"));
  if (!fresh.length && !alerts.length) return [];
  const ids = [...new Set([...fresh.map((f) => f.task_id), ...alerts.map((a) => a.task_id)])];
  const [{ data: tasks }, registries, people, timeZone] = await Promise.all([
    supabase.from("tasks").select("id, ref_number, title, registry_id, due_date").in("id", ids),
    getRegistries(),
    getPeople(),
    getTimeZone(),
  ]);
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  const refOf = (t: { registry_id: string; ref_number: number }) =>
    refLabel(registries.find((r) => r.id === t.registry_id)?.prefix, t.ref_number);

  const items: (BellItem & { at: string })[] = [];
  for (const a of alerts) {
    const t = (tasks ?? []).find((x) => x.id === a.task_id);
    if (!t) continue;
    const late = a.step === "overdue" || a.step === "escalated";
    items.push({
      key: `due-${t.id}`,
      href: `/tasks/${t.id}`,
      title: `${ALERT_WORDS[a.step] ?? "Due"}: ${t.title}`,
      detail: `${refOf(t)} · ${formatDue(t.due_date, todayIn(timeZone), "assigned")}`,
      tone: late ? "danger" : undefined,
      at: a.at,
    });
  }
  for (const f of fresh) {
    const t = (tasks ?? []).find((x) => x.id === f.task_id);
    if (!t || items.some((i) => i.key === `due-${t.id}`)) continue;
    const by = people.find((p) => p.id === f.actor_id)?.name ?? "Admin";
    items.push({
      key: `task-${t.id}`,
      href: `/tasks/${t.id}`,
      title: t.title,
      detail: `${refOf(t)} · ${f.kind === "helping" ? "Help needed" : "For you to look after"} · From ${by} · ${when.format(new Date(f.at))}`,
      at: f.at,
    });
  }
  return items.sort((a, b) => (a.at < b.at ? 1 : -1));
}

// Managers' answers to role and team changes the signed-in person asked for.
async function requestUpdatesForMe(): Promise<BellItem[]> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("my_request_updates");
  const rows = (data ?? []) as {
    request_id: string;
    kind: "role" | "team";
    status: "approved" | "declined";
    subject: string;
    change: string;
    decided_by_name: string;
    decided_at: string;
    note: string;
  }[];
  if (!rows.length) return [];
  const timeZone = await getTimeZone();
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  return rows.map((r) => {
    const what = r.kind === "role" ? `${r.subject} → ${r.change}` : `${r.subject}: ${r.change}`;
    return {
      key: `request-${r.request_id}`,
      href: r.kind === "role" ? "/settings/staff" : "/settings/teams",
      title: `${r.status === "approved" ? "Approved" : "Declined"}: ${what}`,
      detail: `${r.kind === "role" ? "Role" : "Team"} change · by ${r.decided_by_name} · ${when.format(new Date(r.decided_at))}${r.note ? ` · “${r.note}”` : ""}`,
      tone: r.status === "approved" ? "good" : "danger",
    };
  });
}

const NOTICE_TONE: Record<string, BellItem["tone"]> = {
  upload_rejected: "danger",
  document_expired: "danger",
  approval_needed: "danger",
  onboarded: "good",
};

// Onboarding, Compliance and people notices for the signed-in person.
async function noticesForMe(): Promise<(BellItem & { kind?: string })[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("notifications")
    .select("id, kind, title, body, created_at, seen_at")
    // Read ones stay for 30 days (cmeprojects); unread ones always show.
    .or(`seen_at.is.null,created_at.gte.${new Date(Date.now() - 30 * 86_400_000).toISOString()}`)
    .order("created_at", { ascending: false })
    .limit(40);
  if (!data?.length) return [];
  const timeZone = await getTimeZone();
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  return data.map((n) => ({
    kind: n.kind,
    key: `notice-${n.id}`,
    href: `/n/${n.id}`,
    title: n.title,
    detail: [n.body, when.format(new Date(n.created_at))].filter(Boolean).join(" · "),
    tone: NOTICE_TONE[n.kind],
    read: Boolean(n.seen_at),
  }));
}

// The live notification switches (only what's been switched off is stored).
async function getChannels(): Promise<ChannelMap> {
  const { data } = await (await createClient()).from("app_settings").select("value").eq("key", "notify.channels").maybeSingle();
  return asChannelMap(data?.value);
}

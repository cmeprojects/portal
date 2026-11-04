// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { createAdminClient } from "@/lib/supabase/admin";
import { assistantUsage } from "@/lib/assistant";
import { getTimeZone } from "@/lib/settings";
import { ROLE_LABELS, ROLES, isRole } from "@/lib/roles";
import { Card, PageHeader } from "@/components/ui";

// cmeprojects: the system admin's home. The system admin is never given
// tasks, so this shows how the platform is doing: people, sign-ins, activity,
// emails, the Assistant's spending and recent changes. Tasks are under Tasks.

const DAY = 86_400_000;

function Stat({ label, value, note, href }: { label: string; value: string | number; note?: string; href?: string }) {
  const body = (
    <Card className="flex h-full flex-col gap-1 p-4">
      <span className="text-sm text-muted">{label}</span>
      <span className="text-3xl font-semibold tabular-nums">{value}</span>
      {note ? <span className="text-xs text-muted">{note}</span> : null}
    </Card>
  );
  return href ? (
    <Link href={href} className="block rounded-lg hover:ring-2 hover:ring-brand/30">
      {body}
    </Link>
  ) : (
    body
  );
}

// A simple bar chart (no library): one bar per label.
function Bars({ title, rows, unit }: { title: string; rows: { label: string; value: number }[]; unit: string }) {
  const max = Math.max(1, ...rows.map((r) => r.value));
  return (
    <Card className="flex flex-col gap-3 p-5">
      <h2 className="heading-sm">{title}</h2>
      <ul className="flex flex-col gap-2" aria-label={title}>
        {rows.map((r) => (
          <li key={r.label} className="grid grid-cols-[7rem_1fr_3rem] items-center gap-3 text-sm">
            <span className="truncate text-muted">{r.label}</span>
            <span className="h-3 overflow-hidden rounded-full bg-page" aria-hidden="true">
              <span className="block h-full rounded-full bg-brand" style={{ width: `${(r.value / max) * 100}%` }} />
            </span>
            <span className="text-right tabular-nums" aria-label={`${r.value} ${unit}`}>
              {r.value}
            </span>
          </li>
        ))}
      </ul>
    </Card>
  );
}

export async function PlatformDashboard({ name }: { name: string }) {
  const d = await loadPlatform();
  return <PlatformView name={name} d={d} />;
}

// Everything the dashboard shows, read with the server key (system admin only).
async function loadPlatform() {
  const admin = createAdminClient();
  const now = Date.now();
  const since30 = new Date(now - 30 * DAY).toISOString();
  const since56 = new Date(now - 56 * DAY).toISOString();
  const [{ data: people }, users, { data: tasks }, { count: bells }, { data: emails }, { data: changes }, { data: features }, { count: drafts }, usage, timeZone] =
    await Promise.all([
      admin.from("profiles").select("id, role, active"),
      admin.auth.admin.listUsers({ perPage: 1000 }).then((r) => r.data?.users ?? []).catch(() => []),
      admin.from("tasks").select("created_at, status").gte("created_at", since56),
      admin.from("notifications").select("id", { count: "exact", head: true }).gte("created_at", since30),
      admin.from("email_outbox").select("sent_at, last_error").gte("created_at", since30),
      admin.from("audit_log").select("id, action, entity_id, created_at").order("created_at", { ascending: false }).limit(6),
      admin.from("features").select("key, label, enabled, included, premium, parent").order("sort_order"),
      admin.from("settings_drafts").select("key", { count: "exact", head: true }),
      assistantUsage().catch(() => null),
      getTimeZone(),
    ]);

  const active = (people ?? []).filter((p) => p.active);
  const byRole = ROLES.filter((r) => r !== "system_admin")
    .map((r) => ({ label: ROLE_LABELS[r].split(" (")[0], value: active.filter((p) => isRole(p.role) && p.role === r).length }))
    .filter((r) => r.value > 0);
  const signedIn = (days: number) => users.filter((u) => u.last_sign_in_at && now - new Date(u.last_sign_in_at).getTime() < days * DAY).length;
  const neverJoined = users.filter((u) => !u.last_sign_in_at).length;

  // Tasks created each week, for the last 8 weeks.
  const weeks = Array.from({ length: 8 }, (_, i) => {
    const end = now - i * 7 * DAY;
    const start = end - 7 * DAY;
    const n = (tasks ?? []).filter((t) => {
      const at = new Date(t.created_at).getTime();
      return at >= start && at < end;
    }).length;
    const label = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", timeZone }).format(new Date(start));
    return { label: `Week of ${label}`, value: n };
  }).reverse();

  const sent = (emails ?? []).filter((e) => e.sent_at).length;
  const failed = (emails ?? []).filter((e) => !e.sent_at && e.last_error).length;
  const waiting = (emails ?? []).filter((e) => !e.sent_at && !e.last_error).length;
  const main = (features ?? []).filter((f) => !f.parent && f.premium);
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  return { people, active, users, signed7: signedIn(7), signed30: signedIn(30), neverJoined, weeks, byRole, bells, sent, failed, waiting, usage, main, changes: (changes ?? []).map((c) => ({ ...c, at: when.format(new Date(c.created_at)) })), drafts };
}

function PlatformView({ name, d }: { name: string; d: Awaited<ReturnType<typeof loadPlatform>> }) {
  const { people, active, neverJoined, weeks, byRole, bells, sent, failed, waiting, usage, main, changes, drafts } = d;
  return (
    <>
      <PageHeader
        title={`Platform${name ? ` · ${name.split(" ")[0]}` : ""}`}
        intro="How the portal is doing. You're never given tasks; see Tasks in the menu for everyone's work."
      />
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Stat label="Active people" value={active.length} note={`${(people ?? []).length - active.length} deactivated`} href="/settings/staff" />
        <Stat label="Signed in, last 7 days" value={d.signed7} note={`${d.signed30} in the last 30 days`} />
        <Stat label="Invited, not joined yet" value={neverJoined} href="/settings/staff" />
        <Stat label="Settings not live yet" value={drafts ?? 0} note="Saved, waiting for Deploy" href="/system" />
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <Bars title="Tasks created each week" rows={weeks} unit="tasks" />
        <Bars title="Active people by access level" rows={byRole.length ? byRole : [{ label: "Nobody yet", value: 0 }]} unit="people" />
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Stat label="Bell notifications, 30 days" value={bells ?? 0} />
        <Stat label="Emails sent, 30 days" value={sent} note={`${waiting} waiting · ${failed} failed`} href="/system/health" />
        <Stat label="Assistant this month" value={usage ? `A$${usage.monthAud.toFixed(2)}` : "–"} note={usage ? `${usage.questionsMonth} questions · limit A$${usage.limitAud}` : "Not set up"} href="/assistant" />
        <Stat label="Features on" value={`${main.filter((f) => f.enabled && f.included !== false).length} of ${main.length}`} note="Premium modules" href="/system" />
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="flex flex-col gap-2 p-5">
          <h2 className="heading-sm">Modules</h2>
          <ul className="flex flex-col divide-y divide-line text-sm">
            {main.map((f) => (
              <li key={f.key} className="flex items-center justify-between py-2">
                <span>{f.label}</span>
                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${f.enabled && f.included !== false ? "bg-good-soft text-ink" : "bg-page text-muted"}`}>
                  {f.enabled && f.included !== false ? "On" : "Off"}
                </span>
              </li>
            ))}
          </ul>
        </Card>
        <Card className="flex flex-col gap-2 p-5">
          <div className="flex items-center justify-between">
            <h2 className="heading-sm">Recent changes</h2>
            <Link href="/system/audit" className="text-sm font-semibold text-brand underline">
              Change log
            </Link>
          </div>
          <ul className="flex flex-col divide-y divide-line text-sm">
            {changes.length === 0 ? <li className="py-2 text-muted">Nothing yet.</li> : null}
            {changes.map((c) => (
              <li key={c.id} className="flex flex-wrap justify-between gap-2 py-2">
                <span>{c.action.replaceAll("_", " ")}{c.entity_id ? ` · ${c.entity_id}` : ""}</span>
                <span className="text-muted">{c.at}</span>
              </li>
            ))}
          </ul>
        </Card>
      </div>
      <p className="text-sm">
        <Link href="/system/health" className="font-semibold text-brand underline">
          Open System health
        </Link>{" "}
        for the database, storage, emails and the hourly timer.
      </p>
    </>
  );
}

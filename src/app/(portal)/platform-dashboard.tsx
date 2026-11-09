// Staff Portal · © cmeproject. All rights reserved.
import { LogIn, MailQuestion, Rocket, Users } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { assistantUsage } from "@/lib/assistant";
import { getTimeZone } from "@/lib/settings";
import { BUCKET_LABELS, LIMITS, bytes, level, type Level, type Plan } from "@/lib/health";
import { ROLE_LABELS, ROLES, isRole } from "@/lib/roles";
import { Bars, Gauge, Hover, LineChart, Panel, Tile } from "@/components/dash";

// cmeprojects: the system admin's home. The system admin is never given
// tasks, so this shows how the platform is doing, in colour: people,
// sign-ins, activity, the database and file storage, emails, the Assistant's
// spending and recent changes. Hover (or tab to) any panel for the details.

const DAY = 86_400_000;
// The company's own colours (they follow Branding), with green, amber and red
// kept for status only.
const GOOD = "var(--good)";
const WARN = "var(--warn)";
const BAD = "var(--bad)";
const LEVEL_COLOUR: Record<Level, string> = { ok: GOOD, warn: WARN, full: BAD };
const LEVEL_WORD: Record<Level, string> = { ok: "Plenty of room", warn: "Getting full", full: "Nearly full" };

type Health = { database_bytes: number; files: { bucket: string; files: number; bytes: number }[] };

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

async function loadPlatform() {
  const admin = createAdminClient();
  const supabase = await createClient();
  const now = Date.now();
  const since30 = new Date(now - 30 * DAY).toISOString();
  const since56 = new Date(now - 56 * DAY).toISOString();
  const [{ data: people }, users, { data: tasks }, { count: bells }, { data: emails }, { data: changes }, { data: features }, { count: drafts }, usage, timeZone, health, { data: planRow }] =
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
      supabase.rpc("system_health").then((r) => (r.error ? null : (r.data as Health))),
      supabase.from("app_settings").select("value").eq("key", "system.hosting_plan").maybeSingle(),
    ]);

  const active = (people ?? []).filter((p) => p.active);
  const byRole = ROLES.filter((r) => r !== "system_admin")
    .map((r) => ({ label: ROLE_LABELS[r].split(" (")[0], value: active.filter((p) => isRole(p.role) && p.role === r).length }))
    .filter((r) => r.value > 0);
  const signedIn = (days: number) => users.filter((u) => u.last_sign_in_at && now - new Date(u.last_sign_in_at).getTime() < days * DAY).length;

  const day = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", timeZone });
  const weeks = Array.from({ length: 8 }, (_, i) => {
    const end = now - i * 7 * DAY;
    const start = end - 7 * DAY;
    const inWeek = (tasks ?? []).filter((t) => {
      const at = new Date(t.created_at).getTime();
      return at >= start && at < end;
    });
    return { label: day.format(new Date(start)), value: inWeek.length, done: inWeek.filter((t) => t.status === "completed" || t.status === "closed").length };
  }).reverse();

  const plan: Plan = planRow?.value === "pro" ? "pro" : "free";
  const fileBytes = (health?.files ?? []).reduce((s, f) => s + Number(f.bytes), 0);
  const fileCount = (health?.files ?? []).reduce((s, f) => s + Number(f.files), 0);
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  const main = (features ?? []).filter((f) => !f.parent && f.premium);
  // Each module with its parts, as staff see it (the system admin always sees everything).
  const isOn = (f: { enabled: boolean; included: boolean | null }) => f.enabled && f.included !== false;
  const modules = main.map((m) => {
    const parts = (features ?? []).filter((f) => f.parent === m.key);
    return { key: m.key, label: m.label, on: isOn(m), parts: parts.length, partsOn: parts.filter(isOn).length };
  });
  const core = (features ?? []).filter((f) => ["teams", "roles", "attachments", "auto_escalation", "two_factor"].includes(f.key)).map((f) => ({ key: f.key, label: f.label, on: isOn(f) }));

  return {
    people: people ?? [],
    active,
    signed7: signedIn(7),
    signed30: signedIn(30),
    neverJoined: users.filter((u) => !u.last_sign_in_at).length,
    weeks,
    byRole,
    bells: bells ?? 0,
    sent: (emails ?? []).filter((e) => e.sent_at).length,
    failed: (emails ?? []).filter((e) => !e.sent_at && e.last_error).length,
    waiting: (emails ?? []).filter((e) => !e.sent_at && !e.last_error).length,
    usage,
    modules,
    core,
    drafts: drafts ?? 0,
    changes: (changes ?? []).map((c) => ({ ...c, at: when.format(new Date(c.created_at)) })),
    storage: health
      ? {
          plan,
          database: { used: Number(health.database_bytes), limit: LIMITS.database[plan] },
          files: { used: fileBytes, limit: LIMITS.files[plan], count: fileCount, buckets: health.files },
        }
      : null,
  };
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

function Meter({ title, pct, used, limit, details, href }: { title: string; pct: number; used: string; limit: string; details: ReactNode; href: string }) {
  const lv = level(pct);
  const colour = LEVEL_COLOUR[lv];
  return (
    <Hover label={`${title}: ${used} of ${limit}`} details={details}>
      <Link href={href} className="flex items-center gap-3 rounded-md p-2 hover:bg-page">
        <div className="relative">
          <Gauge pct={pct} colour={colour} />
          <span className="absolute inset-x-0 bottom-0 text-center text-sm font-semibold text-ink tabular-nums">
            {pct > 0 && pct < 1 ? "<1" : Math.round(pct)}%
          </span>
        </div>
        <div className="min-w-0">
          <p className="font-semibold text-ink">{title}</p>
          <p className="text-xs text-muted">
            {used} of {limit}
          </p>
          <p className="mt-1 inline-flex items-center gap-1.5 text-xs font-medium" style={{ color: colour }}>
            <span className="size-2 rounded-full" style={{ background: colour }} />
            {LEVEL_WORD[lv]}
          </p>
        </div>
      </Link>
    </Hover>
  );
}

// ---------------------------------------------------------------------------
// The dashboard
// ---------------------------------------------------------------------------

export async function PlatformDashboard({ name }: { name: string }) {
  const d = await loadPlatform();
  return <PlatformView name={name} d={d} />;
}

function PlatformView({ name, d }: { name: string; d: Awaited<ReturnType<typeof loadPlatform>> }) {
  const s = d.storage;
  const ai = d.usage;
  const totalEmails = d.sent + d.failed + d.waiting;
  const modulesOn = d.modules.filter((m) => m.on).length;

  return (
    <>
      {/* cmeprojects: a branded banner with the headline numbers. */}
      <section className="relative overflow-hidden rounded-xl bg-brand-dark px-6 py-6 text-side-fg shadow-card sm:px-8">
        <div aria-hidden="true" className="pointer-events-none absolute -top-20 -right-16 size-72 rounded-full bg-white/5" />
        <div aria-hidden="true" className="pointer-events-none absolute -bottom-24 left-1/3 size-64 rounded-full bg-[var(--brand-accent)]/15" />
        <div className="relative flex flex-wrap items-end justify-between gap-6">
          <div>
            <p className="text-xs font-semibold tracking-[0.2em] text-side-muted uppercase">Platform</p>
            <h1 className="font-display text-3xl font-semibold">Good to see you{name ? `, ${name.split(" ")[0]}` : ""}</h1>
            <p className="mt-1 max-w-xl text-sm text-side-muted">How the portal is doing. Everyone&apos;s work is under Tasks; hover a meter for details.</p>
          </div>
          <dl className="flex flex-wrap gap-6 text-right">
            {[
              ["People", d.active.length],
              ["Signed in this week", d.signed7],
              ["Modules on", `${modulesOn}/${d.modules.length}`],
            ].map(([k, v]) => (
              <div key={String(k)}>
                <dt className="text-xs text-side-muted">{k}</dt>
                <dd className="font-display text-2xl font-semibold tabular-nums">{v}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Tile label="Active people" value={d.active.length} note={`${d.people.length - d.active.length} deactivated`} href="/settings/staff" icon={Users} accent="brand" />
        <Tile label="Signed in · 7 days" value={d.signed7} note={`${d.signed30} in the last 30 days`} icon={LogIn} accent="good" />
        <Tile label="Invited, not joined" value={d.neverJoined} note="Resend from the Staff page" href="/settings/staff" icon={MailQuestion} accent={d.neverJoined ? "warn" : "accent"} />
        <Tile label="Not live yet" value={d.drafts} note="Saved settings waiting for Deploy" href="/system" icon={Rocket} accent={d.drafts ? "warn" : "accent"} />
      </div>

      <Panel title="Capacity" action={<Link href="/system/health" className="text-xs font-semibold text-brand underline">System health</Link>}>
        <div className="grid gap-2 md:grid-cols-3">
          {s ? (
            <>
              <Meter
                title="Database"
                pct={(s.database.used / s.database.limit) * 100}
                used={bytes(s.database.used)}
                limit={bytes(s.database.limit)}
                href="/system/health"
                details={
                  <div className="flex flex-col gap-1">
                    <p className="font-semibold">Database · Supabase {s.plan === "pro" ? "Pro" : "Free"}</p>
                    <p>
                      {bytes(s.database.used)} of {bytes(s.database.limit)} ({((s.database.used / s.database.limit) * 100).toFixed(1)}%)
                    </p>
                    <p className="text-muted">Tasks, people, trips, forms and settings. Text is small, so this grows slowly.</p>
                  </div>
                }
              />
              <Meter
                title="File storage"
                pct={(s.files.used / s.files.limit) * 100}
                used={bytes(s.files.used)}
                limit={bytes(s.files.limit)}
                href="/system/health"
                details={
                  <div className="flex flex-col gap-1.5">
                    <p className="font-semibold">
                      {s.files.count.toLocaleString("en-AU")} files · {bytes(s.files.used)}
                    </p>
                    <ul className="flex flex-col gap-0.5">
                      {s.files.buckets
                        .filter((b) => Number(b.files) > 0)
                        .map((b) => (
                          <li key={b.bucket} className="flex justify-between gap-2">
                            <span>{BUCKET_LABELS[b.bucket] ?? b.bucket}</span>
                            <span className="tabular-nums text-muted">{bytes(Number(b.bytes))}</span>
                          </li>
                        ))}
                    </ul>
                  </div>
                }
              />
            </>
          ) : (
            <p className="text-sm text-muted md:col-span-2">Database and file storage: run the latest database updates, then refresh.</p>
          )}
          <Meter
            title="Assistant this month"
            pct={ai && ai.limitAud > 0 ? (ai.monthAud / ai.limitAud) * 100 : 0}
            used={ai ? `A$${ai.monthAud.toFixed(2)}` : "A$0"}
            limit={ai ? `A$${ai.limitAud}` : "no limit"}
            href="/assistant"
            details={
              ai ? (
                <div className="flex flex-col gap-1">
                  <p className="font-semibold">Spending against the monthly limit</p>
                  <p>
                    {ai.questionsMonth} questions this month{ai.leftAud !== null ? ` · about A$${ai.leftAud.toFixed(2)} credit left` : ""}
                  </p>
                  <p className="text-muted">At the limit, it answers from your documents without the AI.</p>
                </div>
              ) : (
                <p>The Assistant isn&apos;t set up yet.</p>
              )
            }
          />
        </div>
      </Panel>

      <div className="grid gap-4 lg:grid-cols-[3fr_2fr]">
        <Panel title="Tasks each week">
          <LineChart rows={d.weeks} />
        </Panel>
        <Panel title="People by access level">
          {d.byRole.length ? <Bars rows={d.byRole} /> : <p className="text-sm text-muted">Nobody yet.</p>}
          <div className="mt-auto grid grid-cols-2 gap-2 border-t border-line pt-3 text-sm">
            <div>
              <p className="text-xs text-muted">Bell notices · 30 days</p>
              <p className="font-semibold tabular-nums">{d.bells}</p>
            </div>
            <Hover label={`Emails: ${d.sent} sent, ${d.waiting} waiting, ${d.failed} failed`} details={<p>{d.sent} sent, {d.waiting} waiting, {d.failed} failed in the last 30 days. Failed emails are retried.</p>}>
              <p className="text-xs text-muted">Emails · 30 days</p>
              <p className="font-semibold tabular-nums">
                {d.sent} sent{d.failed ? <span className="text-danger"> · {d.failed} failed</span> : null}
              </p>
              <div className="mt-1 flex h-1.5 overflow-hidden rounded-full bg-page" aria-hidden="true">
                {totalEmails ? (
                  <>
                    <span style={{ width: `${(d.sent / totalEmails) * 100}%`, background: GOOD }} />
                    <span style={{ width: `${(d.waiting / totalEmails) * 100}%`, background: WARN }} />
                    <span style={{ width: `${(d.failed / totalEmails) * 100}%`, background: BAD }} />
                  </>
                ) : null}
              </div>
            </Hover>
          </div>
        </Panel>
      </div>

      <div className="grid gap-4 lg:grid-cols-[3fr_2fr]">
        <Panel
          title={`Modules · ${modulesOn} of ${d.modules.length} on`}
          action={<Link href="/system" className="text-xs font-semibold text-brand underline">Change in Features</Link>}
        >
          <ul className="grid gap-2 sm:grid-cols-2">
            {d.modules.map((m) => (
              <li
                key={m.key}
                className={`flex items-center gap-3 rounded-md border px-3 py-2 ${m.on ? "border-line bg-brand-soft" : "border-dashed border-line bg-surface"}`}
              >
                <span
                  className={`grid size-6 shrink-0 place-items-center rounded-full text-xs font-bold ${m.on ? "bg-good text-white" : "border border-field text-muted"}`}
                  aria-hidden="true"
                >
                  {m.on ? "✓" : "–"}
                </span>
                <span className="min-w-0 flex-1">
                  <span className={`block text-sm font-medium ${m.on ? "text-ink" : "text-muted"}`}>{m.label}</span>
                  <span className="block text-xs text-muted">
                    {m.on ? (m.parts ? `On · ${m.partsOn} of ${m.parts} parts` : "On for staff") : "Off for staff · you still see it"}
                  </span>
                </span>
              </li>
            ))}
          </ul>
          {d.core.length ? (
            <p className="flex flex-wrap gap-x-4 gap-y-1 border-t border-line pt-3 text-xs text-muted">
              <span className="font-semibold text-ink">Core:</span>
              {d.core.map((c) => (
                <span key={c.key} className="inline-flex items-center gap-1">
                  <span className={`size-1.5 rounded-full ${c.on ? "bg-good" : "bg-field"}`} aria-hidden="true" />
                  {c.label}
                  <span className="sr-only">{c.on ? " on" : " off"}</span>
                </span>
              ))}
            </p>
          ) : null}
        </Panel>
        <Panel title="Recent changes" action={<Link href="/system/audit" className="text-xs font-semibold text-brand underline">Change log</Link>}>
          <ul className="flex flex-col divide-y divide-line text-sm">
            {d.changes.length === 0 ? <li className="py-2 text-muted">Nothing yet.</li> : null}
            {d.changes.map((c) => (
              <li key={c.id} className="flex flex-col py-2">
                <span className="first-letter:uppercase">{c.action.replaceAll("_", " ")}</span>
                <span className="text-xs text-muted">
                  {c.entity_id ? `${c.entity_id} · ` : ""}
                  {c.at}
                </span>
              </li>
            ))}
          </ul>
        </Panel>
      </div>
    </>
  );
}


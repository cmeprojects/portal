// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { assistantUsage } from "@/lib/assistant";
import { getTimeZone } from "@/lib/settings";
import { BUCKET_LABELS, LIMITS, bytes, level, type Level, type Plan } from "@/lib/health";
import { ROLE_LABELS, ROLES, isRole } from "@/lib/roles";
import { PageHeader } from "@/components/ui";

// cmeprojects: the system admin's home. The system admin is never given
// tasks, so this shows how the platform is doing, in colour: people,
// sign-ins, activity, the database and file storage, emails, the Assistant's
// spending and recent changes. Hover (or tab to) any panel for the details.

const DAY = 86_400_000;
// The company's own colours (they follow Branding), with green, amber and red
// kept for status only.
const BRAND = "var(--accent)";
const BRAND_LIGHT = "var(--brand-accent)";
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

function Panel({ title, children, action, className = "" }: { title: string; children: ReactNode; action?: ReactNode; className?: string }) {
  return (
    <section className={`flex flex-col gap-3 shadow-card rounded-xl border border-line bg-surface p-4 ${className}`}>
      <header className="flex items-center justify-between gap-2 border-b border-line pb-2">
        <h2 className="text-sm font-semibold tracking-wide text-ink uppercase">{title}</h2>
        {action}
      </header>
      {children}
    </section>
  );
}

// Hover or focus to see more. Opens above everything (no panel clips it).
function Hover({ children, details, label }: { children: ReactNode; details: ReactNode; label: string }) {
  return (
    <div tabIndex={0} aria-label={label} className="group/hover relative rounded-md outline-none focus-visible:ring-2 focus-visible:ring-brand">
      {children}
      <div
        role="tooltip"
        className="pointer-events-none invisible absolute bottom-full max-md:hidden left-1/2 z-50 mb-2 w-72 -translate-x-1/2 rounded-md border border-line bg-surface p-3 text-left text-xs text-ink opacity-0 shadow-xl transition-opacity group-hover/hover:visible group-hover/hover:opacity-100 group-focus/hover:visible group-focus/hover:opacity-100"
      >
        {details}
      </div>
    </div>
  );
}

function Tile({ label, value, note, href }: { label: string; value: string | number; note?: string; href?: string }) {
  const body = (
    <div className="flex h-full flex-col gap-0.5 rounded-lg border border-line border-l-4 border-l-brand bg-surface px-4 py-3 transition duration-200 hover:-translate-y-1 hover:border-l-danger hover:shadow-lg motion-reduce:transform-none motion-reduce:transition-none">
      <span className="text-xs font-medium tracking-wide text-muted uppercase">{label}</span>
      <span className="text-2xl font-semibold text-ink tabular-nums">{value}</span>
      {note ? <span className="text-xs text-muted">{note}</span> : null}
    </div>
  );
  return href ? (
    <Link href={href} className="block rounded-lg focus-visible:outline-2 focus-visible:outline-brand">
      {body}
    </Link>
  ) : (
    body
  );
}

// A small half-circle gauge, coloured by how full it is.
function Gauge({ pct, colour }: { pct: number; colour: string }) {
  const cx = 60;
  const cy = 60;
  const r = 48;
  const at = (p: number) => {
    const a = Math.PI * (1 - p);
    return `${(cx + r * Math.cos(a)).toFixed(2)} ${(cy - r * Math.sin(a)).toFixed(2)}`;
  };
  const arc = (p0: number, p1: number) => `M ${at(p0)} A ${r} ${r} 0 0 1 ${at(p1)}`;
  const p = Math.max(0, Math.min(1, pct / 100));
  return (
    <svg viewBox="0 0 120 66" className="w-32" aria-hidden="true">
      <path d={arc(0, 1)} stroke="var(--line)" strokeWidth="10" fill="none" strokeLinecap="round" />
      {p > 0.004 ? <path d={arc(0, p)} stroke={colour} strokeWidth="10" fill="none" strokeLinecap="round" /> : null}
    </svg>
  );
}

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

// Tasks per week: a calm line chart in the brand colour; hover a dot for numbers.
function LineChart({ rows }: { rows: { label: string; value: number; done: number }[] }) {
  const w = 560;
  const h = 180;
  const pad = { l: 28, r: 24, t: 10, b: 28 };
  const max = Math.max(4, ...rows.map((r) => r.value));
  const x = (i: number) => pad.l + (i * (w - pad.l - pad.r)) / Math.max(1, rows.length - 1);
  const y = (v: number) => h - pad.b - (v * (h - pad.t - pad.b)) / max;
  const line = (key: "value" | "done") => rows.map((r, i) => `${i ? "L" : "M"} ${x(i).toFixed(1)} ${y(r[key]).toFixed(1)}`).join(" ");
  return (
    <div className="flex flex-col gap-2">
      <svg viewBox={`0 0 ${w} ${h}`} className="w-full text-ink" role="img" aria-label="Tasks created and finished each week, last 8 weeks">
        {[0, Math.round(max / 2), max].map((t) => (
          <g key={t}>
            <line x1={pad.l} x2={w - pad.r} y1={y(t)} y2={y(t)} stroke="var(--line)" />
            <text x={pad.l - 6} y={y(t) + 4} fontSize="10" textAnchor="end" fill="var(--muted)">
              {t}
            </text>
          </g>
        ))}
        <path d={`${line("value")} L ${x(rows.length - 1)} ${h - pad.b} L ${x(0)} ${h - pad.b} Z`} fill={BRAND} opacity="0.08" />
        <path d={line("value")} fill="none" stroke={BRAND} strokeWidth="2.5" strokeLinejoin="round" />
        <path d={line("done")} fill="none" stroke={BRAND_LIGHT} strokeWidth="2" strokeDasharray="5 4" strokeLinejoin="round" />
        {rows.map((r, i) => (
          <g key={r.label}>
            <circle cx={x(i)} cy={y(r.value)} r="4.5" fill="var(--surface)" stroke={BRAND} strokeWidth="2.5">
              <title>{`Week of ${r.label}: ${r.value} created, ${r.done} finished`}</title>
            </circle>
            <text x={x(i)} y={h - 8} fontSize="10" textAnchor="middle" fill="var(--muted)">
              {r.label}
            </text>
          </g>
        ))}
      </svg>
      <p className="flex flex-wrap gap-4 text-xs text-muted">
        <span className="flex items-center gap-1.5">
          <span className="h-0.5 w-5" style={{ background: BRAND }} /> Created
        </span>
        <span className="flex items-center gap-1.5">
          <span className="w-5 border-t-2 border-dashed" style={{ borderColor: BRAND_LIGHT }} /> Finished
        </span>
      </p>
    </div>
  );
}

function Bars({ rows }: { rows: { label: string; value: number }[] }) {
  const max = Math.max(1, ...rows.map((r) => r.value));
  return (
    <ul className="flex flex-col gap-2.5">
      {rows.map((r) => (
        <li key={r.label} className="grid grid-cols-[7rem_1fr_2rem] items-center gap-3 text-sm" title={`${r.label}: ${r.value}`}>
          <span className="truncate text-muted">{r.label}</span>
          <span className="h-2.5 overflow-hidden rounded-full bg-page" aria-hidden="true">
            <span className="block h-full rounded-full" style={{ width: `${(r.value / max) * 100}%`, background: BRAND }} />
          </span>
          <span className="text-right font-medium tabular-nums">{r.value}</span>
        </li>
      ))}
    </ul>
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
      <PageHeader
        title={`Platform${name ? ` · ${name.split(" ")[0]}` : ""}`}
        intro="How the portal is doing. You're never given tasks; everyone's work is under Tasks. Hover a meter for details."
      />

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Tile label="Active people" value={d.active.length} note={`${d.people.length - d.active.length} deactivated`} href="/settings/staff" />
        <Tile label="Signed in · 7 days" value={d.signed7} note={`${d.signed30} in the last 30 days`} />
        <Tile label="Invited, not joined" value={d.neverJoined} note="Resend from the Staff page" href="/settings/staff" />
        <Tile label="Not live yet" value={d.drafts} note="Saved settings waiting for Deploy" href="/system" />
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


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
const C = { blue: "#2563eb", teal: "#0d9488", amber: "#f59e0b", purple: "#7c3aed", green: "#16a34a", red: "#dc2626", pink: "#db2777", sky: "#0284c7" };
const LEVEL_COLOUR: Record<Level, string> = { ok: C.green, warn: C.amber, full: C.red };
const LEVEL_WORD: Record<Level, string> = { ok: "Plenty of room", warn: "Getting full", full: "Nearly full" };
const PALETTE = [C.blue, C.teal, C.amber, C.purple, C.pink, C.sky];

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
    main,
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

// A panel with a coloured header strip and icon, like a report card.
function Panel({ title, colour, icon, children, className = "" }: { title: string; colour: string; icon: ReactNode; children: ReactNode; className?: string }) {
  return (
    <section className={`flex flex-col overflow-hidden rounded-xl border border-line bg-surface shadow-sm ${className}`}>
      <div className="h-1" style={{ background: colour }} aria-hidden="true" />
      <header className="flex items-center gap-3 px-5 pt-4">
        <span className="grid size-9 place-items-center rounded-full text-white" style={{ background: colour }} aria-hidden="true">
          {icon}
        </span>
        <h2 className="heading-sm">{title}</h2>
      </header>
      <div className="flex flex-1 flex-col gap-3 p-5">{children}</div>
    </section>
  );
}

// Hover or focus to see more (keyboard friendly, no JavaScript).
function Hover({ children, details }: { children: ReactNode; details: ReactNode }) {
  return (
    <div tabIndex={0} className="group relative rounded-lg outline-none focus-visible:ring-2 focus-visible:ring-brand">
      {children}
      <div
        role="tooltip"
        className="pointer-events-none invisible absolute top-full left-1/2 z-30 mt-2 w-72 -translate-x-1/2 rounded-lg border border-line bg-surface p-3 text-left text-xs text-ink opacity-0 shadow-xl transition group-hover:visible group-hover:opacity-100 group-focus:visible group-focus:opacity-100"
      >
        {details}
      </div>
    </div>
  );
}

function Tile({ label, value, note, colour, icon, href }: { label: string; value: string | number; note?: string; colour: string; icon: ReactNode; href?: string }) {
  const body = (
    <div className="flex h-full items-center gap-4 rounded-xl border p-4 shadow-sm" style={{ borderColor: `${colour}55`, background: `${colour}14` }}>
      <span className="grid size-12 shrink-0 place-items-center rounded-full text-white" style={{ background: colour }} aria-hidden="true">
        {icon}
      </span>
      <span className="min-w-0">
        <span className="block text-sm text-muted">{label}</span>
        <span className="block text-3xl font-semibold tabular-nums" style={{ color: colour }}>
          {value}
        </span>
        {note ? <span className="block text-xs text-muted">{note}</span> : null}
      </span>
    </div>
  );
  return href ? (
    <Link href={href} className="block rounded-xl hover:ring-2 hover:ring-brand/30">
      {body}
    </Link>
  ) : (
    body
  );
}

// A half-circle gauge: green, amber and red zones, a coloured fill and a needle.
function Gauge({ pct, colour }: { pct: number; colour: string }) {
  const cx = 100;
  const cy = 100;
  const r = 80;
  const at = (p: number) => {
    const a = Math.PI * (1 - p);
    return `${(cx + r * Math.cos(a)).toFixed(2)} ${(cy - r * Math.sin(a)).toFixed(2)}`;
  };
  const arc = (p0: number, p1: number) => `M ${at(p0)} A ${r} ${r} 0 0 1 ${at(p1)}`;
  const p = Math.max(0, Math.min(1, pct / 100));
  const a = Math.PI * (1 - p);
  return (
    <svg viewBox="0 0 200 118" className="w-full max-w-60" aria-hidden="true">
      <path d={arc(0, 0.75)} stroke={C.green} strokeOpacity="0.25" strokeWidth="18" fill="none" />
      <path d={arc(0.75, 0.9)} stroke={C.amber} strokeOpacity="0.3" strokeWidth="18" fill="none" />
      <path d={arc(0.9, 1)} stroke={C.red} strokeOpacity="0.3" strokeWidth="18" fill="none" />
      {p > 0.002 ? <path d={arc(0, p)} stroke={colour} strokeWidth="18" strokeLinecap="round" fill="none" /> : null}
      <line x1={cx} y1={cy} x2={cx + 62 * Math.cos(a)} y2={cy - 62 * Math.sin(a)} stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
      <circle cx={cx} cy={cy} r="6" fill="currentColor" />
      <text x="20" y="116" fontSize="10" fill="currentColor" opacity="0.6">0%</text>
      <text x="165" y="116" fontSize="10" fill="currentColor" opacity="0.6">100%</text>
    </svg>
  );
}

function GaugeCard({ title, used, limit, colourFor, detail, icon, href }: { title: string; used: string; limit: string; colourFor: number; detail: ReactNode; icon: ReactNode; href: string }) {
  const lv = level(colourFor);
  const colour = LEVEL_COLOUR[lv];
  return (
    <Panel title={title} colour={colour} icon={icon}>
      <Hover details={detail}>
        <div className="flex flex-col items-center gap-1 text-ink">
          <Gauge pct={colourFor} colour={colour} />
          <p className="text-2xl font-semibold tabular-nums" style={{ color: colour }}>
            {colourFor < 1 && colourFor > 0 ? "<1" : Math.round(colourFor)}%
          </p>
          <p className="text-sm text-muted">
            {used} of {limit}
          </p>
          <span className="rounded-full px-3 py-1 text-xs font-semibold text-white" style={{ background: colour }}>
            {LEVEL_WORD[lv]}
          </span>
        </div>
      </Hover>
      <Link href={href} className="mt-auto text-center text-sm font-semibold text-brand underline">
        Details
      </Link>
    </Panel>
  );
}

// Tasks per week: a line chart with dots; hover a dot for its numbers.
function LineChart({ rows }: { rows: { label: string; value: number; done: number }[] }) {
  const w = 560;
  const h = 200;
  const pad = { l: 32, r: 12, t: 12, b: 34 };
  const max = Math.max(4, ...rows.map((r) => r.value));
  const x = (i: number) => pad.l + (i * (w - pad.l - pad.r)) / Math.max(1, rows.length - 1);
  const y = (v: number) => h - pad.b - (v * (h - pad.t - pad.b)) / max;
  const line = (key: "value" | "done") => rows.map((r, i) => `${i ? "L" : "M"} ${x(i).toFixed(1)} ${y(r[key]).toFixed(1)}`).join(" ");
  const ticks = [0, Math.round(max / 2), max];
  return (
    <div className="flex flex-col gap-2">
      <svg viewBox={`0 0 ${w} ${h}`} className="w-full text-ink" role="img" aria-label="Tasks created and finished each week, last 8 weeks">
        {ticks.map((t) => (
          <g key={t}>
            <line x1={pad.l} x2={w - pad.r} y1={y(t)} y2={y(t)} stroke="currentColor" strokeOpacity="0.1" />
            <text x={pad.l - 6} y={y(t) + 4} fontSize="11" textAnchor="end" fill="currentColor" opacity="0.6">
              {t}
            </text>
          </g>
        ))}
        <path d={`${line("value")} L ${x(rows.length - 1)} ${h - pad.b} L ${x(0)} ${h - pad.b} Z`} fill={C.blue} opacity="0.1" />
        <path d={line("value")} fill="none" stroke={C.blue} strokeWidth="3" strokeLinejoin="round" />
        <path d={line("done")} fill="none" stroke={C.green} strokeWidth="2.5" strokeDasharray="6 5" strokeLinejoin="round" />
        {rows.map((r, i) => (
          <g key={r.label}>
            <circle cx={x(i)} cy={y(r.value)} r="6" fill="white" stroke={C.blue} strokeWidth="3">
              <title>{`Week of ${r.label}: ${r.value} created, ${r.done} finished`}</title>
            </circle>
            <text x={x(i)} y={h - 12} fontSize="11" textAnchor="middle" fill="currentColor" opacity="0.7">
              {r.label}
            </text>
          </g>
        ))}
      </svg>
      <p className="flex flex-wrap gap-4 text-xs text-muted">
        <span className="flex items-center gap-1.5">
          <span className="h-1 w-5 rounded" style={{ background: C.blue }} /> Created
        </span>
        <span className="flex items-center gap-1.5">
          <span className="h-1 w-5 rounded border-t-2 border-dashed" style={{ borderColor: C.green }} /> Finished
        </span>
        <span>Hover a dot for the numbers.</span>
      </p>
    </div>
  );
}

function ColourBars({ rows }: { rows: { label: string; value: number }[] }) {
  const max = Math.max(1, ...rows.map((r) => r.value));
  return (
    <ul className="flex flex-col gap-3">
      {rows.map((r, i) => (
        <li key={r.label} className="grid grid-cols-[7.5rem_1fr_2.5rem] items-center gap-3 text-sm" title={`${r.label}: ${r.value}`}>
          <span className="truncate text-muted">{r.label}</span>
          <span className="h-4 overflow-hidden rounded-full bg-page" aria-hidden="true">
            <span className="block h-full rounded-full" style={{ width: `${(r.value / max) * 100}%`, background: PALETTE[i % PALETTE.length] }} />
          </span>
          <span className="text-right font-semibold tabular-nums">{r.value}</span>
        </li>
      ))}
    </ul>
  );
}

// Small icons (stroke, currentColor).
const Icon = ({ d }: { d: string }) => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d={d} />
  </svg>
);
const I = {
  people: <Icon d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />,
  signin: <Icon d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3" />,
  invite: <Icon d="M4 4h16v16H4zM22 6l-10 7L2 6" />,
  draft: <Icon d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z" />,
  db: <Icon d="M12 3c4.4 0 8 1.3 8 3s-3.6 3-8 3-8-1.3-8-3 3.6-3 8-3zM4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3" />,
  files: <Icon d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6" />,
  ai: <Icon d="M12 2v4M12 18v4M4.9 4.9l2.8 2.8M16.3 16.3l2.8 2.8M2 12h4M18 12h4M4.9 19.1l2.8-2.8M16.3 7.7l2.8-2.8" />,
  chart: <Icon d="M3 3v18h18M7 15l4-4 3 3 5-6" />,
  bell: <Icon d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.94 1.94 0 0 0 3.4 0" />,
  mail: <Icon d="M4 4h16v16H4zM22 6l-10 7L2 6" />,
  grid: <Icon d="M3 3h7v7H3zM14 3h7v7h-7zM14 14h7v7h-7zM3 14h7v7H3z" />,
  log: <Icon d="M12 8v4l3 3M3 12a9 9 0 1 0 9-9" />,
};

// ---------------------------------------------------------------------------
// The dashboard
// ---------------------------------------------------------------------------

export async function PlatformDashboard({ name }: { name: string }) {
  const d = await loadPlatform();
  return <PlatformView name={name} d={d} />;
}

function PlatformView({ name, d }: { name: string; d: Awaited<ReturnType<typeof loadPlatform>> }) {
  const s = d.storage;
  const dbPct = s ? (s.database.used / s.database.limit) * 100 : 0;
  const filePct = s ? (s.files.used / s.files.limit) * 100 : 0;
  const ai = d.usage;
  const aiPct = ai && ai.limitAud > 0 ? (ai.monthAud / ai.limitAud) * 100 : 0;
  const totalEmails = d.sent + d.failed + d.waiting;

  return (
    <>
      <PageHeader
        title={`Platform${name ? ` · ${name.split(" ")[0]}` : ""}`}
        intro="How the portal is doing. You're never given tasks; everyone's work is under Tasks in the menu. Hover any panel for details."
      />

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Tile label="Active people" value={d.active.length} note={`${d.people.length - d.active.length} deactivated`} colour={C.blue} icon={I.people} href="/settings/staff" />
        <Tile label="Signed in, last 7 days" value={d.signed7} note={`${d.signed30} in the last 30 days`} colour={C.teal} icon={I.signin} />
        <Tile label="Invited, not joined yet" value={d.neverJoined} note="Resend from the Staff page" colour={C.amber} icon={I.invite} href="/settings/staff" />
        <Tile label="Settings not live yet" value={d.drafts} note="Saved, waiting for Deploy" colour={C.purple} icon={I.draft} href="/system" />
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {s ? (
          <>
            <GaugeCard
              title="Database"
              icon={I.db}
              used={bytes(s.database.used)}
              limit={bytes(s.database.limit)}
              colourFor={dbPct}
              href="/system/health"
              detail={
                <div className="flex flex-col gap-1">
                  <p className="font-semibold">Database ({s.plan === "pro" ? "Supabase Pro" : "Supabase Free"})</p>
                  <p>
                    {bytes(s.database.used)} used of {bytes(s.database.limit)} ({dbPct.toFixed(1)}%).
                  </p>
                  <p className="text-muted">Tasks, people, trips, forms and settings. Text is small, so this grows slowly.</p>
                </div>
              }
            />
            <GaugeCard
              title="File storage"
              icon={I.files}
              used={bytes(s.files.used)}
              limit={bytes(s.files.limit)}
              colourFor={filePct}
              href="/system/health"
              detail={
                <div className="flex flex-col gap-1">
                  <p className="font-semibold">
                    {s.files.count.toLocaleString("en-AU")} files · {bytes(s.files.used)} of {bytes(s.files.limit)}
                  </p>
                  <ul className="flex flex-col gap-0.5">
                    {s.files.buckets
                      .filter((b) => Number(b.files) > 0)
                      .map((b, i) => (
                        <li key={b.bucket} className="flex items-center justify-between gap-2">
                          <span className="flex items-center gap-1.5">
                            <span className="size-2 rounded-full" style={{ background: PALETTE[i % PALETTE.length] }} />
                            {BUCKET_LABELS[b.bucket] ?? b.bucket}
                          </span>
                          <span className="tabular-nums">{bytes(Number(b.bytes))}</span>
                        </li>
                      ))}
                  </ul>
                </div>
              }
            />
          </>
        ) : (
          <Panel title="Database and file storage" colour={C.sky} icon={I.db} className="md:col-span-2">
            <p className="text-sm text-muted">Not available yet: run the latest database updates, then refresh.</p>
          </Panel>
        )}
        <GaugeCard
          title="Assistant this month"
          icon={I.ai}
          used={ai ? `A$${ai.monthAud.toFixed(2)}` : "A$0"}
          limit={ai ? `A$${ai.limitAud}` : "no limit set"}
          colourFor={aiPct}
          href="/assistant"
          detail={
            ai ? (
              <div className="flex flex-col gap-1">
                <p className="font-semibold">Spending against the monthly limit</p>
                <p>
                  A${ai.monthAud.toFixed(2)} of A${ai.limitAud} · {ai.questionsMonth} questions this month
                </p>
                {ai.leftAud !== null ? <p>Credit left: about A${ai.leftAud.toFixed(2)}</p> : null}
                <p className="text-muted">At the limit, it answers from your documents without the AI.</p>
              </div>
            ) : (
              <p>The Assistant isn&apos;t set up yet.</p>
            )
          }
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-[3fr_2fr]">
        <Panel title="Tasks each week" colour={C.blue} icon={I.chart}>
          <LineChart rows={d.weeks} />
        </Panel>
        <Panel title="Active people by access level" colour={C.teal} icon={I.people}>
          {d.byRole.length ? <ColourBars rows={d.byRole} /> : <p className="text-sm text-muted">Nobody yet.</p>}
        </Panel>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Panel title="Bell notices" colour={C.pink} icon={I.bell}>
          <p className="text-3xl font-semibold tabular-nums" style={{ color: C.pink }}>
            {d.bells}
          </p>
          <p className="text-sm text-muted">Sent in the last 30 days</p>
        </Panel>
        <Panel title="Emails, 30 days" colour={C.sky} icon={I.mail}>
          <Hover
            details={
              <p>
                {d.sent} sent, {d.waiting} waiting, {d.failed} failed. Failed emails are retried; see System health if the number grows.
              </p>
            }
          >
            <div className="flex h-4 overflow-hidden rounded-full bg-page" aria-label={`${d.sent} sent, ${d.waiting} waiting, ${d.failed} failed`}>
              {totalEmails ? (
                <>
                  <span style={{ width: `${(d.sent / totalEmails) * 100}%`, background: C.green }} />
                  <span style={{ width: `${(d.waiting / totalEmails) * 100}%`, background: C.amber }} />
                  <span style={{ width: `${(d.failed / totalEmails) * 100}%`, background: C.red }} />
                </>
              ) : null}
            </div>
            <p className="mt-2 flex flex-wrap gap-3 text-xs">
              <span style={{ color: C.green }}>● {d.sent} sent</span>
              <span style={{ color: C.amber }}>● {d.waiting} waiting</span>
              <span style={{ color: C.red }}>● {d.failed} failed</span>
            </p>
          </Hover>
        </Panel>
        <Panel title="Modules" colour={C.purple} icon={I.grid} className="lg:col-span-2">
          <ul className="flex flex-wrap gap-2">
            {d.main.map((f) => {
              const on = f.enabled && f.included !== false;
              return (
                <li key={f.key}>
                  <Link
                    href="/system"
                    className="inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-semibold"
                    style={on ? { background: `${C.green}1a`, borderColor: `${C.green}66`, color: C.green } : undefined}
                    title={on ? `${f.label} is on` : `${f.label} is off for staff (you still see it)`}
                  >
                    <span className="size-2 rounded-full" style={{ background: on ? C.green : "currentColor" }} />
                    {f.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </Panel>
      </div>

      <Panel title="Recent changes" colour={C.amber} icon={I.log}>
        <ul className="flex flex-col divide-y divide-line text-sm">
          {d.changes.length === 0 ? <li className="py-2 text-muted">Nothing yet.</li> : null}
          {d.changes.map((c) => (
            <li key={c.id} className="flex flex-wrap justify-between gap-2 py-2">
              <span>
                {c.action.replaceAll("_", " ")}
                {c.entity_id ? ` · ${c.entity_id}` : ""}
              </span>
              <span className="text-muted">{c.at}</span>
            </li>
          ))}
        </ul>
        <Link href="/system/audit" className="text-sm font-semibold text-brand underline">
          Open the change log
        </Link>
      </Panel>
    </>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";

// cmeprojects: the dashboard building blocks (panels, number tiles, gauges and
// charts), shared by every role's dashboard so they all look the same. New
// modules add their own tiles with these.
const BRAND = "var(--accent)";
const BRAND_LIGHT = "var(--brand-accent)";

export function Panel({ title, children, action, className = "" }: { title: string; children: ReactNode; action?: ReactNode; className?: string }) {
  return (
    <section className={`flex flex-col gap-3 shadow-card rounded-xl border border-line bg-surface p-4 ${className}`}>
      <header className="flex items-center justify-between gap-2 border-b border-line pb-2">
        <h2 className="text-sm font-semibold text-ink">{title}</h2>
        {action}
      </header>
      {children}
    </section>
  );
}

// Hover or focus to see more. Opens above everything (no panel clips it).

// Hover or focus to see more. Opens above everything (no panel clips it).
export function Hover({ children, details, label }: { children: ReactNode; details: ReactNode; label: string }) {
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

// cmeprojects: a number tile. An icon says what it's about; tone colours the
// number when it needs attention (red = act now, amber = soon, green = good).
const TONE = { danger: "text-danger", warn: "text-warn", good: "text-good" } as const;
export function Tile({ label, value, note, href, icon: Icon, tone }: { label: string; value: string | number; note?: string; href?: string; icon?: LucideIcon; tone?: keyof typeof TONE }) {
  const body = (
    <div className="flex h-full flex-col gap-0.5 rounded-lg border border-line border-l-4 border-l-brand bg-surface px-4 py-3 transition duration-200 hover:-translate-y-1 hover:border-l-danger hover:shadow-lg motion-reduce:transform-none motion-reduce:transition-none">
      <span className="flex items-center justify-between gap-2">
        <span className="text-xs font-medium tracking-wide text-muted uppercase">{label}</span>
        {Icon ? <Icon aria-hidden="true" className="size-4 shrink-0 text-muted" strokeWidth={1.75} /> : null}
      </span>
      <span className={`text-2xl font-semibold tabular-nums ${tone && (tone === "good" || (value !== 0 && value !== "0")) ? TONE[tone] : "text-ink"}`}>{value}</span>
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

// A small half-circle gauge, coloured by how full it is.
export function Gauge({ pct, colour }: { pct: number; colour: string }) {
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

// Tasks per week: a calm line chart in the brand colour; hover a dot for numbers.
export function LineChart({ rows }: { rows: { label: string; value: number; done: number }[] }) {
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

export function Bars({ rows }: { rows: { label: string; value: number }[] }) {
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

// Staff Portal · © cmeproject. All rights reserved.
import type { ComponentProps, ReactNode } from "react";
import Link from "next/link";

// Buttons: crisp corners, white with a thin border; the main action filled.
// 44px tall on phones (easy to tap during a shift), compact on bigger screens.
const BUTTON = {
  primary: "border-brand bg-brand text-brand-fg hover:opacity-90",
  secondary: "border-transparent bg-brand-soft text-brand hover:border-brand/40",
  outline: "border-field bg-surface text-ink hover:border-muted",
  danger: "border-field bg-surface text-danger hover:border-danger",
};

export function buttonClass(variant: keyof typeof BUTTON = "primary", extra = "") {
  return `inline-flex min-h-11 items-center justify-center gap-2 rounded-md border px-4 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50 md:min-h-10 ${BUTTON[variant]} ${extra}`;
}

export function Button({
  variant = "primary",
  className = "",
  ...props
}: ComponentProps<"button"> & { variant?: keyof typeof BUTTON }) {
  return <button className={buttonClass(variant, className)} {...props} />;
}

export const inputClass =
  "h-11 w-full rounded-md border border-field bg-surface px-3 text-base text-ink placeholder:text-muted/70 focus:border-brand focus:outline-none md:text-sm";

export function Field({
  label,
  hint,
  children,
  htmlFor,
}: {
  label: string;
  hint?: ReactNode;
  htmlFor: string;
  children: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={htmlFor} className="text-sm font-medium">
        {label}
      </label>
      {children}
      {hint ? <p className="text-xs text-muted">{hint}</p> : null}
    </div>
  );
}

export function Card({ className = "", ...props }: ComponentProps<"div">) {
  return <div className={`rounded-lg border border-line bg-surface ${className}`} {...props} />;
}

export function Notice({ tone = "info", children }: { tone?: "info" | "error" | "success"; children: ReactNode }) {
  const tones = {
    info: "bg-brand-soft text-brand",
    error: "bg-danger-soft text-danger",
    success: "bg-good-soft text-good",
  };
  return (
    <p role={tone === "error" ? "alert" : "status"} className={`rounded-md px-4 py-3 text-sm ${tones[tone]}`}>
      {children}
    </p>
  );
}

export function Badge({ children, tone = "soft" }: { children: ReactNode; tone?: "soft" | "dark" | "grey" | "warn" | "good" }) {
  const tones = {
    soft: "bg-brand-soft text-brand",
    dark: "bg-brand text-brand-fg",
    grey: "bg-page text-muted ring-1 ring-line ring-inset",
    warn: "bg-warn-soft text-warn",
    good: "bg-good-soft text-good",
  };
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold whitespace-nowrap ${tones[tone]}`}>
      {children}
    </span>
  );
}

export function PageHeader({ eyebrow, title, intro, action }: { eyebrow?: string; title: string; intro?: string; action?: ReactNode }) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div>
        {eyebrow ? <p className="text-xs font-medium tracking-widest text-muted uppercase">{eyebrow}</p> : null}
        <h1 className="heading">{title}</h1>
        {intro ? <p className="mt-1 max-w-2xl text-sm text-muted">{intro}</p> : null}
      </div>
      {action}
    </div>
  );
}

// Underlined tabs (e.g. Assigned to me · Helping on).
export function Tabs({ label, items }: { label: string; items: { href: string; text: string; current: boolean }[] }) {
  return (
    <nav aria-label={label} className="flex gap-1 overflow-x-auto overflow-y-hidden border-b border-line [scrollbar-width:thin]">
      {items.map((t) => (
        <Link
          key={t.href}
          href={t.href}
          aria-current={t.current ? "page" : undefined}
          className={`-mb-px flex min-h-11 shrink-0 items-center border-b-2 px-3 text-sm font-semibold whitespace-nowrap ${
            t.current ? "border-brand text-ink" : "border-transparent text-muted hover:text-ink"
          }`}
        >
          {t.text}
        </Link>
      ))}
    </nav>
  );
}

export function Credits() {
  return <p className="text-xs text-muted">Built by cmeproject</p>;
}

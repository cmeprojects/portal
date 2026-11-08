// Staff Portal · © cmeproject. All rights reserved.
import type { LucideIcon } from "lucide-react";
import type { ComponentProps, ReactNode } from "react";
import Link from "next/link";
import { ToastOnMount } from "@/components/toast";

// Buttons: crisp corners, white with a thin border; the main action filled.
// 44px tall on phones (easy to tap during a shift), compact on bigger screens.
// cmeprojects: one set of button styles for the whole portal, each with clear
// hover, pressed, focus and disabled states.
const BUTTON = {
  primary: "border-brand bg-brand text-brand-fg shadow-sm hover:brightness-110",
  secondary: "border-transparent bg-brand-soft text-brand hover:border-brand/30",
  outline: "border-field bg-surface text-ink shadow-sm hover:border-muted hover:bg-page",
  danger: "border-field bg-surface text-danger shadow-sm hover:border-danger hover:bg-danger-soft",
};

// "sm": a quieter, smaller button for rows of actions (still 36px to tap).
export function buttonClass(variant: keyof typeof BUTTON = "primary", extra = "", size: "md" | "sm" = "md") {
  const box = size === "sm" ? "min-h-9 px-3 text-[13px] md:min-h-8" : "min-h-11 px-4 text-sm md:min-h-10";
  return `inline-flex items-center justify-center gap-2 rounded-lg border font-semibold transition-[color,background-color,border-color,filter,transform] duration-150 active:translate-y-px disabled:pointer-events-none disabled:opacity-50 ${box} ${BUTTON[variant]} ${extra}`;
}

export function Button({
  variant = "primary",
  size = "md",
  className = "",
  ...props
}: ComponentProps<"button"> & { variant?: keyof typeof BUTTON; size?: "md" | "sm" }) {
  return <button className={buttonClass(variant, className, size)} {...props} />;
}

export const inputClass =
  "h-11 w-full rounded-lg border border-field bg-surface px-3 text-base text-ink transition-[border-color,box-shadow] placeholder:text-muted/70 focus:border-brand focus:ring-3 focus:ring-brand/15 focus:outline-none disabled:bg-page disabled:text-muted md:text-sm";

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
      <label htmlFor={htmlFor} className="text-sm font-medium text-ink">
        {label}
      </label>
      {children}
      {hint ? <p className="text-xs text-muted">{hint}</p> : null}
    </div>
  );
}

export function Card({ className = "", ...props }: ComponentProps<"div">) {
  return <div className={`shadow-card rounded-xl border border-line bg-surface ${className}`} {...props} />;
}

export function Notice({ tone = "info", children }: { tone?: "info" | "error" | "success"; children: ReactNode }) {
  // cmeprojects: success messages pop up across the whole portal; errors and
  // information stay next to what they're about.
  if (tone === "success" && typeof children === "string") return <ToastOnMount text={children} />;
  const tones = {
    info: "border-brand/20 bg-brand-soft text-brand",
    error: "border-danger/25 bg-danger-soft text-danger",
    success: "border-good/25 bg-good-soft text-good",
  };
  return (
    <p role={tone === "error" ? "alert" : "status"} className={`rounded-lg border px-4 py-3 text-sm leading-relaxed ${tones[tone]}`}>
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
        {eyebrow ? <p className="mb-1 text-xs font-semibold tracking-wider text-muted uppercase">{eyebrow}</p> : null}
        <h1 className="heading">{title}</h1>
        {intro ? <p className="mt-1.5 max-w-2xl text-sm leading-relaxed text-muted">{intro}</p> : null}
      </div>
      {action}
    </div>
  );
}

// Underlined tabs (e.g. Assigned to me · Helping on).
export function Tabs({ label, items }: { label: string; items: { href: string; text: string; current: boolean }[] }) {
  return (
    <nav aria-label={label} className="flex gap-1 overflow-x-auto overflow-y-hidden border-b border-line [scrollbar-width:thin] print:hidden">
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

// cmeprojects: what a list shows when it's empty: an icon, a short line, and
// the next step when there is one.
export function EmptyState({ icon: Icon, title, text, action }: { icon?: LucideIcon; title: string; text?: string; action?: { href: string; label: string } }) {
  return (
    <div className="flex flex-col items-center gap-2 px-6 py-10 text-center">
      {Icon ? (
        <span className="mb-1 flex size-12 items-center justify-center rounded-full bg-brand-soft text-brand">
          <Icon aria-hidden="true" className="size-6" strokeWidth={1.75} />
        </span>
      ) : null}
      <p className="font-semibold text-ink">{title}</p>
      {text ? <p className="max-w-sm text-sm text-muted">{text}</p> : null}
      {action ? (
        <Link href={action.href} className={buttonClass("primary", "mt-2", "sm")}>
          {action.label}
        </Link>
      ) : null}
    </div>
  );
}

export function Credits() {
  return <p className="text-xs text-muted">Built by cmeproject</p>;
}

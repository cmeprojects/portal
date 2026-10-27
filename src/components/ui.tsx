// Staff Portal · © cmeproject. All rights reserved.
import type { ComponentProps, ReactNode } from "react";

const BUTTON = {
  primary: "bg-brand text-white hover:bg-brand-dark",
  secondary: "bg-brand-soft text-brand hover:bg-brand/15",
  outline: "border border-field bg-white text-brand hover:bg-brand-soft",
  danger: "border border-field bg-white text-danger hover:bg-red-50",
};

export function buttonClass(variant: keyof typeof BUTTON = "primary", extra = "") {
  return `inline-flex min-h-11 items-center justify-center gap-2 rounded-full px-5 text-[15px] font-bold transition-colors disabled:cursor-not-allowed disabled:opacity-60 ${BUTTON[variant]} ${extra}`;
}

export function Button({
  variant = "primary",
  className = "",
  ...props
}: ComponentProps<"button"> & { variant?: keyof typeof BUTTON }) {
  return <button className={buttonClass(variant, className)} {...props} />;
}

export const inputClass =
  "h-12 w-full rounded-xl border border-field bg-white px-3.5 text-base text-ink placeholder:text-muted/70 focus:border-brand focus:outline-none";

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
      <label htmlFor={htmlFor} className="text-[15px] font-semibold">
        {label}
      </label>
      {children}
      {hint ? <p className="text-sm text-muted">{hint}</p> : null}
    </div>
  );
}

export function Card({ className = "", ...props }: ComponentProps<"div">) {
  return <div className={`rounded-[20px] border border-line bg-white ${className}`} {...props} />;
}

export function Notice({ tone = "info", children }: { tone?: "info" | "error" | "success"; children: ReactNode }) {
  const tones = {
    info: "bg-brand-soft text-brand",
    error: "bg-red-50 text-danger",
    success: "bg-green-50 text-good",
  };
  return (
    <p role={tone === "error" ? "alert" : "status"} className={`rounded-xl px-4 py-3 text-[15px] font-medium ${tones[tone]}`}>
      {children}
    </p>
  );
}

export function Badge({ children, tone = "soft" }: { children: ReactNode; tone?: "soft" | "dark" | "grey" | "warn" | "good" }) {
  const tones = {
    soft: "bg-brand-soft text-brand",
    dark: "bg-brand-dark text-white",
    grey: "bg-slate-100 text-slate-600",
    warn: "bg-orange-50 text-warn",
    good: "bg-green-50 text-good",
  };
  return (
    <span className={`inline-flex items-center rounded-full px-3 py-1 text-[13px] font-bold ${tones[tone]}`}>
      {children}
    </span>
  );
}

export function PageHeader({ eyebrow, title, intro, action }: { eyebrow?: string; title: string; intro?: string; action?: ReactNode }) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div>
        {eyebrow ? <p className="text-sm font-semibold text-muted">{eyebrow}</p> : null}
        <h1 className="text-[28px] font-extrabold leading-tight">{title}</h1>
        {intro ? <p className="mt-1 max-w-2xl text-[15px] text-muted">{intro}</p> : null}
      </div>
      {action}
    </div>
  );
}

export function Credits() {
  return (
    <p className="text-[13px] text-muted">
      Developed by <span className="font-semibold">cmeproject</span>
    </p>
  );
}

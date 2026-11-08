// Staff Portal · © cmeproject. All rights reserved.
import type { ReactNode } from "react";
import type { Branding } from "@/lib/branding";
import { Credits } from "@/components/ui";

// Layout for the sign-in, invite and two-factor pages (cmeprojects): on a
// computer, the company's panel on the left (logo, name, a short welcome) and
// the form on the right; on a phone, the logo above the form.
function Logo({ brand, size }: { brand: Branding; size: "lg" | "md" }) {
  return (
    <div className={`flex items-center justify-center rounded-xl bg-white p-3 ring-1 ring-black/5 ${size === "lg" ? "h-24 w-36" : "h-20 w-32"}`}>
      {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
      <img src={brand.logoUrl} alt={brand.companyName} className="max-h-full max-w-full object-contain" />
    </div>
  );
}

export function AuthShell({ brand, children }: { brand: Branding; children: ReactNode }) {
  return (
    <main className="grid min-h-screen md:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]">
      <aside className="relative hidden flex-col justify-between overflow-hidden bg-brand-dark p-10 text-side-fg md:flex lg:p-14">
        <div aria-hidden="true" className="pointer-events-none absolute -right-24 -bottom-24 size-96 rounded-full bg-white/5" />
        <div aria-hidden="true" className="pointer-events-none absolute -top-16 -left-16 size-64 rounded-full bg-white/5" />
        <Logo brand={brand} size="lg" />
        <div className="relative flex max-w-md flex-col gap-3">
          <p className="text-xs font-semibold tracking-[0.25em] text-side-muted uppercase">{brand.portalName}</p>
          <p className="font-display text-4xl leading-tight font-semibold text-balance">{brand.companyName}</p>
          <p className="text-base leading-relaxed text-side-muted">Tasks, registers, onboarding and your team, in one place.</p>
        </div>
        <p className="relative text-xs text-side-muted">Built by cmeproject</p>
      </aside>
      <div className="flex flex-col items-center justify-center gap-6 px-4 py-10">
        <div className="flex w-full max-w-sm flex-col gap-6">
          <div className="flex flex-col items-center gap-3 text-center md:hidden">
            <Logo brand={brand} size="md" />
            <p className="font-display text-xs font-light tracking-[0.3em] text-muted uppercase">{brand.portalName}</p>
          </div>
          <div className="shadow-card flex flex-col gap-5 rounded-xl border border-line bg-surface p-6">{children}</div>
          {brand.supportContact ? <p className="text-center text-sm whitespace-pre-line text-muted">{brand.supportContact}</p> : null}
        </div>
        <div className="md:hidden">
          <Credits />
        </div>
      </div>
    </main>
  );
}

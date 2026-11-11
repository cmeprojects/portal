// Staff Portal · © cmeproject. All rights reserved.
import type { ReactNode } from "react";
import type { Branding } from "@/lib/branding";
import { Credits } from "@/components/ui";

// Layout for the sign-in, invite and two-factor pages (cmeprojects): one
// centred column on every screen size, with the company logo large at the
// top, then the portal name, the form card, and the support contact.
export function AuthShell({ brand, children }: { brand: Branding; children: ReactNode }) {
  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-page px-4 py-10 sm:py-14">
      <div aria-hidden="true" className="pointer-events-none absolute inset-x-0 top-0 h-72 bg-gradient-to-b from-brand-soft to-transparent" />
      <div className="relative flex w-full max-w-md flex-col items-center gap-6">
        <div className="flex flex-col items-center gap-4 text-center">
          <div className="shadow-card flex h-28 w-48 items-center justify-center rounded-2xl bg-white p-4 ring-1 ring-black/5 sm:h-32 sm:w-56">
            {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
            <img src={brand.logoUrl} alt={brand.companyName} className="max-h-full max-w-full object-contain" />
          </div>
          <div className="flex flex-col gap-1">
            <p className="font-display text-xl font-semibold text-ink sm:text-2xl">{brand.companyName}</p>
            <p className="text-xs font-semibold tracking-[0.25em] text-muted uppercase">{brand.portalName}</p>
          </div>
        </div>
        <div className="shadow-card flex w-full flex-col gap-5 rounded-2xl border border-line bg-surface p-6 sm:p-8">{children}</div>
        {brand.supportContact ? <p className="text-center text-sm whitespace-pre-line text-muted">{brand.supportContact}</p> : null}
        <Credits />
      </div>
    </main>
  );
}

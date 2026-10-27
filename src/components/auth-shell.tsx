// Staff Portal · © cmeproject. All rights reserved.
import type { ReactNode } from "react";
import type { Branding } from "@/lib/branding";
import { Credits } from "@/components/ui";

// Layout for the sign-in, invite and two-factor pages: the company's logo,
// then a single panel, centred.
export function AuthShell({ brand, children }: { brand: Branding; children: ReactNode }) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 px-4 py-10">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <div className="flex flex-col items-center gap-3 text-center">
          <div className="flex h-28 w-40 items-center justify-center rounded-lg bg-white p-3 ring-1 ring-line">
            {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
            <img src={brand.logoUrl} alt={brand.companyName} className="max-h-full max-w-full object-contain" />
          </div>
          <p className="font-display text-xs font-light tracking-[0.3em] text-muted uppercase">{brand.portalName}</p>
        </div>
        <div className="flex flex-col gap-5 rounded-lg border border-line bg-surface p-5">{children}</div>
      </div>
      <Credits />
    </main>
  );
}

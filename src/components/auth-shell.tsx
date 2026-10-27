// Staff Portal · © cmeproject. All rights reserved.
import type { ReactNode } from "react";
import type { Branding } from "@/lib/branding";
import { Credits } from "@/components/ui";

// Layout for the sign-in, invite and two-factor pages: phone-first card
// under the company's full logo.
export function AuthShell({ brand, children }: { brand: Branding; children: ReactNode }) {
  return (
    <main className="flex min-h-screen flex-col items-center bg-page">
      <div className="flex w-full flex-col items-center gap-3 rounded-b-[28px] bg-brand-dark px-6 pb-16 pt-10">
        <div className="flex h-32 w-44 items-center justify-center rounded-[20px] bg-white p-3">
          {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
          <img src={brand.logoUrl} alt={brand.companyName} className="max-h-full max-w-full object-contain" />
        </div>
        <p className="text-[15px] font-semibold text-white/85">{brand.portalName}</p>
      </div>
      <div className="-mt-9 w-full max-w-md px-4">
        <div className="flex flex-col gap-5 rounded-[20px] border border-line bg-white px-5 py-6 sm:px-7">
          {children}
        </div>
      </div>
      <footer className="mt-auto py-6">
        <Credits />
      </footer>
    </main>
  );
}

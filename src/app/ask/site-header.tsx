// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";

// cmeprojects: the website's top bar, in the portal's menu colour. Contact us
// is always there; Sign in until they're signed in (their name and the
// portal link then sit at the bottom of the side panel).
export function SiteHeader({ logoUrl, companyName, showLogo = true, signedIn, children }: { logoUrl: string; companyName: string; showLogo?: boolean; signedIn: boolean; children?: ReactNode }) {
  return (
    <header className="flex items-center gap-3 bg-[var(--side-bg)] px-4 py-2.5 text-side-fg sm:px-6">
      {children}
      <Link href="/ask" aria-label={`${companyName} home`} className={`flex items-center transition-opacity duration-500 ${showLogo ? "opacity-100" : "pointer-events-none opacity-0"}`}>
        {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
        <img src={logoUrl} alt={companyName} className="h-9 w-auto max-w-40 rounded-md bg-white object-contain px-1.5 py-1" />
      </Link>
      <div className="ml-auto flex items-center gap-2">
        <Link href="/ask/get-started" className="inline-flex min-h-10 items-center rounded-full border border-white/40 px-4 text-sm font-semibold hover:bg-[var(--side-hover)]">
          Contact us
        </Link>
        {signedIn ? null : (
          <Link href="/login?next=/ask" className="inline-flex min-h-10 items-center rounded-full bg-white px-4 text-sm font-semibold text-[var(--side-bg)]">
            Sign in
          </Link>
        )}
      </div>
    </header>
  );
}

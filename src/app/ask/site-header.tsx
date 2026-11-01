// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";

// cmeprojects: the website's light top row: the small logo on the left (it can
// fade in once a chat starts), Contact us and Sign in on the right. Signed-in
// staff have their name and the portal link in the side panel instead.
export function SiteHeader({ logoUrl, companyName, showLogo = true, logoClass = "", signedIn, children }: { logoUrl: string; companyName: string; showLogo?: boolean; logoClass?: string; signedIn: boolean; children?: ReactNode }) {
  return (
    <header className="flex items-center gap-2 px-4 py-3 sm:px-6">
      {children}
      <Link href="/ask" aria-label={`${companyName} home`} className={`flex items-center transition-opacity duration-500 ${showLogo ? "opacity-100" : "pointer-events-none opacity-0"} ${logoClass}`}>
        {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
        <img src={logoUrl} alt={companyName} className="h-9 w-auto max-w-36 object-contain" />
      </Link>
      <div className="ml-auto flex items-center gap-2">
        <Link href="/ask/get-started" className="inline-flex min-h-10 items-center rounded-full border border-line bg-surface px-4 text-sm font-semibold hover:border-muted">
          Contact us
        </Link>
        {signedIn ? null : (
          <Link href="/login?next=/ask" className="inline-flex min-h-10 items-center rounded-full bg-brand px-4 text-sm font-semibold text-brand-fg">
            Sign in
          </Link>
        )}
      </div>
    </header>
  );
}

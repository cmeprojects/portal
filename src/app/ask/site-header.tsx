// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";

// cmeprojects: the website's top bar. Signed in: their name, position and a
// link into the portal. Otherwise: Sign in (which comes back here).
export function SiteHeader({ logoUrl, companyName, showLogo = true, visitor }: { logoUrl: string; companyName: string; showLogo?: boolean; visitor: { name: string; position: string } | null }) {
  return (
    <header className="flex items-center justify-between gap-3 px-4 py-3 sm:px-6">
      <Link href="/ask" aria-label={`${companyName} home`} className={`flex items-center gap-3 transition-opacity duration-500 ${showLogo ? "opacity-100" : "pointer-events-none opacity-0"}`}>
        {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
        <img src={logoUrl} alt={companyName} className="h-9 w-auto max-w-40 object-contain" />
      </Link>
      {visitor ? (
        <div className="flex items-center gap-3">
          <div className="hidden text-right leading-tight sm:block">
            <p className="text-sm font-semibold">{visitor.name}</p>
            {visitor.position ? <p className="text-xs text-muted">{visitor.position}</p> : null}
          </div>
          <Link href="/" className="inline-flex min-h-11 items-center rounded-full bg-brand px-4 text-sm font-semibold text-brand-fg">
            Open portal
          </Link>
        </div>
      ) : (
        <Link href="/login?next=/ask" className="inline-flex min-h-11 items-center rounded-full border border-line bg-surface px-4 text-sm font-semibold hover:border-muted">
          Sign in
        </Link>
      )}
    </header>
  );
}

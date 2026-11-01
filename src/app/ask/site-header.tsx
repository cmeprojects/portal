// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";
import { signOutWebsite } from "./actions";

export type HeaderVisitor = { name: string; position: string } | null;

type Props = {
  logoUrl: string;
  companyName: string;
  urgentPhone: string;
  visitor: HeaderVisitor;
  // Something before the logo, for example the chat history button.
  leading?: ReactNode;
};

const pill = "inline-flex min-h-10 items-center rounded-full px-4 text-sm font-semibold";

// cmeprojects: the website's top bar. Logo on the left. On the right:
// visitors get Request a call back, the urgent support number, About and
// Sign in; signed-in staff get their name, About, the portal and Sign out.
export function SiteHeader({ logoUrl, companyName, urgentPhone, visitor, leading }: Props) {
  return (
    <header className="flex flex-wrap items-center gap-x-3 gap-y-2 border-b border-line bg-surface px-4 py-2.5 sm:px-6">
      {leading}
      <Link href="/ask" aria-label={`${companyName} home`} className="flex items-center">
        {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
        <img src={logoUrl} alt={companyName} className="h-10 w-auto max-w-40 object-contain" />
      </Link>

      <nav aria-label="Website" className="ml-auto flex flex-wrap items-center justify-end gap-2">
        {visitor ? (
          <>
            <span className="hidden text-right leading-tight sm:block">
              <span className="block text-sm font-semibold">{visitor.name}</span>
              {visitor.position ? <span className="block text-xs text-muted">{visitor.position}</span> : null}
            </span>
            <Link href="/ask/about" className={`${pill} hover:bg-page`}>
              About
            </Link>
            <Link href="/" className={`${pill} bg-brand text-brand-fg`}>
              Portal
            </Link>
            <form action={signOutWebsite}>
              <button className={`${pill} border border-line hover:bg-page`}>Sign out</button>
            </form>
          </>
        ) : (
          <>
            {urgentPhone ? (
              <a href={`tel:${urgentPhone.replace(/[^\d+]/g, "")}`} className="hidden flex-col items-end leading-tight md:flex">
                <span className="text-xs text-muted">For urgent support please call</span>
                <span className="text-lg font-bold text-brand">{urgentPhone}</span>
              </a>
            ) : null}
            <Link href="/ask/get-started" className={`${pill} border border-brand text-brand hover:bg-brand-soft`}>
              Request a call back
            </Link>
            <Link href="/ask/about" className={`${pill} hover:bg-page`}>
              About
            </Link>
            <Link href="/login?next=/ask" className={`${pill} bg-brand text-brand-fg`}>
              Sign in
            </Link>
          </>
        )}
      </nav>
      {/* On a phone the urgent number gets its own line under the bar. */}
      {!visitor && urgentPhone ? (
        <a href={`tel:${urgentPhone.replace(/[^\d+]/g, "")}`} className="w-full text-center text-sm md:hidden">
          For urgent support please call <strong className="text-brand">{urgentPhone}</strong>
        </a>
      ) : null}
    </header>
  );
}

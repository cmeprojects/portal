// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";

type Props = {
  logoUrl: string;
  companyName: string;
  signedIn: boolean;
  // The button that opens and closes the side panel (pages with chats only).
  toggle?: ReactNode;
};

const outline = "inline-flex min-h-9 items-center rounded-md border border-white/70 px-4 text-sm font-semibold text-white hover:bg-white/10";

// cmeprojects: the website's blue top bar: the panel button, the logo and the
// company name on the left; Request a call back (visitors) and About on the right.
export function SiteHeader({ logoUrl, companyName, signedIn, toggle }: Props) {
  return (
    <header className="sticky top-0 z-30 flex items-center gap-3 bg-brand px-3 py-2.5 text-white sm:px-5">
      {toggle}
      <Link href="/ask" aria-label={`${companyName} home`} className="flex items-center gap-3">
        <span className="flex h-11 items-center rounded-md bg-white px-2">
          {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
          <img src={logoUrl} alt="" className="h-9 w-auto max-w-28 object-contain" />
        </span>
        <span className="hidden font-display text-lg font-semibold sm:inline">{companyName}</span>
      </Link>
      <nav aria-label="Website" className="ml-auto flex items-center gap-2">
        {signedIn ? null : (
          <Link href="/ask/get-started" className={`${outline} bg-white !text-brand hover:bg-white/90`}>
            Request a call back
          </Link>
        )}
        <Link href="/ask/about" className={outline}>
          About
        </Link>
      </nav>
    </header>
  );
}

// The square button that shows or hides the side panel, with its hint on hover.
export function PanelToggle({ open, onClick }: { open: boolean; onClick: () => void }) {
  return (
    <span className="group relative">
      <button
        type="button"
        onClick={onClick}
        aria-expanded={open}
        aria-label={open ? "Hide options" : "Expand to see options"}
        className="flex size-8 items-center justify-center rounded-md border border-white/40 text-white transition hover:bg-white/10"
      >
        <svg viewBox="0 0 24 24" className={`size-4 transition-transform ${open ? "rotate-180" : ""}`} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M6 9l6 6 6-6" />
        </svg>
      </button>
      <span
        role="tooltip"
        className="pointer-events-none absolute top-full left-0 z-40 mt-2 rounded-md bg-ink px-2.5 py-1.5 text-xs whitespace-nowrap text-surface opacity-0 shadow transition-opacity group-hover:opacity-100 group-focus-within:opacity-100"
      >
        {open ? "Hide options" : "Expand to see options"}
      </span>
    </span>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { getBranding } from "@/lib/branding";

export async function generateMetadata(): Promise<Metadata> {
  const { companyName } = await getBranding();
  return {
    title: { default: `Ask ${companyName}`, template: `%s · ${companyName}` },
    description: `Ask questions about ${companyName}'s support services and the NDIS, or leave your details and we'll call you.`,
    robots: { index: true, follow: true },
  };
}

// cmeprojects: the public website around the Assistant. Anyone can open it;
// staff sign in to the portal from here.
export default async function AskLayout({ children }: LayoutProps<"/ask">) {
  const brand = await getBranding();
  const link = "flex min-h-11 items-center rounded-md px-3 text-sm hover:bg-brand-soft";
  return (
    <div className="flex min-h-dvh flex-col bg-page text-ink">
      <header className="flex flex-wrap items-center justify-between gap-3 border-b border-line bg-surface px-4 py-3 sm:px-6">
        <Link href="/ask" className="flex items-center gap-3 font-display text-lg font-semibold">
          {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
          <img src={brand.logoUrl} alt="" className="h-9 w-auto max-w-40 object-contain" />
          <span>{brand.companyName}</span>
        </Link>
        <nav aria-label="Website" className="flex flex-wrap items-center gap-1">
          <Link href="/ask" className={link}>
            Ask a question
          </Link>
          <Link href="/ask/get-started" className={link}>
            Get support
          </Link>
          <Link href="/login" className={`${link} border border-line font-semibold`}>
            Sign in
          </Link>
        </nav>
      </header>
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}

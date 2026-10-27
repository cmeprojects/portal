// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { ROLE_LABELS } from "@/lib/roles";
import { BrandMark } from "@/components/brand-mark";
import { Sidebar } from "@/components/sidebar";
import { ThemeSwitch } from "@/components/theme-switch";
import { navFor } from "@/components/nav";
import { signOut } from "@/app/login/actions";

// Frame for every page after sign-in: the company's sidebar on desktop, a top
// bar with a drop-down menu on phones.
export default async function PortalLayout({ children }: LayoutProps<"/">) {
  const [{ profile, features }, brand] = await Promise.all([requireSession(), getBranding()]);

  const footer = (
    <div className="flex flex-wrap items-center justify-between gap-3 md:flex-col md:items-start">
      <Link href="/account" className="min-w-0 rounded-md text-sm" title="My account">
        <p className="truncate font-medium text-side-fg underline-offset-2 hover:underline">{profile.full_name || profile.email}</p>
        <p className="text-xs text-side-muted">{ROLE_LABELS[profile.role]} · My account</p>
      </Link>
      <form action={signOut}>
        <button className="min-h-9 text-xs text-side-muted underline hover:text-side-fg">Sign out</button>
      </form>
      <ThemeSwitch />
      <p className="text-[11px] text-side-muted">Built by cmeproject</p>
    </div>
  );

  return (
    <div className="min-h-screen md:grid md:grid-cols-[230px_minmax(0,1fr)]">
      <Sidebar groups={navFor(profile.role, features)} brandMark={<BrandMark brand={brand} />} footer={footer} />
      <main className="mx-auto flex w-full max-w-6xl min-w-0 flex-col gap-6 px-4 py-6 md:px-8 md:py-8">{children}</main>
    </div>
  );
}

// Staff Portal · © cmeproject. All rights reserved.
import { requireSession } from "@/lib/session";
import { getBranding } from "@/lib/branding";
import { ROLE_LABELS } from "@/lib/roles";
import { BrandMark } from "@/components/brand-mark";
import { Sidebar } from "@/components/sidebar";
import { navFor } from "@/components/nav";
import { Credits } from "@/components/ui";
import { signOut } from "@/app/login/actions";

export default async function PortalLayout({ children }: LayoutProps<"/">) {
  const [{ profile, features }, brand] = await Promise.all([requireSession(), getBranding()]);

  const footer = (
    <div className="flex flex-col gap-3 px-3">
      <div>
        <p className="font-semibold text-white">{profile.full_name || profile.email}</p>
        <p className="text-sm text-white/70">{ROLE_LABELS[profile.role]}</p>
      </div>
      <form action={signOut}>
        <button className="min-h-11 rounded-full border border-white/30 px-4 text-sm font-semibold text-white hover:bg-white/10">
          Sign out
        </button>
      </form>
    </div>
  );

  return (
    <div className="min-h-screen lg:flex">
      <Sidebar groups={navFor(profile.role, features)} brandMark={<BrandMark brand={brand} onDark />} footer={footer} />
      <div className="flex min-w-0 flex-1 flex-col">
        <main className="flex flex-1 flex-col gap-6 px-4 py-6 sm:px-8 sm:py-8">{children}</main>
        <footer className="px-4 pb-6 sm:px-8">
          <Credits />
        </footer>
      </div>
    </div>
  );
}

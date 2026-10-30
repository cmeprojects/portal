// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata, Viewport } from "next";
import { getBranding, getCarsAppLook } from "@/lib/branding";
import { getSession } from "@/lib/session";
import { LiveRefresh } from "@/components/live-refresh";

// The Cars app (cmeprojects): installed on staff phones from the portal link.
// A plain, full-screen frame: the company's bar on top, big buttons below.
export async function generateMetadata(): Promise<Metadata> {
  const [brand, look] = await Promise.all([getBranding(), getCarsAppLook()]);
  return {
    title: { default: `${brand.companyName} Cars`, template: `%s · ${brand.companyName} Cars` },
    manifest: "/cars-app/manifest.webmanifest",
    appleWebApp: { capable: true, title: look.name, statusBarStyle: "black-translucent" },
    icons: { icon: "/cars-app/icon/192", apple: "/cars-app/icon/180" },
  };
}

export async function generateViewport(): Promise<Viewport> {
  const brand = await getBranding();
  return { width: "device-width", initialScale: 1, viewportFit: "cover", themeColor: brand.colorDark };
}

export default async function CarsAppLayout({ children }: LayoutProps<"/cars-app">) {
  const [brand, session, look] = await Promise.all([getBranding(), getSession(), getCarsAppLook()]);
  const name = session?.profile.full_name || session?.profile.email || "";
  return (
    <div className="flex min-h-dvh flex-col bg-page">
      <header className="sticky top-0 z-30 bg-[var(--side-bg)] pt-[env(safe-area-inset-top)] text-side-fg">
        <div className="mx-auto flex max-w-xl items-center gap-3 px-4 py-3">
          {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
          <img src={brand.logoMarkUrl} alt="" className="size-9 shrink-0 rounded-md bg-white object-contain p-0.5" />
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate font-display text-sm font-semibold tracking-wider uppercase">{brand.companyName}</p>
            <p className="text-[11px] tracking-[0.2em] text-side-muted uppercase">{look.name}</p>
          </div>
          {name ? <p className="max-w-[40%] truncate text-right text-xs text-side-muted">{name}</p> : null}
        </div>
      </header>
      <LiveRefresh tables={["app_settings", "features", "cars"]} onShow />
      <main className="mx-auto flex w-full max-w-xl flex-1 flex-col gap-4 px-4 pt-4 pb-[calc(env(safe-area-inset-bottom)+1.5rem)]">{children}</main>
    </div>
  );
}

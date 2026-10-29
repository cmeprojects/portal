// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import QRCode from "qrcode";
import { requireSession } from "@/lib/session";
import { canManageCars, canUseCars, getCarRules } from "@/lib/cars";
import { getBranding } from "@/lib/branding";
import { env } from "@/lib/env";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { PrintButton } from "@/components/print-button";

export const metadata: Metadata = { title: "Get the Cars app" };

const qr = (url: string) => QRCode.toString(url, { type: "svg", margin: 1, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } });

// How staff install the Cars app, a poster for the office, and a QR sticker
// for each car's dashboard (scanning it opens that car in the app).
export default async function InstallCarsAppPage({ searchParams }: PageProps<"/cars/install">) {
  const { profile, features } = await requireSession();
  if (!canUseCars(profile.role, features)) redirect("/");
  const [brand, rules, params] = await Promise.all([getBranding(), getCarRules(), searchParams]);
  const manages = canManageCars(profile.role, rules);
  const appUrl = `${env.siteUrl}/cars-app`;
  const onlyCar = typeof params.car === "string" ? params.car : "";
  const supabase = await createClient();
  const { data: cars } = manages ? await supabase.from("cars").select("id, name, rego").eq("active", true).order("name") : { data: [] };
  const stickers = (cars ?? []).filter((c) => !onlyCar || c.id === onlyCar);
  const [posterSvg, ...carSvgs] = await Promise.all([qr(appUrl), ...stickers.map((c) => qr(`${appUrl}?car=${c.id}`))]);

  return (
    <>
      <div className="print:hidden">
        <SectionTabs section="cars" current="/cars/install" />
        <PageHeader
          eyebrow="Cars"
          title="Get the Cars app"
          intro="Put Cars on your phone's home screen. It's free, there's nothing to download from an app store, and it updates itself."
          action={<PrintButton label={onlyCar ? "Print the sticker" : "Print poster and stickers"} />}
        />
      </div>

      {!onlyCar ? (
        <div className="grid gap-4 md:grid-cols-2 print:hidden">
          <Card className="flex flex-col gap-2 p-5">
            <h2 className="heading-sm">iPhone</h2>
            <ol className="list-decimal space-y-1 pl-5 text-sm">
              <li>Open <strong>{appUrl}</strong> in <strong>Safari</strong> (or scan the QR code with the camera).</li>
              <li>Sign in with your email and password.</li>
              <li>Choose a 4-number PIN.</li>
              <li>Tap <strong>Share</strong> (the square with an arrow), then <strong>Add to Home Screen</strong>, then <strong>Add</strong>.</li>
            </ol>
          </Card>
          <Card className="flex flex-col gap-2 p-5">
            <h2 className="heading-sm">Android</h2>
            <ol className="list-decimal space-y-1 pl-5 text-sm">
              <li>Open <strong>{appUrl}</strong> in <strong>Chrome</strong> (or scan the QR code with the camera).</li>
              <li>Sign in with your email and password.</li>
              <li>Choose a 4-number PIN.</li>
              <li>Tap <strong>Install app</strong> when it pops up, or the <strong>⋮</strong> menu, then <strong>Install app</strong>.</li>
            </ol>
          </Card>
          <Card className="flex flex-col gap-2 p-5 md:col-span-2">
            <h2 className="heading-sm">After that</h2>
            <p className="text-sm">
              Open <strong>Cars</strong> from your home screen and enter your PIN. You stay signed in for {rules.appDays} days, then sign in
              with your email once more. Forgot your PIN? Tap &quot;Forgot your PIN?&quot;, sign in, and choose a new one. The app only
              opens Cars; the rest of the portal still asks you to sign in as usual.
            </p>
          </Card>
        </div>
      ) : null}

      {/* The poster: one per page when printed. */}
      {!onlyCar ? (
        <section className="flex flex-col items-center gap-4 rounded-xl border border-line bg-white p-8 text-center text-black print:break-after-page print:border-0">
          {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
          <img src={brand.logoUrl} alt="" className="h-20 w-auto object-contain" />
          <p className="font-display text-3xl font-semibold tracking-wide uppercase">Using a company car?</p>
          <p className="max-w-md text-lg">Scan this with your phone camera to get the {brand.companyName} Cars app.</p>
          <div className="w-64 max-w-full" dangerouslySetInnerHTML={{ __html: posterSvg }} />
          <p className="text-sm">{appUrl}</p>
          <p className="max-w-md text-sm">Sign in once, choose a PIN, then press Start when you take a car and Return when you bring it back.</p>
        </section>
      ) : null}

      {manages && stickers.length ? (
        <section className="flex flex-col gap-3">
          <h2 className="heading-sm print:hidden">Dashboard stickers</h2>
          <p className="text-sm text-muted print:hidden">Scanning a car&apos;s sticker opens the app with that car already picked.</p>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 print:grid-cols-2">
            {stickers.map((c, i) => (
              <div key={c.id} className="flex break-inside-avoid flex-col items-center gap-2 rounded-xl border-2 border-dashed border-black/40 bg-white p-4 text-center text-black">
                <p className="text-sm font-semibold">{brand.companyName}</p>
                <div className="w-40" dangerouslySetInnerHTML={{ __html: carSvgs[i] }} />
                <p className="text-lg font-semibold">{c.name}</p>
                <p className="rounded border-2 border-black px-2 font-semibold tracking-widest">{c.rego}</p>
                <p className="text-xs">Scan to start or return this car</p>
              </div>
            ))}
          </div>
        </section>
      ) : null}
    </>
  );
}

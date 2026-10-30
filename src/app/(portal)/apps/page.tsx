// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import QRCode from "qrcode";
import { requireSession } from "@/lib/session";
import { canManageCars, canUseCars, getCarRules } from "@/lib/cars";
import { getBranding, getCarsAppLook, getStaffAppLook, initialsOf } from "@/lib/branding";
import { carsAppOffered, getStaffAppTiles, staffAppOn } from "@/lib/staff-app";
import { createClient } from "@/lib/supabase/server";
import { env } from "@/lib/env";
import { Card, PageHeader } from "@/components/ui";
import { PrintButton } from "@/components/print-button";
import { AppSquare } from "@/components/app-glyph";

export async function generateMetadata(): Promise<Metadata> {
  return { title: `${initialsOf((await getBranding()).companyName) || "Our"} Apps` };
}

const qr = (url: string) => QRCode.toString(url, { type: "svg", margin: 1, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } });

// cmeprojects: the company's phone apps (the Cars app and the Staff app),
// with how to put each on a phone, and QR stickers for those who print them.
export default async function AppsPage() {
  const { profile, features } = await requireSession();
  const [brand, carsLook, staffLook, rules, tiles, carsOffered] = await Promise.all([
    getBranding(),
    getCarsAppLook(),
    getStaffAppLook(),
    getCarRules(),
    getStaffAppTiles(profile.id, profile.role, features),
    carsAppOffered(features),
  ]);
  const carsApp = canUseCars(profile.role, features) && carsOffered;
  const staffApp = staffAppOn(features) && (tiles.length > 0 || profile.role === "system_admin");
  if (!carsApp && !staffApp) redirect("/");
  const title = `${initialsOf(brand.companyName) || "Our"} Apps`;
  const prints = profile.role === "system_admin" || profile.role === "manager";
  const carsUrl = `${env.siteUrl}/cars-app`;
  const staffUrl = `${env.siteUrl}/app`;

  // Stickers for each feature in the Staff app (managers and the system admin print them).
  const supabase = await createClient();
  const { data: inApp } =
    staffApp && prints
      ? await supabase.from("custom_features").select("slug, name, menu_label, app_icon, app_colour").eq("status", "published").eq("enabled", true).eq("in_app", true).order("sort_order")
      : { data: [] };
  const [carsQr, staffQr, ...featureQrs] = await Promise.all([
    qr(carsUrl),
    qr(staffUrl),
    ...(inApp ?? []).map((f) => qr(`${staffUrl}/f/${f.slug}`)),
  ]);

  const apps = [
    carsApp && {
      key: "cars",
      name: carsLook.name,
      icon: "/cars-app/icon/192",
      url: carsUrl,
      svg: carsQr,
      what: "Start and return company cars. Your trips and kilometres are recorded for you.",
      inside: ["Cars"],
    },
    staffApp && {
      key: "staff",
      name: staffLook.name,
      icon: "/app/icon/192",
      url: staffUrl,
      svg: staffQr,
      what: "Everything you fill in on the go, in one app.",
      inside: tiles.map((t) => t.label),
    },
  ].filter((a): a is Exclude<typeof a, false> => Boolean(a));

  return (
    <>
      <div className="print:hidden">
        <PageHeader
          title={title}
          intro={`${brand.companyName}'s apps for your phone. They're free, there's nothing to download from an app store, and they update themselves. One PIN opens them all.`}
          action={prints ? <PrintButton label="Print posters and stickers" /> : undefined}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2 print:hidden">
        {apps.map((a) => (
          <Card key={a.key} className="flex flex-col gap-4 p-5">
            <div className="flex items-center gap-4">
              {/* eslint-disable-next-line @next/next/no-img-element -- the app's own icon */}
              <img src={a.icon} alt="" className="size-16 rounded-2xl shadow-md" />
              <div className="min-w-0">
                <h2 className="heading-sm">{a.name}</h2>
                <p className="text-sm text-muted">{a.what}</p>
                {a.inside.length ? <p className="mt-1 text-xs text-muted">Inside: {a.inside.join(", ")}</p> : null}
              </div>
            </div>
            <div className="flex flex-wrap items-start gap-5">
              <div className="flex w-32 flex-col items-center gap-1 text-center">
                <div className="w-32 rounded-lg border border-line bg-white p-1.5" dangerouslySetInnerHTML={{ __html: a.svg }} />
                <span className="text-xs text-muted">On a computer? Scan this with your phone camera.</span>
              </div>
              <div className="min-w-0 flex-1 text-sm">
                <p className="mb-1 font-semibold">On your phone:</p>
                <a href={a.key === "cars" ? "/cars-app" : "/app"} className="mb-3 inline-block rounded-md bg-brand px-4 py-2.5 font-semibold text-brand-fg">
                  Open {a.name}
                </a>
                <p className="font-semibold">iPhone (Safari)</p>
                <ol className="mb-2 list-decimal pl-5">
                  <li>Open it in <strong>Safari</strong> and sign in.</li>
                  <li>Choose a 4-number PIN (or enter yours).</li>
                  <li>Tap <strong>Share</strong> (the square with an arrow), then <strong>Add to Home Screen</strong>, then <strong>Add</strong>.</li>
                </ol>
                <p className="font-semibold">Android (Chrome)</p>
                <ol className="list-decimal pl-5">
                  <li>Open it in <strong>Chrome</strong> and sign in.</li>
                  <li>Choose a 4-number PIN (or enter yours).</li>
                  <li>Tap <strong>Install app</strong> when it pops up, or the <strong>⋮</strong> menu, then <strong>Install app</strong>.</li>
                </ol>
              </div>
            </div>
          </Card>
        ))}
      </div>
      <Card className="p-5 text-sm print:hidden">
        <h2 className="heading-sm">After that</h2>
        <p className="mt-1">
          Open the app from your home screen and enter your PIN. You stay signed in for {rules.appDays} days, then sign in with your email once
          more. It&apos;s the same PIN for every app. Forgot it? Tap &quot;Forgot your PIN?&quot;, sign in, and choose a new one. The apps only
          open what&apos;s in them; the rest of the portal still asks you to sign in as usual.
        </p>
      </Card>

      {prints ? (
        <>
          <h2 className="heading-sm print:hidden">Posters and stickers to print</h2>
          {apps.map((a) => (
            <section key={a.key} className="flex break-inside-avoid flex-col items-center gap-3 rounded-xl border border-line bg-white p-8 text-center text-black print:break-after-page print:border-0">
              {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
              <img src={brand.logoUrl} alt="" className="h-16 w-auto object-contain" />
              <p className="font-display text-2xl font-semibold tracking-wide uppercase">Get the {a.name} app</p>
              <p className="max-w-md">Scan this with your phone camera, sign in once and choose a PIN.</p>
              <div className="w-56 max-w-full" dangerouslySetInnerHTML={{ __html: a.svg }} />
              <p className="text-sm">{a.url}</p>
            </section>
          ))}
          {(inApp ?? []).length ? (
            <section className="flex flex-col gap-3">
              <p className="text-sm text-muted print:hidden">
                Stick these where the job happens (the fridge, a client&apos;s room). Scanning one opens {staffLook.name} straight on that feature.
              </p>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 print:grid-cols-2">
                {(inApp ?? []).map((f, i) => (
                  <div key={f.slug} className="flex break-inside-avoid flex-col items-center gap-2 rounded-xl border-2 border-dashed border-black/40 bg-white p-4 text-center text-black">
                    <div className="flex items-center gap-2">
                      <AppSquare icon={f.app_icon} colour={f.app_colour} size="size-10" />
                      <p className="text-lg font-semibold">{f.name}</p>
                    </div>
                    <div className="w-40" dangerouslySetInnerHTML={{ __html: featureQrs[i] }} />
                    <p className="text-xs">Scan to open {f.menu_label} in {staffLook.name}</p>
                  </div>
                ))}
              </div>
            </section>
          ) : null}
          {carsApp && canManageCars(profile.role, rules) ? (
            <p className="text-sm text-muted print:hidden">
              Dashboard stickers for each car are on{" "}
              <Link href="/cars/install" className="font-semibold text-brand underline">
                Cars → Get the app
              </Link>
              .
            </p>
          ) : null}
        </>
      ) : null}
    </>
  );
}

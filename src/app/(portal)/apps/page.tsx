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
import { AutoPrint } from "@/components/auto-print";

export async function generateMetadata(): Promise<Metadata> {
  return { title: `${initialsOf((await getBranding()).companyName) || "Our"} Apps` };
}

// "EC Cars" → "EC Cars app", but "EC APP" stays "EC APP".
const appLabel = (name: string) => (/\bapp$/i.test(name.trim()) ? name.trim() : `${name.trim()} app`);

const qr = (url: string) => QRCode.toString(url, { type: "svg", margin: 1, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } });

// cmeprojects: the company's phone apps (the Cars app and the Staff app),
// with how to put each on a phone, and QR stickers for those who print them.
export default async function AppsPage({ searchParams }: PageProps<"/apps">) {
  const { profile, features } = await requireSession();
  // ?sticker=car-<id> or f-<slug>: just that one sticker, to print.
  const query = await searchParams;
  const only = typeof query.sticker === "string" ? query.sticker : "";
  const printNow = query.print === "1";
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
  // Dashboard stickers for each car (car managers): open that car in whichever app has Cars.
  const carManager = canUseCars(profile.role, features) && canManageCars(profile.role, rules);
  const { data: cars } = carManager ? await supabase.from("cars").select("id, name, rego").eq("active", true).order("name") : { data: [] };
  const carBase = carsOffered ? carsUrl : `${staffUrl}/cars`;
  const [carsQr, staffQr, ...rest] = await Promise.all([
    qr(carsUrl),
    qr(staffUrl),
    ...(inApp ?? []).map((f) => qr(`${staffUrl}/f/${f.slug}`)),
    ...(cars ?? []).map((c) => qr(`${carBase}?car=${c.id}`)),
  ]);
  const featureQrs = rest.slice(0, (inApp ?? []).length);
  const carQrs = rest.slice((inApp ?? []).length);
  // Each sticker: the company's logo, what it's for, the QR code, and which app it opens.
  type Sticker = { key: string; title: string; sub: string; line: string; svg: string; app: string; appIcon: string; icon?: { icon: string; colour: string } };
  const carApp = carsOffered ? { app: carsLook.name, appIcon: "/cars-app/icon/192" } : { app: staffLook.name, appIcon: "/app/icon/192" };
  const stickers: Sticker[] = [
    ...(carsApp && prints
      ? [{ key: "app-cars", title: appLabel(carsLook.name), sub: "For company cars", line: "Scan to get the app, sign in once and choose a PIN", svg: carsQr, app: carsLook.name, appIcon: "/cars-app/icon/192" }]
      : []),
    ...(staffApp && prints
      ? [{ key: "app-staff", title: appLabel(staffLook.name), sub: "For staff", line: "Scan to get the app, sign in once and choose a PIN", svg: staffQr, app: staffLook.name, appIcon: "/app/icon/192" }]
      : []),
    ...(inApp ?? []).map((f, i) => ({
      key: `f-${f.slug}`,
      title: f.name,
      sub: f.menu_label !== f.name ? f.menu_label : "",
      line: `Scan to open ${f.menu_label}`,
      svg: featureQrs[i],
      app: staffLook.name,
      appIcon: "/app/icon/192",
      icon: { icon: f.app_icon, colour: f.app_colour },
    })),
    ...(cars ?? []).map((c, i) => ({
      key: `car-${c.id}`,
      title: c.name,
      sub: c.rego,
      line: "Scan to start or return this car",
      svg: carQrs[i],
      ...carApp,
      icon: { icon: "car", colour: "#134f8e" },
    })),
  ];
  const single = only ? stickers.find((x) => x.key === only) : undefined;

  const stickerCard = (x: Sticker, big = false) => (
    <div
      className={`flex h-full break-inside-avoid flex-col items-center gap-1.5 rounded-xl border-2 border-dashed border-black/40 bg-white text-center text-black ${big ? "p-6" : "p-3 print:gap-2 print:p-4"}`}
    >
      {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
      <img src={brand.logoUrl} alt={brand.companyName} className={`${big ? "h-14" : "h-7 print:h-10"} w-auto object-contain`} />
      <div className="flex items-center gap-2">
        {x.icon ? <AppSquare icon={x.icon.icon} colour={x.icon.colour} size={big ? "size-12" : "size-8 print:size-10"} /> : null}
        <span className="text-left">
          <span className={`block leading-tight font-semibold ${big ? "text-2xl" : "text-sm print:text-base"}`}>{x.title}</span>
          {x.sub ? <span className="block text-xs font-semibold tracking-wider print:text-sm">{x.sub}</span> : null}
        </span>
      </div>
      <div className={big ? "w-56" : "w-24 print:w-32"} dangerouslySetInnerHTML={{ __html: x.svg }} />
      <p className={big ? "text-sm" : "text-[11px] leading-tight print:text-xs"}>{x.line}</p>
      <span className="mt-auto flex items-center gap-1.5 rounded-full border border-black/30 py-0.5 pr-3 pl-0.5 text-xs font-semibold">
        {/* eslint-disable-next-line @next/next/no-img-element -- the app's own icon */}
        <img src={x.appIcon} alt="" className="size-5 rounded-full" />
        {appLabel(x.app)}
      </span>
    </div>
  );

  // A whole-page poster for an app (the noticeboard).
  const poster = (name: string, svg: string, url: string) => (
    <section className="flex break-inside-avoid flex-col items-center gap-4 rounded-xl border border-line bg-white p-8 text-center text-black print:min-h-[85vh] print:justify-center print:gap-6 print:break-after-page print:border-0">
      {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
      <img src={brand.logoUrl} alt={brand.companyName} className="h-16 w-auto object-contain print:h-28" />
      <p className="font-display text-2xl font-semibold tracking-wide uppercase print:text-5xl">Get the {appLabel(name)}</p>
      <p className="max-w-md print:max-w-xl print:text-2xl">Scan this with your phone camera, sign in once and choose a PIN.</p>
      <div className="w-56 max-w-full print:w-[26rem]" dangerouslySetInnerHTML={{ __html: svg }} />
      <p className="text-sm print:text-lg">{url}</p>
    </section>
  );
  const appPoster = (key: string) => (key === "app-cars" ? poster(carsLook.name, carsQr, carsUrl) : poster(staffLook.name, staffQr, staffUrl));

  // One sticker on its own, ready to print.
  if (single) {
    return (
      <>
        <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
          <Link href="/apps" className="text-sm font-semibold text-brand underline">
            ‹ Back to {`${initialsOf(brand.companyName) || "Our"} Apps`}
          </Link>
          <PrintButton label={single.key.startsWith("app-") ? "Print this poster" : "Print this sticker"} />
        </div>
        {printNow ? <AutoPrint /> : null}
        {single.key.startsWith("app-") ? (
          <div className="mx-auto w-full max-w-xl print:max-w-none">{appPoster(single.key)}</div>
        ) : (
          <div className="mx-auto w-80 max-w-full">{stickerCard(single, true)}</div>
        )}
      </>
    );
  }

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
          {/* The posters print full page; on screen they're the first tiles below. */}
          {apps.map((a) => (
            <div key={a.key} className="hidden print:block">
              {appPoster(a.key === "cars" ? "app-cars" : "app-staff")}
            </div>
          ))}
          {stickers.length ? (
            <section className="flex flex-col gap-3">
              <p className="text-sm text-muted print:hidden">
                Stick these where the job happens: on the fridge, in a client&apos;s room, on each car&apos;s dashboard. Scanning one opens the app
                straight on it. Tap a sticker to print just that one, or print them all with the button at the top.
              </p>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 print:grid-cols-4 print:gap-3">
                {stickers.map((x) => (
                  <Link
                    key={x.key}
                    href={`/apps?sticker=${x.key}&print=1`}
                    title={x.key.startsWith("app-") ? `Print the ${x.title} poster` : `Print the ${x.title} sticker`}
                    className={`group flex flex-col gap-1 rounded-xl outline-offset-4 hover:outline-2 hover:outline-brand ${x.key.startsWith("app-") ? "print:hidden" : ""}`}
                  >
                    {stickerCard(x)}
                    <span className="self-center text-xs font-semibold text-brand group-hover:underline print:hidden">
                      {x.key.startsWith("app-") ? "Tap to print the poster" : "Tap to print"}
                    </span>
                  </Link>
                ))}
              </div>
            </section>
          ) : null}
        </>
      ) : null}
    </>
  );
}

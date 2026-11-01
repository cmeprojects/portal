// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { getBranding } from "@/lib/branding";
import { getVisitor, getWebsiteContent, loadSettings } from "@/lib/assistant";
import { Credits } from "@/components/ui";
import { SiteHeader } from "../site-header";
import { siteBase, websiteMetadata } from "../seo";

export async function generateMetadata(): Promise<Metadata> {
  const brand = await getBranding();
  const site = await getWebsiteContent(brand.logoUrl);
  return websiteMetadata("/ask/about", { title: "About us", description: site.aboutIntro.slice(0, 160) || undefined });
}

// cmeprojects: the company's About page: who they are, mission, vision and
// services (all set in Website settings), with details search engines read.
export default async function AboutPage() {
  const [brand, visitor, settings, base] = await Promise.all([getBranding(), getVisitor(), loadSettings(), siteBase()]);
  const site = await getWebsiteContent(brand.logoUrl);
  const me = visitor.userId ? { name: visitor.name, position: visitor.position } : null;
  // Structured details for search engines (who the company is and how to call).
  const organisation = {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: brand.companyName,
    url: base,
    logo: site.logoUrl.startsWith("http") ? site.logoUrl : `${base}${site.logoUrl}`,
    description: site.aboutIntro || undefined,
    telephone: settings.phone || undefined,
    areaServed: "AU",
    makesOffer: site.services.map((name) => ({ "@type": "Offer", itemOffered: { "@type": "Service", name } })),
  };
  const section = (title: string, text: string) =>
    text ? (
      <section className="flex flex-col gap-2">
        <h2 className="font-display text-xl font-semibold">{title}</h2>
        <p className="leading-relaxed whitespace-pre-line text-muted">{text}</p>
      </section>
    ) : null;

  return (
    <>
      <SiteHeader logoUrl={site.logoUrl} companyName={brand.companyName} signedIn={Boolean(me)} />
      <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-8 px-4 py-10 sm:py-14">
        <h1 className="font-display text-3xl font-semibold tracking-tight sm:text-4xl">About {brand.companyName}</h1>
        {section("Who we are", site.aboutIntro)}
        {section("Our mission", site.mission)}
        {section("Our vision", site.vision)}
        {site.services.length ? (
          <section className="flex flex-col gap-3">
            <h2 className="font-display text-xl font-semibold">Our services</h2>
            <ul className="grid gap-2 sm:grid-cols-2">
              {site.services.map((s) => (
                <li key={s} className="rounded-lg border border-line bg-surface px-4 py-3">
                  {s}
                </li>
              ))}
            </ul>
          </section>
        ) : null}
        {!site.aboutIntro && !site.mission && !site.vision && !site.services.length ? (
          <p className="text-muted">More about us is coming soon.</p>
        ) : null}
        <div className="flex flex-wrap gap-3">
          <Link href="/ask" className="inline-flex min-h-11 items-center rounded-full bg-brand px-5 text-sm font-semibold text-brand-fg">
            Ask a question
          </Link>
          {me ? null : (
            <Link href="/ask/get-started" className="inline-flex min-h-11 items-center rounded-full border border-brand px-5 text-sm font-semibold text-brand">
              Request a call back
            </Link>
          )}
        </div>
      </main>
      <footer className="px-4 pb-4 text-center">{settings.show_credits ? <Credits /> : null}</footer>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(organisation).replace(/</g, "\\u003c") }} />
    </>
  );
}

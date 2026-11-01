// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { getWebsiteContent } from "@/lib/assistant";
import { env } from "@/lib/env";

// cmeprojects: search-engine details for the public website, from Website
// settings → Search engines (SEO). The portal itself stays hidden from search.
export async function siteBase(): Promise<string> {
  const brand = await getBranding();
  const site = await getWebsiteContent(brand.logoUrl);
  return site.siteUrl || env.siteUrl;
}

// The website's home address: "/" when it's the front page, otherwise "/ask".
export async function homePath(): Promise<string> {
  const brand = await getBranding();
  return (await getWebsiteContent(brand.logoUrl)).frontPage ? "/" : "/ask";
}

export async function websiteMetadata(path: string, page?: { title: string; description?: string }): Promise<Metadata> {
  const brand = await getBranding();
  const site = await getWebsiteContent(brand.logoUrl);
  const base = site.siteUrl || env.siteUrl;
  if (path === "/" && !site.frontPage) path = "/ask";
  const title = page ? `${page.title} · ${brand.companyName}` : site.seoTitle || `${brand.companyName} | NDIS support services`;
  const description =
    page?.description || site.seoDescription || `Ask ${brand.companyName} about our NDIS support services, or request a call back from our team.`;
  return {
    metadataBase: new URL(base),
    title: { absolute: title },
    description,
    alternates: { canonical: path },
    robots: { index: true, follow: true },
    openGraph: { type: "website", url: path, siteName: brand.companyName, title, description, images: [{ url: site.logoUrl }], locale: "en_AU" },
    twitter: { card: "summary", title, description, images: [site.logoUrl] },
  };
}

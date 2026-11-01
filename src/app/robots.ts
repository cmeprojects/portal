// Staff Portal · © cmeproject. All rights reserved.
import type { MetadataRoute } from "next";
import { siteBase } from "./ask/seo";

// cmeprojects: search engines may read the public website (the front page and
// /ask pages) and nothing else: the staff portal stays out of search results
// (its pages also say "noindex").
export default async function robots(): Promise<MetadataRoute.Robots> {
  const base = await siteBase().catch(() => "");
  return {
    rules: [{ userAgent: "*", allow: ["/$", "/ask", "/ask/about", "/ask/get-started"], disallow: ["/"] }],
    sitemap: base ? `${base}/sitemap.xml` : undefined,
  };
}

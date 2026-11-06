// Staff Portal · © cmeproject. All rights reserved.
import type { MetadataRoute } from "next";
import { connection } from "next/server";
import { homePath, siteBase } from "./ask/seo";

// cmeprojects: the public website's pages, for search engines.
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  // cmeprojects: made when asked for, not while building (a build has no database).
  await connection();
  const [base, home] = await Promise.all([siteBase(), homePath()]);
  const now = new Date();
  return [
    { url: `${base}${home}`, lastModified: now, changeFrequency: "weekly", priority: 1 },
    { url: `${base}/ask/about`, lastModified: now, changeFrequency: "monthly", priority: 0.8 },
    { url: `${base}/ask/get-started`, lastModified: now, changeFrequency: "monthly", priority: 0.7 },
  ];
}

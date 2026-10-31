// Staff Portal · © cmeproject. All rights reserved.
import type { MetadataRoute } from "next";

// A private staff portal: search engines are asked not to look at any of it
// (every page also says "noindex"), except the public website at /ask. Shared links still show the name and logo.
export default function robots(): MetadataRoute.Robots {
  return { rules: [{ userAgent: "*", allow: ["/ask"], disallow: ["/"] }] };
}

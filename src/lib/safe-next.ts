// Staff Portal · © cmeproject. All rights reserved.

// Only allow redirects to pages on this site (never to another website).
// cmeprojects (Zero Trust review, 28 Nov 2026): browsers drop tabs and new lines from an address
// and read a backslash as a slash, so "/<tab>/evil.example" or "/\evil.example" would leave the
// site. Refuse any control character, space or backslash, then check by parsing that the result
// is still a path on this site.
export function safeNext(value: unknown, fallback = "/"): string {
  if (typeof value !== "string" || value.length > 2000) return fallback;
  if (!value.startsWith("/") || value.startsWith("//")) return fallback;
  // eslint-disable-next-line no-control-regex -- control characters are exactly what's refused
  if (/[\u0000- \u007f\\]/.test(value)) return fallback;
  try {
    const base = "https://this-site.invalid";
    const url = new URL(value, base);
    // Checked again after the address is tidied ("/.//x" becomes "//x", another website).
    if (url.origin !== base || url.pathname.startsWith("//")) return fallback;
    return `${url.pathname}${url.search}${url.hash}`;
  } catch {
    return fallback;
  }
}

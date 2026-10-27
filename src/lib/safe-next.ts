// Staff Portal · © cmeproject. All rights reserved.

// Only allow redirects to pages on this site (never to another website).
export function safeNext(value: unknown, fallback = "/"): string {
  if (typeof value !== "string") return fallback;
  if (!value.startsWith("/") || value.startsWith("//") || value.startsWith("/\\")) return fallback;
  return value;
}

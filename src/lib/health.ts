// Staff Portal · © cmeproject. All rights reserved.

// System health sums (cmeprojects): how full the database and file storage
// are for the Supabase plan. Pure, so they can be checked without a database.

export type Plan = "free" | "pro";

const MB = 1024 * 1024;
const GB = 1024 * MB;

// Supabase limits: Free 500 MB database and 1 GB files; Pro 8 GB and 100 GB.
export const LIMITS = {
  database: { free: 500 * MB, pro: 8 * GB },
  files: { free: 1 * GB, pro: 100 * GB },
} as const;

export type Level = "ok" | "warn" | "full";
export const level = (pct: number): Level => (pct >= 90 ? "full" : pct >= 75 ? "warn" : "ok");

export type Meter = { key: string; label: string; used: number; limit: number; pct: number; level: Level; note: string };

export function bytes(n: number) {
  if (n >= GB) return `${(n / GB).toFixed(n >= 10 * GB ? 0 : 1)} GB`;
  if (n >= MB) return `${(n / MB).toFixed(n >= 10 * MB ? 0 : 1)} MB`;
  return `${Math.max(1, Math.round(n / 1024))} KB`;
}

export function meter(key: string, label: string, used: number, limit: number, note: string): Meter {
  const pct = limit > 0 ? Math.min(100, (used / limit) * 100) : 0;
  return { key, label, used, limit, pct, level: level(pct), note };
}

// What each storage folder holds, in plain words.
export const BUCKET_LABELS: Record<string, string> = {
  "compliance-files": "Staff documents (onboarding uploads)",
  "compliance-library": "Policies and forms to read",
  "task-files": "Photos and files on tasks",
  "car-files": "Car and odometer photos",
  branding: "Logos",
};

// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects (rostering round 2, update 123): shared by the roster, the
// timesheets and the worker's own pages. Times are Sydney wall-clock.
import { sydneyParts } from "@/lib/sydney-time";

export type Band = "day" | "eve" | "night";
export const BANDS: Record<Band, [string, string]> = {
  day: ["Day", "bg-brand-soft text-ink"],
  eve: ["Evening", "bg-yellow-soft text-ink"],
  night: ["Night", "bg-page text-ink ring-1 ring-line"],
};
const mins = (t: string) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));

// Day 6am–6pm, evening 6–10pm, night 10pm–6am (or across midnight).
export function bandOf(startsAt: string, endsAt: string): Band {
  const a = sydneyParts(startsAt);
  const b = sydneyParts(endsAt);
  const s = mins(a.time);
  const e = mins(b.time);
  if (a.date !== b.date || s >= 22 * 60 || s < 6 * 60) return "night";
  if (s >= 18 * 60 || e > 19 * 60) return "eve";
  return "day";
}

// Availability is saved as morning / afternoon / night.
export function availabilitySlot(startsAt: string): "am" | "pm" | "night" {
  const h = Number(sydneyParts(startsAt).time.slice(0, 2));
  return h >= 6 && h < 12 ? "am" : h >= 12 && h < 18 ? "pm" : "night";
}

// Hours split into the award's pay columns (weekday by time, Saturday,
// Sunday, public holiday), with the unpaid break taken off the largest.
export const PAY_COLUMNS: [PayKey, string][] = [
  ["wd0", "Weekday 12am–6am"],
  ["wd6", "Weekday 6am–8pm"],
  ["wd20", "Weekday 8pm–10pm"],
  ["wd22", "Weekday 10pm–12am"],
  ["sat", "Saturday"],
  ["sun", "Sunday"],
  ["ph", "Public holiday"],
];
export type PayKey = "wd0" | "wd6" | "wd20" | "wd22" | "sat" | "sun" | "ph";
export function payColumns(startsAt: string, endsAt: string, breakMinutes: number, holidays: Set<string>): Record<PayKey, number> {
  const out: Record<PayKey, number> = { wd0: 0, wd6: 0, wd20: 0, wd22: 0, sat: 0, sun: 0, ph: 0 };
  const end = new Date(endsAt).getTime();
  for (let t = new Date(startsAt).getTime(); t < end; t += 15 * 60_000) {
    const p = sydneyParts(new Date(t).toISOString());
    const h = mins(p.time) / 60;
    const k: PayKey = holidays.has(p.date) ? "ph" : p.dow === 5 ? "sat" : p.dow === 6 ? "sun" : h < 6 ? "wd0" : h < 20 ? "wd6" : h < 22 ? "wd20" : "wd22";
    out[k] += 0.25;
  }
  if (breakMinutes) {
    const k = (Object.keys(out) as PayKey[]).sort((x, y) => out[y] - out[x])[0];
    out[k] = Math.max(0, out[k] - breakMinutes / 60);
  }
  return out;
}

// "9am", "4:30pm".
export function shortTime(iso: string): string {
  const t = sydneyParts(iso).time;
  const h = Number(t.slice(0, 2));
  const m = t.slice(3, 5);
  return `${((h + 11) % 12) + 1}${m === "00" ? "" : `:${m}`}${h < 12 ? "am" : "pm"}`;
}

// cmeprojects (update 128): shift types and allowances (shared by the server and the form).
export const SHIFT_TYPES: [string, string][] = [
  ["standard", "Standard"],
  ["personal_care", "Personal care"],
  ["domestic", "Domestic assistance"],
  ["community_access", "Community access"],
  ["overnight", "Overnight (active)"],
  ["sleepover", "Sleepover"],
  ["training", "Training"],
  ["meeting", "Meeting"],
  ["admin", "Administration"],
  ["other", "Other"],
];
export const SHIFT_ALLOWANCES = ["Sleepover", "Broken shift", "First aid", "Higher duties", "Vehicle (own car)"];
export const shiftTypeLabel = (v: string) => SHIFT_TYPES.find(([k]) => k === v)?.[1] ?? v;

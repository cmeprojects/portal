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

// cmeprojects: shift log lines in plain words. Older lines (written before
// update 132) are reworded here too, so the whole history reads the same way.
export function eventWords(summary: string, automatic: boolean): string {
  let s = summary
    .replace(/^added the shift and published it/, "added and published this shift")
    .replace(/^added the shift \(repeating\) and published it/, "added and published this shift (repeating)")
    .replace(/^added the shift \(repeating\) as a draft/, "added this shift as a draft (repeating)")
    .replace(/^added the shift as a draft/, "added this shift as a draft")
    .replace(/^published it \(the worker is told\)/, "published this shift")
    .replace(/^cancelled the shift/, "cancelled this shift")
    .replace(/^moved it back to draft/, "moved this shift back to draft")
    .replace(/^made it an open shift$/, "made this an open shift, so staff can put their hand up")
    .replace(/^(gave|assigned) the shift to /, "assigned this shift to ")
    .replace(/^re-assigned the shift from /, "re-assigned this shift from ")
    .replace(/^moved it from /, "moved this shift from ")
    .replace(/^accepted the shift/, "accepted this shift")
    .replace(/^declined the shift/, "declined this shift")
    .replace(/^recorded a signature \(worker in, (.+)\)$/, "recorded $1's clock-in signature")
    .replace(/^recorded a signature \(worker out, (.+)\)$/, "recorded $1's clock-out signature")
    .replace(/^recorded a signature \(client, (.+)\)$/, "recorded $1's signature (client)")
    .replace(/^recorded a signature \(representative, (.+)\)$/, "recorded $1's signature (client's representative)")
    .replace(/ 0(\d) ([A-Z][a-z]{2})/g, " $1 $2");
  if (automatic) {
    if (s === "told the worker") return "The worker was sent a notice about this shift.";
    s = s.charAt(0).toUpperCase() + s.slice(1);
    return `${s} (automatically).`;
  }
  return `${s}.`;
}

// cmeprojects (update 141): repeating shifts. The same calculation feeds the
// panel's preview and the save, so what's shown is what's made. Dates are
// plain YYYY-MM-DD (Sydney calendar days).
export type RepeatFreq = "daily" | "weekly" | "fortnightly" | "monthly";
export type RepeatRule = { freq: RepeatFreq; every: number; days: number[]; until: string; count: number; byCount: boolean };
export const REPEAT_MAX_DAYS = 183;
export const REPEAT_MAX_SHIFTS = 100;
const DAY_NAMES_LONG = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
const plusDays = (d: string, n: number) => new Date(Date.parse(`${d}T12:00:00Z`) + n * 86_400_000).toISOString().slice(0, 10);
const weekday = (d: string) => (new Date(`${d}T12:00:00Z`).getUTCDay() + 6) % 7;
const isDate = (d: string) => /^\d{4}-\d{2}-\d{2}$/.test(d) && !Number.isNaN(Date.parse(`${d}T12:00:00Z`));

export function repeatDates(start: string, r: RepeatRule): string[] {
  if (!isDate(start)) return [];
  const every = Math.max(1, Math.min(12, Math.floor(r.every) || 1));
  const cap = plusDays(start, REPEAT_MAX_DAYS);
  const last = r.byCount ? cap : isDate(r.until) && r.until >= start ? (r.until < cap ? r.until : cap) : start;
  const limit = r.byCount ? Math.max(1, Math.min(REPEAT_MAX_SHIFTS, Math.floor(r.count) || 1)) : REPEAT_MAX_SHIFTS;
  const out: string[] = [];
  if (r.freq === "monthly") {
    const [y, m, dd] = start.split("-").map(Number);
    for (let i = 0; out.length < limit; i += every) {
      const t = new Date(Date.UTC(y, m - 1 + i, dd, 12));
      if (t.getUTCDate() !== dd) continue; // no 31st (or 29th to 30th) that month
      const d = t.toISOString().slice(0, 10);
      if (d > last) break;
      out.push(d);
    }
    return out;
  }
  const weeks = r.freq === "fortnightly" ? 2 * every : every;
  const days = [...new Set(r.days.filter((n) => n >= 0 && n <= 6))];
  const startMonday = plusDays(start, -weekday(start));
  for (let d = start; d <= last && out.length < limit; d = plusDays(d, 1)) {
    if (r.freq === "daily") {
      if (Math.round((Date.parse(`${d}T12:00:00Z`) - Date.parse(`${start}T12:00:00Z`)) / 86_400_000) % every === 0) out.push(d);
      continue;
    }
    const weekNo = Math.floor((Date.parse(`${d}T12:00:00Z`) - Date.parse(`${startMonday}T12:00:00Z`)) / (7 * 86_400_000));
    if (days.includes(weekday(d)) && weekNo % weeks === 0) out.push(d);
  }
  return out;
}

// "Repeats every week on Tuesday and Thursday until 19 December 2026 (5 shifts)."
export function repeatSummary(start: string, r: RepeatRule, dates: string[]): string {
  if (!dates.length) return r.freq === "daily" || r.freq === "monthly" ? "No dates: check the end date." : "No dates: choose at least one day.";
  const every = Math.max(1, Math.floor(r.every) || 1);
  const unit = r.freq === "daily" ? "day" : r.freq === "monthly" ? "month" : r.freq === "fortnightly" ? "fortnight" : "week";
  const head = every === 1 ? `every ${unit}` : `every ${every} ${unit}s`;
  const names = [...new Set(r.days)].sort().map((n) => DAY_NAMES_LONG[n]);
  const on = r.freq === "weekly" || r.freq === "fortnightly" ? ` on ${names.length > 1 ? `${names.slice(0, -1).join(", ")} and ${names[names.length - 1]}` : names[0] ?? ""}` : r.freq === "monthly" ? ` on day ${Number(start.slice(8))}` : "";
  const lastDay = new Date(`${dates[dates.length - 1]}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });
  return `Repeats ${head}${on} until ${lastDay} (${dates.length} shift${dates.length === 1 ? "" : "s"}).`;
}

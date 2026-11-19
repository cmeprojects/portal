// Staff Portal · © cmeproject. All rights reserved.
//
// cmeprojects (owner's standing rule, 19 Nov 2026): contact details are checked
// before they're saved, everywhere: emails, Australian phone numbers (via
// lib/phone.ts) and Australian addresses. Shared by every form that saves them.
import { checkPhone } from "@/lib/phone";

export type Check = { ok: true; value: string } | { ok: false; error: string };

// A real-looking email: something@domain.tld, no spaces, lower-cased.
export function checkEmail(raw: string): Check {
  const v = raw.trim().toLowerCase();
  if (!v) return { ok: true, value: "" };
  if (v.length > 120 || !/^[a-z0-9._%+'-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$/.test(v) || v.includes("..")) return { ok: false, error: "Enter a valid email address (for example name@example.com)." };
  return { ok: true, value: v };
}

// An Australian phone number (mobile, landline with area code, 13/1300/1800), saved in one format.
export function checkAuPhone(raw: string): Check {
  if (!raw.trim()) return { ok: true, value: "" };
  return checkPhone("AU", raw);
}

// The first digit(s) of each state's postcodes (Australia Post ranges, including PO boxes).
const POSTCODES: Record<string, [number, number][]> = {
  NSW: [[1000, 2599], [2619, 2899], [2921, 2999]],
  ACT: [[200, 299], [2600, 2618], [2900, 2920]],
  VIC: [[3000, 3999], [8000, 8999]],
  QLD: [[4000, 4999], [9000, 9999]],
  SA: [[5000, 5999]],
  WA: [[6000, 6999]],
  TAS: [[7000, 7999]],
  NT: [[800, 999]],
};
export const AU_STATES = Object.keys(POSTCODES);

export function checkPostcode(state: string, raw: string): Check {
  const v = raw.trim();
  if (!v) return { ok: true, value: "" };
  if (!/^\d{4}$/.test(v)) return { ok: false, error: "A postcode is 4 numbers." };
  const n = Number(v);
  if (state && POSTCODES[state] && !POSTCODES[state].some(([a, b]) => n >= a && n <= b)) return { ok: false, error: `${v} isn't a ${state} postcode. Check the state and postcode.` };
  if (!AU_STATES.some((s) => POSTCODES[s].some(([a, b]) => n >= a && n <= b))) return { ok: false, error: `${v} isn't an Australian postcode.` };
  return { ok: true, value: v };
}

// A street address: a number and a street name ("12 Smith St", "Unit 3/22 Banksia Road", "PO Box 12").
export function checkStreet(raw: string): Check {
  const v = raw.trim().replace(/\s+/g, " ");
  if (!v) return { ok: true, value: "" };
  if (/^(po box|gpo box|locked bag)\s*\d+/i.test(v)) return { ok: true, value: v };
  if (!/\d/.test(v) || !/[a-z]{2,}/i.test(v)) return { ok: false, error: "Enter the street address with its number and street name (for example 12 Smith Street)." };
  return { ok: true, value: v };
}

// A one-line full address: street, then suburb, state and postcode
// ("3/22 Banksia Road, Dulwich Hill NSW 2203"). The state and postcode must match.
export function checkFullAddress(raw: string): Check {
  const v = raw.trim().replace(/\s+/g, " ");
  if (!v) return { ok: true, value: "" };
  const m = v.match(/^(.+),\s*([A-Za-z' -]+?)\s+(NSW|VIC|QLD|WA|SA|TAS|ACT|NT)\s+(\d{4})$/i);
  if (!m) return { ok: false, error: "Write the full address: street, a comma, then suburb, state and postcode (for example 12 Smith Street, Dulwich Hill NSW 2203)." };
  const street = checkStreet(m[1]);
  if (!street.ok) return street;
  const pc = checkPostcode(m[3].toUpperCase(), m[4]);
  if (!pc.ok) return pc;
  return { ok: true, value: `${street.value}, ${m[2].trim()} ${m[3].toUpperCase()} ${m[4]}` };
}

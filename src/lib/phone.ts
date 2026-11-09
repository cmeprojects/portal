// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: phone numbers. Australia by default; other countries by their
// dialling code. Numbers are saved in one tidy international format, for
// example "+61 412 345 678" (mobile) or "+61 2 9876 5432" (landline).
export const COUNTRIES: { code: string; dial: string; name: string }[] = [
  { code: "AU", dial: "61", name: "Australia (+61)" },
  { code: "NZ", dial: "64", name: "New Zealand (+64)" },
  { code: "PH", dial: "63", name: "Philippines (+63)" },
  { code: "IN", dial: "91", name: "India (+91)" },
  { code: "NP", dial: "977", name: "Nepal (+977)" },
  { code: "LK", dial: "94", name: "Sri Lanka (+94)" },
  { code: "CN", dial: "86", name: "China (+86)" },
  { code: "VN", dial: "84", name: "Vietnam (+84)" },
  { code: "ID", dial: "62", name: "Indonesia (+62)" },
  { code: "MY", dial: "60", name: "Malaysia (+60)" },
  { code: "SG", dial: "65", name: "Singapore (+65)" },
  { code: "GB", dial: "44", name: "United Kingdom (+44)" },
  { code: "US", dial: "1", name: "United States or Canada (+1)" },
  { code: "ZA", dial: "27", name: "South Africa (+27)" },
  { code: "KE", dial: "254", name: "Kenya (+254)" },
  { code: "NG", dial: "234", name: "Nigeria (+234)" },
];

export type PhoneCheck = { ok: true; value: string } | { ok: false; error: string };

// Check a number typed for a country. Blank is fine (the field is optional).
export function checkPhone(country: string, raw: string): PhoneCheck {
  const typed = raw.trim();
  if (!typed) return { ok: true, value: "" };
  if (/[a-z]/i.test(typed)) return { ok: false, error: "Use numbers only (letters aren't part of a phone number)." };
  let digits = typed.replace(/[^\d+]/g, "");
  const c = COUNTRIES.find((x) => x.code === country) ?? COUNTRIES[0];
  // Typed with its own code (+61 4…, 0061 4…): use it.
  if (digits.startsWith("+")) digits = digits.slice(1);
  else if (digits.startsWith("00")) digits = digits.slice(2);
  else digits = c.dial + digits.replace(/^0/, "");
  if (!digits.startsWith(c.dial)) {
    const other = [...COUNTRIES].sort((a, b) => b.dial.length - a.dial.length).find((x) => digits.startsWith(x.dial));
    if (!other) return { ok: false, error: "Check the country code." };
    return checkPhone(other.code, `+${digits}`);
  }
  const local = digits.slice(c.dial.length);
  if (c.code === "AU") {
    if (/^4\d{8}$/.test(local)) return { ok: true, value: `+61 ${local.slice(0, 3)} ${local.slice(3, 6)} ${local.slice(6)}` };
    if (/^[2378]\d{8}$/.test(local)) return { ok: true, value: `+61 ${local[0]} ${local.slice(1, 5)} ${local.slice(5)}` };
    if (/^1[38]00\d{6}$/.test(local) || /^13\d{4}$/.test(local)) return { ok: true, value: local };
    return { ok: false, error: "Enter an Australian mobile (04xx xxx xxx) or landline with area code (for example 02 9876 5432)." };
  }
  if (c.code === "NZ") {
    if (/^2\d{7,9}$/.test(local) || /^[3-9]\d{7}$/.test(local)) return { ok: true, value: `+64 ${local}` };
    return { ok: false, error: "That doesn't look like a New Zealand number." };
  }
  if (local.length < 6 || local.length > 13) return { ok: false, error: `That number looks too ${local.length < 6 ? "short" : "long"} for ${c.name.replace(/ \(.*/, "")}.` };
  return { ok: true, value: `+${c.dial} ${local}` };
}

// Split a saved number back into country and local part, for editing.
export function splitPhone(saved: string): { country: string; local: string } {
  const s = saved.trim();
  if (!s) return { country: "AU", local: "" };
  if (!s.startsWith("+")) return { country: "AU", local: s };
  const digits = s.slice(1).replace(/\D/g, "");
  const c = [...COUNTRIES].sort((a, b) => b.dial.length - a.dial.length).find((x) => digits.startsWith(x.dial));
  if (!c) return { country: "AU", local: s };
  const rest = digits.slice(c.dial.length);
  return { country: c.code, local: c.code === "AU" ? `0${rest}` : rest };
}

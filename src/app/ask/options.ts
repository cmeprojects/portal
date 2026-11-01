// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: the choices on the website's enquiry form. Kept out of
// actions.ts, which may only export server functions (exporting anything else
// there stops all the website's actions working).
export const NEEDS = ["Daily living support", "Community access", "Supported independent living", "Not sure yet"];

// An Australian mobile (04…) or landline (02, 03, 07, 08), with or without +61.
// Returns it as 10 digits, or "" when it isn't one.
export function australianPhone(raw: string): string {
  let digits = raw.replace(/[^\d+]/g, "");
  if (digits.startsWith("+61")) digits = `0${digits.slice(3)}`;
  else if (digits.startsWith("61") && digits.length === 11) digits = `0${digits.slice(2)}`;
  return /^0[2-478]\d{8}$/.test(digits) ? digits : "";
}

export const AU_POSTCODE = /^\d{4}$/;

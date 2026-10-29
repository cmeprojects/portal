// Staff Portal · © cmeproject. All rights reserved.

// The Cars app's lock (cmeprojects). After a full sign-in, the app stays
// signed in for the set number of days; each time it's opened, the PIN
// unlocks it for a few minutes. The unlock is a signed cookie, so it can't be
// made up in the browser. Used by the proxy and the unlock page.

export const APP_PATH = "/cars-app";
export const UNLOCK_COOKIE = "cars_unlock";
// Marks a browser (or installed app) that has used the Cars app.
export const APP_COOKIE = "cars_app";
export const APP_DAYS_COOKIE = "cars_app_days";
// Set by "Lock": the PIN is needed even if they've only just signed in.
export const LOCKED_COOKIE = "cars_locked";
// Unlocked for this long after the last use; then the PIN again.
export const UNLOCK_MINUTES = 15;

const enc = new TextEncoder();

async function key(): Promise<CryptoKey> {
  const secret = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  if (secret.length < 20) throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY");
  return crypto.subtle.importKey("raw", enc.encode(`cars-app-lock:${secret}`), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
}

const b64 = (buf: ArrayBuffer) => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

async function sign(payload: string): Promise<string> {
  return b64(await crypto.subtle.sign("HMAC", await key(), enc.encode(payload)));
}

export async function unlockValue(userId: string, now = Date.now()): Promise<string> {
  const payload = `${userId}.${now + UNLOCK_MINUTES * 60_000}`;
  return `${payload}.${await sign(payload)}`;
}

// True if the cookie unlocks the app for this person right now.
export async function isUnlocked(value: string | undefined, userId: string, now = Date.now()): Promise<boolean> {
  if (!value) return false;
  const [uid, exp, sig] = value.split(".");
  if (!uid || !exp || !sig || uid !== userId || Number(exp) < now) return false;
  const expected = await sign(`${uid}.${exp}`);
  if (expected.length !== sig.length) return false;
  let diff = 0;
  for (let i = 0; i < sig.length; i++) diff |= expected.charCodeAt(i) ^ sig.charCodeAt(i);
  return diff === 0;
}

export const isAppPath = (path: string) => path === APP_PATH || path.startsWith(`${APP_PATH}/`);

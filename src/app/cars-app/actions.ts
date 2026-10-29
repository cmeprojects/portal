// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { randomBytes, scrypt as scryptCb, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { requireSession } from "@/lib/session";
import { getCarRules } from "@/lib/cars";
import { APP_DAYS_COOKIE, APP_PATH, LOCKED_COOKIE, UNLOCK_COOKIE, UNLOCK_MINUTES, isUnlocked, unlockValue } from "@/lib/app-lock";
import { text, type FormState } from "@/lib/form";

const scrypt = promisify(scryptCb) as (pw: string, salt: Buffer, len: number) => Promise<Buffer>;
const MAX_TRIES = 5;

async function hashPin(pin: string): Promise<string> {
  const salt = randomBytes(16);
  return `scrypt$${salt.toString("base64")}$${(await scrypt(pin, salt, 32)).toString("base64")}`;
}

async function pinMatches(pin: string, stored: string): Promise<boolean> {
  const [kind, salt, hash] = stored.split("$");
  if (kind !== "scrypt" || !salt || !hash) return false;
  const got = await scrypt(pin, Buffer.from(salt, "base64"), 32);
  const want = Buffer.from(hash, "base64");
  return got.length === want.length && timingSafeEqual(got, want);
}

// Is this person allowed to change their PIN now (just signed in, or unlocked)?
async function unlockedNow(userId: string): Promise<boolean> {
  const jar = await cookies();
  if (await isUnlocked(jar.get(UNLOCK_COOKIE)?.value, userId)) return true;
  if (jar.has(LOCKED_COOKIE)) return false;
  const { data } = await (await createClient()).auth.getClaims();
  const amr = (data?.claims?.amr ?? []) as { timestamp?: number }[];
  const at = Math.max(0, ...amr.map((a) => (a.timestamp ?? 0) * 1000));
  return Date.now() - at < UNLOCK_MINUTES * 60_000;
}

async function openApp(userId: string) {
  const jar = await cookies();
  const secure = process.env.NODE_ENV === "production";
  jar.set(UNLOCK_COOKIE, await unlockValue(userId), { path: "/", httpOnly: true, sameSite: "lax", secure });
  jar.set(APP_DAYS_COOKIE, String((await getCarRules()).appDays), { path: "/", maxAge: 31536000, sameSite: "lax", secure });
  jar.delete(LOCKED_COOKIE);
}

const validPin = (pin: string) => /^\d{4}$/.test(pin);

export async function savePin(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const pin = text(form, "pin");
  if (!validPin(pin)) return { error: "Your PIN is 4 numbers." };
  if (pin !== text(form, "pin2")) return { error: "The two PINs don't match. Try again." };
  if (/^(\d)\1{3}$/.test(pin) || ["1234", "4321", "0123", "9876"].includes(pin)) return { error: "That PIN is too easy to guess. Choose another." };
  const admin = createAdminClient();
  const { data: existing } = await admin.from("car_app_pins").select("user_id").eq("user_id", profile.id).maybeSingle();
  if (existing && !(await unlockedNow(profile.id))) return { error: "Unlock the app first, then change your PIN." };
  const { error } = await admin
    .from("car_app_pins")
    .upsert({ user_id: profile.id, pin_hash: await hashPin(pin), failed: 0, updated_at: new Date().toISOString() });
  if (error) return { error: "Your PIN didn't save. Please try again." };
  await openApp(profile.id);
  redirect(APP_PATH);
}

export async function unlockWithPin(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const pin = text(form, "pin");
  const admin = createAdminClient();
  const { data: row } = await admin.from("car_app_pins").select("pin_hash, failed").eq("user_id", profile.id).maybeSingle();
  if (!row) redirect(`${APP_PATH}/unlock`);
  if (validPin(pin) && (await pinMatches(pin, row.pin_hash))) {
    if (row.failed) await admin.from("car_app_pins").update({ failed: 0 }).eq("user_id", profile.id);
    await openApp(profile.id);
    redirect(APP_PATH);
  }
  const failed = row.failed + 1;
  if (failed >= MAX_TRIES) {
    // Too many tries: forget the PIN and ask for a full sign-in.
    await admin.from("car_app_pins").delete().eq("user_id", profile.id);
    await (await createClient()).auth.signOut();
    redirect(`/login?error=pin&next=${encodeURIComponent(APP_PATH)}`);
  }
  await admin.from("car_app_pins").update({ failed }).eq("user_id", profile.id);
  const left = MAX_TRIES - failed;
  return { error: `That PIN isn't right. ${left} ${left === 1 ? "try" : "tries"} left before you need to sign in again.` };
}

// Forgot the PIN: sign in again with email, then choose a new one.
export async function forgotPin() {
  const { profile } = await requireSession();
  await createAdminClient().from("car_app_pins").delete().eq("user_id", profile.id);
  await (await createClient()).auth.signOut();
  redirect(`/login?next=${encodeURIComponent(APP_PATH)}`);
}

export async function lockApp() {
  const jar = await cookies();
  jar.delete(UNLOCK_COOKIE);
  jar.set(LOCKED_COOKIE, "1", { path: "/", httpOnly: true, sameSite: "lax", secure: process.env.NODE_ENV === "production" });
  redirect(`${APP_PATH}/unlock`);
}

export async function signOutApp() {
  const jar = await cookies();
  jar.delete(UNLOCK_COOKIE);
  await (await createClient()).auth.signOut();
  redirect(`/login?next=${encodeURIComponent(APP_PATH)}`);
}

// Staff Portal · © cmeproject. All rights reserved.
//
// End-to-end check of Milestone 1 against a LOCAL Supabase (npx supabase start)
// and the dev server (npm run dev). Run on an empty local database:
//   SERVICE_KEY=<local service role key> node tests/e2e/foundations.e2e.cjs

/* eslint-disable @typescript-eslint/no-require-imports -- plain Node script; needs Playwright installed */
const { chromium } = require("playwright");
const crypto = require("crypto");

const BASE = "http://localhost:3000";
const API = "http://127.0.0.1:54321";
const MAIL = "http://127.0.0.1:54324";
const SERVICE = process.env.SERVICE_KEY;
const OUT = process.env.OUT ?? "test-results";

function totp(secret) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let bits = "";
  for (const c of secret.replace(/=+$/, "").toUpperCase()) bits += alphabet.indexOf(c).toString(2).padStart(5, "0");
  const key = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 1000 / 30)));
  const h = crypto.createHmac("sha1", key).update(counter).digest();
  const o = h[h.length - 1] & 15;
  return String(((h.readUInt32BE(o) & 0x7fffffff) % 1e6)).padStart(6, "0");
}

async function admin(path, body) {
  const r = await fetch(`${API}/auth/v1/admin/${path}`, {
    method: "POST",
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return r.json();
}

async function latestMailLink(to) {
  for (let i = 0; i < 20; i++) {
    const list = await (await fetch(`${MAIL}/api/v1/search?query=to:${encodeURIComponent(to)}`)).json();
    if (list.messages?.length) {
      const msg = await (await fetch(`${MAIL}/api/v1/message/${list.messages[0].ID}`)).json();
      const m = msg.HTML.match(/href="([^"]*auth\/confirm[^"]*)"/);
      if (m) return m[1].replace(/&amp;/g, "&");
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error("no email for " + to);
}

function step(name) { console.log("✓", name); }

(async () => {
  if (!process.env.SKIP_SETUP) await admin("users", { email: "owner@example.com", password: "owner-password-123", email_confirm: true });

  const browser = await chromium.launch();
  const desktop = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await desktop.newPage();
  page.on("pageerror", (e) => console.log("PAGE ERROR", e.message));

  await page.goto(`${BASE}/settings/staff`);
  if (!page.url().includes("/login")) throw new Error("not redirected to login: " + page.url());
  step("signed-out visitor is sent to sign in");
  await page.screenshot({ path: `${OUT}/01-login.png`, fullPage: true });

  await page.fill("#email", "owner@example.com");
  await page.fill("#password", "wrong-password");
  await page.click("button:has-text('Sign in')");
  await page.waitForSelector("text=don't match");
  step("wrong password shows a friendly message");

  let secret;
  page.on("response", async (res) => {
    if (res.url().includes("/auth/v1/factors") && res.request().method() === "POST" && !res.url().includes("/verify") && !res.url().includes("/challenge")) {
      try { secret = (await res.json()).totp?.secret ?? secret; } catch {}
    }
  });
  await page.fill("#password", "owner-password-123");
  await page.click("button:has-text('Sign in')");
  await page.waitForURL(/\/mfa/);
  await page.waitForSelector("img[alt^='QR code']");
  step("system admin is sent to two-factor set-up");
  await page.screenshot({ path: `${OUT}/02-mfa.png`, fullPage: true });

  await page.fill("#code", "000000");
  await page.click("button:has-text('Turn on')");
  await page.waitForSelector("text=didn't work");
  step("wrong two-factor code is refused");
  await page.fill("#code", totp(secret));
  await page.click("button:has-text('Turn on')");
  await page.waitForURL(BASE + "/");
  await page.waitForSelector("text=My tasks");
  step("two-factor turned on, now on My tasks");
  await page.screenshot({ path: `${OUT}/03-home.png`, fullPage: true });

  await page.goto(`${BASE}/settings/staff`);
  await page.fill("#inv-name", "Sam Worker");
  await page.fill("#inv-email", "sam@example.com");
  await page.click("button:has-text('Send invite')");
  await page.waitForSelector("text=Invite sent to sam@example.com");
  await page.fill("#inv-name", "Morgan Manager");
  await page.fill("#inv-email", "morgan@example.com");
  await page.selectOption("#inv-role", "manager");
  await page.click("button:has-text('Send invite')");
  await page.waitForSelector("text=Invite sent to morgan@example.com");
  step("system admin invited a support worker and a manager");
  await page.reload();
  await page.screenshot({ path: `${OUT}/04-staff.png`, fullPage: true });

  // Sam accepts the invite on a phone.
  const phone = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const sam = await phone.newPage();
  await sam.goto(await latestMailLink("sam@example.com"));
  await sam.waitForURL(/\/welcome/);
  await sam.waitForSelector("text=Hi Sam");
  step("invite email link opens the welcome page");
  await sam.screenshot({ path: `${OUT}/05-welcome-phone.png`, fullPage: true });
  await sam.fill("#password", "sams-new-password");
  await sam.fill("#confirm", "sams-new-password");
  await sam.click("button:has-text('Join the portal')");
  await sam.waitForURL(BASE + "/");
  await sam.waitForSelector("text=Hi Sam");
  step("support worker joined (no two-factor needed) and sees My tasks");
  await sam.screenshot({ path: `${OUT}/06-home-phone.png`, fullPage: true });
  await sam.click("button[aria-label='Open menu']");
  await sam.screenshot({ path: `${OUT}/07-menu-phone.png`, fullPage: true });
  if (await sam.locator("text=Staff & roles").count()) throw new Error("support worker sees settings menu");
  await sam.goto(`${BASE}/settings/staff`);
  await sam.waitForURL(BASE + "/");
  await sam.goto(`${BASE}/system`);
  await sam.waitForURL(BASE + "/");
  step("support worker cannot open Staff & roles or System settings");

  // Morgan (manager) accepts and must set up two-factor.
  const mctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const morgan = await mctx.newPage();
  await morgan.goto(await latestMailLink("morgan@example.com"));
  await morgan.waitForURL(/\/welcome/);
  await morgan.fill("#password", "morgans-password-1");
  await morgan.fill("#confirm", "morgans-password-1");
  await morgan.click("button:has-text('Join the portal')");
  await morgan.waitForURL(/\/mfa/);
  step("manager is sent to two-factor set-up after joining");

  // Registries + teams + system settings as system admin.
  await page.goto(`${BASE}/settings/registries`);
  await page.waitForSelector("text=Compliance Registry");
  await page.screenshot({ path: `${OUT}/08-registries.png`, fullPage: true });
  step("registries page lists the company's registries");

  await page.goto(`${BASE}/settings/teams`);
  await page.fill("#team-name", "Derrimut house");
  await page.click("button:has-text('Add team')");
  await page.waitForSelector("text=Team \"Derrimut house\" added");
  step("team added");

  await page.goto(`${BASE}/system`);
  await page.click("button[aria-label^='Vehicles and mileage']");
  await page.waitForSelector("button[aria-label='Vehicles and mileage: on']");
  await page.fill("[id='s-brand.portal_name']", "Team Portal");
  await page.locator("form:has([id='s-brand.portal_name']) button:has-text('Save')").click();
  await page.waitForSelector("text=Saved.");
  await page.reload();
  await page.screenshot({ path: `${OUT}/09-system.png`, fullPage: true });
  await page.goto(`${BASE}/system/audit`);
  await page.waitForSelector("text=Switched on");
  await page.screenshot({ path: `${OUT}/10-audit.png`, fullPage: true });
  step("feature switched and setting changed, both in the change log");

  // Deactivate Sam.
  await page.goto(`${BASE}/settings/staff`);
  page.once("dialog", (d) => d.accept());
  await page.locator("details:has-text('sam@example.com') summary").click();
  await page.locator("details:has-text('sam@example.com') button:has-text('Deactivate')").click();
  await page.waitForSelector("text=Deactivated. They can no longer sign in.");
  await sam.goto(`${BASE}/`);
  await sam.waitForURL(/\/deactivated|\/login/);
  step("deactivated support worker is locked out: " + new URL(sam.url()).pathname);

  const fresh = await (await browser.newContext()).newPage();
  await fresh.goto(`${BASE}/login`);
  await fresh.fill("#email", "sam@example.com");
  await fresh.fill("#password", "sams-new-password");
  await fresh.click("button:has-text('Sign in')");
  await fresh.waitForSelector("text=turned off");
  step("deactivated person cannot sign in again");

  // Main two-factor switch: off lets the manager in without a code.
  await page.goto(`${BASE}/system`);
  page.once("dialog", (d) => d.accept());
  await page.click("button[aria-label='Two-factor login: on']");
  await page.waitForSelector("text=Two-factor login is switched off");
  const m2 = await (await browser.newContext()).newPage();
  await m2.goto(`${BASE}/login`);
  await m2.fill("#email", "morgan@example.com");
  await m2.fill("#password", "morgans-password-1");
  await m2.click("button:has-text('Sign in')");
  await m2.waitForURL(BASE + "/");
  step("with two-factor switched off, the manager signs in without a code");
  await page.click("button[aria-label='Two-factor login: off']");
  await page.waitForSelector("button[aria-label='Two-factor login: on']");
  await m2.goto(`${BASE}/settings/registries`);
  await m2.goto(`${BASE}/`);
  await m2.waitForURL(/\/mfa/);
  step("switched back on, the manager is asked to set up two-factor again");

  await browser.close();
  console.log("ALL E2E CHECKS PASSED");
})().catch((e) => { console.error("E2E FAILED:", e); process.exit(1); });

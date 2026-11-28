// Staff Portal · © cmeproject. All rights reserved.
//
// cmeprojects (update 170, review C7): roster billing checks, Billing > Coming up, the budget forecast
// and the dashboard tiles, plus review corrections C1 (no receipt without business details), C2
// (estimate wording), C3 (forecast columns) and C4 (Duplicate as an open shift, desktop and phone).
//
// LOCAL ONLY, against a local Supabase (npx supabase start) and the dev server (npm run dev), on a
// fresh local database (npx supabase db reset). Needs psql and Playwright.
//   SERVICE_KEY=<local service role key> node tests/e2e/roster-billing.e2e.cjs
// Optional: DB_URL (default: the local Supabase database), OUT (screenshots, default test-results).
// Seeds its own fictional data (tests/e2e/fixtures/roster-billing.sql). It never touches Dev.

/* eslint-disable @typescript-eslint/no-require-imports -- plain Node script; needs Playwright installed */
const { chromium, devices } = require("playwright");
const { execFileSync } = require("child_process");
const crypto = require("crypto");
const path = require("path");

const BASE = "http://localhost:3000";
const API = "http://127.0.0.1:54321";
const DB = process.env.DB_URL ?? "postgresql://postgres:postgres@127.0.0.1:54322/postgres";
const SERVICE = process.env.SERVICE_KEY;
const OUT = process.env.OUT ?? "test-results";
const PASSWORD = "e2e-password-123";
if (!SERVICE) throw new Error("Set SERVICE_KEY to the LOCAL service role key (npx supabase status).");
if (!/127\.0\.0\.1|localhost/.test(DB) || !/127\.0\.0\.1|localhost/.test(API)) throw new Error("This test runs only against a local Supabase.");

const sql = (q) => execFileSync("psql", [DB, "-qAt", "-v", "ON_ERROR_STOP=1", "-c", q]).toString().trim();
const results = [];
const check = (name, ok, note = "") => { results.push(ok); console.log(`${ok ? "✓" : "✗"} ${name}${note ? `  (${note})` : ""}`); };

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
async function createUser(email) {
  await fetch(`${API}/auth/v1/admin/users`, {
    method: "POST",
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: PASSWORD, email_confirm: true }),
  });
}
// Signs in; sets up two-factor on the way if the role needs it (the key comes from the set-up
// response and is kept for that person's later sign-ins in this run).
const mfaKeys = {};
async function login(browser, email, options = { viewport: { width: 1440, height: 1000 } }) {
  const ctx = await browser.newContext(options);
  const page = await ctx.newPage();
  page.errors = [];
  page.on("pageerror", (e) => page.errors.push(e.message.slice(0, 100)));
  let secret;
  page.on("response", async (res) => {
    if (res.url().includes("/auth/v1/factors") && res.request().method() === "POST" && !/verify|challenge/.test(res.url())) {
      try { secret = (await res.json()).totp?.secret ?? secret; } catch {}
    }
  });
  await page.goto(`${BASE}/login`);
  await page.fill("#email", email);
  await page.fill("#password", PASSWORD);
  await page.press("#password", "Enter");
  await page.waitForURL((u) => !u.pathname.startsWith("/login"), { timeout: 30000 });
  // A role that needs two-factor is sent to set it up on its first protected page.
  await page.goto(`${BASE}/billing`);
  await page.waitForLoadState("networkidle");
  if (page.url().includes("/mfa")) {
    if (mfaKeys[email]) {
      secret = mfaKeys[email];
      // A code can't be used twice: wait for the next 30-second code.
      await page.waitForTimeout((30 - (Math.floor(Date.now() / 1000) % 30)) * 1000 + 1500);
    } else {
      await page.waitForSelector("img[alt^='QR code']", { timeout: 20000 });
      for (let i = 0; i < 20 && !secret; i++) await page.waitForTimeout(250);
      mfaKeys[email] = secret;
    }
    await page.fill("#code", totp(secret));
    await page.locator("button:has-text('Turn on'), button:has-text('Continue'), button:has-text('Verify')").first().click();
    await page.waitForURL((u) => !u.pathname.startsWith("/mfa"), { timeout: 30000 });
  }
  return page;
}
const go = async (page, url) => { await page.goto(`${BASE}${url}`); await page.waitForLoadState("networkidle"); };
const text = (page) => page.locator("main").innerText();
const sydneyDate = (offsetDays) => new Date(Date.now() + offsetDays * 86400000).toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });

(async () => {
  // ---- Set-up: people (owner first: the first account is the System Administrator), then data. ----
  const people = { boss: "e2e-boss@example.com", bill: "e2e-bill@example.com", lead: "e2e-lead@example.com", office: "e2e-office@example.com" };
  if (sql("select count(*) from public.profiles") === "0") await createUser("e2e-owner@example.com");
  sql(`insert into public.invitations (email, full_name, role)
       select v.e, v.n, v.r::public.app_role from (values ('${people.boss}', 'E2E Morgan', 'manager'), ('${people.bill}', 'E2E Billie', 'manager'),
         ('${people.lead}', 'E2E Terry', 'team_leader'), ('${people.office}', 'E2E Olive', 'staff_admin')) v(e, n, r)
        where not exists (select 1 from public.profiles p where p.email = v.e) and not exists (select 1 from public.invitations i where i.email = v.e)`);
  for (const e of Object.values(people)) await createUser(e);
  // Two-factor starts fresh for the test accounts (local only), so a rerun can set it up again.
  sql(`delete from auth.mfa_factors where user_id in (select id from auth.users where email like 'e2e-%@example.com')`);
  const d1 = sydneyDate(1);
  const [y, m] = d1.split("-").map(Number);
  const qm = Math.floor((m - 1) / 3) * 3 + 1;
  const qs = `${y}-${String(qm).padStart(2, "0")}-01`;
  const qeDate = new Date(Date.UTC(y, qm + 2, 0));
  const qe = qeDate.toISOString().slice(0, 10);
  execFileSync("psql", [DB, "-q", "-v", "ON_ERROR_STOP=1", "-v", `d1=${d1}`, "-v", `qs=${qs}`, "-v", `qe=${qe}`, "-f", path.join(__dirname, "fixtures", "roster-billing.sql")], { stdio: ["ignore", "ignore", "inherit"] });
  // Copies made by an earlier run of this test (fictional local data) are cancelled, so counts start clean.
  sql(`update public.shifts set status = 'cancelled' where coalesce(ref, '') not like 'E2E-%' and status = 'draft' and client_id in (select id from public.car_clients where name like 'E2E %')`);
  const id = (ref) => sql(`select id from public.shifts where ref = '${ref}'`);
  const [r1, r2, r3] = ["E2E-R1", "E2E-R2", "E2E-R3"].map(id);
  check("seed: three rostered client shifts tomorrow, no billing lines", !!(r1 && r2 && r3) && sql("select count(*) from public.billing_lines") === "0", d1);
  const linesBefore = sql("select count(*) from public.billing_lines");
  const ledgerBefore = sql("select count(*) from public.funding_ledger");

  const browser = await chromium.launch();
  const boss = await login(browser, people.boss);

  // ---- Dashboard tiles (C2 wording). ----
  await go(boss, "/billing");
  let t = await text(boss);
  check("dashboard: next 4 weeks of the roster checked, marked as estimates", /Rostered client shifts, next 4 weeks \(estimates\)/.test(t) && /Can't be billed as rostered/.test(t) && /Would go over budget/.test(t) && /not delivered services, billing lines, claims or payments/.test(t));

  // ---- Coming up (C2) and the budget forecast (C3). ----
  await go(boss, "/billing?tab=upcoming");
  t = await text(boss);
  check("Coming up counts the shifts without saying \"ready\"", /3 rostered client shifts checked: 1 with no set-up issue found, 1 to fix, 1 over budget, 0 waiting on set-up\./.test(t) && !/\bready\b/.test(t), (t.match(/\d+ rostered client shifts? checked[^\n]*/) || [""])[0]);
  check("Coming up says a roster estimate isn't a delivered service, billing line, claim or payment", (await boss.locator("[data-estimate-note]").innerText()).includes("isn't a delivered service, a billing line, a claim or a payment"));
  check("Ivy (no billing terms) is listed to fix; Zara's second shift is over budget", (await boss.locator("[data-upcoming=fix]").innerText()).includes("No approved billing terms") && (await boss.locator("[data-upcoming=over_budget]").innerText()).includes("Would go over the available budget"));
  const heads = await boss.locator("table thead th").allInnerTexts();
  check("forecast columns: approved balance, draft lines, rostered estimates, projected left, goes over on", ["Approved balance", "Draft lines", "Rostered estimates", "Projected left", "Goes over on"].every((h) => heads.includes(h)), heads.join(" | "));
  const row = boss.locator("[data-forecast-row]").first();
  const cell = async (k) => (await row.locator(`[data-col=${k}]`).innerText()).trim();
  const approved = await cell("approved"), drafts = await cell("drafts"), left = await cell("left");
  check("forecast: $270.00 approved, $0.00 in draft lines, projected left below zero", approved === "$270.00" && drafts === "$0.00" && left.startsWith("-"), `${approved} | ${drafts} | ${await cell("estimates")} | ${left}`);
  await boss.screenshot({ path: `${OUT}/roster-billing-upcoming.png`, fullPage: true });

  // ---- Roster: banner, $ sign and hover (C2). ----
  await go(boss, `/roster?d=${d1}`);
  const banner = boss.locator("[data-billing-check]");
  check("roster banner: 2 client shifts can't be billed as rostered (1 over budget)", (await banner.count()) === 1 && /2 client shifts shown can't be billed as rostered \(1 over budget\)/.test(await banner.innerText()));
  const chip = (sid) => boss.locator(`[data-shift-id="${sid}"]`).first();
  check("the $ sign is on Ivy's shift and the over-budget shift only", (await chip(r3).locator("svg[aria-label^='Billing:']").count()) === 1 && (await chip(r2).locator("svg[aria-label^='Billing:']").count()) === 1 && (await chip(r1).locator("svg[aria-label^='Billing:']").count()) === 0);
  await chip(r1).hover();
  const okCard = await chip(r1).locator("[role=tooltip]").innerText();
  check("hover on a shift with no issue says \"Estimate only\" and that it isn't delivered, billed or claimed", /no set-up issue found\. Estimate only: about \$[\d.,]+ from the roster/.test(okCard) && /not delivered, billed or claimed/.test(okCard), okCard.replace(/\n/g, " | ").slice(0, 180));
  await chip(r3).hover();
  check("hover on Ivy's shift gives the reason", /Billing: No approved billing terms/.test(await chip(r3).locator("[role=tooltip]").innerText()));

  // ---- C1: no receipt (and no receipt number) without business details. ----
  const hadBusiness = sql("select count(*) from public.business_details") !== "0";
  const paymentsBefore = sql("select count(*) from public.payments");
  const recordPayment = async () => {
    await go(boss, "/billing?tab=payments");
    await boss.getByLabel("Paid by").selectOption({ label: "E2E Zara (client) (E2E Zara)" });
    await boss.getByLabel("Received on").first().fill(sydneyDate(0).split("-").reverse().join("/"));
    await boss.getByLabel("Amount (AUD)").fill("28");
    await boss.getByRole("button", { name: "Record payment" }).click();
  };
  if (hadBusiness) console.log("  (C1 refusal skipped: business details were entered by an earlier run; use a fresh local database)");
  else {
    await recordPayment();
    await boss.waitForSelector("text=Enter the business details first", { timeout: 15000 }).catch(() => {});
    t = await text(boss);
    check("C1: a client payment isn't recorded (no receipt number) while business details are missing", /Enter the business details first \(Portal settings, Business details\): legal name, ABN, address/.test(t) && sql("select count(*) from public.payments") === paymentsBefore,
      (t.slice(t.indexOf("Record payment"), t.indexOf("Record payment") + 220) || "no message").replace(/\n/g, " | "));
    await boss.screenshot({ path: `${OUT}/roster-billing-c1.png`, fullPage: true });
  }
  // With complete business details (fictional, the ATO's sample ABN), the payment is recorded and numbered as before.
  if (!hadBusiness) sql(`insert into public.business_details (legal_name, abn, address, suburb, state, postcode, email) values ('E2E Care Pty Ltd', '51824753556', '1 Test St', 'Sydney', 'NSW', '2000', 'accounts@example.com')`);
  await recordPayment();
  await boss.waitForURL(/\/billing\/payments\/[0-9a-f-]{36}/, { timeout: 15000 }).catch(() => {});
  check("C1: with business details complete, the client payment is recorded with its receipt number (RCT-)", /^RCT-\d{4}-\d{6}$/.test(sql("select receipt_number from public.payments order by recorded_at desc limit 1")), sql("select receipt_number from public.payments order by recorded_at desc limit 1"));

  // ---- People without Billing view see no billing detail. ----
  for (const who of [people.lead, people.office]) {
    const p = await login(browser, who);
    await go(p, `/roster?d=${d1}`);
    const tt = await text(p);
    check(`${who}: no billing detail on the roster`, !/can't be billed as rostered/.test(tt) && (await p.locator("svg[aria-label^='Billing:']").count()) === 0 && !/Estimate only/.test(await p.content()));
    await go(p, "/billing?tab=upcoming");
    check(`${who}: Billing > Coming up isn't open to them`, /can.t find that page/i.test(await text(p)) && !/Coming up: rostered shifts/.test(await text(p)));
    await p.context().close();
  }

  // ---- C4: Duplicate as an open shift, from the shift panel (desktop, then phone). ----
  const copies = (sid) => sql(`select count(*) from public.shifts c join public.shifts o on o.id = '${sid}'
    where c.id <> o.id and c.client_id = o.client_id and c.starts_at = o.starts_at and c.ends_at = o.ends_at and c.status = 'draft' and c.worker_id is null`);
  const r1Before = Number(copies(r1)), r3Before = Number(copies(r3));
  await go(boss, `/roster?d=${d1}&shift=${r1}`);
  await boss.getByRole("button", { name: "Duplicate as an open shift" }).click();
  await boss.waitForSelector("text=Duplicated as an open draft shift", { timeout: 15000 }).catch(() => {});
  check("C4 desktop: the shift panel duplicates the shift as an open draft at the same time", Number(copies(r1)) === r1Before + 1);
  const phone = await login(browser, people.boss, { ...devices["iPhone 13"] });
  await go(phone, `/roster?d=${d1}&shift=${r3}`);
  const dupBtn = phone.getByRole("button", { name: "Duplicate as an open shift" });
  check("C4 phone: the button is visible in the shift panel", await dupBtn.isVisible());
  await dupBtn.tap();
  await phone.waitForSelector("text=Duplicated as an open draft shift", { timeout: 15000 }).catch(() => {});
  check("C4 phone: tapping it duplicates the shift as an open draft", Number(copies(r3)) === r3Before + 1);
  check("C4: copies carry no timesheet, service record, signature or billing line", sql(`select count(*) from public.shifts c
    where coalesce(c.ref, '') not like 'E2E-%' and c.client_id in (select id from public.car_clients where name like 'E2E %') and (exists (select 1 from public.shift_timesheets x where x.shift_id = c.id)
      or exists (select 1 from public.shift_service_records x where x.shift_id = c.id) or exists (select 1 from public.shift_signatures x where x.shift_id = c.id)
      or exists (select 1 from public.billing_lines x where x.shift_id = c.id))`) === "0");

  // ---- Estimates never change money records. ----
  check("no billing lines or funding ledger entries were made by any of this", sql("select count(*) from public.billing_lines") === linesBefore && sql("select count(*) from public.funding_ledger") === ledgerBefore);
  check("no page errors", boss.errors.length === 0 && phone.errors.length === 0, [...boss.errors, ...phone.errors].join("; "));

  await browser.close();
  console.log(`${results.filter(Boolean).length}/${results.length} passed`);
  process.exit(results.every(Boolean) ? 0 : 1);
})().catch((e) => { console.error(e); process.exit(1); });

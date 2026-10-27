// Staff Portal · © cmeproject. All rights reserved.
//
// End-to-end check of registers (custom fields, register pages, set-up,
// follow-up actions, assets) against a LOCAL Supabase and the dev server.
// Run on a freshly reset local database (npx supabase db reset):
//   SERVICE_KEY=<local service role key> node tests/e2e/registers.e2e.cjs

/* eslint-disable @typescript-eslint/no-require-imports -- plain Node script; needs Playwright installed */
const { chromium } = require("playwright");
const { execFileSync } = require("child_process");

const BASE = "http://localhost:3000";
const API = "http://127.0.0.1:54321";
const MAIL = "http://127.0.0.1:54324";
const DB = "postgresql://postgres:postgres@127.0.0.1:54322/postgres";
const SERVICE = process.env.SERVICE_KEY;
const OUT = process.env.OUT ?? "test-results";

const sql = (q) => execFileSync("psql", [DB, "-qAtc", q]).toString().trim();
const step = (name) => console.log("✓", name);

async function createUser(email) {
  const r = await fetch(`${API}/auth/v1/admin/users`, {
    method: "POST",
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test-password-123", email_confirm: true }),
  });
  if (!r.ok) throw new Error(await r.text());
}

async function signIn(browser, email, viewport = { width: 1280, height: 900 }) {
  const ctx = await browser.newContext({ viewport, acceptDownloads: true });
  const page = await ctx.newPage();
  page.on("pageerror", (e) => console.log("PAGE ERROR", e.message));
  await page.goto(`${BASE}/login`);
  await page.fill("#email", email);
  await page.fill("#password", "test-password-123");
  await page.click("button:has-text('Sign in')");
  await page.waitForURL(BASE + "/");
  return page;
}

(async () => {
  await createUser("owner@example.com");
  sql(`update public.features set enabled = false where key = 'two_factor'`);
  sql(`insert into public.invitations (email, full_name, role) values
    ('boss@example.com', 'Morgan Manager', 'manager'),
    ('sam@example.com', 'Sam Worker', 'support_worker')`);
  await createUser("boss@example.com");
  await createUser("sam@example.com");
  sql(`update public.profiles set full_name = 'Olivia Owner' where email = 'owner@example.com'`);
  sql(`insert into public.registry_managers select id, (select id from profiles where email = 'boss@example.com')
       from public.registries where prefix = 'RSK'`);

  const browser = await chromium.launch();
  const owner = await signIn(browser, "owner@example.com");

  // Registers list
  await owner.goto(`${BASE}/registers`);
  for (const name of ["General tasks", "Conflict of Interest Register", "Risk Management Register", "Asset Register"]) {
    await owner.waitForSelector(`h2:has-text("${name}")`);
  }
  await owner.screenshot({ path: `${OUT}/r-01-registers.png`, fullPage: true });
  step("registers page lists the 7 registers plus General tasks");

  // Asset with an estimated value
  await owner.click("h2:has-text('Asset Register')");
  await owner.click("text=+ Add item");
  await owner.fill("#r-title", "Electric wheelchair");
  const f = (k) => `[name=f_${k}]`;
  await owner.fill(f("brand"), "Pride");
  await owner.fill(f("purchase_value"), "4000");
  const twoYearsAgo = new Date(Date.now() - 2 * 365.25 * 864e5).toISOString().slice(0, 10);
  await owner.fill(f("purchase_date"), twoYearsAgo);
  await owner.fill(f("useful_life"), "4");
  await owner.click("text=Estimate from purchase value and age");
  const estimate = Number(await owner.inputValue(f("current_value")));
  if (Math.abs(estimate - 2000) > 20) throw new Error("estimate was " + estimate);
  await owner.selectOption(f("status"), "In use");
  await owner.screenshot({ path: `${OUT}/r-02-asset-form.png`, fullPage: true });
  await owner.click("button:has-text('Add to the list')");
  await owner.waitForURL(/\/records\//);
  await owner.waitForSelector("text=AST-0001 >> visible=true");
  const assetUrl = owner.url().replace("?saved=1", "");
  step(`asset added with an estimated current value ($${estimate})`);

  // Risk task with custom fields, created by Sam
  const sam = await signIn(browser, "sam@example.com", { width: 390, height: 844 });
  await sam.goto(`${BASE}/tasks/new`);
  await sam.selectOption("#registry_id", { label: "Risk Management Register" });
  await sam.waitForSelector("text=Risk Management Register details");
  await sam.fill("#title", "Wet floor in kitchen");
  await sam.fill("#description", "Floor is slippery after mopping.");
  await sam.click("button:has-text('Create task')");
  await sam.waitForSelector("#title:invalid, [name=f_risk_rating]:invalid", { timeout: 2000 }).catch(() => {});
  await sam.selectOption(f("risk_rating"), "High");
  await sam.fill(f("consequence"), "Someone could slip and fall.");
  await sam.screenshot({ path: `${OUT}/r-03-new-risk-phone.png`, fullPage: true });
  await sam.click("button:has-text('Create task')");
  await sam.waitForURL(/\/tasks\/[0-9a-f-]{36}/);
  await sam.waitForSelector("text=RSK-0001 >> visible=true");
  await sam.waitForSelector("dd:has-text('High')");
  const riskUrl = sam.url().replace("?created=1", "");
  step("support worker created a Risk task with its own fields (RSK-0001)");

  // Maintenance task linked to the asset
  await sam.goto(`${BASE}/tasks/new`);
  await sam.selectOption("#registry_id", { label: "Maintenance and Repair Register" });
  await sam.fill("#title", "Wheelchair battery not charging");
  await sam.selectOption(f("asset"), { label: "AST-0001 · Electric wheelchair" });
  await sam.selectOption(f("triggers"), "Breakdown");
  await sam.click("button:has-text('Create task')");
  await sam.waitForSelector("text=MNT-0001 >> visible=true");
  await owner.goto(assetUrl);
  await owner.waitForSelector("text=Wheelchair battery not charging");
  await owner.screenshot({ path: `${OUT}/r-04-asset-page.png`, fullPage: true });
  step("maintenance task links to the asset, and the asset lists it");

  // Manager edits details and adds a follow-up action
  const boss = await signIn(browser, "boss@example.com");
  await boss.goto(riskUrl);
  await boss.click("summary:has-text('Edit details')");
  await boss.selectOption("#f-" + sql(`select left(id::text, 8) from registries where prefix = 'RSK'`) + "-risk_rating", "Extreme");
  await boss.fill("#e-outcome", "Warning signs put out; new mop ordered.");
  await boss.click("button:has-text('Save changes')");
  await boss.waitForSelector("text=Saved.");
  await boss.reload();
  await boss.waitForSelector("text=updated outcome, risk rating");
  await boss.click("summary:has-text('Add a follow-up action')");
  await boss.fill("#a-title", "Buy non-slip mats");
  await boss.selectOption("#a-who", { label: "Sam Worker" });
  await boss.click("button:has-text('Add action')");
  await boss.waitForSelector("text=Action added");
  await boss.reload();
  await boss.waitForSelector("a:has-text('Buy non-slip mats')");
  await boss.screenshot({ path: `${OUT}/r-05-risk-task.png`, fullPage: true });
  step("manager updated the risk rating and outcome, and added a follow-up action");
  const mail = await (await fetch(`${MAIL}/api/v1/search?query=${encodeURIComponent("to:sam@example.com")}`)).json();
  if (!(mail.messages ?? []).some((m) => m.Subject.includes("RSK-0002"))) throw new Error("no action email to Sam");
  step("the person given the action was emailed (RSK-0002)");

  // Register page and download
  await boss.goto(`${BASE}/registers`);
  await boss.click("h2:has-text('Risk Management Register')");
  await boss.waitForSelector("th:has-text('Risk rating')");
  await boss.waitForSelector("td:has-text('Extreme')");
  await boss.screenshot({ path: `${OUT}/r-06-risk-register.png`, fullPage: true });
  await boss.click("button:has-text('Download for Excel')");
  await boss.click("button:has-text('This month')");
  const [download] = await Promise.all([boss.waitForEvent("download"), boss.click("form button:has-text('Download')")]);
  const ExcelJS = require("exceljs");
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(await download.path());
  const ws = wb.worksheets[0];
  const all = [];
  ws.eachRow((r) => all.push(r.values.filter(Boolean).join("|")));
  const text = all.join("\n");
  if (!text.includes("Risk rating") || !text.includes("Wet floor in kitchen") || !text.includes("Extreme") || !text.includes("Risk Management Register"))
    throw new Error("bad Excel: " + text.slice(0, 400));
  if (ws.getImages().length !== 1) throw new Error("no logo in the Excel file");
  step("register page shows its own columns, and downloads an Excel file for this month with the logo and header");

  // Manager creates a register and adds a field
  await boss.goto(`${BASE}/registers/new`);
  await boss.fill("#name", "Incident Register");
  await boss.check("[name=requires_approval]");
  await boss.click("button:has-text('Create register')");
  await boss.waitForURL(/\/setup\?created=1/);
  await boss.click("summary:has-text('+ Add a field')");
  await boss.fill("#new-label", "Incident type");
  await boss.selectOption("#new-type", "choice");
  await boss.fill("#new-options", "Injury\nNear miss\nProperty damage");
  await boss.check("form:has(#new-label) [name=required]");
  await boss.click("button:has-text('Add field')");
  await boss.waitForSelector("text=Added \"Incident type\"");
  await boss.reload();
  await boss.waitForSelector("text=Morgan Manager");
  await boss.screenshot({ path: `${OUT}/r-07-setup.png`, fullPage: true });
  if (sql(`select prefix from registries where name = 'Incident Register'`) !== "IR") throw new Error("prefix");
  step("manager created a register (prefix IR), added a dropdown field and became its manager");

  await sam.goto(`${BASE}/tasks/new`);
  await sam.selectOption("#registry_id", { label: "Incident Register" });
  await sam.waitForSelector("label:has-text('Incident type')");
  step("the new register and its field appear on the New task form straight away");

  await sam.goto(`${BASE}/registers`);
  await sam.click("h2:has-text('Risk Management Register')");
  if (await sam.locator("a:has-text('Set up')").count()) throw new Error("support worker sees Set up");
  await sam.goto(`${BASE}/registers/${sql(`select id from registries where prefix = 'RSK'`)}/setup`);
  await sam.waitForURL(/\/registers\/[0-9a-f-]{36}$/);
  step("support workers can't open a register's set-up");

  await browser.close();
  console.log("ALL REGISTER E2E CHECKS PASSED");
})().catch((e) => {
  console.error("E2E FAILED:", e);
  process.exit(1);
});

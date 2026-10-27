// Staff Portal · © cmeproject. All rights reserved.
//
// End-to-end check of Milestone 2 (tasks, helpers, emails) against a LOCAL
// Supabase and the dev server. Run on an empty local database:
//   SERVICE_KEY=<local service role key> node tests/e2e/tasks.e2e.cjs

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

async function createUser(email, password) {
  const r = await fetch(`${API}/auth/v1/admin/users`, {
    method: "POST",
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, email_confirm: true }),
  });
  if (!r.ok) throw new Error(await r.text());
}

async function mails(to) {
  const list = await (await fetch(`${MAIL}/api/v1/search?query=${encodeURIComponent(`to:${to}`)}`)).json();
  return list.messages ?? [];
}

async function waitForMail(to, subjectPart) {
  for (let i = 0; i < 20; i++) {
    const found = (await mails(to)).find((m) => m.Subject.includes(subjectPart));
    if (found) return found;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`no email to ${to} about "${subjectPart}"`);
}

async function signIn(browser, email, viewport = { width: 1280, height: 900 }) {
  const page = await (await browser.newContext({ viewport })).newPage();
  page.on("pageerror", (e) => console.log("PAGE ERROR", e.message));
  await page.goto(`${BASE}/login`);
  await page.fill("#email", email);
  await page.fill("#password", "test-password-123");
  await page.click("button:has-text('Sign in')");
  await page.waitForURL(BASE + "/");
  return page;
}

(async () => {
  // Two-factor is tested elsewhere; switch it off so this test can focus on tasks.
  await createUser("owner@example.com", "test-password-123");
  sql(`update public.features set enabled = false where key = 'two_factor'`);
  sql(`insert into public.teams (name) values ('Team A'), ('Team B')`);
  sql(`insert into public.invitations (email, full_name, role, team_id) values
    ('boss@example.com', 'Morgan Manager', 'manager', null),
    ('lead@example.com', 'Taylor Lead', 'team_leader', null),
    ('sam@example.com',  'Sam Worker', 'support_worker', (select id from public.teams where name = 'Team A')),
    ('kim@example.com',  'Kim Worker', 'support_worker', (select id from public.teams where name = 'Team B')),
    ('ali@example.com',  'Ali Worker', 'support_worker', (select id from public.teams where name = 'Team B'))`);
  for (const e of ["boss", "lead", "sam", "kim", "ali"]) await createUser(`${e}@example.com`, "test-password-123");
  sql(`insert into public.team_leaders select t.id, p.id from public.teams t, public.profiles p
       where t.name = 'Team A' and p.email = 'lead@example.com'`);
  sql(`insert into public.registry_managers select r.id, p.id from public.registries r, public.profiles p
       where r.name = 'Continuous Improvement Register' and p.email = 'boss@example.com'`);

  const browser = await chromium.launch();

  // Sam creates a task on a phone.
  const sam = await signIn(browser, "sam@example.com", { width: 390, height: 844 });
  await sam.goto(`${BASE}/tasks/new`);
  await sam.fill("#title", "Check first aid kit expiry dates");
  await sam.selectOption("#registry_id", { label: "Continuous Improvement Register" });
  await sam.click("label:has-text('High') >> nth=0");
  await sam.fill("#description", "Kits in both cars and the office.\nReplace anything out of date.");
  await sam.selectOption("#assigned_to", { label: "Kim Worker · Support worker" });
  await sam.check("input[name=helpers][value='" + sql(`select id from profiles where email='lead@example.com'`) + "']");
  await sam.screenshot({ path: `${OUT}/m2-01-new-task-phone.png`, fullPage: true });
  await sam.click("button:has-text('Create task')");
  await sam.waitForURL(/\/tasks\/[0-9a-f-]{36}\?created=1/);
  await sam.waitForSelector("text=Task created");
  const taskUrl = sam.url().replace("?created=1", "");
  await sam.screenshot({ path: `${OUT}/m2-02-task-phone.png`, fullPage: true });
  step("support worker created a task on a phone");

  const toKim = await waitForMail("kim@example.com", "New task for you");
  const ccLead = (toKim.Cc ?? []).map((c) => c.Address);
  if (!ccLead.includes("lead@example.com")) throw new Error("helper not copied in: " + JSON.stringify(toKim.Cc));
  step("assignee emailed, helper copied in");
  await waitForMail("boss@example.com", "New task in Continuous Improvement Register");
  step("registry manager emailed");

  // Kim sees it and tags Ali.
  const kim = await signIn(browser, "kim@example.com");
  await kim.waitForSelector("text=Check first aid kit expiry dates");
  await kim.click("button[aria-label='1 new task for you']");
  await kim.waitForSelector("text=New for you");
  await kim.screenshot({ path: `${OUT}/m2-05-bell.png` });
  step("the bell shows 1 new task for the assignee");
  await kim.screenshot({ path: `${OUT}/m2-03-my-tasks.png`, fullPage: true });
  await kim.click("a:has-text('Check first aid kit expiry dates') >> nth=0");
  await kim.waitForSelector("text=Tag someone to help out");
  await kim.selectOption("#helper", { label: "Ali Worker" });
  await kim.click("button:has-text('Add helper')");
  await kim.waitForSelector("text=Helper added");
  await kim.waitForSelector("text=added Ali Worker as a helper");
  await kim.screenshot({ path: `${OUT}/m2-04-task-desktop.png`, fullPage: true });
  step("assignee sees the task and tagged a helper");
  await kim.goto(`${BASE}/`);
  await kim.waitForSelector("button[aria-label='No new tasks']");
  step("opening the task cleared it from the bell");
  await waitForMail("ali@example.com", "You're helping on");
  step("new helper emailed");

  // Who can see it.
  const lead = await signIn(browser, "lead@example.com");
  await lead.goto(`${BASE}/my-tasks?tab=helping`);
  await lead.waitForSelector("text=Check first aid kit expiry dates");
  step("helper sees it under Helping on");

  const boss = await signIn(browser, "boss@example.com");
  await boss.waitForSelector("h1:has-text('Dashboard')");
  await boss.waitForSelector("#all a:has-text('Check first aid kit expiry dates')");
  await boss.selectOption("#d-person", { label: "Kim Worker" });
  await boss.click("button:has-text('Show')");
  await boss.waitForURL(/person=/);
  await boss.waitForSelector("#all a:has-text('Check first aid kit expiry dates')");
  await boss.screenshot({ path: `${OUT}/m2-06-dashboard.png`, fullPage: true });
  step("manager lands on the dashboard and sees all ongoing tasks in their register, filtered by person");
  await boss.goto(taskUrl);
  await boss.waitForSelector("h1:has-text('Check first aid kit expiry dates')");
  step("registry manager can open the task");

  const owner = await signIn(browser, "owner@example.com");
  await owner.goto(`${BASE}/tasks/new`);
  await owner.fill("#title", "Private maintenance job");
  await owner.selectOption("#registry_id", { label: "Maintenance and Repair Register" });
  await owner.click("button:has-text('Create task')");
  await owner.waitForURL(/\/tasks\/[0-9a-f-]{36}/);
  const privateUrl = owner.url().replace("?created=1", "");
  await sam.goto(privateUrl);
  await sam.waitForSelector("text=We can't find that page");
  if (await sam.locator("text=Private maintenance job").count()) throw new Error("support worker saw someone else's task");
  await sam.goto(`${BASE}/`);
  if (await sam.locator("text=Private maintenance job").count()) throw new Error("leak on My tasks");
  step("support worker cannot open or list a task that isn't theirs");

  const sent = sql(`select count(*) filter (where sent_at is not null) || '/' || count(*) from public.email_outbox`);
  step(`emails sent from the queue: ${sent}`);

  await browser.close();
  console.log("ALL TASK E2E CHECKS PASSED");
})().catch((e) => {
  console.error("E2E FAILED:", e);
  process.exit(1);
});

// cmeprojects perf audit: per-module navigation time, database calls and rounds.
const { chromium } = require("playwright");
const B = "http://localhost:3100", R = "http://127.0.0.1:54400";
const who = process.argv[2] || "boss", label = process.argv[3] || "run";
const PAGES = [["Dashboard", "/"], ["Tasks", "/tasks"], ["Registers", "/registers"], ["Staff", "/settings/staff"], ["Onboarding", "/compliance"], ["Directory", "/people"], ["My requests", "/requests"], ["Reports", "/reports"], ["My account", "/account"], ["Settings", "/system"]];
const rounds = (log) => {
  const s = [...log].sort((a, b) => a.start - b.start);
  let n = 0, end = -1;
  for (const r of s) { if (r.start >= end) { n++; end = r.end; } else end = Math.max(end, r.end); }
  return n;
};
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto(`${B}/login`); await p.fill("#email", `${who}@example.com`); await p.fill("#password", "test-password-123");
  await p.press("#password", "Enter"); await p.waitForURL((u) => !u.pathname.startsWith("/login"), { timeout: 60000 });
  await p.waitForLoadState("networkidle");
  // Warm-up pass so the first visit isn't counted against a page.
  for (const [, path] of PAGES) await p.goto(B + path, { waitUntil: "networkidle" }).catch(() => {});
  await p.goto(B + "/", { waitUntil: "networkidle" });
  const out = [];
  for (const [name, path] of PAGES) {
    const runs = [];
    for (let i = 0; i < 3; i++) {
      await fetch(R + "/__reset");
      const t0 = Date.now();
      // Exactly what the app asks the server for when you click a menu link.
      const res = await p.request.get(B + path, { headers: { RSC: "1" } });
      await res.body();
      const ms = Date.now() - t0;
      const log = await (await fetch(R + "/__log")).json();
      runs.push({ ms, calls: log.length, auth: log.filter((l) => l.path.startsWith("/auth/")).length, rounds: rounds(log), kb: Math.round(log.reduce((a, l) => a + l.size, 0) / 1024), status: res.status() });
    }
    runs.sort((x, y) => x.ms - y.ms);
    out.push({ name, ...runs[1] });
  }
  // Full page load metrics for the dashboard.
  await fetch(R + "/__reset");
  await p.goto(B + "/", { waitUntil: "load" });
  const v = await p.evaluate(() => new Promise((res) => {
    const nav = performance.getEntriesByType("navigation")[0];
    let lcp = 0;
    new PerformanceObserver((l) => { for (const e of l.getEntries()) lcp = e.startTime; }).observe({ type: "largest-contentful-paint", buffered: true });
    setTimeout(() => res({ ttfb: Math.round(nav.responseStart), fcp: Math.round(performance.getEntriesByName("first-contentful-paint")[0]?.startTime || 0), lcp: Math.round(lcp), domInteractive: Math.round(nav.domInteractive), js: Math.round(performance.getEntriesByType("resource").filter((r) => r.initiatorType === "script").reduce((a, r) => a + (r.transferSize || 0), 0) / 1024) }), 1500);
  }));
  console.log(JSON.stringify({ label, who, pages: out, fullLoad: v }));
  await b.close();
})();

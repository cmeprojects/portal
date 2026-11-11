const { chromium } = require("playwright");
(async () => { const b = await chromium.launch(); const p = await b.newPage();
  await p.goto("http://localhost:3100/login"); await p.fill("#email", "boss@example.com"); await p.fill("#password", "test-password-123");
  await p.press("#password", "Enter"); await p.waitForURL((u) => !u.pathname.startsWith("/login"), { timeout: 60000 });
  await p.goto("http://localhost:3100/requests", { waitUntil: "networkidle" }); await p.waitForTimeout(6000);
  for (const [href, h] of [["/account", "My account"], ["/requests", "My requests"]]) {
    await p.evaluate(({ h }) => { window.__m = { }; const t0 = performance.now(); window.__t0 = t0;
      new MutationObserver(() => {
        if (!window.__m.skel && document.querySelector('main [role=status] .animate-pulse')) window.__m.skel = Math.round(performance.now() - window.__t0);
        const h1 = [...document.querySelectorAll("main h1")].find((x) => x.textContent.includes(h));
        if (h1 && !window.__m.h1) window.__m.h1 = Math.round(performance.now() - window.__t0);
      }).observe(document.body, { subtree: true, childList: true, characterData: true }); }, { h });
    await p.evaluate(() => { window.__t0 = performance.now(); });
    await p.locator(`nav a[href="${href}"]`).first().click();
    await p.locator("main h1", { hasText: h }).first().waitFor();
    await p.waitForTimeout(300);
    console.log(href, JSON.stringify(await p.evaluate(() => window.__m)));
    await p.waitForTimeout(5000);
  }
  await b.close(); })();

const { chromium } = require("playwright");
const R = "http://127.0.0.1:54400";
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1280, height: 900 } });
  await p.goto("http://localhost:3100/login"); await p.fill("#email", "boss@example.com"); await p.fill("#password", "test-password-123");
  await p.press("#password", "Enter"); await p.waitForURL((u) => !u.pathname.startsWith("/login"), { timeout: 60000 });
  for (const path of ["/requests", "/people", "/tasks"]) {
    let rsc = 0; const onReq = (r) => { if (r.headers()["rsc"]) rsc++; }; p.on("request", onReq);
    await fetch(R + "/__reset");
    await p.goto("http://localhost:3100" + path, { waitUntil: "networkidle", timeout: 120000 }); await p.waitForTimeout(4000);
    const log = await (await fetch(R + "/__log")).json(); p.off("request", onReq);
    console.log(path, "background page requests (prefetch):", rsc, "| database calls while opening and sitting 4s:", log.length);
  }
  await b.close(); })();

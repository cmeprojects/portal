// Counts and delays every call from the app to Supabase (cmeprojects perf audit).
const http = require("http");
const DELAY = Number(process.env.DELAY || 0);
const log = [];
const server = http.createServer((req, res) => {
  if (req.url === "/__log") { res.end(JSON.stringify(log)); return; }
  if (req.url === "/__reset") { log.length = 0; res.end("ok"); return; }
  const start = Date.now();
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => setTimeout(() => {
    const up = http.request({ host: "127.0.0.1", port: 54321, path: req.url, method: req.method, headers: req.headers }, (r) => {
      res.writeHead(r.statusCode, r.headers);
      let size = 0;
      r.on("data", (c) => { size += c.length; res.write(c); });
      r.on("end", () => { res.end(); log.push({ path: req.url.split("?")[0], method: req.method, start, end: Date.now(), size }); });
    });
    up.on("error", () => { res.writeHead(502); res.end(); });
    up.end(Buffer.concat(chunks));
  }, DELAY));
});
server.listen(54400, () => console.log("relay on 54400, delay", DELAY));

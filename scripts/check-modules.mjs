// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects: the module catalogue in code (src/lib/modules.ts) and in the
// database migrations (public.app_modules) must list the same ids.
import { readFileSync, readdirSync } from "node:fs";

const code = new Set([...readFileSync("src/lib/modules.ts", "utf8").matchAll(/\{ id: "([a-z_.]+)", category:/g)].map((m) => m[1]));
const sql = readdirSync("supabase/migrations").filter((f) => f.endsWith(".sql")).sort().map((f) => readFileSync(`supabase/migrations/${f}`, "utf8")).join("\n");
const db = new Set();
for (const block of sql.matchAll(/insert into public\.app_modules[\s\S]*?;/g)) for (const m of block[0].matchAll(/\('([a-z_.]+)', (?:null|'[a-z_.]+'), '/g)) if (!m[1].startsWith("cat_")) db.add(m[1]);
const missingDb = [...code].filter((id) => !db.has(id));
const missingCode = [...db].filter((id) => !code.has(id));
if (missingDb.length || missingCode.length) {
  console.error("Module catalogue mismatch.");
  if (missingDb.length) console.error("  In src/lib/modules.ts but not in a migration:", missingDb.join(", "));
  if (missingCode.length) console.error("  In a migration but not in src/lib/modules.ts:", missingCode.join(", "));
  process.exit(1);
}
console.log(`Module catalogue: ${code.size} modules match.`);

// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (Zero Trust review, 28 Nov 2026): redirects stay on this site.
//   node --experimental-strip-types tests/unit/safe-next.test.mjs
import assert from "node:assert/strict";
import { safeNext } from "../../src/lib/safe-next.ts";

const offSite = ["//evil.example", "/\\evil.example", "/\t/evil.example", "/\n/evil.example", "/\r\\evil.example", "/ /evil.example", "https://evil.example", "evil.example", "/%2F%2Fevil.example\\x", "", null, undefined, 42];
for (const v of offSite) {
  const out = safeNext(v);
  assert.equal(out, "/", `refused: ${JSON.stringify(v)}`);
  assert.equal(new URL(out, "https://portal.example.com").host, "portal.example.com");
}
const onSite = [["/tasks/1", "/tasks/1"], ["/billing?tab=upcoming", "/billing?tab=upcoming"], ["/roster?d=2026-11-29#x", "/roster?d=2026-11-29#x"], ["/my-shifts", "/my-shifts"]];
for (const [v, want] of onSite) assert.equal(safeNext(v), want, `kept: ${v}`);
// Whatever comes back always resolves to this site.
for (const v of ["/\t/x", "/a/../../b", "/%09/evil.example", "/.//evil.example"]) assert.equal(new URL(safeNext(v), "https://portal.example.com").host, "portal.example.com", `stays on site: ${JSON.stringify(v)}`);
console.log(`safe-next: ${offSite.length + onSite.length + 4} checks passed`);

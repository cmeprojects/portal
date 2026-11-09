# Performance audit: findings and proposal (cmeprojects)

Staff Portal · © cmeproject · 9 November 2026 · Development copy (`dev`) · **Before implementation**

## How it was measured

- **Production build** (`next build` / `next start`), not development mode.
- **A relay** between the app and Supabase that counts every database call and can add delay per call. The delay simulates a database outside Sydney, since the app runs in Sydney (`vercel.json` → `syd1`).
- **Server time per page:** the same request the browser makes on a menu click, median of 3.
- **Browser timings:** time to first byte (TTFB), first paint (FCP), largest paint (LCP), and click to new page.
- **Two data sizes:**
  - *Small:* the current test data.
  - *Realistic:* 314 people, 10,515 tasks, 3,070 notifications and 908 onboarding records. These are synthetic test records on the local copy only.
- **Database query statistics** (`pg_stat_statements`) and query plans.

## Summary of the architecture

- **Next.js 16 (App Router) on Vercel (Sydney).** Pages render on the server and read the database through Supabase's REST API, which pools database connections on Supabase's side, so the app holds no connections of its own.
- **Security is enforced in the database** with row-level security (RLS) and security-definer functions. Pages also check the role on the server.
- **The shared frame** (menu, bell, photo, profile reminder) is in `(portal)/layout.tsx`. On a menu click, Next keeps the frame and only fetches the new page (measured), so the frame isn't rebuilt on every click.
- **Every page** calls `requireSession()` once per request (cached for that request): three database calls for access, profile and switches.
- **Middleware** (`proxy.ts`) checks the sign-in on each request, and checks for remote sign-out at most once a minute.

## Current measurements (baseline)

### Small data, database next door (0 ms delay)
| Page | Server time | Database calls |
|---|---|---|
| Dashboard | 112 ms | 30 |
| Tasks | 92 ms | 25 |
| Registers | 82 ms | 25 |
| Staff | 117 ms | 51 |
| Onboarding | 130 ms | 48 |
| Directory | 78 ms | 27 |
| My requests | 83 ms | 22 |
| Reports | 93 ms | 24 |
| My account | 86 ms | 28 |
| Settings | 97 ms | 25 |

Full load of the dashboard: TTFB 81 ms, FCP 120 ms, LCP 420 ms.
Menu click: loading screen at about 50 ms, page at about 350 ms (60 ms server, plus about 300 ms of React's built-in pause before replacing a loading screen).

### Small data, 100 ms delay per database call (a database outside Sydney)
All pages took **480–730 ms** of server time, which means about 5–6 database waits one after another. Dashboard full load: TTFB 501 ms, LCP 856 ms.

### Realistic data, 0 ms delay
| Page | Server time | Database calls | Data from database |
|---|---|---|---|
| **Tasks** | **6,590 ms** | 25 | 420 KB |
| Dashboard | 1,601 ms | 30 | 386 KB |
| Registers | 1,419 ms | 25 | 78 KB |
| Onboarding | 1,354 ms | **312** | 330 KB |
| Reports | 1,172 ms | 24 | 375 KB |
| Staff | 924 ms | **293** | 514 KB |
| Directory, My requests, My account, Settings | 270–290 ms | 22–28 | small |

## Findings and root causes

1. **Security rules run their checks once per row (the main issue as data grows).**
   - 72 of the 115 RLS policies call functions like `is_member()`, `has_role()` and `auth.uid()` directly. Postgres runs them **for every row**, not once per query.
   - The task rule calls `can_see_task(id)` per row, which looks the task up again and re-checks membership and role each time.
   - Proof, on 10,515 tasks as a manager, in a test transaction that was rolled back:
     - reading tasks: **5,806 ms → 3 ms**
     - reading settings: 14.8 ms → 0.8 ms

     The rule was written the way Supabase recommends: `(select is_member())`, so it's checked once. Results are the same.
2. **Location of the database (likely the main cause of the lag you feel today).** With little data, a page needs 5–6 database waits one after another. In Sydney each wait takes a few milliseconds. Outside Sydney each takes 100–200 ms, which makes a page 0.5–1.2 s. Vercel already runs in Sydney, so the Supabase project's region needs checking.
3. **Sign-in checks may be network calls.** `getClaims()` checks the sign-in instantly when the project uses Supabase's newer **JWT signing keys**. With the older shared secret, every check calls Supabase's Auth server. The middleware and the page both check, so that's up to 2 extra waits per click. This is a dashboard setting, not code.
4. **One database call per person (N+1).**
   - The Onboarding overview calls `compliance_status` and `work_status` **for each person**: 312 calls with 300 staff.
   - The Staff page calls `compliance_status` for each person: 293 calls.
   - They run in parallel, but 300 calls at once is heavy on the server and on Supabase.
5. **Settings read many times per page.** `app_settings` is read **up to 17 times** in one page (branding, time zone, people rules, notification channels and so on), each a separate call.
6. **Whole lists are loaded and sent.** Tasks (420 KB) and the Dashboard (386 KB) load every visible task, then filter and count in the app. Reports does the same (375 KB).
7. **Background prefetching.** Each page view starts 37–61 background requests for links the person might click (about one database call each). It's useful for the menu, but wasteful for long lists like the directory rows and task rows.
8. **Indexes.** Tasks, notifications, task events, helpers and onboarding records are already indexed on the columns they're searched by. No missing index was found yet. Plans will be re-checked after fix 1, and an index added only where a plan shows a full table scan.
9. **Not a problem:**
   - the frame isn't rebuilt on menu clicks;
   - there's no database connection pooling to manage (Supabase does it);
   - JavaScript and images aren't the bottleneck;
   - the about 300 ms pause before a loading screen is replaced is normal React behaviour.

## Recommended improvements, ranked by impact

| # | Change | Why (evidence) | Impact | Complexity | Risk |
|---|---|---|---|---|---|
| 1 | **Rewrite the RLS policies** so each check runs once per query (`(select …)`), and inline the task rule's columns. Database update 60 with an undo. | Tasks 5,806 → 3 ms, settings 15 → 1 ms | Very high as data grows | Medium | Medium: security rules. Mitigated by the 784 database tests, plus a new test comparing visible rows per role before and after |
| 2 | **Check the Supabase region and switch on JWT signing keys** (dashboard settings, no code) | 5–6 waits × 100–200 ms if not in Sydney; up to 2 extra waits per click with the old secret | Very high if not Sydney | Low (settings) | Low. A new project in Sydney is needed if the region is wrong |
| 3 | **One database function for the onboarding and staff summaries**, instead of a call per person | 312 and 293 calls → 1 | High as staff grow | Medium | Low (read-only, same permission checks) |
| 4 | **Read settings once per request** (cached for that request); branding cached across requests and refreshed on Deploy | Up to 17 reads → 1 | Medium | Low | Low |
| 5 | **Tasks and Dashboard: count in the database and page the lists** (for example 50 at a time with search and filters on the server) | 420 and 386 KB per page, 1.6 s or more at volume | High at volume | Medium–high | Medium (UI). Re-measured after fix 1 first, as it may cover most of it |
| 6 | **No background prefetch on long lists** (directory rows, task rows); keep it for the menu | 37–61 background requests per page | Low–medium | Low | Low |
| 7 | **Indexes only where plans show full scans** after fix 1 | Evidence-based | Low–medium | Low | Low |

**Not recommended:**
- **A separate `/api/app/bootstrap` endpoint.** The frame already stays loaded between clicks (measured), so it would add a request, not remove one. Fixes 4 and 1 deal with the repeated reads.
- **Caching permissions across requests.** Role changes must apply immediately, and the database must keep the final say.

## Risks and dependencies

- **Fix 1 changes security rules.** It's a mechanical change (the same conditions, checked once), generated as explicit, readable SQL with an undo. It's verified by the full database test suite, a before-and-after row-count comparison for every role on the main tables, and a full re-crawl.
- **Fix 2 needs you**, in the Supabase dashboard. A new region means a new project and moving data (I'd give steps). JWT signing keys can be switched on in place. Existing sign-ins keep working.
- **Fix 5 changes how big lists page.** It'll be done after fix 1 is measured, so only what's still needed is built.

## Implementation and testing plan (updated)

| Step | What | Where | Checked by |
|---|---|---|---|
| 0 | **Checkpoint** branch `restore-before-performance`. **Extra baseline:** sign-in time and the most-used buttons (save, approve, upload, acknowledge, sign) | Local copy | Timings recorded before any change |
| 1 | **Security rules checked once per query, not once per row** (72 rules; row-specific checks stay per row). Update 60 with an undo | Database | 784 database tests; new test: what each role sees in each main table must match before and after; re-measure |
| 2 | **Region and sign-in keys** (by you): Supabase in Sydney, like the app; JWT signing keys switched on | Supabase dashboard | Re-measure page and sign-in times on Development |
| 3 | **Summaries calculated in the database**: onboarding overview and staff list in one call each, instead of one per person (312 and 293 → 1) | Database function, update 60 | Permission test per role; re-measure |
| 4 | **Settings read once per request**; branding kept between requests and refreshed on Deploy | App | Re-measure (up to 17 reads → 1) |
| 5 | **Less background prefetch** on long lists (directory and task rows); the menu keeps it | App | Background requests per page before and after |
| 6 | **Re-measure everything**: every page, sign-in and buttons, small and realistic data, with and without delay | Local copy | Before-and-after table |
| 7 | **Where still slow:** tasks, dashboard and reports **counted and paged in the database** (tiles, charts and totals come back as numbers; lists 50 at a time with server-side search and filters) | Database functions and app | Same results as today per role; re-measure |
| 8 | **Faster buttons**: show the result straight away where safe (the server still confirms), and reload only what changed after a button press | App | Button timings before and after; failed saves still show the error |
| 9 | **Indexes** only where query plans show full table scans | Database | Query plans before and after |
| 10 | **Load test**: 20 simulated staff navigating and pressing buttons at once, realistic data | Local copy | Response times (typical and worst), errors |
| 11 | **Regression**: all database tests, workflow browser tests, per-role permission checks, full re-crawl, lint, typecheck, build | Local copy | All pass |
| 12 | **Report**: changes, files and database objects affected, before and after figures, remaining bottlenecks, recommendations | Docs | Pushed with the work |

Security rules for every step: the database keeps the final say; nothing about permissions is cached between people or requests; database summaries run as the signed-in person, so the same rules decide what's counted; every database change has an undo file.

All of this happens on Development only, with the synthetic data kept to my local copy.

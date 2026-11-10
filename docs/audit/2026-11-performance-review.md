# Performance, RLS security and scalability review (cmeprojects)

Staff Portal · © cmeproject · 10 November 2026 · **Review only: nothing has been changed.**

Companion file: [`2026-11-rls-register.md`](2026-11-rls-register.md), with every affected policy's original definition, proposed definition, and apply and rollback SQL.

## How this was checked (no changes made)

- **Code:** read from the `dev` branch.
- **Database definitions:** taken from a throwaway database built from all 76 migrations.
- **Measurements** on a local copy only (never Supabase or Vercel):
  - a production build of the app;
  - a relay that counts every database call and can add delay;
  - synthetic data: 314 people, 10,515 tasks, 3,070 notifications, 908 onboarding records;
  - four test accounts: manager, staff admin, team leader, support worker.
- **Every experiment on a policy ran inside a transaction that was rolled back.** No policy, function, index, setting or data was changed anywhere.
- **Measured vs estimated:** "Measured" means run and timed here. "Estimate" is labelled as such.

## A. Executive summary

**What makes it slow, in order:**

1. **Distance between the app and the database (confirmed, the main cause today).** The app runs in Sydney (`vercel.json` → `syd1`) and the Development database is in **Seoul** (`ap-northeast-2`, from the Supabase dashboard). A page waits on the database about 5–6 times, one after another. With 100 ms added per call to imitate the distance, every page took 480–730 ms of server time (measured). The owner is already moving Development to a Sydney project.
2. **Security rules re-checked for every row (confirmed, the main cause as data grows).**
   - **94 of 115** policies call functions that don't depend on the row (`auth.uid()`, `is_member()`, `has_role(...)` and others). Postgres runs them once per row instead of once per query.
   - The task rule runs a full permission function per row.
   - Measured, reading tasks with 10,515 synthetic tasks: manager **7.1 s**, staff admin **9.1 s**, team leader **8.8 s**, support worker **10.0 s** (who can see only 3 of them).
3. **One database call per person (confirmed).** The Onboarding overview makes 2 calls per person (312 with 300 staff) and the Staff page 1 per person (293). Measured.
4. **Whole task lists loaded to count them (confirmed).**
   - **Dashboard:** up to 3,000 open tasks, plus three lists of up to 10,000 rows, for the charts.
   - **Tasks page:** up to 3,000 tasks.
   - **Registers:** up to 5,000 rows to count per register.
   - **Reports:** similar.
5. **Settings read separately many times per page (confirmed).** Settings are read in 30 places in the code. Each helper is cached within one request, but each makes its own call. Up to 17 calls on one page (measured).
6. **Background prefetch (confirmed, minor).** 37–61 background requests per page view (measured), about one database call each. Fine for the menu; wasteful for long lists.

**Needs verification (by the owner):** whether the Supabase project uses the newer **JWT signing keys**. With them, sign-in checks happen on the server without a network call. With the older shared secret, each check can be an extra trip to Supabase. Locally, checks made no network call. Production must be checked: **Supabase → Project Settings → JWT Keys**.

**Not problems (verified):**
- the menu and bell aren't rebuilt on menu clicks;
- the app holds no database connections of its own (Supabase's API pools them);
- task, notification, history and onboarding tables are indexed for how they're searched;
- every table has row security on; there are no views (so no RLS bypass through views);
- all 222 privileged (security definer) functions have a fixed `search_path`;
- role escalation through profile edits is blocked by the `guard_profile_update` trigger, with tests.

**Greatest impact:**
1. Sydney database (owner, in progress).
2. RLS optimisation: measured 7–10 s → 5–8 ms on tasks.
3. Per-person calls → one call.
4. Counting in the database.

## B. Findings register

| # | Finding | Evidence (measured unless stated) | Root cause | Impact | Recommendation | Security risk | Complexity | Priority |
|---|---|---|---|---|---|---|---|---|
| 1 | Database in Seoul, app in Sydney | Supabase dashboard `ap-northeast-2`; `vercel.json` `syd1`; 100 ms per call → 480–730 ms per page | Cross-region round trips, 5–6 in sequence per page | 0.5–1.2 s per page now (estimate from measured wave count × typical latency) | Move Development to a Sydney project (owner, in progress); every client copy in Sydney | Low (data in Australia is better for privacy) | Low–medium (owner task) | 1 (in progress) |
| 2 | RLS functions evaluated per row | 94/115 policies (register); tasks 7.1–10.0 s per role; onboarding records about 0.4 s; profiles about 0.1–0.14 s | Row-independent calls not wrapped in `(select …)`; `can_see_task(id)` per row | Grows with data; dominant at volume | Pattern A on 94 policies; pattern B on the task family | Low (A), medium (B), mitigated by tests | Medium | 2 |
| 3 | Per-person calls | Onboarding 312 calls, Staff 293 calls; code: `compliance/page.tsx` (Progress), `settings/staff/page.tsx` | `compliance_status` and `work_status` called per person | 300 parallel calls per page view; heavy on Supabase | One function returning a summary per visible person | Medium (must keep the same visibility) | Medium | 3 |
| 4 | Settings read separately | 30 read sites; up to 17 calls per page | Separate helpers (branding, time zone, people rules, SLA, idle, channels, drafts…) | 10–17 small calls per page | One settings read per request, shared by all helpers; public branding cached between requests and refreshed on Deploy | Low (no permissions cached) | Low | 4 |
| 5 | Background prefetch | 37–61 background requests per page view | Default prefetch on every link, including long lists | Extra server work and Vercel invocations | No prefetch on list rows (directory, task rows); keep it for the menu | Low | Low | 5 |
| 6 | Whole task lists loaded to count | `role-dashboard.tsx` (3,000 + 3×10,000 rows), `dashboard-view.tsx` (3,000), `registers/page.tsx` (5,000); 386–420 KB per page at volume | Counting and grouping done in the app | Data size and app work grow with tasks | Counts, groups and trends in SQL (security invoker); task list paged on the server | Low–medium | Medium–high | 6 (after re-measuring) |
| 7 | Sign-in checks may be network calls | Locally none; production unknown | Depends on Supabase JWT key type | Up to 2 extra waits per click (estimate) | Owner checks JWT Keys; switch to signing keys if offered (no code change) | Low | Low | 1b (check) |
| 8 | Privileged helpers callable by signed-out visitors | 50 security definer functions executable by `anon` | Default execute grant not revoked on older helpers | No data exposed today (they return "no access" without a user), but unnecessary | Revoke `anon` execute on helpers not used by the public website | Low (hardening) | Low | 7 |
| 9 | Overlapping permissive policies | 9 table/operation pairs with more than one permissive policy | Separate rules for "own" and "manager" access | Each is evaluated (OR'd); small once pattern A applies | Keep (they're intentional); no merge without proof | Low | n/a | n/a |

## C. RLS change register

**Pattern A: 94 policies** (full list with original, proposed, apply and rollback SQL in [`2026-11-rls-register.md`](2026-11-rls-register.md)).
- **The change:** calls that don't depend on the row are wrapped as `(select …)`.
  - Example: `(is_system_admin() OR (user_id = auth.uid()))` becomes `((select public.is_system_admin()) OR (user_id = (select auth.uid())))`.
- **Why it's faster:** Postgres evaluates the wrapped call once per statement (as an "initplan") instead of once per row.
- **Why it's safe:**
  - every wrapped function is `STABLE` (verified), so it returns the same value throughout one statement;
  - the arguments are fixed values, never row columns;
  - the boolean logic is unchanged;
  - row-dependent calls (`can_see_task(id)`, `leads_user(…)`, `can_manage_form(form_id)` and others) are left as they are.
- **Security implications:** none intended. The evaluated condition is the same. Nothing is cached beyond the single statement, and nothing is shared between users or requests.

**Pattern B: task visibility** (`tasks`, plus `task_events`, `task_helpers` and `task_attachments` to follow the same approach):
- **The change:** inline the same conditions as `can_see_task(id)` on the row's own columns, with person-level checks evaluated once, and the team leader's people from a new read-only helper `my_led_people()`. It's security definer with a fixed search path, mirrors `leads_user()`, and can't be run by signed-out visitors.
- **SQL and rollback** are in the register.

**Validation of the proposal, already done (no changes kept):**
| Check | Result |
|---|---|
| All 94 proposed statements and 95 rollbacks parsed and applied, then rolled back, on a throwaway database | All ran |
| Rows visible in **all 62 tables**, per role (manager, staff admin, team leader, support worker), before vs after, compared by fingerprint of every row | **Identical for every table and role** |
| Task rule pattern B: rows and timing per role | Identical task IDs; 7.1–10.0 s → **5–8 ms** |
| Full security test suite with the proposal applied | See the update at the end of this file |

**Test cases for implementation:**
- Per role (staff, team leader, manager, staff admin, system admin, signed out):
  - SELECT: the same rows as before (fingerprints) in every table;
  - INSERT, UPDATE, DELETE: allowed and refused the same as before (the existing suites cover this, plus a new before-and-after matrix);
  - record-ID manipulation: direct requests for another person's records are refused;
  - team boundaries: a leader sees only their teams' people and tasks;
  - role change while signed in: the new access applies on the next request;
  - expired or invalid session: refused.
- Rollback SQL run twice, and the original rules restored exactly (compared with the database definitions).

## D. Calculations to move into SQL

| Area | Today | Proposed | Response shape | RLS | Freshness | Benefit |
|---|---|---|---|---|---|---|
| Dashboard tiles and charts | App loads up to 3,000 open tasks + 3×10,000 rows and counts them | One SQL function: counts by status, overdue, escalated, waiting for approval, due this week; by person; by register; overdue ageing; weekly opened and closed; on-time % | About 1–5 KB of numbers | **Security invoker**: the user's own RLS decides which tasks are counted | Live | Hundreds of KB → a few KB; less app work |
| Tasks list | Up to 3,000 rows loaded | Server-side filters, search and sort, 50 per page, plus a total count | One page of rows + total | Normal RLS | Live | Constant size as tasks grow |
| Registers overview | 5,000 rows to count per register | `count(*) group by registry_id` in one function | One row per register | Security invoker | Live | 5,000 rows → about 10 rows |
| Onboarding overview and staff | 2 calls per person | One function: per visible person, done / total, waiting for checks, expired or expiring, cleared, override | One row per visible person | Must keep the **same visibility as `compliance_status`** (Compliance managers, people managers, managers, leaders of that person). Implemented as a function that applies the same check per person, tested against today's per-person results for each role | Live | 300 calls → 1 |
| Reports (tasks, compliance) | Rows loaded, then grouped in the app | Grouping, date filters and totals in SQL; export still returns the actual authorised rows | Totals + paged rows | Security invoker for totals; normal RLS for rows | Live | Smaller, faster reports |
| People and HR counts (active staff, by team or position, pending requests, upcoming expiries) | Mostly small lists today | Add to the same summary functions only where a page counts lists | Numbers | As above | Live | Small now, protects growth |

**Mechanisms:**
- **Plain queries** for lists.
- **Security invoker functions** for summaries, so RLS still applies.
- **No new views:** functions keep the security model explicit.
- **No materialised views:** they don't apply RLS per user and would need refresh jobs. Not needed at this scale once RLS is fixed.

Business rules (approvals, workflows, validation) stay where they are.

## E. Implementation plan (each stage separate, with its own rollback)

| Stage | Scope | Affects | Depends on | Risks | Tests | Rollback | Expected benefit |
|---|---|---|---|---|---|---|---|
| 0 | Restore point; baseline re-measured on the **new Sydney Development** copy | Nothing | Owner's move | None | Timing only | n/a | True baseline |
| 1 | RLS pattern A (94 policies) | Database update 60 (policies only) | 0 | Low | Full suite; per-role, per-table fingerprints; write-permission matrix; re-crawl | `undo-60.sql` (the register's rollbacks) | Every page at volume |
| 2 | RLS pattern B (task family) + `my_led_people()` | Update 61 | 1 | Medium | As 1, plus the task-family matrix | `undo-61.sql` | Tasks 7–10 s → milliseconds at volume |
| 3 | Onboarding and staff summary function | Update 62; `compliance/page.tsx`, `settings/staff/page.tsx` | 1 | Medium (visibility) | Per role: same people and figures as today | Undo + app revert commit | 300 calls → 1 |
| 4 | Settings read once per request | `lib/settings.ts`, `lib/branding.ts`, layout | None | Low | Settings changes show after Deploy; re-measure | App revert | 10–17 calls → 1 |
| 5 | Selective prefetch | Directory, task tables | None | Low | Background request count | App revert | Fewer background requests |
| 6 | **Re-measure** (pages, sign-in, buttons) | None | 1–5 | None | Same conditions as baseline | n/a | Decide whether 7 is needed |
| 7 | Dashboard, registers, reports counted in SQL; tasks paged | Update 63; dashboard, registers, reports, tasks pages | 6 | Medium (UI) | Totals match lists per role; workflows | Undo + app revert | Data size constant as tasks grow |
| 8 | Revoke `anon` execute on unneeded helpers | Update 64 | None | Low (must keep what the public website uses) | Website and sign-in pages work signed out; full suite | Undo grants | Hardening |
| 9 | Load test: 20 simultaneous users, realistic data | Local only | 1–7 | None | p50/p95 response times, errors, calls/min, before vs after | n/a | Evidence for scaling |

Each database stage is a version-controlled migration, a live update and an undo file, safe to run again. The re-runnable setup file is rebuilt so new copies match.

## F. Performance baseline (measured)

**Small data (current test data), database next door (0 ms), server time per page:** Dashboard 112 ms (30 calls), Tasks 92 (25), Registers 82 (25), Staff 117 (51), Onboarding 130 (48), Directory 78 (27), My requests 83 (22), Reports 93 (24), My account 86 (28), Settings 97 (25).
- **Dashboard full load:** TTFB 81 ms, FCP 120 ms, LCP 420 ms.
- **Menu click:** loading screen at about 50 ms, page at about 350 ms. That's about 60 ms of server time plus React's standard pause of about 300 ms before replacing a loading screen.

**Small data, 100 ms added per database call:** 480–730 ms server time per page. Dashboard full load: TTFB 501 ms, LCP 856 ms.

**Realistic synthetic data, 0 ms delay:** Tasks 6,590 ms (25 calls, 420 KB), Dashboard 1,601 ms (30, 386 KB), Registers 1,419 ms, Onboarding 1,354 ms (312 calls), Reports 1,172 ms, Staff 924 ms (293 calls, 514 KB); Directory, My requests, My account and Settings about 270–290 ms.

**Single-table reads per role (realistic data):**
| Table | Manager | Staff admin | Team leader | Support worker |
|---|---|---|---|---|
| tasks | 7,117 ms | 9,112 ms | 8,822 ms | 9,954 ms |
| compliance_records | 383 ms | 444 ms | 372 ms | 488 ms |
| profiles | 141 ms | 137 ms | 103 ms | 121 ms |
| notifications | 58 ms | 5 ms | 3 ms | 5 ms |
| app_settings | 23 ms | 18 ms | 17 ms | 28 ms |

**Not measured here:** sign-in and button timings (planned for stage 0), CPU and memory under load (stage 9), and production Vercel and Supabase timings (after the move to Sydney).

## G. Approval request

Please approve each separately:

1. **Stage 1:** RLS pattern A on 94 policies (update 60, undo-60).
2. **Stage 2:** task-family RLS rewrite + `my_led_people()` (update 61, undo-61).
3. **Stage 3:** onboarding and staff summary function (update 62) and the two pages.
4. **Stage 4:** settings read once per request.
5. **Stage 5:** selective prefetch.
6. **Stage 6:** re-measure, then decide on stage 7 (dashboard, registers, reports and tasks counted and paged in SQL) with the figures.
7. **Stage 8:** revoke `anon` execute on unneeded helper functions.
8. **Stage 9:** load test with 20 simultaneous users (local, synthetic data).

**Owner actions (no approval needed from me):** finish the move to Sydney; check **JWT Keys** in the new project and say which type it uses.

## Update: security test suite with the proposal applied

All database test files were run on throwaway databases with every proposed policy change (patterns A and B) applied: **783 checks passed, 0 files failing.** The 784th check in the normal run checks that the setup file is current, and doesn't apply here. Nothing was kept: each test database was deleted afterwards.

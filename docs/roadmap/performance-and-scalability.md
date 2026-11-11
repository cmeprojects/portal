# Stage-by-Stage Development Instructions
## Application Performance, Supabase RLS and Scalability

**Master performance and scalability roadmap (cmeprojects).** Staff Portal · © cmeproject.

The original instructions are kept unchanged below the status register. Only the status register and the "Resume from" notes are maintained.

---

## Status register (last updated 11 November 2026)

| Stage | Title | Status | Evidence / where to resume |
|---|---|---|---|
| 0 | Baseline and Development Environment | **COMPLETED AND VERIFIED** | `docs/audit/2026-11-performance-stage1.md` §Stage 0; baseline also in `docs/audit/2026-11-performance-review.md` §F |
| 1 | RLS Pattern A Optimisation | **COMPLETED AND VERIFIED: formally accepted and CLOSED by the owner (11 Nov 2026)** | `docs/audit/2026-11-performance-stage1.md`; evidence `docs/audit/evidence/stage1/` |
| 2 | Task-Family RLS Optimisation | **DEFERRED, NOT COMPLETED** (not implemented) | Proposal draft: `docs/audit/2026-11-rls-register.md` §Pattern B. Needs the separate security review first |
| 3 | Onboarding and Staff Page Optimisation | **DEFERRED, NOT COMPLETED** (not implemented) | Findings: review §B #3, §D |
| 4 | Settings Optimisation | **DEFERRED, NOT COMPLETED** (not implemented) | Findings: review §B #4 |
| 5 | Background Prefetch Optimisation | **DEFERRED, NOT COMPLETED** (not implemented) | Findings: review §B #5 |
| 6 | Full Performance Remeasurement | **DEFERRED, NOT COMPLETED** (not implemented) | Use the Stage 0 method and tools (below) |
| 7 | SQL Aggregation, Reporting and Pagination | **DEFERRED, NOT COMPLETED** (not implemented) | Findings: review §B #6, §D |
| 8 | Database Function Permissions Review | **DEFERRED, NOT COMPLETED** (not implemented) | Findings: review §B #8 (50 helpers callable by `anon`) |
| 9 | Load and Concurrency Testing | **DEFERRED, NOT COMPLETED** (not implemented) | Synthetic data generator in `docs/audit/evidence/tools/seed.sql` |

**Open notes (not part of any stage's completion):**
- On Development (Sydney, 2 users), a request with no database work took **880 ms** from the owner's browser.
- The cause (network distance vs Vercel request handling) is undiagnosed. The Speed check now also shows "Plain file from Vercel" and "Handled via".
- Pick this up at the start of Stage 6, or earlier if approved.

### What was done in Stages 0 and 1 (don't repeat)
- **Environment:**
  - Development moved to Supabase **Sydney** on 11 Nov 2026; the app runs in **Sydney (`syd1`)**.
  - JWT signing keys: **ECC (P-256)**, so sign-in checks verify on the server without a network call.
  - Restore point: git branch `restore-before-performance`. Supabase Free has no snapshots; the safety net is the tested undo files and the re-runnable setup SQL.
- **Speed check panel** (System health, system admins, read-only): database round trip, sign-in service round trip, connection to the app, plain file from Vercel, "handled via", and 10 main pages.
- **Baselines recorded:**
  - local synthetic volumes (314 people, 10,515 tasks);
  - Sydney Development before and after update 60.
- **Stage 1:**
  - Update 60 (`supabase/migrations/20270104000001_rls_once_per_statement.sql`, `supabase/live-updates/update-60.sql`, rollback `supabase/live-updates/undo-60.sql`).
  - 94 policies; all 115 still enabled; nothing else changed.
  - Verified, six identities:
    - 714/714 condition comparisons;
    - 976/976 INSERT outcomes;
    - 1,116/1,116 SELECT, UPDATE and DELETE outcomes;
    - security snapshot identical apart from the 94 conditions;
    - 784/784 database tests;
    - rollback tested twice.
  - Applied to Development by the owner.

### Artefacts kept for resuming
- **Findings and plan:**
  - `docs/audit/2026-11-performance-plan.md`
  - `docs/audit/2026-11-performance-review.md` (findings register, SQL computation recommendations, stage plan)
- **Policy register** (original, proposed, apply and rollback SQL for all 94 Pattern A policies, plus the Pattern B draft): `docs/audit/2026-11-rls-register.md`
- **Stage 1 evidence:** `docs/audit/evidence/stage1/`
  - `sql/`: the exact SQL executed and the generators
  - `results/`: comparison outputs, snapshots, rollback log, test suite log
  - `policy-summary-94.md`
- **Measurement tools:** `docs/audit/evidence/tools/`
  - `relay.cjs`: counts and delays database calls
  - `measure.cjs`: page timings per module
  - `seed.sql`: synthetic data, **local copies only**
  - `click5.cjs` and `idle.cjs`: click and prefetch timing
  - `setup-sql-rerun-test.sh`: re-runnable setup SQL test

### Rules carried forward
- Each deferred stage needs **explicit approval**. Approval of an earlier stage doesn't authorise the next.
- No `SECURITY DEFINER` helper (including `my_led_people()`) without a separate security assessment and approval.
- Use the status words from the Final Rule.

---

## Original instructions (unchanged)

### STAGE 0 – Baseline and Development Environment
Prompt to agent:
Before making any changes, complete Stage 0 of the approved performance and security optimisation plan.
I want you to:

1. Confirm that you are working exclusively in DEV.
2. Confirm the application hosting region and Supabase database region.
3. Verify that the DEV database is in Sydney.
4. Confirm that a recoverable restore point exists.
5. Record the current performance baseline using realistic test data.
6. Measure page loading, database requests, API response times, payload sizes and query execution times.
7. Identify the slowest pages and queries.
8. Record the current RLS policy count and relevant function definitions.
9. Identify anything that could affect the accuracy of future comparisons.

Do not modify policies, functions, application code or database data.
Deliver:

* Environment confirmation.
* Baseline performance report.
* Database and application region confirmation.
* List of identified bottlenecks.
* Confirmation that the restore point is available.
* Recommendation for Stage 1.

Stop and wait for my review.

### STAGE 1 – RLS Pattern A Optimisation
Prompt to agent:
Proceed with the review and proposed implementation of Stage 1 only.
The objective is to optimise row-independent function evaluations in the existing Supabase RLS policies without changing any user's access permissions.
Before implementation:

1. Inspect all 94 identified policies individually.
2. Show the original SQL and proposed SQL.
3. Explain why each change is safe.
4. Identify functions that are row-independent and suitable for `(SELECT ...)` optimisation.
5. Identify any policies that should remain unchanged.
6. Confirm that the original USING and WITH CHECK conditions remain equivalent.
7. Provide the rollback SQL.
8. Confirm that the changes do not introduce SECURITY DEFINER or other privilege escalation.

Once the review is complete, present the changes for approval.
After approval, implement in DEV only.
Required validation:

* Run the complete six-role security matrix.
* Compare actual accessible record IDs and row fingerprints before and after.
* Test SELECT, INSERT, UPDATE and DELETE.
* Test ownership and team boundaries.
* Test invalid, expired and signed-out sessions.
* Confirm that no additional records become accessible.
* Confirm that rollback restores the original policies.

Deliver:

* List of policies changed.
* Original and proposed SQL.
* Security test results.
* Before-and-after query timings.
* Rollback instructions.
* Any outstanding risks.

Do not proceed to Stage 2 until I review and approve the results.

### STAGE 2 – Task-Family RLS Optimisation
Prompt to agent:
Review Stage 2 separately. Do not assume that approval of Stage 1 automatically authorises this stage.
The objective is to improve the performance of task visibility checks across:

* tasks
* task_events
* task_helpers
* task_attachments

The proposed implementation includes changes to `can_see_task(id)` and the introduction of `my_led_people()`.
Before implementation, I require a detailed security review.
Specifically:

1. Show the original `can_see_task()` function.
2. Show the proposed replacement policy conditions.
3. Show the complete `my_led_people()` function.
4. Explain how it determines which people a Team Leader can access.
5. Explain how it prevents access to unrelated employees and their records.
6. Identify whether the function uses SECURITY INVOKER or SECURITY DEFINER.
7. If SECURITY DEFINER is proposed, explain why it is necessary and what privileges it uses.
8. Confirm the function owner, fixed search_path and EXECUTE permissions.
9. Check for possible access through direct API requests.
10. Confirm that the proposed implementation does not expose additional employee or task information.

Do not use SECURITY DEFINER simply to improve query performance.
If it is genuinely required, provide a separate security assessment and wait for my approval.
Required validation:

* Test all six roles.
* Compare visible task IDs before and after.
* Test all four task-family tables.
* Test team boundaries and assigned-user restrictions.
* Test task ownership and helper permissions.
* Test INSERT, UPDATE and DELETE restrictions.
* Test attempts to access another person's task using a manipulated record ID.
* Test signed-out and expired sessions.
* Confirm rollback restores the original behaviour.

Deliver:

* Original and proposed SQL.
* Function security assessment.
* Permission comparison.
* Complete test results.
* Performance comparison.
* Rollback scripts.

Stop and wait for explicit approval before implementing any SECURITY DEFINER changes or proceeding to Stage 3.

### STAGE 3 – Onboarding and Staff Page Optimisation
Prompt to agent:
Proceed with Stage 3 only.
The objective is to eliminate unnecessary database requests generated for each employee on the Staff and Onboarding pages.
Review the current implementation and replace unnecessary per-person requests with efficient batch queries or SQL summary functions.
Preserve all existing compliance and employee visibility rules.
The new implementation must correctly calculate:

* Completed onboarding requirements.
* Outstanding requirements.
* Total requirements.
* Expired documents and qualifications.
* Expiring documents and qualifications.
* Clearance status.
* Compliance overrides, where applicable.

Pay particular attention to the visibility restrictions for:

* Compliance Managers.
* People Managers.
* Managers.
* Team Leaders.

Prefer SECURITY INVOKER for protected-data summary functions.
Required validation:

1. Compare the old and new employee lists.
2. Compare every employee's compliance results.
3. Confirm that each role sees the same authorised employees.
4. Confirm that summary totals match the original results.
5. Test employees with incomplete onboarding.
6. Test expired and expiring qualifications.
7. Test employees with overrides.
8. Confirm that no additional employee information is exposed.

Measure database calls before and after.
Deliver:

* Functions or queries introduced.
* Files changed.
* Before-and-after request counts.
* Before-and-after response times.
* Security test results.
* Rollback instructions.

Stop and wait for review before Stage 4.

### STAGE 4 – Settings Optimisation
Prompt to agent:
Proceed with Stage 4 only.
Review the application settings retrieval process.
The objective is to reduce repeated database calls by safely loading settings once per request and reusing them where appropriate.
Review:

* Application settings.
* Branding.
* Organisation configuration.
* User-specific settings.
* Permission-related settings.
* Other frequently requested configuration data.

Ensure that settings are not unnecessarily retrieved multiple times during a single page request.
Security requirements:

* Do not share private settings between users.
* Do not expose organisation-specific settings to another organisation.
* Do not cache sensitive settings in a publicly accessible location.
* Ensure that permission changes are reflected correctly.
* Ensure that updated settings are not hidden by stale cached values.

Required validation:

* Test all relevant user roles.
* Test settings changes.
* Test branding changes.
* Test organisation boundaries.
* Test login and logout.
* Confirm that existing application behaviour is unchanged.

Deliver:

* Files changed.
* Settings retrieval changes.
* Before-and-after database request counts.
* Performance results.
* Security validation.
* Rollback instructions.

Stop and wait for review before Stage 5.

### STAGE 5 – Background Prefetch Optimisation
Prompt to agent:
Proceed with Stage 5 only.
Review the application's background prefetching behaviour.
The objective is to reduce unnecessary requests without making navigation slower or breaking existing functionality.
Pay particular attention to:

* Long lists.
* Directory pages.
* Tasks pages.
* Reports.
* Administrative pages.
* Pages that users rarely visit.

Identify which requests are necessary and which can be reduced or removed.
Do not remove useful prefetching without measuring its impact.
Security requirements:

* Do not prefetch sensitive information into an unauthorised context.
* Do not expose protected data through background requests.
* Maintain existing RLS enforcement.
* Do not share cached data between users.

Required validation:

* Measure background request counts before and after.
* Test navigation between frequently used pages.
* Test navigation between administrative pages.
* Confirm that loading performance does not deteriorate.
* Confirm that existing functionality remains intact.

Deliver:

* Prefetching changes.
* Request count comparison.
* Navigation performance results.
* Security test results.
* Rollback instructions.

Stop and wait for review before Stage 6.

### STAGE 6 – Full Performance Remeasurement
Prompt to agent:
Complete Stage 6.
Do not introduce additional optimisation changes yet.
Repeat the performance tests performed during Stage 0 using the same test environment, dataset, user roles and measurement conditions.
Compare the results.
Include:

* Dashboard.
* Tasks.
* Registers.
* Staff.
* Onboarding.
* Directory.
* My Requests.
* Reports.
* My Account.
* Settings.

Measure:

1. TTFB.
2. FCP.
3. LCP.
4. Page navigation time.
5. Database requests per page.
6. Sequential database requests.
7. Database execution time.
8. API response times.
9. Payload sizes.
10. RLS performance.
11. Frontend rendering time.

Clearly distinguish local database performance from end-to-end application performance.
Identify which bottlenecks have been resolved and which remain.
Deliver:

* Stage 0 versus Stage 6 comparison.
* Percentage improvement where measurable.
* Remaining bottlenecks.
* Any regressions.
* Recommendation on whether Stage 7 is necessary.

Do not automatically proceed to Stage 7. Wait for my review and approval.

### STAGE 7 – SQL Aggregation, Reporting and Pagination
Prompt to agent:
Proceed with Stage 7 only after approval.
The objective is to move appropriate calculations from the application into PostgreSQL so that the application retrieves only the information it needs.
Review and optimise:

1. Dashboard summaries and charts.
2. Tasks lists and pagination.
3. Registers summaries.
4. Reports and reporting calculations.
5. People and HR summaries where applicable.

Use SQL for appropriate:

* Counting.
* Grouping.
* Filtering.
* Sorting.
* Summation.
* Date calculations.
* Trend calculations.
* Pagination.

For the Tasks page, use server-side pagination with a reasonable page size, such as 50 records.
For dashboard and reporting calculations, return summary data rather than downloading thousands of records and calculating everything in JavaScript.
Mandatory security requirements:

* Prefer SECURITY INVOKER for protected-data summaries.
* Preserve RLS.
* Do not expose records through unrestricted functions.
* Ensure aggregate results only include records the current user is authorised to access.
* Do not use frontend filtering as a replacement for database permissions.
* Ensure exports still retrieve all authorised records where required.

Required validation:

* Compare old and new dashboard totals.
* Compare old and new report calculations.
* Compare task list results and filters.
* Test pagination and sorting.
* Test exports.
* Test all relevant roles.
* Test inaccessible records and manipulated IDs.
* Verify SQL summaries do not include restricted records.

Deliver:

* SQL functions and queries introduced.
* Files changed.
* Before-and-after payload sizes.
* Before-and-after response times.
* Calculation comparison.
* RLS security results.
* Rollback instructions.

Stop and wait for review before Stage 8.

### STAGE 8 – Database Function Permissions Review
Prompt to agent:
Proceed with Stage 8 only.
Review database functions and their execution permissions.
Identify unnecessary privileges granted to:

* PUBLIC.
* anon.
* authenticated.
* Other roles.

For each function, document:

* Function name.
* Purpose.
* Owner.
* Security mode.
* search_path.
* EXECUTE permissions.
* Application dependencies.
* Whether the function accesses protected data.

Do not revoke permissions simply because they appear unnecessary.
First identify every legitimate application dependency.
Required validation:

* Test public website functionality.
* Test sign-in and authentication.
* Test signed-in application pages.
* Test all six roles.
* Test SQL functions.
* Test existing integrations.
* Confirm that no legitimate functionality is broken.
* Confirm that no protected data is exposed.

Only revoke permissions that have been proven unnecessary.
Deliver:

* Function permission inventory.
* Recommended changes.
* Security impact assessment.
* Test results.
* Rollback instructions.

Stop and wait for review before Stage 9.

### STAGE 9 – Load and Concurrency Testing
Prompt to agent:
Complete Stage 9 in DEV only.
Perform a realistic load test with at least 20 simultaneous users.
Use realistic application data and a representative mix of user roles.
Simulate users performing normal activities such as:

* Opening the dashboard.
* Viewing tasks.
* Updating tasks.
* Accessing registers.
* Viewing employee records.
* Completing onboarding checks.
* Accessing reports.
* Submitting requests.
* Using approval workflows.

Do not test only one page or one database query.
Measure:

* p50 response time.
* p95 response time.
* API response time.
* Database execution time.
* Database load.
* Error rate.
* Timeout rate.
* Requests per minute.
* CPU and memory usage where available.
* Application responsiveness.

Check for:

* Connection saturation.
* Slow queries under concurrency.
* Unexpected request duplication.
* RLS performance degradation.
* Data visibility problems.
* Failed writes.
* Duplicate submissions.
* Application instability.

Do not disable RLS or relax permissions to make the load test pass.
Deliver:

* Test configuration.
* User and role distribution.
* Data volume.
* Results and measurements.
* Identified bottlenecks.
* Security test results.
* Recommendations for further scalability improvements.

Do not make production changes.

### FINAL RULE FOR EVERY STAGE
At the end of each stage, provide a clear completion report.
Use the following status:

* COMPLETED AND VERIFIED
* COMPLETED, AWAITING REVIEW
* FAILED TESTING
* BLOCKED
* NOT IMPLEMENTED

Never mark a stage as completed and verified when tests have not been performed.
Do not proceed to the next stage automatically.
Wait for my review and explicit approval.
If a security issue, unexpected permission change, data exposure or regression is identified, stop immediately and explain the issue before taking further action.

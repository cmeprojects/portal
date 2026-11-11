# Performance Stage 1 (RLS pattern A): completion report (cmeprojects)

Staff Portal · © cmeproject · 11 November 2026 · Development (`dev`) · Scope: Stages 0 and 1 only. **Stage 2 and `my_led_people()` not started.**

Labels: **Measured** (executed and recorded), **Not tested**, **Pending**.

## 1. What changed

- **Migration:** `supabase/migrations/20270104000001_rls_once_per_statement.sql`
- **Live update:** `supabase/live-updates/update-60.sql` (safe to run again)
- **Rollback:** `supabase/live-updates/undo-60.sql` (safe to run again)
- **Setup SQL:** `supabase/install/fresh-install.sql` (rebuilt to include it)
- **The change:**
  - 94 policies only. Their `USING` and `WITH CHECK` conditions are rewritten so that calls not depending on the row (`auth.uid()`, `is_member()`, `has_role(ARRAY[...])` and others, all `STABLE`, with fixed arguments) are evaluated once per statement as `(select …)`.
  - Row-dependent calls are unchanged.
- **Before-and-after summary of all 94:** [`evidence/stage1/policy-summary-94.md`](evidence/stage1/policy-summary-94.md). Full original and proposed text: [`2026-11-rls-register.md`](2026-11-rls-register.md).

## 2. Where it was tested

- **Local copy only** (Supabase's local stack, the same Postgres and security model):
  - all migrations;
  - synthetic data: 314 people, 10,515 tasks, 3,070 notifications, 908 onboarding records;
  - test accounts for each role.
- **Six identities:**
  - staff (support worker);
  - team leader;
  - manager;
  - staff admin;
  - system admin;
  - signed out (`anon`, no user).
- **Executed against the real policies, not simulated:**
  - **Tests 2–4** ran through Postgres' own row-level security as each identity, with update 60 applied and with it undone.
  - **Test 1** evaluated each policy's exact old and new condition text on every row.
  - **Test 6** built every test database from the migrations, including update 60.
- **Your Supabase was never changed by me.** You ran update 60 on Development yourself.

## 3. Security evidence (all Measured)

| # | Test | What was compared | Result | Evidence file |
|---|---|---|---|---|
| 1 | Condition equivalence | For each of the 94 policies' old and new `USING` / `WITH CHECK` condition: the exact set of rows (row fingerprints) for which it is true, for each of the 6 identities | **714 / 714 identical** (186 with rows allowed; the rest allow none for that identity) | `results/condition-equivalence-714.txt`, SQL `sql/t1.sql` |
| 2 | INSERT | For every table × 6 identities: insert a copy of an existing record (new key), a record linked to that person, and constructed "owned by me" and "owned by someone else" rows; allowed or refused, with the reason; every attempt rolled back | **976 / 976 identical**, all **62** tables covered | `results/insert-original-rules.txt` vs `results/insert-update-60.txt`, SQL `sql/insert.sql`, `sql/build_insert.py` |
| 3 | SELECT, UPDATE, DELETE | For every table × 6 identities: rows visible (fingerprints); rows each could update or delete (by primary key), and refusals; every attempt rolled back | **1,116 / 1,116 identical** | `results/select-update-delete-*.txt`, SQL `sql/t23.sql` |
| 4 | Nothing else changed | A security snapshot with update 60 vs after undo: table grants and RLS on/forced flags (72 tables), every public function's privileges, owner, security mode, `search_path` and code fingerprint (237), triggers (55), every policy's name, operation, roles and type (115), schema privileges | **Only the 94 policy conditions differ.** All grants, function privileges, triggers, policy roles and operations, and RLS flags are identical. RLS is still on for every table | `results/security-snapshot-original.txt` vs `results/security-snapshot-update-60.txt` |
| 5 | Rollback | `undo-60.sql` run twice, then the policy definitions compared with the project's original definitions (a database built from the migrations before update 60); then update 60 re-applied twice | Rollback ran both times without error; **policy definitions identical to the originals**; re-applied snapshot identical to the first | `results/rollback-and-reapply-log.txt`, `results/security-snapshot-project-reference.txt` |
| 6 | Full database test suite | Ownership, team boundaries, role changes, two-factor, sign-out of devices, invites, delegation, onboarding, requests and more | **784 / 784 passed, 0 failures** | `results/database-test-suite-784.txt` |
| 7 | App regression | Main pages as manager and support worker; signed-out pages; dashboard side panel; directory; review queue; new request; staff refused the admin Onboarding page | All passed | Run log in this session |

**Not tested in Stage 1** (and not affected by it):
- expired sessions via Supabase's Auth server itself (covered indirectly: the "signed out" identity, plus the session tests in test 6);
- load and concurrency (Stage 9).

## 4. Performance

### Synthetic database (local copy, realistic volumes): Measured
Time to read a whole table through its policies, per identity:

| Table | Before | After update 60 |
|---|---|---|
| compliance_records | 372–488 ms | 2.8–5.2 ms |
| profiles | 103–141 ms | 2.4–2.7 ms |
| notifications | 3–58 ms | 0.9–1.6 ms |
| app_settings | 17–28 ms | 2.3–2.7 ms |
| tasks | 7.1–10.0 s | 6.0–8.6 s (task policies are Stage 2) |

### Actual application (Development, Sydney, 2 users): Measured with the Speed check panel
- **Before update 60** (your first run): pages 892–1,155 ms.
- **After update 60:**
  - first run: 698–1,020 ms;
  - second run: 691–1,089 ms;
  - database round trip 30–32 ms.
- **Your connection to the app server alone, with no database: 880 ms.**

**Interpretation:**
- With 2 users and very little data, page time is dominated by the trip between your browser and the app server. Update 60's effect is **not measurable** in the real app at this size.
- The small difference between runs is within normal variation. Some of it may be warm-up rather than update 60.
- The synthetic results show what it does as data grows.
- **Pending:** the next Speed check, with the new "plain file" and "handled via" readings, to explain the 880 ms.

## 5. Approval status

| Item | Status |
|---|---|
| Stage 0 (restore point, Speed check panel, baseline) | Completed. Sydney baseline recorded; network diagnosis pending your next measurement |
| Stage 1 (update 60) | **Completed and verified** (tests 1–7 above) |
| Stage 2 (task-family policies, `my_led_people()`) | **On hold.** A separate security proposal comes first, for your review |
| Stages 3–9 | Not started |

## 6. Rollback procedure
- **To undo Stage 1** on any copy: Supabase → **SQL Editor** → run `supabase/live-updates/undo-60.sql`. It restores the 94 policies to their exact original definitions (tested twice; see `evidence/stage1/results/rollback-and-reapply-log.txt`).
- **To return to the approved state:** run `supabase/live-updates/update-60.sql`. The migration is `supabase/migrations/20270104000001_rls_once_per_statement.sql`.
- **New copies:** the setup SQL (`supabase/install/fresh-install.sql`) already includes it.
- **Both files** are safe to run more than once.

## 7. Status: Stage 1 COMPLETE (11 November 2026)
- **Update 60:** committed on `dev` and recorded in the migration history (`20270104000001_rls_once_per_statement.sql`, update 60 / undo 60, and the setup SQL).
- **No production resources exist or were modified.** No Supabase project, policy, function or application resource was changed by this work outside Development. Update 60 was run on Development by the owner.
- **Evidence retained in the project:** `docs/audit/evidence/stage1/` (executed SQL, results, snapshots, logs), `docs/audit/2026-11-rls-register.md`, and this report.
- **Regression:** existing results stand. INSERT, SELECT, UPDATE and DELETE are covered by the 784-check suite and the per-role comparisons above. Not re-run at closing, as instructed.

**Deferred (paused, not started):**
- Stage 2: task-family policies and the `my_led_people()` helper. Needs a separate security proposal and approval.
- Stage 3: onboarding and staff summaries.
- Stage 4: settings read once.
- Stage 5: selective prefetch.
- Stage 6: re-measure.
- Stage 7: SQL aggregation and paging.
- Stage 8: function permissions.
- Stage 9: load test.
- The open question of the 880 ms connection time.

## 8. Closure
Stage 1 was **formally accepted as COMPLETE by the owner on 11 November 2026** and is **CLOSED**. The approved migration (`20270104000001_rls_once_per_statement.sql`), update 60, rollback `undo-60.sql` and all evidence in `docs/audit/evidence/stage1/` are kept unchanged. Stages 2–9 stay deferred.

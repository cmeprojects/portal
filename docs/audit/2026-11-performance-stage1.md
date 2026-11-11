# Performance stages 0 and 1: evidence (cmeprojects)

Staff Portal · © cmeproject · 11 November 2026 · Development (`dev`) · Approved: Stage 0 and Stage 1 only.

Labels: **Measured** (run here); **Pending** (needs the owner's Sydney screenshot).

## Stage 0: restore point and baseline
- **Restore point:** git branch `restore-before-performance`.
  - Supabase Free has no snapshot button. The safety net is the tested undo file (below) and the re-runnable setup SQL.
- **Speed check panel:** System health → Speed check (system admins only, read-only).
  - Times the database round trip, the sign-in service round trip, and each of 10 main pages exactly as a menu click asks for them.
  - Three tries each; the middle one counts.
- **Regions:** the app is in Sydney (`syd1`) and Development has moved to Sydney (owner, 11 November).
  - The panel shows "App runs in" and the database round trip. **Pending:** the owner's screenshot, taken **before** running update 60.
- **Baseline on the local copy** (synthetic volumes: 314 people, 10,515 tasks; development mode; measured with the panel): Dashboard 441 ms, Tasks 6,879 ms, Registers 1,740 ms, Staff 2,680 ms, Onboarding 3,795 ms, Directory 451 ms, My requests 399 ms, Reports 2,441 ms, My account 370 ms, System settings 413 ms.

## Stage 1: RLS pattern A (update 60)
- **What changed:**
  - 94 policies: calls that don't depend on the row are wrapped as `(select …)`, so Postgres evaluates them once per statement.
  - Nothing else: no policy added, removed, renamed or loosened; no function, grant, table or data change.
- **Files:**
  - `supabase/migrations/20270104000001_rls_once_per_statement.sql`
  - `supabase/live-updates/update-60.sql`
  - `supabase/live-updates/undo-60.sql`
  - `supabase/install/fresh-install.sql` (rebuilt)
  - policy-by-policy detail in `docs/audit/2026-11-rls-register.md`
- **Database objects affected:** the 94 policies listed in the register (54 tables).

### Security evidence (all measured, local copy with synthetic data; Supabase untouched)
| # | Test | Scope | Result |
|---|---|---|---|
| 1 | **Condition equivalence:** each policy's old and new USING and WITH CHECK conditions evaluated on **every row**, compared by the exact set of rows (row fingerprints, not counts) | 94 policies × 6 identities (staff, team leader, manager, staff admin, system admin, signed out) | **714 of 714 identical**. 186 involve rows actually allowed; the rest allow none for that identity (often empty tables in the test data) |
| 2 | **Effective read access** through the real policies: which rows each identity sees (fingerprints) | 62 tables × 6 identities | **Identical** |
| 3 | **Effective UPDATE and DELETE**: which rows each identity could change or delete (by primary key), and which attempts are refused; every attempt rolled back | 62 tables × 6 identities × 2 operations | **Identical** (1,116 outcomes in total with test 2) |
| 4 | **Full database test suite** (ownership, team boundaries, role changes, two-factor, sign-out, invite and delegation rules and more) | All test files | **784 of 784 passed** |
| 5 | **Rollback:** `undo-60.sql` run twice, then the policies compared with the original definitions | All policies | **Word-for-word identical**; update 60 then re-applied cleanly, also twice |
| 6 | **Setup SQL** (re-runnable) | Empty project; a copy at update 59 | Both end identical to a full install; running again changes nothing |
| 7 | **App regression:** main pages (manager, support worker), signed-out pages, dashboard side panel, directory, review queue, new request, access refused to admin Onboarding for staff | Local copy with update 60 | **All passed** |

INSERT is covered by test 1 (the exact WITH CHECK conditions) and test 4 (insert permission tests).
Invalid, expired and signed-out sessions are covered by the "signed out" identity and the session tests in test 4.

### Speed (measured, local copy, realistic synthetic data; time to read the table through the policies)
| Table | Before (by role) | After update 60 |
|---|---|---|
| compliance_records | 372–488 ms | 2.8–5.2 ms |
| profiles | 103–141 ms | 2.4–2.7 ms |
| notifications | 3–58 ms | 0.9–1.6 ms |
| app_settings | 17–28 ms | 2.3–2.7 ms |
| tasks | 7.1–10.0 s | 6.0–8.6 s (unchanged rule; Stage 2) |

**Pending:** the real Sydney before-and-after from the Speed check panel.

## Not in these stages (need separate approval)
- Stage 2: task-family policies.
- Stage 3: onboarding and staff summaries.
- Stage 4: settings read once.
- Stage 5: prefetch.
- Stages 6–9.

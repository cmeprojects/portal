# HR Stage A: review against requirements (cmeprojects)

15 Nov 2026, Dev only. Covers every change since the HR Pack plan was
approved (commits 990afb5 to now), checked against the owner's instructions.

## Checks run

| Check | Result |
|---|---|
| Production build (`next build`) | Passes |
| Lint and typecheck | Clean (two old unused-import warnings removed) |
| Unit tests (module catalogue) | Pass |
| Database suite | 1,063 checks pass, 0 fail |
| Undo round trips (updates 83 and 84) | Undo matches original; re-apply matches |
| Browser: pages by role (system admin, manager, staff admin, team leader, support worker) | 14 of 14 load, no errors |
| Browser: HR Pack switches (off, deploy, on, restore) | 11 of 11 |
| Browser: team leader private details | Availability only; emergency contact with switch on; manager unchanged |

## Requirements cross-check

| # | Requirement | Status | Evidence or note |
|---|---|---|---|
| A1 | Steps to run update 81 on Dev and verify | Done | Owner ran 81 and 82. Check-list given. **Owner's Dev check not yet reported.** |
| A2 | Team leaders get availability only | Done | Update 84 run on Dev by owner. 15 tests. |
| A2 | Emergency contact separately controlled | Done | System admin switch, off by default (option (a), chosen by owner). Org-wide, not per person. |
| A2 | Full SQL, effect on permissions, Stage 1 comparison, rollback before running | Done | docs/review/2026-11-15-leader-private-details.md; undo-84.sql |
| A2 | Manager, staff admin, system admin and staff unchanged | Done | Tests for each. |
| A2 | Record results and differences | Done | None found. Dev itself not signed into by me; owner's 2-minute check listed. |
| A2 | Work anniversaries kept for team leaders | Done | Start date returned by `team_private()`. |
| A2 | No new SECURITY DEFINER without approval | Done | `team_private()` approved; fixed columns, own team only. |
| A3 | Timer instructions for review before set-up | Done | docs/setup/dev-hourly-timer.md, supabase/setup/timer-checks.sql. **Awaiting authorisation.** |
| A3 | Both reminder types: trigger, verify, clean-up | Done | Expiry (60/30/7/today/expired, once each) and 7-day onboarding (once). |
| 5 | Managers act on General tasks escalations | Ready | Update 83, one function, within existing permissions. **Owner to run.** |
| 6 | "Escalation dealt with": check 82 first | Done | 82 fixes the bounce-back; 83 fixes managers blocked on General tasks. Info needed if it still fails is listed. |
| C | Client decisions (references, DOB, programs, support workers, existing clients) | Recorded | docs/roadmap/client-foundation-plan.md, "Owner decisions". Design starts after A1 to A3. |
| C | All six optional sections stay in scope | Recorded | Plan says optional means "organisation chooses", not excluded. |
| B4, B5 | Termination record; bank and super history | Not started | Correct: after Client Management is under way, each for separate approval. |
| — | User-reported: parts stay On when pack off | Fixed | Parts show Off (greyed) while the pack is off; own setting kept. |
| — | User-reported: premium Compliance turning on with HR | Fixed | Turning HR off also turns Compliance off; it needs its own switch on. |
| — | User-reported: notes not clearing | Fixed | "Saved, not live" goes after deploy; "Deployed" goes after 5 seconds. |

## Boundaries

Dev only (no production changes). Stage 1 kept: only row 85 changed, as
approved, register noted. Stages 2 to 9 deferred. Email and MFA untouched.
No unrelated redesign. Every database change had SQL, effects, rollback and
tests before running.

## Gaps found in this review (and what was done)

1. **Client decisions weren't written into the plan.** Added.
2. **Existing clients' `active` flag is shown/hidden, not a care status.**
   Plan corrected: existing clients start as *pending* with a "to check"
   list, rather than active or discharged (matches "verify before activation").
3. **Two unused imports** (lint warnings). Removed.
4. **Dev confirmation of 81 and 84** relies on the owner's quick checks (I
   can't sign in to Dev). Listed as outstanding.

Noted, not changed:
- Turning HR off and back on **before** deploying leaves Compliance off in
  the draft. Intended: premium packs need their own switch on.
- Once the timer runs, emails are queued but fail (email isn't set up). They
  show as failed on System health. Deferred with email; not a defect.
- The emergency contact switch is all-or-nothing for team leaders. Per-person
  control would need the Access page to take team leaders (option (b), not
  chosen).

## Outstanding (in order)

1. Owner: quick Dev checks for 81 and 84 (lists in the two review docs).
2. Owner: run update 83.
3. Owner: review and authorise the timer instructions; set-up and reminder test.
4. Client design step 1 (client record, reference, programs) for approval.
5. Later, separately: B4 termination record, then B5 bank and super history.

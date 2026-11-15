# Team leaders and private details: change for approval (cmeprojects)

HR Pack Stage A, item 2. Dev only. Written and tested locally; **not run on Dev**.

- Update: `supabase/live-updates/update-84.sql` (safe to run again)
- Undo: `supabase/live-updates/undo-84.sql`
- Same change as a migration: `supabase/migrations/20270127000001_leader_private_view.sql`
- Number 83 stays reserved for the register proposal in `supabase/proposals/`.

## What it changes

1. **The read rule on `staff_private`** ("the person and people managers see
   private details"): the team leader part is removed. The rest is the same,
   word for word, in the Stage 1 form.
2. **New function `team_private()`** (SECURITY DEFINER, approved 15 Nov 2026).
   It returns, for the caller's **own teams only**: the person, availability,
   start date, and the emergency contact **only** when the new switch is on.
   It never returns the caller's own row, nothing while Staff profiles is
   off, and nothing to signed-out users (refused).
3. **New switch** "Team leaders see emergency contacts", under HR Pack →
   Staff profiles. **Off** by default. The system admin turns it on and
   deploys, as with any switch.

Nothing else changes: no writes, no other tables, no other policies, no data.

## Who sees what

| Who | Before | After |
|---|---|---|
| The person | Their whole row | Same |
| People managers (managers, staff admins with people access) | Whole row | Same |
| System admin | Whole row | Same |
| **Team leader, own team** | **Whole row** (address, emergency contact, employee ID, employment type, start date, availability) | Availability and start date; emergency contact only with the switch on |
| Team leader, other teams | Nothing | Nothing |
| Support workers and others | Nothing | Nothing |

On screen: a team leader opening a team member in the Directory sees "Only
the person and people managers see private details" and the availability
grid. Work anniversaries on the home page keep working for team leaders.

## Compared with the Stage 1 speed register

Row 85 keeps the same form and the same once-per-statement calls
(`auth.uid()`, `can_manage_people()`, `feature_enabled('hr_profiles')`,
`is_system_admin()`). Only the row-dependent team leader check goes, so the
rule does slightly less work. No other Stage 1 policy is touched. The
register has a note added (docs/audit/evidence/stage1/policy-summary-94.md).

## Tests (local)

- New `supabase/tests/leader_private.test.sql`, 14 checks: a team leader
  can't select the private row; gets availability and start date for their
  own team; no emergency contact while the switch is off and it shows when on;
  nothing while Staff profiles is off; another team's leader, a support worker
  and signed-out users get nothing; the person, a manager and the system admin
  still read the whole row.
- `hr_profiles.test.sql` updated for the new rule.
- Full database suite: 1,061 checks pass, 0 fail.
- Undo round trip: undo matches the original; re-applying matches.
- Browser: team leader sees availability only (no address, ID or emergency
  contact); emergency contact appears with the switch on; the manager's view
  is unchanged; the switch shows in System settings → HR Pack.

## Rollback

Run `undo-84.sql`. It puts the read rule back exactly as before, removes
`team_private()` and removes the switch. The app copes either way: before
the update, or after an undo, team leaders simply see what the old rule gives.

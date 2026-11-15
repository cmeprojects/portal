# Update 86: staff see only the basic client record (cmeprojects)

For approval. Dev only. Written and tested locally; **not run on Dev**.

- Update: `supabase/live-updates/update-86.sql` (safe to run again)
- Undo: `supabase/live-updates/undo-86.sql`
- Migration: `supabase/migrations/20270130000001_team_clients.sql`

## Why

Found while building the step 1 screens. Update 85's read rule let support
workers and team leaders read the **whole** client row for their teams,
including the free-text reference (the form suggests an NDIS number there).
No screen showed it, but it could be read from the database. Dev has test
data only.

## What it changes

1. Removes update 85's staff read rule on `car_clients`.
2. New function `team_clients()` (**SECURITY DEFINER, needs your
   approval**), like `team_private()` in update 84: for clients linked to the
   caller's own teams only, it returns id, CL- reference, name, preferred
   name and status. Never the free-text reference, the shown/hidden flag or
   who added the client. Signed-out users can't run it.

People managers, car managers and the system admin are unchanged. No other
policy, table or data changes.

## Tests

- `client_record.test.sql` now 24 checks: a support worker can't read client
  rows directly; `team_clients()` gives only their team's clients, with the
  CL- reference and status; another team's staff get only theirs; team
  leaders get their team's; signed-out users are refused; people managers
  still see every client and its reference.
- Full database suite: 1,087 checks pass, 0 fail. Undo round trip matches.

## Rollback

`undo-86.sql` removes `team_clients()` and puts update 85's rule back.

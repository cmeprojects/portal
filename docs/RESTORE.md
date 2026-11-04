# Restore points

If something goes wrong, you can go back to how the portal was before a big
change. Nothing here deletes your people, tasks, forms or cars.

## Before the Website and Assistant (live update 35)

- **Code:** the branch `restore-update-35` on GitHub is the portal exactly as
  it was at update 35 (commit `b62d035`). The branch is never changed.
  - Go back on GitHub: set the Vercel production branch to `restore-update-35`
    and redeploy. Switch it back to `main` when fixed.
  - Or in a copy of the code: `git checkout restore-update-35`.
- **Database:** update 36 only adds new tables (documents, questions,
  enquiries, settings) and one feature switch. To remove them again, run
  `supabase/live-updates/undo-36.sql` (safe to run twice). This deletes the
  uploaded documents, question log and enquiries, and nothing else.
- **Quick off switch:** System settings → Features → "Website and Assistant"
  → Off. The public website then shows "coming soon" and the menu items
  disappear. Nothing is deleted.

## Before the quick fixes (live update 36)

- **Code:** branch `restore-update-36` (commit `e7dc8ac`).
- **Database:** run `supabase/live-updates/undo-37.sql`.

## Before the website redesign (live update 37)

- **Code:** branch `restore-update-37` (commit `5044dbc`).
- **Database:** run `supabase/live-updates/undo-38.sql`.

## Before reports, tasks and clients changes (live update 38)

- **Code:** branch `restore-update-38` (commit `5430a4d`).
- **Database:** run `supabase/live-updates/undo-39.sql`.

## Before round 2 (live update 39)

- **Code:** branch `restore-update-39` (commit `2b54d01`).
- **Database:** run `supabase/live-updates/undo-40.sql`.

## Before enquiry intake (live update 40)

- **Code:** branch `restore-update-40` (commit `bb7059f`).
- **Database:** run `supabase/live-updates/undo-41.sql`.

## Before the website About/SEO round and audit (live update 41)

- **Code:** branch `restore-update-41` (commit `f83556e`).
- **Database:** run `supabase/live-updates/undo-42.sql`.

## Before the settings and features revamp (after live update 45)

The whole system as it is now: every module, updates 1 to 45 applied.

- **Code:** branch `restore-update-45` (commit `8b8fad4`).
- **Database:** run `supabase/live-updates/undo-46.sql` (safe to run again).

## Habit for every big change

1. Make a branch from `main` named `restore-update-NN` before starting.
2. Give every database change an `undo-NN.sql` next to its `update-NN.sql`.
3. Ship it switched off, then switch it on.

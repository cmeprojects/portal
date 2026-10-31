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

## Habit for every big change

1. Make a branch from `main` named `restore-update-NN` before starting.
2. Give every database change an `undo-NN.sql` next to its `update-NN.sql`.
3. Ship it switched off, then switch it on.

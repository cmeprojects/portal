# Live database updates

Staff Portal · © cmeproject

Each file here is one update to run **once** on a copy that's already in use
(SQL Editor → New query → paste → Run), in number order. They're the same
changes as `supabase/migrations/`, bundled so they're easy to copy.
A **brand-new** copy doesn't need these: use `supabase/install/fresh-install.sql`.

## Which copy has which updates

| Copy | Supabase project | Updates applied |
|---|---|---|
| Development (the original copy, still with the Engaged Care look) | cme-dev (was engagedcare-portal) | 1 to 57 (58 to run) |
| Demo | the copy made from the fresh install | all (fresh install) |

Add a row for each new client copy. Run newer files in order on each.

On GitHub, open a file and use the **Copy raw file** button (two squares,
top right of the file) to copy all of it at once.

## One-off scripts

- `clear-onboarding-items.sql` (Development only): removes every current
  read, training and upload onboarding item and what people did for them.
  Keeps the Profile photo item, forms and update 58's defaults. Can't be undone.

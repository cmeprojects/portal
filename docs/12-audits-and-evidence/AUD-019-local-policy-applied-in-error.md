# AUD-019: Incident: proposal SQL applied to the local test database in error

| Field | Value |
|---|---|
| Document ID | AUD-019 |
| Title | Incident: odometer proposal applied to the local test database during a syntax check |
| Category | 12 Audits and evidence |
| Status | Evidence (closed) |
| Prepared by | Technical Lead (prepared by Claude), 16 Nov 2026 |
| Related | QA-008, AUD-018, DEC-001 D-042 |

## What happened

While preparing QA-008 (16 Nov 2026), the developer ran
`supabase/proposals/odometer-uploads-follow-setting.sql` against the **local
development database inside the developer's session** (the Supabase copy
running on `127.0.0.1`, built from the migrations, test data only), intending
a syntax check inside a transaction that would be rolled back. The file has
its own `begin; ... commit;`, so its `commit` ended the outer transaction and
the policy change **was committed** to that local database. The later
`rollback` had nothing to roll back ("there is no transaction in progress").

## Scope

- Changed: one storage policy, "drivers upload odometer photos", on the
  local database only (an extra condition on the setting).
- **Not affected:** the Development copy (`cme-dev`), Demo, any customer copy,
  any data or files. No other object changed.

## Detection and restoration

- Detected immediately from the output, and reported to the owner the same day.
- Restored by running `supabase/proposals/odometer-uploads-follow-setting-undo.sql`.
- **Verified:** the policy's WITH CHECK read back from the catalogue matches the
  original exactly: `((bucket_id = 'car-files'::text) AND cars_on() AND ((storage.foldername(name))[1] = (auth.uid())::text))`.
- The full database suite later ran on a fresh database built from the
  migrations (1,132 checks passed), unaffected.

## Cause and prevention

- Cause: wrapping a file that manages its own transaction.
- Prevention: check proposal SQL only on a throwaway database (the test
  database built per run), never by wrapping a file in `begin ... rollback`;
  round trips use `scratchpad/rt.sh` as before.

## Owner response

Owner acknowledged; no further action needed as the original policy was
verified restored (16 Nov 2026).

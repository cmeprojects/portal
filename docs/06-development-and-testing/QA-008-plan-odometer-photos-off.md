# QA-008: Change plan: odometer photos off (D-009)

| Field | Value |
|---|---|
| Document ID | QA-008 |
| Title | Change plan: odometer photo setting and storage policy |
| Category | 06 Development and testing |
| Version | 0.1 |
| Status | **Approved by the Product Owner (D-042)**: storage policy follows the setting. Nothing implemented on any copy yet |
| Owner / Reviewer / Approver | Technical Lead (the owner) / Technical Lead / Product Owner (the owner) |
| Created | 16 Nov 2026 |
| Related | DEC-001 D-009 and D-037, AUD-018, SEC-002 C7, RSK-15 |

Two separate actions, each reviewable and reversible on its own. Existing
files and customer data are never deleted or changed.

## 1. Affected copies (from docs/ENVIRONMENTS.md, 16 Nov 2026)

| Copy | Project | Data | Affected |
|---|---|---|---|
| Development | `cme-dev` | test data | Yes |
| Demo | `cme-demo` | sample data | Yes |
| Engaged Care | `client-engagedcare` | real | **Not created yet** ("when ready"): would start from the fresh install, so action A2 covers it |
| Other customers | `client-<name>` | real | None exist |

Each copy's current value of the setting **isn't visible from here**: the
owner checks System settings on each (default from the install: Optional).

## 2. Exact setting and policy (verified)

- Setting: `app_settings` key **`vehicles.odo_photo`**, label "Odometer photo
  when returning", values `"off"`, `"optional"` (install default),
  `"required"`. Read by the return screen (`src/components/cars-desk.tsx`)
  and the database function `return_car_trip` (stores no photo path when
  Off).
- Storage policy on `storage.objects`: **"drivers upload odometer photos"**,
  INSERT, role `authenticated`, WITH CHECK `bucket_id = 'car-files' and
  public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text`
  (migration `20261121000001_cars.sql`, live update 18). It doesn't look at
  the setting.
- Not changed by this plan: "car managers upload car photos" (folder
  `cars/`) and "car files are seen by the driver and car reports" (reading;
  existing photos stay viewable to the driver and car report holders).

## 3. Action A: setting Off

**A1 (existing copies: Dev, then Demo), no SQL:** System settings →
Features → open "Cars and Cars app" → Cars section → "Odometer photo when
returning" → **Off** → Save → Deploy. Recorded in the
change log (setting change). The photo field disappears from returning a
car; no new photo paths are saved.
Undo: set it back to Optional and Deploy.

**A2 (new copies only):** `supabase/proposals/odometer-default-off.sql`, a
migration so fresh installs start Off (changes the value only where it's
still the install default). Not run on existing copies. Undo: a migration
setting it back (or change it in System settings on that copy).
Tests: the database suite passes; a fresh-install check shows Off.

## 4. Action B: storage policy follows the setting (next live update number when approved)

`supabase/proposals/odometer-uploads-follow-setting.sql`: same policy plus
`and public.car_setting('vehicles.odo_photo', 'optional') <> 'off'`. With the
setting Off, the database refuses odometer uploads even if someone bypasses
the screen. Undo: `odometer-uploads-follow-setting-undo.sql` restores the
original policy exactly.

Why "follow the setting" rather than removing the policy: one source of
truth (the setting), reversible by a setting if a future decision approves
photos, smallest change. Removing the policy outright is the stricter
alternative (owner's choice).

Notes: `car_setting()` is an existing SECURITY DEFINER function already used
by the Cars functions (no new definer). The original policy's unwrapped
`auth.uid()` (Stage 1 form, SEC-002 C6) is left as it is to keep the change
minimal.

Tests (on implementation): a new database test: with the setting Optional a
driver can upload to their own folder; with Off the upload is refused; car
managers can still upload to `cars/`; reading is unchanged. Round trip
(apply twice, undo twice, compare, re-apply) and the full suite.
Checked so far (16 Nov 2026, local copy only): the proposal and its undo
both run and the undo restores the original policy text exactly. (The
proposal was applied to the local test database by mistake during a syntax
check and immediately restored with the undo; no other copy affected.)

## 5. Order and release

1. A1 on Dev (owner, via System settings), confirm the field is gone.
2. B as its own live update on Dev after approval (separate commit and
   release), then the owner checks an upload attempt is refused.
3. Demo: A1, then B.
4. A2 merged as its own migration (separate commit).
Never combined with QA-007.

## 6. Approved behaviour and exact files (16 Nov 2026, before implementation)

| Setting | Driver upload (database) | Screen |
|---|---|---|
| Off | **Refused** | No photo field |
| Optional | Allowed | Photo field, optional |
| Required | Allowed | Photo field, needed to return the car |

Unchanged: reading existing photos (driver and car report holders), car
managers' uploads to `cars/`. No file is deleted.

Files (to be created only when each step is reached, in this order):

| Step | Files | Runs where |
|---|---|---|
| A1 | none (System settings, owner) | Dev, Demo |
| A2 | `supabase/migrations/20270204000001_odometer_default_off.sql` (from `supabase/proposals/odometer-default-off.sql`); `supabase/install/fresh-install.sql` rebuilt | Fresh installs only (not a live update) |
| B | `supabase/migrations/20270205000001_odometer_uploads_follow_setting.sql`; **`supabase/live-updates/update-91.sql`** and **`undo-91.sql`** (from the two proposal files); `supabase/tests/odometer_uploads.test.sql` | Owner runs update 91 on Dev, tests, then Demo |

Rollback: A1 set back to Optional; A2 a follow-up migration (or the setting
on that copy); B `undo-91.sql`, which restores the original policy exactly.

## 7. Implementation record

- **A1 (16 Nov 2026):** Dev set to Off, saved and deployed by the owner.
  **Demo: not applicable** (no Demo copy exists at present; owner, 16 Nov 2026).
- **A2 (16 Nov 2026):** migration `supabase/migrations/20270204000001_odometer_default_off.sql`;
  fresh install rebuilt; new test `supabase/tests/odometer_default.test.sql`
  (2 checks); full database suite 1,134 checks pass. Not a live update:
  nothing to run on Dev. Rollback: revert the commit (fresh installs then
  start Optional again) or change the setting on a copy.
- **B prepared for review (16 Nov 2026), not applied:** `supabase/proposals/update-91/`
  (migration, `update-91.sql`, `undo-91.sql`, `check-update-91.sql`, README).
  Local check 9 of 9 inside a rolled-back transaction; local state confirmed
  unchanged. Awaiting the owner's approval of the migration and undo files.
- **B approved and moved into place (16 Nov 2026):** `supabase/live-updates/update-91.sql`
  (sha256 7919674b…), `undo-91.sql` (b3ac1be3…), `supabase/migrations/20270205000001_odometer_uploads_follow_setting.sql`
  (e64aa5e0…), identical to the reviewed files. Fresh install rebuilt. Full
  database suite 1,134 checks pass; round trip on the local copy: undo
  matches the original, re-apply matches. Dev verification script:
  `supabase/setup/verify-update-91.sql` (dry-run locally: 3 of 3, rolled
  back, local state unchanged). **Waiting for the owner to run update 91 on
  Dev.**
- **Simpler Dev checks (16 Nov 2026):** the owner found `verify-update-91.sql`
  confusing (step 4 stopped with "Change the test emails in step 4 first";
  nothing changed). Replaced by `supabase/setup/verify-91-before.sql`
  (read only) and `supabase/setup/verify-91-after.sql` (picks test accounts
  itself; each test upload undone inside the check; 7 results). Dry-run on
  the local copy: all as expected, local state unchanged.

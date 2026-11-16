# Update 91 (proposal for review): odometer uploads follow the setting

QA-008 action B. **Approved by the owner (16 Nov 2026) and moved into place unchanged**
(SHA-256 identical before and after the move):

| File here | Goes to |
|---|---|
| `20270205000001_odometer_uploads_follow_setting.sql` | `supabase/migrations/` (fresh installs) |
| `update-91.sql` | `supabase/live-updates/` (owner runs on Dev) |
| `undo-91.sql` | `supabase/live-updates/` |
| `check-update-91.sql` | stays here: local check (one transaction, always rolled back) |

Checked 16 Nov 2026 on the local copy (all inside a rolled-back transaction;
local state confirmed unchanged afterwards): Optional and Required allow a
driver's upload to their own folder; Off refuses it; Off also refuses
another person's folder; car managers still upload to `cars/`; the reading
and car-manager policies are unchanged; the undo restores the original policy
exactly; after the undo, Off no longer blocks (original behaviour). All 9
passed. `update-91.sql` and `undo-91.sql` also run without errors on a
database without file storage (they skip).

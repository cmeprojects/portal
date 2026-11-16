-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (QA-008 A2, decision D-009 / D-042): fresh installs start with
-- "Odometer photo when returning" Off. Fresh installs only: existing copies
-- are set in System settings (Dev done by the owner, 16 Nov 2026). Changes the
-- value only where it's still the install default (Optional).
update public.app_settings set value = '"off"'::jsonb
 where key = 'vehicles.odo_photo' and value = '"optional"'::jsonb;

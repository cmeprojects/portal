-- Staff Portal · © cmeproject. All rights reserved.
-- PROPOSAL (not applied; awaiting the owner, plan QA-008 action A2).
-- For NEW copies only (a migration, so fresh installs start with the setting
-- Off, matching decision D-009). It is NOT run as a live update: existing
-- copies are set in System settings instead (action A1), which is logged.
update public.app_settings set value = '"off"'::jsonb
 where key = 'vehicles.odo_photo' and value = '"optional"'::jsonb;

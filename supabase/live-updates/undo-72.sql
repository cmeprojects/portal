-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 72. Safe to run again.
begin;
update public.app_modules set parent_id = null where id in ('system.audit', 'system.builder', 'system.health');
update public.app_modules set label = 'Access & delegation' where id = 'system.access';
commit;

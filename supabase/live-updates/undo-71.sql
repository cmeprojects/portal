-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 71. Safe to run again.
begin;
update public.app_modules set parent_id = null where id in ('workflows.sla', 'workflows.request_rules');
delete from public.access_grants where module_id = 'system.settings.general';
delete from public.app_modules where id = 'system.settings.general';
update public.app_modules set label = 'System settings' where id = 'system.settings';
commit;

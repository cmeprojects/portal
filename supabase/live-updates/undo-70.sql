-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 70: the catalogue groups as before. Safe to run again.
begin;
update public.app_modules set category = 'operations' where id in ('ops.cars', 'ops.cars.use', 'ops.cars.manage', 'ops.cars.app', 'ops.apps');
update public.app_modules set label = 'Apps' where id = 'ops.apps';
update public.app_modules set category = 'workflows' where id in ('workflows.forms', 'workflows.request_rules', 'workflows.sla');
update public.app_modules set label = 'Staff access' where id = 'system.access';
delete from public.access_grants where module_id = 'cat_apps';
delete from public.app_modules where id = 'cat_apps';
alter table public.app_modules drop constraint if exists app_modules_category_check;
alter table public.app_modules add constraint app_modules_category_check
  check (category in ('workspace', 'operations', 'people', 'hr', 'clients', 'workflows', 'insights', 'engagement', 'system'));
commit;

-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: menu tidy-up (owner's choices). Catalogue groups only; nobody's
-- access changes.
--   * New "Apps" group: Cars (one item; Use / Manage / Get the app are tabs on
--     its page) and Phone apps.
--   * Forms moves to Operations; SLA settings and Request approvals to
--     Administration; Staff access is now "Access & delegation".
alter table public.app_modules drop constraint if exists app_modules_category_check;
alter table public.app_modules add constraint app_modules_category_check
  check (category in ('workspace', 'operations', 'apps', 'people', 'hr', 'clients', 'workflows', 'insights', 'engagement', 'system'));

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order)
values ('cat_apps', null, 'apps', 'Apps', 'normal', true, 2)
on conflict (id) do update set label = excluded.label;

update public.app_modules set category = 'apps' where id in ('ops.cars', 'ops.cars.use', 'ops.cars.manage', 'ops.cars.app', 'ops.apps');
update public.app_modules set label = 'Phone apps' where id = 'ops.apps';
update public.app_modules set category = 'operations' where id = 'workflows.forms';
update public.app_modules set category = 'system' where id in ('workflows.request_rules', 'workflows.sla');
update public.app_modules set label = 'Access & delegation' where id = 'system.access';

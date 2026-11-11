-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 69. WARNING: removes module grants given after update 69
-- (Staff details, Payroll and tax, and Identity and work rights access stay).
-- Safe to run again.
begin;
drop function if exists public.my_modules();
drop function if exists public.can(text, text, uuid);
drop trigger if exists check_module_grant on public.access_grants;
drop function if exists public.check_module_grant();
delete from public.access_grants where area is null;
drop index if exists public.access_grants_one_live_module;
drop index if exists public.access_grants_user_module;
alter table public.access_grants drop constraint if exists access_grants_area_or_module;
alter table public.access_grants alter column area set not null;
alter table public.access_grants drop column if exists module_id;
alter table public.access_grants drop column if exists actions;
alter table public.access_grants drop column if exists effect;
alter table public.access_grants drop column if exists include_children;
alter table public.access_grants drop column if exists starts_at;
delete from public.app_modules where id like 'cat\_%' or id in ('hr.records.details', 'hr.records.payroll', 'hr.records.identity', 'system.settings.branding',
  'system.settings.messages', 'system.settings.people', 'system.settings.compliance', 'system.settings.tasks', 'system.settings.reports',
  'system.settings.vehicles', 'system.settings.hr', 'ops.registers.setup');
delete from public.app_modules where id = 'hr.records';
alter table public.app_modules drop column if exists legacy_kind;
alter table public.app_modules drop column if exists legacy_area;
alter table public.app_modules drop column if exists actions;
alter table public.app_modules drop column if exists added_at;
-- The catalogue as update 68 left it.
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('workspace.dashboard', null, 'workspace', 'Dashboard', 'normal', false, 10),
  ('workspace.onboarding', null, 'workspace', 'My onboarding', 'normal', false, 20),
  ('workspace.requests', null, 'workspace', 'My requests', 'normal', false, 30),
  ('workspace.forms', null, 'workspace', 'My forms', 'normal', false, 40),
  ('workspace.contracts', null, 'workspace', 'My contracts', 'normal', false, 50),
  ('workspace.directory', null, 'workspace', 'Directory', 'normal', false, 60),
  ('ops.tasks', null, 'operations', 'Tasks', 'normal', true, 70),
  ('ops.registers', null, 'operations', 'Registers', 'normal', true, 80),
  ('ops.cars', null, 'operations', 'Cars', 'normal', true, 90),
  ('ops.cars.use', 'ops.cars', 'operations', 'Use a car', 'normal', false, 100),
  ('ops.cars.manage', 'ops.cars', 'operations', 'Manage cars', 'normal', false, 110),
  ('ops.cars.app', 'ops.cars', 'operations', 'Get the app', 'normal', false, 120),
  ('ops.features', null, 'operations', 'Built features', 'normal', true, 130),
  ('ops.scoreboard', null, 'operations', 'Scoreboard', 'normal', false, 140),
  ('ops.apps', null, 'operations', 'Apps', 'normal', false, 150),
  ('people.staff', null, 'people', 'Staff', 'normal', true, 160),
  ('people.invite', null, 'people', 'Invite staff', 'normal', false, 170),
  ('people.teams', null, 'people', 'Teams', 'normal', true, 180),
  ('people.roles', null, 'people', 'Roles', 'normal', true, 190),
  ('hr.onboarding', null, 'hr', 'Onboarding', 'normal', true, 200),
  ('hr.onboarding.overview', 'hr.onboarding', 'hr', 'Overview and checks', 'normal', false, 210),
  ('hr.onboarding.expiry', 'hr.onboarding', 'hr', 'Expiry list', 'normal', false, 220),
  ('hr.contracts', null, 'hr', 'Contracts', 'sensitive', true, 230),
  ('hr.requests', null, 'hr', 'Staff requests', 'normal', true, 240),
  ('clients.list', null, 'clients', 'Clients', 'normal', true, 250),
  ('workflows.forms', null, 'workflows', 'Forms', 'normal', true, 260),
  ('workflows.request_rules', null, 'workflows', 'Request approvals', 'normal', true, 270),
  ('workflows.sla', null, 'workflows', 'SLA settings', 'normal', true, 280),
  ('insights.reports', null, 'insights', 'Reports', 'normal', true, 290),
  ('insights.reports.tasks', 'insights.reports', 'insights', 'Tasks', 'normal', false, 300),
  ('insights.reports.cars', 'insights.reports', 'insights', 'Cars', 'normal', false, 310),
  ('insights.reports.compliance', 'insights.reports', 'insights', 'Compliance', 'normal', false, 320),
  ('engagement.assistant', null, 'engagement', 'Assistant', 'normal', false, 330),
  ('engagement.enquiries', null, 'engagement', 'Enquiries', 'normal', true, 340),
  ('engagement.website', null, 'engagement', 'Website settings', 'normal', true, 350),
  ('system.settings', null, 'system', 'System settings', 'protected', false, 360),
  ('system.access', null, 'system', 'Staff access', 'protected', false, 370),
  ('system.audit', null, 'system', 'Change log', 'normal', true, 380),
  ('system.builder', null, 'system', 'Feature builder', 'protected', false, 390),
  ('system.health', null, 'system', 'System health', 'protected', false, 400)
on conflict (id) do update set parent_id = excluded.parent_id, category = excluded.category, label = excluded.label,
  sensitivity = excluded.sensitivity, delegable = excluded.delegable, sort_order = excluded.sort_order;
commit;

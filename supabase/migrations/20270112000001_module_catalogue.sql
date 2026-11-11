-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects step 1 (module framework): the module catalogue, and pinned
-- shortcuts that follow each person across devices.
--   * app_modules: every module and submodule (id, parent, category, label,
--     sensitivity, delegable, status). The same ids are in src/lib/modules.ts
--     (scripts/check-modules.mjs checks they match). It grants nothing: menus
--     still follow today's permissions; delegation builds on it later.
--   * pinned_items: each person's own shortcuts (only they see and change them).
-- No new SECURITY DEFINER function.

create table if not exists public.app_modules (
  id          text primary key check (id ~ '^[a-z_]+(\.[a-z_]+)*$'),
  parent_id   text references public.app_modules (id),
  category    text not null check (category in ('workspace', 'operations', 'people', 'hr', 'clients', 'workflows', 'insights', 'engagement', 'system')),
  label       text not null,
  sensitivity text not null default 'normal' check (sensitivity in ('normal', 'sensitive', 'protected')),
  delegable   boolean not null default false,
  status      text not null default 'active' check (status in ('active', 'planned', 'retired')),
  sort_order  int not null default 0
);
alter table public.app_modules enable row level security;
revoke all on public.app_modules from anon;
revoke insert, update, delete, truncate on public.app_modules from authenticated;
grant select on public.app_modules to authenticated;
drop policy if exists "members read the module catalogue" on public.app_modules;
create policy "members read the module catalogue" on public.app_modules for select to authenticated using ((select public.is_member()));

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

create table if not exists public.pinned_items (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  href       text not null check (href ~ '^/[A-Za-z0-9/_?=&.-]*$' and length(href) <= 200),
  label      text not null check (length(label) between 1 and 60),
  position   int not null default 0,
  created_at timestamptz not null default now(),
  primary key (user_id, href)
);
alter table public.pinned_items enable row level security;
revoke all on public.pinned_items from anon;
revoke truncate on public.pinned_items from authenticated;
grant select, insert, update, delete on public.pinned_items to authenticated;
drop policy if exists "your own pinned shortcuts" on public.pinned_items;
create policy "your own pinned shortcuts" on public.pinned_items for all to authenticated
  using (user_id = (select auth.uid()) and (select public.is_member()))
  with check (user_id = (select auth.uid()) and (select public.is_member()));

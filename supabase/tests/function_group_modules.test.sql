-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 104): which parts belong to each function group, and
-- the future-module rule (Stage 4). A mapping gives nobody access.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.fg(p_key text) returns uuid language sql security definer as $$ select id from public.function_groups where key = p_key $$;
grant execute on all functions in schema test to authenticated;

-- The catalogue rule: every part is registered properly.
select test.ok(not exists (
  select 1 from public.app_modules m
   where m.status = 'active' and m.parent_id is null and m.id not like 'cat\_%' and m.category <> 'workspace' and m.sensitivity <> 'protected'
     and not exists (select 1 from public.function_group_modules f where f.module_id = m.id)),
  'every active part (except My workspace and protected parts) belongs to at least one function group');
select test.ok(not exists (select 1 from public.app_modules where status = 'active' and (sensitivity is null or cardinality(actions) = 0)), 'every active part has a sensitivity and actions');
select test.ok((select count(distinct function_group_id) from public.function_group_modules where module_id = 'ops.tasks') = 3, 'a part can belong to more than one group (Tasks: three)');

-- A mapping gives nobody access.
insert into public.job_titles (name, access_level) values ('Clinician', 'support_worker');
insert into public.job_title_functions (job_title_id, function_group_id) values ((select id from public.job_titles where name = 'Clinician'), test.fg('allied_health'));
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Clinician') where email = 'sam@example.com';
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(not public.can('workflows.forms', 'create') and not public.can_make_forms(), 'Allied Health is mapped to Forms, but its people get no access from that');
reset role;

-- A new part starts with no access.
insert into public.app_modules (id, category, label, actions, sensitivity, sort_order) values ('ops.newpart', 'operations', 'New part', '{view}', 'normal', 999);
select test.ok((select not grant_ready from public.app_modules where id = 'ops.newpart'), 'a new part isn''t switched over until approved');
select test.ok(not exists (select 1 from public.access_baselines where module_id = 'ops.newpart') and not exists (select 1 from public.access_grants where module_id = 'ops.newpart'), 'and has no grants');
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can('ops.newpart', 'view'), 'so nobody but the system admin has it');
reset role;

-- Who changes the mapping.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.function_group_modules (function_group_id, module_id) values (test.fg('finance_accounts'), 'ops.cars')$$, 'only whoever looks after Roles changes the mapping');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.function_group_modules (function_group_id, module_id) values (test.fg('finance_accounts'), 'ops.cars');
select test.refused($$insert into public.function_group_modules (function_group_id, module_id) values (test.fg('finance_accounts'), 'system.access')$$, 'protected parts belong to no group');
select test.refused($$insert into public.function_group_modules (function_group_id, module_id) values (test.fg('finance_accounts'), 'workspace.dashboard')$$, 'nor do everyone''s own pages');
select test.refused($$insert into public.function_group_modules (function_group_id, module_id) values (test.fg('finance_accounts'), 'hr.onboarding.expiry')$$, 'sub-parts follow their part');
delete from public.function_group_modules where function_group_id = test.fg('finance_accounts') and module_id = 'ops.cars';
reset role;
select test.ok(not exists (select 1 from public.function_group_modules where function_group_id = test.fg('finance_accounts') and module_id = 'ops.cars'), 'the system admin maps and unmaps parts');
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.function_group_modules) > 0, 'everyone can read the mapping');
reset role;

\o

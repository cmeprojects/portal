-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 94): grants for job titles, function groups and access
-- levels in can() (Stage 3, D-047).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('newbie@example.com', 'Nina', 'new_starter');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('newbie@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.fg(p_key text) returns uuid language sql security definer as $$ select id from public.function_groups where key = p_key $$;
create function test.jt(p_name text) returns uuid language sql security definer as $$ select id from public.job_titles where name = p_name $$;
create function test.can_as(p_email text, p_module text, p_action text, p_person uuid default null) returns boolean language plpgsql as $$
declare v boolean;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  v := public.can(p_module, p_action, p_person);
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;

update public.features set enabled = true where key = 'vehicles';
insert into public.job_titles (name, access_level) values ('Care Coordinator', 'support_worker'), ('Trainee', 'support_worker');
insert into public.job_title_functions (job_title_id, function_group_id) values (test.jt('Care Coordinator'), test.fg('care_coordination')), (test.jt('Trainee'), test.fg('care_coordination'));
update public.profiles set job_title_id = test.jt('Care Coordinator') where email in ('sam@example.com', 'kim@example.com');
insert into public.teams (name) values ('North'), ('South');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';

-- Nothing changes until a module is switched over.
select test.ok(not test.can_as('sam@example.com', 'ops.cars.manage', 'configure'), 'no grants: a support worker can''t (same as today)');
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$insert into public.access_baselines (function_group_id, module_id) values (test.fg('care_coordination'), 'ops.cars.manage')$$, 'a module not switched over can''t be given to a group');
reset role;
update public.app_modules set grant_ready = true where id in ('ops.cars.manage', 'hr.contracts');

-- Who may set them.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.access_baselines (function_group_id, module_id) values (test.fg('care_coordination'), 'ops.cars.manage')$$, 'a manager can''t set role or group grants (system admin only for now)');
reset role;

-- Function group, then job title, then access level.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (function_group_id, module_id, actions) values (test.fg('care_coordination'), 'ops.cars.manage', '{view,configure}');
reset role;
select test.ok(test.can_as('sam@example.com', 'ops.cars.manage', 'configure'), 'a function group grant gives its roles access');
select test.ok(not test.can_as('sam@example.com', 'ops.cars.manage', 'delete'), 'only the actions given');
select test.ok(not test.can_as('newbie@example.com', 'ops.cars.manage', 'configure'), 'never for a new starter');
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (job_title_id, module_id, effect) values (test.jt('Care Coordinator'), 'ops.cars.manage', 'restrict');
reset role;
select test.ok(not test.can_as('sam@example.com', 'ops.cars.manage', 'configure'), 'a job title restriction beats the group''s allow');
select test.act_as('owner@example.com');
set role authenticated;
update public.access_baselines set revoked_at = now() where job_title_id = test.jt('Care Coordinator') and revoked_at is null;
insert into public.access_baselines (access_level, module_id, effect) values ('support_worker', 'ops.cars.manage', 'restrict');
reset role;
select test.ok(test.can_as('sam@example.com', 'ops.cars.manage', 'configure'), 'the group''s allow beats the access-level default');
select test.ok(not test.can_as('lead@example.com', 'ops.cars.manage', 'configure'), 'a team leader with no role or group grant: no');
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (access_level, module_id, actions) values ('team_leader', 'ops.cars.manage', '{configure}');
select test.refused($$insert into public.access_baselines (access_level, module_id) values ('new_starter', 'ops.cars.manage')$$, 'new starters can''t hold an access-level default');
reset role;
select test.ok(test.can_as('lead@example.com', 'ops.cars.manage', 'configure'), 'an access-level default applies to everyone at that level');

-- A person's restriction is never overridden.
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (access_level, module_id) values ('manager', 'ops.cars.manage');
insert into public.access_grants (module_id, user_id, granted_by, effect) values ('ops.cars.manage', test.pid('boss@example.com'), test.pid('owner@example.com'), 'restrict');
reset role;
select test.ok(not test.can_as('boss@example.com', 'ops.cars.manage', 'configure'), 'a person''s restriction beats the access-level default');

-- Sensitive parts: job title or person only.
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$insert into public.access_baselines (function_group_id, module_id) values (test.fg('care_coordination'), 'hr.contracts')$$, 'a sensitive part can''t be given to a function group');
insert into public.access_baselines (job_title_id, module_id, actions) values (test.jt('Care Coordinator'), 'hr.contracts', '{view}');
select test.refused($$insert into public.access_baselines (function_group_id, module_id) values (test.fg('care_coordination'), 'system.settings')$$, 'protected parts never');
select test.refused($$insert into public.access_baselines (function_group_id, module_id) values (test.fg('care_coordination'), 'hr.records.payroll')$$, 'staff records keep their own rules');
reset role;
select test.ok(test.can_as('sam@example.com', 'hr.contracts', 'view'), 'a sensitive part given to the job title works');

-- Scope: own teams.
select test.act_as('owner@example.com');
set role authenticated;
update public.access_baselines set revoked_at = now() where access_level = 'team_leader' and revoked_at is null;
insert into public.access_baselines (access_level, module_id, scope) values ('team_leader', 'ops.cars.manage', 'own_teams');
reset role;
select test.ok(test.can_as('lead@example.com', 'ops.cars.manage', 'view', test.pid('sam@example.com')), 'own teams: someone in my team');
select test.ok(not test.can_as('lead@example.com', 'ops.cars.manage', 'view', test.pid('kim@example.com')), 'own teams: not someone in another team');

-- Kept for history: revoked, never edited or deleted.
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$update public.access_baselines set actions = '{delete}' where access_level = 'team_leader' and revoked_at is null$$, 'a grant isn''t edited (revoke and add)');
delete from public.access_baselines;
reset role;
select test.ok((select count(*) from public.access_baselines where module_id not like 'hr.onboarding%') = 7, 'nothing is deleted');
select test.ok((select count(*) from public.access_baselines where revoked_at is not null and revoked_by = test.pid('owner@example.com') and module_id not like 'hr.onboarding%') = 2, 'revoking records who');

-- Manager Administrators: only within their own authority (boss is one, above).
insert into public.job_titles (name, access_level) values ('Driver', 'support_worker');
select test.act_as('owner@example.com');
set role authenticated;
update public.access_grants set revoked_at = now() where user_id = test.pid('boss@example.com') and module_id = 'ops.cars.manage' and revoked_at is null;
insert into public.access_grants (module_id, user_id, granted_by, actions, can_pass_on) values ('ops.cars.manage', test.pid('boss@example.com'), test.pid('owner@example.com'), '{view,configure}', true);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.access_baselines (job_title_id, module_id, actions) values (test.jt('Driver'), 'ops.cars.manage', '{view}');
select test.refused($$insert into public.access_baselines (function_group_id, module_id, actions) values (test.fg('service_delivery'), 'ops.cars.manage', '{delete}')$$, 'a Manager Administrator can''t give wider actions than they hold');
select test.refused($$insert into public.access_baselines (function_group_id, module_id, actions) values (test.fg('service_delivery'), 'ops.cars.manage', '{}')$$, 'or "everything" when they hold only some actions');
select test.refused($$insert into public.access_baselines (access_level, module_id, actions) values ('staff_admin', 'ops.cars.manage', '{view}')$$, 'a Manager Administrator can''t set access-level defaults');
select test.refused($$insert into public.access_baselines (job_title_id, module_id, actions) values (test.jt('Driver'), 'hr.contracts', '{view}')$$, 'nor give a part they don''t hold');
reset role;
select test.ok((select granted_by = test.pid('boss@example.com') from public.access_baselines where job_title_id = test.jt('Driver') and revoked_at is null), 'a Manager Administrator gives a role what they hold (recorded as theirs)');
update public.profiles set job_title_id = test.jt('Driver') where email = 'kim@example.com';
select test.ok(test.can_as('kim@example.com', 'ops.cars.manage', 'view'), 'and it works');
update public.admin_designations set status = 'ended' where user_id = test.pid('boss@example.com');
select test.ok(not test.can_as('kim@example.com', 'ops.cars.manage', 'view'), 'it stops counting when they stop being a Manager Administrator');
update public.admin_designations set status = 'active' where user_id = test.pid('boss@example.com');
select test.act_as('boss@example.com');
set role authenticated;
update public.access_baselines set revoked_at = now() where job_title_id = test.jt('Driver') and revoked_at is null;
select test.ok((select count(*) from public.access_baselines where function_group_id = test.fg('care_coordination') and revoked_at is not null) = 0, 'they can''t revoke what someone else gave');
update public.access_baselines set revoked_at = now() where function_group_id = test.fg('care_coordination') and revoked_at is null;
reset role;
select test.ok((select revoked_at is not null from public.access_baselines where job_title_id = test.jt('Driver') order by created_at desc limit 1), 'they revoke what they gave');
select test.ok((select count(*) from public.access_baselines where function_group_id = test.fg('care_coordination') and revoked_at is null) = 1, 'and not what the system admin gave');

-- Who reads them.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.access_baselines where access_level = 'manager') = 0, 'staff can''t read other levels'' grants');
select test.ok((select count(*) from public.access_baselines where function_group_id = test.fg('care_coordination')) >= 1, 'staff read their own groups'' grants (the check needs them)');
reset role;

-- Modules not switched over: helpers unchanged (person-grant gate still applies).
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(not public.can_manage_cars(), 'helpers of modules not yet switched over are unchanged');
reset role;

\o
\echo 'All role, group and access-level grant tests passed.'

-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects module framework step 2: can() matches today's rules exactly for
-- modules they cover, and the new rules (inheritance, restrict, sensitive,
-- actions, scope, dates, new modules, protected) for everything else.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
create function test.team(p_name text) returns uuid language sql security definer as $$ select id from public.teams where name = p_name $$;
grant execute on all functions in schema test to authenticated;

-- Some of today's access, to compare against.
insert into public.access_grants (area, user_id, granted_by, can_reveal_tfn) values ('payroll_tax', test.pid('boss@example.com'), test.pid('owner@example.com'), true);
insert into public.access_grants (area, user_id, scope, scope_ids, granted_by) values ('staff_details', test.pid('office@example.com'), 'teams', array[test.team('North')], test.pid('owner@example.com'));
update public.delegation_rules set mode = 'selected', people = array[test.pid('boss2@example.com')] where area = 'tasks';

-- 1. Today's rules give exactly the same answers through can(), for every person.
create function test.mismatches() returns int language plpgsql as $$
declare n int := 0; m record; p record;
begin
  for m in select id, legacy_kind, legacy_area from public.app_modules where legacy_kind is not null loop
    if m.legacy_kind = 'settings' then
      if public.can(m.id) is distinct from public.can_admin_area(m.legacy_area) then n := n + 1; end if;
    else
      for p in select id from public.profiles loop
        if public.can(m.id, 'view', p.id) is distinct from public.has_access(m.legacy_area, p.id) then n := n + 1; end if;
      end loop;
      if public.can(m.id) is distinct from public.holds_area(m.legacy_area) then n := n + 1; end if;
    end if;
  end loop;
  for p in select id from public.profiles loop
    if public.can('hr.records.payroll', 'reveal_tfn', p.id) is distinct from public.has_tfn_access(p.id) then n := n + 1; end if;
  end loop;
  return n;
end $$;
grant execute on all functions in schema test to authenticated;
do $$
declare who text;
begin
  foreach who in array array['owner@example.com', 'boss@example.com', 'boss2@example.com', 'office@example.com', 'lead@example.com', 'sam@example.com'] loop
    perform test.act_as(who);
    set local role authenticated;
    perform test.ok(test.mismatches() = 0, 'can() gives today''s answers exactly for ' || who);
    reset role;
  end loop;
end $$;

-- 2. New rules (modules not covered by today's rules).
-- (Step 3: admin access only goes to nominated Manager Administrators.)
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com')), (test.pid('boss2@example.com'), test.pid('owner@example.com'));
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can('ops.cars.manage'), 'a manager without a grant can''t administer a module');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
-- Whole Cars module, all actions.
insert into public.access_grants (module_id, user_id, granted_by) values ('ops.cars', test.pid('boss@example.com'), test.pid('owner@example.com'));
-- Only one submodule (Expiry list), parent not granted.
insert into public.access_grants (module_id, user_id, granted_by, actions) values ('hr.onboarding.expiry', test.pid('boss2@example.com'), test.pid('owner@example.com'), array['view']);
-- The whole HR category for boss2, but Contracts is sensitive.
insert into public.access_grants (module_id, user_id, granted_by) values ('cat_hr', test.pid('boss2@example.com'), test.pid('owner@example.com'));
-- A restriction on one child.
insert into public.access_grants (module_id, user_id, granted_by, effect) values ('ops.cars.manage', test.pid('boss@example.com'), test.pid('owner@example.com'), 'restrict');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by) values ('system.settings', test.pid('boss@example.com'), test.pid('owner@example.com'))$$, 'protected modules can''t be delegated');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by, actions) values ('ops.scoreboard', test.pid('boss@example.com'), test.pid('owner@example.com'), array['launch_rockets'])$$, 'only real actions');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by) values ('ops.tasks', test.pid('sam@example.com'), test.pid('owner@example.com'))$$, 'support workers can''t receive admin grants');
select test.ok(public.can('system.settings') and public.can('hr.contracts', 'sign_for_employer'), 'the system admin can do everything');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can('ops.cars') and public.can('ops.cars.use') and public.can('ops.cars.app'), 'a module grant covers its submodules');
select test.ok(not public.can('ops.cars.manage'), 'a restricted submodule stays blocked even with the module on');
select test.ok(not public.can('system.settings') and not public.can('system.health'), 'protected modules: never');
select test.ok(not public.can('ops.scoreboard'), 'nothing unrelated');
reset role;

select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(public.can('hr.onboarding.expiry', 'view') and not public.can('hr.onboarding.expiry', 'export'), 'a submodule on its own, view only');
select test.ok(public.can('hr.requests') and public.can('hr.onboarding'), 'a category grant covers its normal modules');
select test.ok(not public.can('hr.contracts'), 'a sensitive module is never inherited from the category');
select test.ok(public.can('system.settings.tasks') = public.can_admin_area('tasks'), 'settings areas still follow the Delegation tab');
reset role;

-- Sensitive: explicit grant works.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_grants (module_id, user_id, granted_by, actions) values ('hr.contracts', test.pid('boss2@example.com'), test.pid('owner@example.com'), array['view']);
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(public.can('hr.contracts', 'view') and not public.can('hr.contracts', 'sign_for_employer'), 'a sensitive module with its own grant, only the actions given');
reset role;

-- Scope: teams.
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by) values ('people.staff', test.pid('office@example.com'), test.pid('owner@example.com'))$$, 'staff admins only get admin access passed on by a manager');
insert into public.access_grants (module_id, user_id, granted_by, scope, scope_ids) values ('people.staff', test.pid('boss@example.com'), test.pid('owner@example.com'), 'teams', array[test.team('North')]);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can('people.staff', 'view', test.pid('sam@example.com')) and not public.can('people.staff', 'view', test.pid('kim@example.com')), 'scope: only people in their teams');
reset role;

-- Dates: not started yet / ended.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_grants (module_id, user_id, granted_by, starts_at) values ('clients.list', test.pid('boss@example.com'), test.pid('owner@example.com'), now() + interval '1 day');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can('clients.list'), 'a grant that hasn''t started gives nothing yet');
reset role;

-- A module added later isn't covered by an earlier category grant.
insert into public.app_modules (id, category, label, delegable, added_at) values ('hr.future_thing', 'hr', 'Future thing', true, now() + interval '1 minute');
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(not public.can('hr.future_thing'), 'a new module isn''t given to anyone automatically');
reset role;

-- Revoking works immediately.
select test.act_as('owner@example.com');
set role authenticated;
update public.access_grants set revoked_at = now() where module_id = 'ops.cars' and user_id = test.pid('boss@example.com');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can('ops.cars'), 'revoked: no access straight away');
select test.refused($$insert into public.access_grants (module_id, user_id, granted_by) values ('ops.tasks', test.pid('boss@example.com'), test.pid('boss@example.com'))$$, 'nobody grants themselves');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.my_modules()) = 0, 'a support worker administers nothing');
reset role;

set role anon;
select test.refused($$select public.can('ops.tasks')$$, 'signed out: no permission checks');
reset role;

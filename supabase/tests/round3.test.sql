-- Staff Portal · © cmeproject. All rights reserved.
--
-- Round 3: the system admin isn't affected by switches, external contractors
-- have no access yet, registers choose who creates tasks, managers share
-- areas with staff admins, and managers look after Compliance with no staff admin.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

-- 1. Switches never lock the system admin out.
update public.features set enabled = false where key = 'forms';
select test.act_as('owner@example.com');
select test.ok(public.feature_enabled('forms'), 'the system admin can still use Forms while it''s off');
select test.ok(not public.feature_live('forms'), 'but it''s off for everyone else');
select test.act_as('boss@example.com');
select test.ok(not public.feature_enabled('forms'), 'a manager can''t');
update public.features set enabled = false where key = 'email_notifications';
select test.act_as('owner@example.com');
select test.ok(not public.feature_enabled('email_notifications'), 'emails off applies to the system admin too');
select public.notify(test.pid('sam@example.com'), 'approval_needed', 'Please approve', '', '/', true);
select test.ok((select count(*) from public.email_outbox) = 0, 'no email goes out while Emails is off, whoever triggered it');

-- 2. External contractors: an access level with no permissions yet.
insert into public.invitations (email, full_name, role) values ('ot@example.com', 'Olivia', 'external');
insert into auth.users (email) values ('ot@example.com');
select test.act_as('ot@example.com');
set role authenticated;
select test.ok(not public.is_member(), 'an external contractor isn''t a member yet');
select test.ok((select count(*) from public.registries) = 0, 'and sees no registers');
reset role;

-- 3. A register chooses who creates tasks in it.
insert into public.registries (name, kind, prefix) values ('Incidents', 'tasks', 'INC');
update public.app_settings set value = '["support_worker"]' where key = 'tasks.limited_roles';
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.create_task('Fall', (select id from public.registries where prefix = 'INC'), test.pid('boss@example.com'))$$,
  'a support worker can''t use other registers by default');
reset role;
update public.registries set create_roles = '{support_worker}' where prefix = 'INC';
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.create_task('Fall', (select id from public.registries where prefix = 'INC'), test.pid('boss@example.com')) is not null,
  'once the register allows support workers, they can');
reset role;
update public.registries set create_roles = '{team_leader}' where prefix = 'INC';
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.create_task('Check', (select id from public.registries where prefix = 'INC'), test.pid('sam@example.com'))$$,
  'a register limited to team leaders refuses others');
reset role;

-- 5. A delegated manager shares an area with a staff admin.
insert into public.invitations (email, full_name, role) values ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('office@example.com');
update public.delegation_rules set mode = 'managers' where area = 'branding';
select test.act_as('boss@example.com');
set role authenticated;
select public.share_area('branding', test.pid('office@example.com'), true);
select test.refused($$select public.share_area('roles', test.pid('office@example.com'), true)$$, 'roles can''t be shared');
select test.refused($$select public.share_area('branding', test.pid('sam@example.com'), true)$$, 'only with staff admins');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_admin_area('branding'), 'the staff admin now looks after branding');
reset role;
update public.delegation_rules set mode = 'admin' where area = 'branding';
select test.act_as('office@example.com');
set role authenticated;
select test.ok(not public.can_admin_area('branding'), 'until the manager no longer has it');
reset role;

-- 6. No active staff admin: managers look after Compliance.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_manage_compliance(), 'with a staff admin, a manager doesn''t manage Compliance by default');
reset role;
update public.profiles set active = false where email = 'office@example.com';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_manage_compliance(), 'with no active staff admin, managers do');
reset role;

-- 4. The weekly mileage report settings exist.
select test.ok((select count(*) from public.app_settings where key in ('vehicles.weekly_day', 'vehicles.weekly_hour', 'vehicles.weekly_period')) = 3, 'the weekly report has its day, hour and period');

\o
\echo All round 3 tests passed.

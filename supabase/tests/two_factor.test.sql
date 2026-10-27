-- Staff Portal · © cmeproject. All rights reserved.
--
-- The main two-factor switch.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('boss@example.com');

select test.act_as('boss@example.com', 'aal1');
set role authenticated;
select test.ok((select count(*) from public.profiles) = 1, 'switch on: manager without a code sees only their own profile');
select test.ok((select mfa_required from public.my_access()), 'switch on: manager is told a code is needed');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.features set enabled = false where key = 'two_factor'$$,
  'a manager cannot turn two-factor off');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
update public.features set enabled = false where key = 'two_factor';
reset role;
select test.ok((select count(*) from public.audit_log where action = 'feature_off' and entity_id = 'two_factor') = 1,
  'turning two-factor off is logged');

select test.act_as('boss@example.com', 'aal1');
set role authenticated;
select test.ok((select count(*) from public.profiles) = 2, 'switch off: manager without a code sees colleagues');
select test.ok((select not mfa_required from public.my_access()), 'switch off: nobody is told a code is needed');
reset role;

select test.act_as('owner@example.com', 'aal1');
set role authenticated;
update public.features set enabled = true where key = 'two_factor';
reset role;
select test.ok(public.feature_enabled('two_factor'), 'switch off: system admin without a code can turn it back on');

\o
\echo 'All two-factor switch tests passed.'

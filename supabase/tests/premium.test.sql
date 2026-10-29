-- Staff Portal · © cmeproject. All rights reserved.
--
-- Premium features: only the system admin decides what's included and switches them.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('sam@example.com');

select test.ok((select premium from public.features where key = 'vehicles'), 'Cars is a premium feature');

insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('boss@example.com');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.features set included = false where key = 'vehicles'$$, 'a manager can''t change the plan');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.features set included = false, enabled = false where key = 'vehicles';
reset role;
select test.ok(not public.feature_enabled('vehicles'), 'the system admin can take Cars out of the plan');
select test.act_as('owner@example.com');
set role authenticated;
update public.features set included = true, enabled = true where key = 'vehicles';
reset role;
select test.ok(public.feature_enabled('vehicles'), 'and put it back in');

-- Not in the plan (set by cmeproject in the database, not signed in as anyone).
select set_config('request.jwt.claims', '', false);
update public.features set included = false where key = 'vehicles';
select test.ok(not public.feature_enabled('vehicles'), 'not included: Cars doesn''t work, even if it was on');
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.car_board()) = 0, 'staff see no cars');
reset role;
select set_config('request.jwt.claims', '', false);
update public.features set enabled = false where key = 'vehicles';
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$update public.features set enabled = true where key = 'vehicles'$$, 'switching it on alone isn''t enough while it''s out of the plan');
reset role;

\o
\echo All premium feature tests passed.

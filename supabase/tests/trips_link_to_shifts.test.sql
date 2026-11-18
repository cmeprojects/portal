-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 135): a car trip links itself to the driver's published shift.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('lee@example.com', 'Lee', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('lee@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.purpose(p_name text) returns uuid language sql security definer as $$ select id from public.car_purposes where name = p_name $$;
create function test.car(p_rego text) returns uuid language sql security definer as $$ select id from public.cars where rego = p_rego $$;
create function test.trip_shift(p_email text) returns uuid language sql security definer as $$
  select shift_id from public.car_trips where id = (select max(id) from public.car_trips where driver_id = (select id from public.profiles where email = p_email)) $$;
create function test.shift_of(p_email text) returns uuid language sql security definer as $$
  select id from public.shifts where worker_id = (select id from public.profiles where email = p_email) and status = 'published' $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.cars (name, rego, odometer) values ('Corolla', 'TRP 001', 1000), ('Camry', 'TRP 002', 2000);
-- Sam has a published shift on now; Lee only has a draft.
insert into public.shifts (worker_id, starts_at, ends_at, status) values
  (test.pid('sam@example.com'), now() - interval '30 minutes', now() + interval '2 hours', 'published'),
  (test.pid('lee@example.com'), now() - interval '30 minutes', now() + interval '2 hours', 'draft');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select public.start_car_trip(test.car('TRP 001'), test.purpose('Community access'), null, 1000);
reset role;
select test.ok(test.trip_shift('sam@example.com') = test.shift_of('sam@example.com'), 'a trip taken during a published shift is linked to it');

select test.act_as('lee@example.com');
set role authenticated;
select public.start_car_trip(test.car('TRP 002'), test.purpose('Community access'), null, 2000);
reset role;
select test.ok(test.trip_shift('lee@example.com') is null, 'a draft shift is not linked');

\o
select 'All trip link tests passed.';

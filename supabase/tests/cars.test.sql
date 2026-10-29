-- Staff Portal · © cmeproject. All rights reserved.
--
-- Cars: managers set up cars, clients and purposes; staff start and return
-- trips as themselves; undo for a few minutes; corrections; reminders.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan Manager', 'manager'), ('sam@example.com', 'Sam Worker', 'support_worker'),
  ('lee@example.com', 'Lee Worker', 'support_worker'), ('nico@example.com', 'Nico New', 'new_starter');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('lee@example.com'), ('nico@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.purpose(p_name text) returns uuid language sql security definer as $$ select id from public.car_purposes where name = p_name $$;
create function test.car(p_rego text) returns uuid language sql security definer as $$ select id from public.cars where rego = p_rego $$;
create function test.client(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.trip(p_email text) returns bigint language sql security definer as $$
  select max(id) from public.car_trips where driver_id = (select id from public.profiles where email = p_email) $$;
grant execute on all functions in schema test to authenticated;

-- Set-up: staff can't add cars; a manager can.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.cars (name, rego, odometer) values ('Sneaky', 'SNK 001', 10)$$, 'staff can''t add cars');
select test.refused($$insert into public.car_purposes (name) values ('Joyride')$$, 'or purposes');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.cars (name, rego, car_type, odometer) values ('Kia Carnival', '1EC 4KC', 'People mover', 48213),
  ('Hyundai i30', 'XYZ 789', 'Hatchback', 31540);
insert into public.car_clients (name, reference) values ('Jamie N.', 'NDIS 4301'), ('Robert K.', 'NDIS 4302');
update public.car_clients set active = false where name = 'Robert K.';
insert into public.car_purposes (name, sort_order) values ('Respite outing', 60);
select test.refused($$insert into public.cars (name, rego) values ('Copy', '1ec4kc')$$, 'the same rego can''t be added twice');
select test.refused($$delete from public.cars$$, 'cars are switched off, never deleted');
reset role;
select test.ok((select count(*) from public.audit_log where action in ('added_car', 'added_car_client', 'added_car_purpose')) = 5,
  'adding cars, clients and purposes goes in the change log');

-- Staff see cars and client names, but not client references.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.car_board()) = 2, 'staff see the cars');
select test.ok((select count(*) from public.car_clients) = 0, 'staff can''t read the client list itself');
select test.ok((select array_agg(name) from public.car_client_options()) = array['Jamie N.'], 'they get active client names only');

-- Starting.
select test.refused($$select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Community access'), null, 48000)$$,
  'the start reading can''t be lower than the last one');
select test.refused($$select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Other'), null, 48213)$$,
  '"Other" needs a few words');
select test.refused($$select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Community access'), test.client('Robert K.'), 48213)$$,
  'a switched-off client can''t be chosen');
select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Community access'), test.client('Jamie N.'), 48220);
select test.ok((select driver_id = test.pid('sam@example.com') and client_name = 'Jamie N.' and gap_km = 7
                  from public.car_trips where id = test.trip('sam@example.com')),
  'the driver is whoever is signed in, and 7 km since the last return is flagged');
select test.refused($$select public.start_car_trip(test.car('XYZ 789'), test.purpose('Office errand'), null, 31540)$$,
  'one car at a time');
select test.refused($$update public.car_trips set end_odo = 99999$$, 'trips can''t be edited directly');
reset role;

select test.act_as('lee@example.com');
set role authenticated;
select test.refused($$select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Office errand'), null, 48220)$$,
  'a car that''s out can''t be taken');
select test.ok((select driver_name from public.car_board() where rego = '1EC 4KC') = 'Sam Worker', 'everyone sees who has it');
select test.ok((select count(*) from public.car_trips) = 0, 'staff don''t see other people''s trips');
select test.refused($$select public.return_car_trip(test.trip('sam@example.com'), 48300)$$, 'or return someone else''s car');
reset role;

select test.act_as('nico@example.com');
set role authenticated;
select test.ok((select count(*) from public.car_board()) = 0, 'new starters can''t use cars yet');
reset role;

-- Undo a start, within the time.
select test.act_as('sam@example.com');
set role authenticated;
select public.undo_car_start(test.trip('sam@example.com'));
select test.ok((select count(*) from public.car_trips) = 0, 'undo removes the trip');
select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Community access'), null, 48220);
reset role;
update public.car_trips set started_at = now() - interval '11 minutes';
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.undo_car_start(test.trip('sam@example.com'))$$, 'not after 10 minutes');

-- Returning.
select test.refused($$select public.return_car_trip(test.trip('sam@example.com'), 48100)$$, 'the end reading can''t be lower than the start');
select test.ok(public.return_car_trip(test.trip('sam@example.com'), 48257) = 37, 'returning works out the km');
select test.ok((select odometer from public.cars where rego = '1EC 4KC') = 48257, 'and updates the car''s reading');
select public.undo_car_return(test.trip('sam@example.com'));
select test.ok((select returned_at is null from public.car_trips where id = test.trip('sam@example.com'))
               and (select odometer from public.cars where rego = '1EC 4KC') = 48220, 'undo return reopens the trip and the reading');
select public.return_car_trip(test.trip('sam@example.com'), 48260);
reset role;

-- The Kia is free again; Lee takes it and forgets to bring it back.
select test.act_as('lee@example.com');
set role authenticated;
select public.start_car_trip(test.car('1EC 4KC'), test.purpose('Office errand'), null, 48260);
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.undo_car_return(test.trip('sam@example.com'))$$, 'no undo once someone else has the car');
reset role;

update public.car_trips set started_at = now() - interval '2 days' where driver_id = test.pid('lee@example.com');
select public.run_car_alerts(((now() at time zone 'Australia/Melbourne')::date::timestamp + interval '21 hours') at time zone 'Australia/Melbourne');
select test.ok(exists (select 1 from public.notifications where user_id = test.pid('lee@example.com') and kind = 'car_still_out'),
  'the driver is reminded at night');
select public.run_car_alerts(((now() at time zone 'Australia/Melbourne')::date::timestamp + interval '21 hours') at time zone 'Australia/Melbourne' + interval '1 hour');
select test.ok((select count(*) from public.notifications where kind = 'car_still_out') = 1, 'only once');
select test.ok(exists (select 1 from public.notifications where user_id = test.pid('boss@example.com') and kind = 'car_not_returned'),
  'car managers are told the next morning');
select test.ok(exists (select 1 from public.email_outbox where to_user = test.pid('boss@example.com')), 'by email too');

-- A car manager returns it for Lee, with a reason.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.return_car_trip(test.trip('lee@example.com'), 48300)$$, 'returning for someone needs a reason');
select public.return_car_trip(test.trip('lee@example.com'), 48300, null, 'Keys were left at the office');
select test.ok((select count(*) from public.car_trips) = 2, 'car managers see everyone''s trips');
select test.refused($$select public.correct_car_trip(test.trip('sam@example.com'), 48220, 48250, 'Community access', null, '')$$,
  'corrections need a reason');
select public.correct_car_trip(test.trip('sam@example.com'), 48220, 48250, 'Community access', null, 'Typo in the end reading');
reset role;
select test.ok(exists (select 1 from public.notifications where user_id = test.pid('lee@example.com') and kind = 'car_returned_for_you'),
  'the driver is told it was returned for them');
select test.ok((select km from public.car_trips where id = test.trip('sam@example.com')) = 30
               and exists (select 1 from public.audit_log where action = 'car_trip_corrected'), 'the correction is kept in the change log');

-- Rego and service reminders, once each.
update public.cars set rego_expires = current_date + 10, service_due_km = 48500 where rego = '1EC 4KC';
select public.run_car_alerts(((now() at time zone 'Australia/Melbourne')::date + 1)::timestamp at time zone 'Australia/Melbourne' + interval '8 hours');
select public.run_car_alerts(((now() at time zone 'Australia/Melbourne')::date + 1)::timestamp at time zone 'Australia/Melbourne' + interval '9 hours');
select test.ok((select count(*) from public.notifications where user_id = test.pid('boss@example.com') and kind = 'car_rego') = 1,
  'rego due is told once');
select test.ok((select count(*) from public.notifications where user_id = test.pid('boss@example.com') and kind = 'car_service') = 1,
  'and a service coming up');

-- Settings: car managers set the client field; the rest is for the system admin (or a delegate).
select test.act_as('boss@example.com');
set role authenticated;
update public.app_settings set value = '"required"' where key = 'vehicles.client_field';
select test.refused($$update public.app_settings set value = '"nonsense"' where key = 'vehicles.client_field'$$, 'only off, optional or required');
select test.refused($$update public.app_settings set value = '60' where key = 'vehicles.undo_minutes'$$,
  'a car manager can''t change the other car settings without being given Cars');
reset role;
select test.ok((select value #>> '{}' from public.app_settings where key = 'vehicles.client_field') = 'required',
  'a car manager can make the client required');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.start_car_trip(test.car('XYZ 789'), test.purpose('Office errand'), null, 31540)$$,
  'with the client required, it must be chosen');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
select public.set_delegation(test.pid('boss@example.com'), array['vehicles']);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.app_settings set value = '"off"' where key = 'vehicles.client_field';
reset role;
select test.ok((select value #>> '{}' from public.app_settings where key = 'vehicles.client_field') = 'off',
  'a manager given Cars can change the car settings');

-- Switching Cars off stops everything (records stay).
update public.features set enabled = false where key = 'vehicles';
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.car_board()) = 0 and (select count(*) from public.car_trips) = 0, 'switched off: nothing shows');
reset role;
select test.ok((select count(*) from public.car_trips) = 2, 'and the trips are kept');

\o
\echo All car tests passed.

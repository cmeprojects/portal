-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 122): rostering, first version.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('pay@example.com', 'Pat', 'support_worker'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'), ('newbie@example.com', 'Nia', 'new_starter');
insert into auth.users (email) values ('boss@example.com'), ('pay@example.com'), ('sam@example.com'), ('kim@example.com'), ('newbie@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
create function test.at(p_days int, p_hour int) returns timestamptz language sql as $$
  select ((current_date + p_days)::timestamp + make_interval(hours => p_hour)) at time zone 'Australia/Sydney' $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Payroll Officer') where email = 'pay@example.com';
insert into public.car_clients (name, status) values ('Zara North', 'active'), ('Alex South', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients where name = 'Zara North';
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '2 Other St', true from public.car_clients where name = 'Alex South';
-- Update 130: client shifts need a service and a location.
insert into public.client_services (client_id, program_id, label, status, start_date, location_id)
select c.id, (select id from public.client_programs where name = 'Private'), 'Support', 'planned', current_date, l.id from public.car_clients c join public.client_locations l on l.client_id = c.id;
insert into public.leave_periods (user_id, leave_type, start_date, end_date) values (test.pid('kim@example.com'), 'annual', current_date + 3, current_date + 4);

-- Payroll & Rostering rosters Sam.
select test.act_as('pay@example.com');
set role authenticated;
insert into public.shifts (worker_id, starts_at, ends_at, client_id, location_id, service_id, status)
select test.pid('sam@example.com'), test.at(2, 9), test.at(2, 15), c.id, l.id, (select v.id from public.client_services v where v.client_id = c.id), 'published' from public.car_clients c join public.client_locations l on l.client_id = c.id where c.name = 'Zara North';
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at) values (test.pid('sam@example.com'), test.at(2, 14), test.at(2, 18))$$, 'no two shifts at once for one worker');
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at) values (test.pid('kim@example.com'), test.at(3, 9), test.at(3, 12))$$, 'not while they''re on approved leave');
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at) values (test.pid('newbie@example.com'), test.at(5, 9), test.at(5, 12))$$, 'not someone still onboarding');
select test.refused($$insert into public.shifts (starts_at, ends_at, client_id, location_id, service_id) select test.at(6, 9), test.at(6, 12), (select id from public.car_clients where name = 'Zara North'), l.id, (select v.id from public.client_services v join public.car_clients c on c.id = v.client_id where c.name = 'Zara North') from public.client_locations l where l.address = '2 Other St'$$, 'not another client''s location');
select test.refused($$insert into public.shifts (starts_at, ends_at) values (test.at(6, 9), test.at(7, 9))$$, 'no shift over 16 hours');
insert into public.shifts (starts_at, ends_at, status, notes) values (test.at(6, 9), test.at(6, 13), 'published', 'Open shift');
insert into public.shifts (worker_id, starts_at, ends_at, status) values (test.pid('kim@example.com'), test.at(8, 9), test.at(8, 13), 'draft');
reset role;
select test.ok(test.n('pay@example.com', '(select count(*) from public.leave_periods)') = 1, 'people who roster see leave dates');

-- Who sees what.
select test.ok(test.n('sam@example.com', '(select count(*) from public.shifts where worker_id is not null)') = 1, 'workers see their own published shifts');
select test.ok(test.n('kim@example.com', '(select count(*) from public.shifts where worker_id is not null)') = 0, 'not their drafts, nor others'' shifts');
select test.ok(test.n('kim@example.com', '(select count(*) from public.shifts where worker_id is null)') = 1, 'everyone sees open shifts');
select test.act_as('kim@example.com');
set role authenticated;
insert into public.shift_interest (shift_id) select id from public.shifts where worker_id is null;
update public.shifts set notes = 'mine' where worker_id is null;
select test.refused($$insert into public.shifts (starts_at, ends_at) values (test.at(9, 9), test.at(9, 12))$$, 'staff can''t add shifts');
select test.refused($$delete from public.shifts$$, 'shifts are never deleted');
reset role;
select test.ok((select count(*) from public.shift_interest) = 1, 'staff put their hand up for an open shift');
select test.ok((select notes from public.shifts where worker_id is null) = 'Open shift', 'staff can''t change shifts');

-- Telling workers (server only), once.
select public.run_roster_alerts();
select public.run_roster_alerts();
select test.ok((select count(*) from public.notifications where kind = 'shift_published' and user_id = test.pid('sam@example.com')) = 1, 'the worker is told once about a published shift');
select test.ok((select count(*) from public.notifications where kind = 'shift_published' and user_id = test.pid('kim@example.com')) = 0, 'not about a draft');
select test.act_as('boss@example.com');
set role authenticated;
update public.shifts set ends_at = test.at(2, 16) where worker_id = test.pid('sam@example.com');
reset role;
select public.run_roster_alerts();
select test.ok((select count(*) from public.notifications where kind = 'shift_published' and user_id = test.pid('sam@example.com')) = 2, 'and told again when it changes');
select test.act_as('boss@example.com');
set role authenticated;
update public.shifts set status = 'cancelled' where worker_id = test.pid('sam@example.com');
select test.refused($$update public.shifts set status = 'published' where status = 'cancelled'$$, 'a cancelled shift stays cancelled');
reset role;
set role authenticated;
select test.refused($$select public.run_roster_alerts()$$, 'staff can''t run the reminders');
reset role;

\o

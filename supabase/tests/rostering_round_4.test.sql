-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 129): shift templates; declined, cancelled and unfilled notices.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.at(p_hours int) returns timestamptz language sql as $$ select date_trunc('hour', now()) + make_interval(hours => p_hours) $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.shift_templates (name, start_time, end_time) values ('Morning', '07:00', '09:00')$$, 'only people who roster make templates');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shift_templates (name, shift_type, start_time, end_time, allowances) values ('Morning personal care', 'personal_care', '07:00', '09:00', '{First aid}');
select test.ok((select count(*) from public.shift_templates) = 1, 'people who roster save a template');
select test.refused($$delete from public.shift_templates$$, 'templates are switched off, not deleted');
-- Shifts: one the worker will decline, one to cancel, one vacant soon.
insert into public.shifts (worker_id, starts_at, ends_at, status) values
  (test.pid('sam@example.com'), test.at(30), test.at(32), 'published'),
  (test.pid('sam@example.com'), test.at(60), test.at(62), 'published'),
  (null, test.at(20), test.at(22), 'published');
reset role;
select set_config('request.jwt.claims', '', false);
create temp table r0 as select public.run_roster_alerts() as v; -- tells Sam about the two shifts
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_responses (shift_id, response, note) select id, 'declined', 'I''m away that day' from public.shifts where starts_at = test.at(30);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.shifts set status = 'cancelled' where starts_at = test.at(60);
reset role;
select set_config('request.jwt.claims', '', false);
create temp table r1 as select public.run_roster_alerts() as v;
select test.ok((select (v ->> 'declined')::int from r1) = 1, 'the people who roster are told when a worker declines');
select test.ok((select body from public.notifications where kind = 'shift_declined' and user_id = test.pid('boss@example.com')) = 'I''m away that day', 'with the worker''s reason');
select test.ok((select (v ->> 'cancelled')::int from r1) = 1, 'the worker is told when their shift is cancelled');
select test.ok((select (v ->> 'unfilled')::int from r0) + (select (v ->> 'unfilled')::int from r1) = 2, 'vacant and declined shifts within 48 hours are flagged');
select test.ok((select worker_id from public.shifts where starts_at = test.at(30)) = test.pid('sam@example.com'), 'a declined shift stays with the worker until someone acts');
create temp table r2 as select public.run_roster_alerts() as v;
select test.ok((select (v ->> 'declined')::int + (v ->> 'cancelled')::int + (v ->> 'unfilled')::int from r2) = 0, 'each notice is sent once');
\o
select 'All rostering round 4 tests passed.';

-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 123): rostering round 2 (premium package).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('pay@example.com', 'Pat', 'support_worker'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'), ('tom@example.com', 'Tom', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('pay@example.com'), ('sam@example.com'), ('kim@example.com'), ('tom@example.com');
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
create function test.shift(p_email text, p_days int) returns uuid language sql security definer as $$
  select id from public.shifts where worker_id = test.pid(p_email) and (starts_at at time zone 'Australia/Sydney')::date = current_date + p_days and status <> 'cancelled' limit 1 $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Payroll Officer') where email = 'pay@example.com';

-- Checks: Tom's NDIS Worker Screening (needed before work) has expired; Kim's First Aid (not before work) has expired.
insert into public.compliance_items (kind, title, before_work, needs_expiry) values ('upload', 'NDIS Worker Screening Check', true, true), ('upload', 'First Aid', false, true);
insert into public.compliance_records (item_id, user_id, version, status, expires_on, doc_number, file_path)
select i.id, test.pid('tom@example.com'), 1, 'accepted', current_date - 3, '123456', 'secret/path.pdf' from public.compliance_items i where i.title = 'NDIS Worker Screening Check';
insert into public.compliance_records (item_id, user_id, version, status, expires_on)
select i.id, test.pid('kim@example.com'), 1, 'accepted', current_date - 3 from public.compliance_items i where i.title = 'First Aid';

select test.ok((select enabled and premium from public.features where key = 'rostering'), 'Rostering is a premium package (on here)');
select test.ok(test.n('pay@example.com', '(select count(*) from public.roster_check_dates())') = 2, 'people who roster see check names and dates');
select test.ok(test.n('sam@example.com', '(select count(*) from public.roster_check_dates())') = 0, 'other staff see none');
select test.ok(test.n('pay@example.com', '(select count(*) from public.compliance_records)') = 0, 'and still can''t read the records themselves (files, numbers)');

-- Expired "before work" check refuses; other expired checks don't.
select test.act_as('pay@example.com');
set role authenticated;
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at, status) values (test.pid('tom@example.com'), test.at(2, 9), test.at(2, 12), 'published')$$, 'expired "before work" check: refused');
insert into public.shifts (worker_id, starts_at, ends_at, status) values (test.pid('kim@example.com'), test.at(3, 9), test.at(3, 12), 'published');
-- Sam: one shift that has happened, one coming up (both in one repeating series).
insert into public.shifts (worker_id, starts_at, ends_at, break_minutes, status, series_id)
values (test.pid('sam@example.com'), test.at(-1, 9), test.at(-1, 15), 30, 'published', '11111111-1111-1111-1111-111111111111'),
       (test.pid('sam@example.com'), test.at(4, 9), test.at(4, 15), 30, 'published', '11111111-1111-1111-1111-111111111111');
update public.shifts set ends_at = test.at(4, 16) where id = test.shift('sam@example.com', 4);
reset role;
select test.ok((select count(*) from public.shifts where worker_id = test.pid('kim@example.com')) = 1, 'an expired check that isn''t needed before work only warns');
select test.ok((select count(*) from public.shifts where series_id is not null) = 2, 'repeating shifts share a series');
select test.ok((select summary from public.shift_events where shift_id = test.shift('sam@example.com', 4) order by id desc limit 1) = 'changed the finish time from 3:00pm to 4:00pm', 'the log is in plain words');

-- Timesheets.
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_timesheets (shift_id, actual_start, actual_end, break_minutes, status)
values (test.shift('sam@example.com', -1), test.at(-1, 9), test.at(-1, 16), 30, 'approved');
select test.refused($$insert into public.shift_timesheets (shift_id, actual_start, actual_end) values (test.shift('sam@example.com', 4), test.at(4, 9), test.at(4, 16))$$, 'not for a shift that hasn''t started');
select test.refused($$update public.shift_timesheets set status = 'approved'$$, 'a worker can''t approve their own timesheet');
reset role;
select test.ok((select status from public.shift_timesheets) = 'submitted', 'sent as "to approve" whatever the worker asked');
select test.ok(test.n('kim@example.com', '(select count(*) from public.shift_timesheets)') = 0, 'other staff don''t see it');
select test.act_as('pay@example.com');
set role authenticated;
select test.refused($$update public.shift_timesheets set actual_end = test.at(-1, 15)$$, 'a correction needs a reason');
update public.shift_timesheets set actual_end = test.at(-1, 15), change_reason = 'Left at 3pm (checked with the family)';
update public.shift_timesheets set status = 'approved';
reset role;
select test.ok((select status = 'approved' and decided_by = test.pid('pay@example.com') from public.shift_timesheets), 'people who roster approve, and it''s recorded');
select test.ok((select count(*) from public.shift_events where summary like 'changed the clock-out time from 4:00pm to 3:00pm ("Left at 3pm%') = 1, 'the correction and its reason are in the log');

-- Change requests: Sam asks to swap the coming shift with Kim.
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_change_requests (shift_id, kind, swap_with, reason) values (test.shift('sam@example.com', 4), 'swap', test.pid('kim@example.com'), 'Uni exam');
select test.refused($$insert into public.shift_change_requests (shift_id, kind, reason) values (test.shift('sam@example.com', 4), 'cannot_work', 'x')$$, 'one waiting request per shift');
select test.refused($$update public.shift_change_requests set status = 'approved'$$, 'a worker can''t approve their own request');
reset role;
select public.run_roster_alerts();
select test.ok((select count(*) from public.notifications where kind = 'shift_request' and user_id = test.pid('boss@example.com')) = 1, 'the roster team is told about the request');
select test.act_as('boss@example.com');
set role authenticated;
update public.shift_change_requests set status = 'approved';
reset role;
select test.ok((select worker_id from public.shifts where id = (select shift_id from public.shift_change_requests)) = test.pid('kim@example.com'), 'approving a swap moves the shift');
select public.run_roster_alerts();
select test.ok((select count(*) from public.notifications where kind = 'shift_request_decided' and user_id = test.pid('sam@example.com')) = 1, 'the worker is told it was approved');

-- The package switched off: changes refused (nothing deleted).
update public.features set enabled = false where key = 'rostering';
select test.act_as('pay@example.com');
set role authenticated;
select test.refused($$insert into public.shifts (starts_at, ends_at) values (test.at(6, 9), test.at(6, 12))$$, 'package off: no new shifts');
reset role;
select test.ok((select count(*) from public.shifts) = 3, 'package off: nothing is deleted');
update public.features set enabled = true where key = 'rostering';

\o

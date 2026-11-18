-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 145): qualifications for shift types.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.item() returns uuid language sql security definer as $$ select id from public.compliance_items where title = 'Nursing registration' $$;
grant execute on all functions in schema test to authenticated;
insert into public.compliance_items (kind, title, needs_expiry) values ('upload', 'Nursing registration', true);
insert into public.compliance_items (kind, title) values ('training', 'Medication course');
update public.shift_types set required_items = array[test.item()] where key = 'wound_care';
update public.shift_types set required_items = array[(select id from public.compliance_items where title = 'Medication course')] where key = 'medication_support';
select test.refused($$update public.shift_types set required_items = array[gen_random_uuid()] where key = 'transport'$$, 'only items from the onboarding list');
-- Sam holds a current registration and the course (no expiry); Kim's registration has expired.
insert into public.compliance_records (item_id, version, user_id, status, expires_on) values (test.item(), 1, test.pid('sam@example.com'), 'accepted', current_date + 365);
insert into public.compliance_records (item_id, version, user_id, status) select id, 1, test.pid('sam@example.com'), 'done' from public.compliance_items where title = 'Medication course';
insert into public.compliance_records (item_id, version, user_id, status, expires_on) values (test.item(), 1, test.pid('kim@example.com'), 'accepted', current_date - 1);

select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), now() + interval '1 day', now() + interval '1 day 1 hour', 'draft', 'wound_care');
select test.ok((select count(*) from public.shifts) = 1, 'a worker who holds the qualification can be given the shift');
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type) values (test.pid('kim@example.com'), now() + interval '2 days', now() + interval '2 days 1 hour', 'draft', 'wound_care')$$, 'an expired qualification is refused');
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type) values (test.pid('kim@example.com'), now() + interval '2 days', now() + interval '2 days 1 hour', 'draft', 'medication_support')$$, 'a missing qualification is refused');
insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), now() + interval '3 days', now() + interval '3 days 1 hour', 'draft', 'medication_support');
select test.ok((select count(*) from public.shifts) = 2, 'a qualification with no expiry counts');
select test.ok((select count(*) from public.roster_check_dates(test.pid('sam@example.com')) where expires_on is null) = 1, 'people who roster see checks with no expiry date');
select test.refused($$update public.shifts set worker_id = test.pid('kim@example.com') where shift_type = 'wound_care'$$, 'changing the worker is checked too');
insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type) values (test.pid('kim@example.com'), now() + interval '4 days', now() + interval '4 days 1 hour', 'draft', 'transport');
select test.ok((select count(*) from public.shifts) = 3, 'a type with no qualifications set isn''t restricted');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.roster_check_dates()) = 0, 'staff who don''t roster see no one''s checks');
reset role;
\o
select 'All shift type qualification tests passed.';

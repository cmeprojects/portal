-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 128): rostering round 3.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.at(p_days int, p_hour int) returns timestamptz language sql as $$
  select ((current_date + p_days)::timestamp + make_interval(hours => p_hour)) at time zone 'Australia/Sydney' $$;
create function test.sid() returns uuid language sql security definer as $$ select id from public.shifts order by created_at limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Ready Client', 'active'), ('Pending Client', 'pending');
insert into public.cars (name, rego) values ('Corolla', 'TEST01');
-- Update 130: client shifts need a service and a location.
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients where name = 'Ready Client';
insert into public.client_services (client_id, program_id, label, status, start_date, location_id)
select c.id, (select id from public.client_programs where name = 'Private'), 'Support', 'planned', current_date, l.id from public.car_clients c join public.client_locations l on l.client_id = c.id;
-- Update 148: services list the shift types they cover (here: every client shift type).
update public.client_services set shift_types = (select array_agg(key) from public.shift_types where used_for in ('client', 'both')) where origin = 'legacy' and cardinality(shift_types) = 0;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at, client_id, status) select test.pid('sam@example.com'), test.at(2, 9), test.at(2, 12), id, 'draft' from public.car_clients where name = 'Pending Client'$$, 'a client who isn''t active can''t be rostered');
insert into public.shifts (worker_id, starts_at, ends_at, client_id, service_id, location_id, status, shift_type, vehicle_id, allowances)
select test.pid('sam@example.com'), test.at(2, 9), test.at(2, 12), c.id, v.id, v.location_id, 'draft', 'personal_care', (select id from public.cars where rego = 'TEST01'), '{Sleepover}' from public.car_clients c join public.client_services v on v.client_id = c.id where c.name = 'Ready Client';
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at, status, vehicle_id) values (test.pid('kim@example.com'), test.at(2, 10), test.at(2, 11), 'draft', (select id from public.cars where rego = 'TEST01'))$$, 'a car can''t be double-booked');
update public.shifts set starts_at = test.at(2, 10), worker_id = test.pid('kim@example.com'), shift_type = 'domestic', status = 'published' where id = test.sid();
update public.shifts set worker_id = test.pid('sam@example.com') where id = test.sid();
select test.refused($$insert into public.shift_events (shift_id, actor, summary) values (test.sid(), auth.uid(), 'I made this up')$$, 'nobody can write the log by hand');
select test.ok((select count(*) from public.shift_events where shift_id = test.sid()) > 0, 'people who roster read the log');
reset role;
select test.ok((select ref from public.shifts where id = test.sid()) ~ '^SH-[0-9]{6}$', 'each shift has a reference');
select test.ok((select old_value || ' → ' || new_value from public.shift_events where shift_id = test.sid() and field = 'Start time') = '9:00am → 10:00am', 'the log shows each field before and after');
select test.ok((select old_value || ' → ' || new_value from public.shift_events where shift_id = test.sid() and field = 'Shift type') = 'Personal Care → Domestic', 'shift type changes are logged');
select test.ok((select count(*) from public.shift_events where shift_id = test.sid() and field = 'Status' and new_value = 'Published') = 1, 'publishing is an event');
select test.ok((select source from public.shift_events where shift_id = test.sid() and field = 'Start time') = 'portal', 'the source is recorded');

-- Worker response.
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$insert into public.shift_responses (shift_id, response) values (test.sid(), 'accepted')$$, 'only the rostered worker can answer');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_responses (shift_id, response) values (test.sid(), 'accepted');
select test.ok((select count(*) from public.shift_events where shift_id = test.sid() and kind = 'event') > 0, 'workers see their shift''s events');
select test.ok((select count(*) from public.shift_events where shift_id = test.sid() and kind = 'change') = 0, 'but not the internal change log');
select test.ok((select count(*) from public.shift_notes) = 0, 'workers can''t read internal notes');
-- Signatures.
insert into public.shift_signatures (shift_id, kind, signer_name, signature) values (test.sid(), 'worker_in', 'Sam', 'data:image/png;base64,AAAA');
select test.refused($$update public.shift_signatures set signer_name = 'Someone else'$$, 'a worker can''t change a signature');
reset role;
select test.ok((select source from public.shift_events where shift_id = test.sid() and summary like 'accepted%') = 'worker', 'the worker''s answer is logged as from the worker');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.shift_signatures set signer_name = 'Changed'$$, 'a signature can''t be edited, even by people who roster');
select test.refused($$update public.shift_signatures set voided_at = now()$$, 'voiding needs a reason');
update public.shift_signatures set voided_at = now(), void_reason = 'Signed on the wrong shift';
select test.refused($$delete from public.shift_signatures$$, 'signatures are never deleted');
insert into public.shift_notes (shift_id, body) values (test.sid(), 'Kim asked not to work Tuesdays.');
select test.refused($$update public.shift_notes set body = 'changed'$$, 'internal notes stay as written');
-- A new time clears the worker's answer.
update public.shifts set ends_at = test.at(2, 13) where id = test.sid();
reset role;
select test.ok((select count(*) from public.shift_signatures where voided_at is not null and void_reason <> '') = 1, 'a voided signature is kept with its reason');
select test.ok((select count(*) from public.shift_responses) = 0, 'changing the time clears the worker''s answer');
select test.ok((select count(*) from public.shift_notes) = 1, 'internal notes are saved');

\o
select 'All rostering round 3 tests passed.';

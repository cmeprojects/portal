-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 149): incident management.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid() returns uuid language sql security definer as $$ select id from public.car_clients limit 1 $$;
create function test.inc() returns uuid language sql security definer as $$ select id from public.client_incidents order by created_at limit 1 $$;
create function test.sid() returns uuid language sql security definer as $$ select id from public.shifts limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Zara', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients;
insert into public.client_services (client_id, program_id, label, status, start_date, location_id, shift_types)
select c.id, (select id from public.client_programs where name = 'Private'), 'Support', 'planned', current_date, l.id, '{personal_care}' from public.car_clients c join public.client_locations l on l.client_id = c.id;

-- A worker's shift note with an incident becomes an incident record.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type)
select test.pid('sam@example.com'), s.client_id, s.id, s.location_id, now() - interval '3 hours', now() - interval '1 hour', 'published', 'personal_care' from public.client_services s;
reset role;
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_service_records (shift_id, delivered, concern, concern_note) values (test.sid(), 'Shower and lunch.', true, 'A small fall in the bathroom, no injury seen.');
select test.ok((select count(*) from public.client_incidents) = 1, 'a shift note incident becomes an incident record (the worker sees it)');
select test.ok((select ref from public.client_incidents) ~ '^INC-[0-9]{6}$', 'it has a reference');
select test.refused($$update public.client_incidents set status = 'acknowledged'$$, 'the worker can''t manage it');
reset role;
select test.ok((select source || '|' || (told_at is not null) from public.client_incidents) = 'shift_note|true', 'from the shift note, and already told (the shift note notice covers it)');
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_incidents) = 0, 'other workers don''t see it');
select test.refused($$insert into public.client_incidents (client_id, summary) values (test.cid(), 'Made up')$$, 'other workers can''t report against a client they don''t work with');
reset role;

-- The manager works it through.
select test.act_as('boss@example.com');
set role authenticated;
update public.client_incidents set status = 'acknowledged';
update public.client_incidents set status = 'investigating', kind = 'fall', severity = 'high';
select test.refused($$update public.client_incidents set reportable = true$$, 'reportable needs a category');
update public.client_incidents set reportable = true, reportable_category = 'serious_injury';
reset role;
select test.ok((select report_due_at = reported_at + interval '24 hours' from public.client_incidents), 'a serious injury is due to the Commission within 24 hours');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_incidents set status = 'closed', outcome = 'Reviewed.'$$, 'a reportable incident can''t close before it''s reported');
update public.client_incidents set reported_to_regulator_at = now(), regulator_ref = 'NDIS-12345';
select test.refused($$update public.client_incidents set status = 'closed'$$, 'closing needs an outcome');
update public.client_incidents set status = 'closed', outcome = 'Hoist plan reviewed with the family; extra training booked.';
select test.refused($$update public.client_incidents set summary = 'changed'$$, 'a closed incident stays as it was');
insert into public.client_incident_events (incident_id, body) values (test.inc(), 'Family called back, happy with the plan.');
select test.refused($$delete from public.client_incidents$$, 'incidents are never deleted');
reset role;
select test.ok((select count(*) from public.client_incident_events where incident_id = test.inc() and kind = 'step') >= 5, 'every step is on the timeline');
select test.ok(((public.plus_business_days('2026-11-20 10:00+11'::timestamptz, 5)) at time zone 'Australia/Sydney')::date = '2026-11-27', 'five business days skips the weekend');
-- Staff report one directly; the notice goes out once.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_incidents (client_id, kind, severity, summary) values (test.cid(), 'medication', 'medium', 'Evening medication missed.');
reset role;
select public.run_incident_alerts();
select test.ok((select count(*) from public.notifications where kind = 'incident') = 1, 'staff-reported incidents are notified once');
\o
select 'All incident tests passed.';

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

-- The manager triages it and chooses an investigator (Kim, a support worker).
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_incidents set status = 'investigating'$$, 'triage needs an investigator');
select test.refused($$update public.client_incidents set reportable = true$$, 'reportable needs a category');
update public.client_incidents set kind = 'fall', severity = 'high', reportable = true, reportable_category = 'serious_injury', investigator_id = test.pid('kim@example.com'), status = 'investigating';
select test.ok((select triaged_at is not null and staff_involved = test.pid('sam@example.com') from public.client_incidents), 'triaged, and the shift''s worker is the staff member involved');
reset role;
select test.ok((select report_due_at = reported_at + interval '24 hours' from public.client_incidents), 'a serious injury is due to the Commission within 24 hours');
select public.run_incident_alerts();
select test.ok((select count(*) from public.notifications where kind = 'incident_investigate' and user_id = test.pid('kim@example.com')) = 1, 'the investigator is told');

-- The investigator fills in the investigation, adds an action, and sends it for sign-off.
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_incidents) = 1, 'the investigator sees it');
select test.refused($$update public.client_incidents set severity = 'low'$$, 'the investigator can''t change the triage');
select test.refused($$update public.client_incidents set status = 'review'$$, 'sign-off needs findings');
update public.client_incidents set findings = 'Wet floor after the shower; no mat in place.', contributing_factors = 'Mat sent for washing.';
select test.refused($$update public.client_incidents set status = 'review'$$, 'sign-off needs the family told (or why not)');
update public.client_incidents set family_told_at = now(), family_told_note = 'Called her daughter.';
insert into public.client_incident_actions (incident_id, action, owner_id, due_on) values (test.inc(), 'Buy a second bath mat', test.pid('sam@example.com'), current_date + 3);
update public.client_incidents set status = 'review';
select test.refused($$update public.client_incidents set status = 'closed', outcome = 'x'$$, 'the investigator can''t sign it off');
reset role;

-- The action owner marks it done; they can't change it.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.client_incident_actions set due_on = current_date + 30$$, 'the owner can''t move the due date');
reset role;

-- The manager signs off.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_incidents set status = 'closed', outcome = 'Reviewed.'$$, 'a reportable incident can''t close before it''s reported');
update public.client_incidents set reported_to_regulator_at = now(), regulator_ref = 'NDIS-12345';
select test.refused($$update public.client_incidents set status = 'closed', outcome = 'Reviewed.'$$, 'every action must be done first');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
update public.client_incident_actions set done_at = now(), done_note = 'Bought and in place.';
reset role;
select test.ok((select done_by = test.pid('sam@example.com') from public.client_incident_actions), 'the owner marked their action done');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_incidents set status = 'closed'$$, 'signing off needs an outcome');
update public.client_incidents set status = 'closed', outcome = 'Second mat bought; bathroom routine updated with the family.';
select test.refused($$update public.client_incidents set summary = 'changed'$$, 'a closed incident stays as it was');
insert into public.client_incident_events (incident_id, body) values (test.inc(), 'Family called back, happy with the plan.');
select test.refused($$delete from public.client_incidents$$, 'incidents are never deleted');
update public.client_incidents set status = 'investigating';
select test.ok((select status from public.client_incidents) = 'investigating', 'a manager can reopen it');
reset role;
select test.ok((select count(*) from public.client_incident_events where incident_id = test.inc() and kind = 'step') >= 7, 'every step is on the timeline');
select test.ok(((public.plus_business_days('2026-11-20 10:00+11'::timestamptz, 5)) at time zone 'Australia/Sydney')::date = '2026-11-27', 'five business days skips the weekend');
-- Staff report one directly; the notice goes out once.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_incidents (client_id, kind, severity, summary) values (test.cid(), 'medication', 'medium', 'Evening medication missed.');
reset role;
select public.run_incident_alerts();
select test.ok((select count(*) from public.notifications where kind = 'incident') = 1, 'staff-reported incidents are notified once');
select test.ok((select prefix || '|' || name from public.register_templates where key = 'incidents') = 'WRK-INC|Workplace Incident Register', 'the workplace register template uses WRK-INC');
select test.ok(exists (select 1 from public.access_baselines b join public.job_titles j on j.id = b.job_title_id where j.name = 'Team Leader' and b.module_id = 'clients.incidents' and b.actions = '{view,edit}' and b.scope = 'assigned' and b.revoked_at is null) or not exists (select 1 from public.job_titles where name = 'Team Leader' and active), 'team leaders get the case manager incident default');
insert into public.registries (name, prefix) values ('Old incidents', 'INC');
select test.refused($$insert into public.registries (name, prefix) values ('Bad', 'WRK--INC')$$, 'a prefix allows only one hyphen between letters');
\o
select 'All incident tests passed.';

-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (updates 88 to 90): Clients & Care steps 3 to 5: details and
-- people (sensitive), safety, service arrangements and the readiness check.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.prog(p_name text) returns uuid language sql security definer as $$ select id from public.client_programs where name = p_name $$;
create function test.loc(p_label text) returns uuid language sql security definer as $$ select id from public.client_locations where label = p_label $$;
create function test.svc(p_label text) returns uuid language sql security definer as $$ select id from public.client_services where label = p_label $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';
insert into public.car_clients (name) values ('Zara North');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

-- Step 3: details and people (sensitive).
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_details (client_id, phone, ndis_number) values (test.cid('Zara North'), '0400 000 000', '431234567');
select test.refused($$update public.client_details set ndis_number = '12' where client_id = test.cid('Zara North')$$, 'an NDIS number is nine numbers');
select test.refused($$update public.client_details set date_of_birth = current_date + 1 where client_id = test.cid('Zara North')$$, 'date of birth can''t be in the future');
insert into public.client_people (client_id, kind, name, relationship, phone) values (test.cid('Zara North'), 'guardian', 'Gus Guardian', 'Guardian', '0400 111 111');
select test.refused($$insert into public.client_people (client_id, kind, name) values (test.cid('Zara North'), 'emergency', 'No Way To Reach')$$, 'a contact needs a phone or email');
reset role;
select test.ok(exists (select 1 from public.audit_log where action = 'client_people_added' and details ->> 'item' = 'guardian' and details::text not like '%Gus%'), 'adding a person is logged, without their details');
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_details) = 0 and (select count(*) from public.client_people) = 0, 'support workers can''t see contact details, identifiers or people');
reset role;
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_details) = 0 and (select count(*) from public.client_people) = 0, 'team leaders can''t either');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
delete from public.client_people where name = 'Gus Guardian';
reset role;
select test.ok((select count(*) from public.client_people) = 1, 'people are never deleted (ended instead)');

-- Step 4: safety.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_alerts (client_id, kind, severity, title, worker_instructions) values (test.cid('Zara North'), 'medical', 'high', 'Severe nut allergy', 'EpiPen in the kitchen drawer. Call 000 first.');
insert into public.client_alert_notes (alert_id, client_id, details) values ((select id from public.client_alerts where title = 'Severe nut allergy'), gen_random_uuid(), 'Anaphylaxis in 2024; plan reviewed by GP.');
insert into public.client_alerts (client_id, kind, title, active) values (test.cid('Zara North'), 'behaviour', 'Old alert', false);
reset role;
select test.ok((select client_id = test.cid('Zara North') from public.client_alert_notes), 'a note always belongs to its alert''s client');
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select array_agg(title) from public.client_alerts) = array['Severe nut allergy'], 'staff see their team client''s active alerts');
select test.ok((select worker_instructions like 'EpiPen%' from public.client_alerts), 'with what to do');
select test.ok((select count(*) from public.client_alert_notes) = 0, 'but not the detailed risk notes');
select test.refused($$insert into public.client_alerts (client_id, kind, title) values (test.cid('Zara North'), 'other', 'x')$$, 'staff can''t add alerts');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_alerts) = 0, 'another team''s staff see no alerts');
reset role;

-- Step 5: services and readiness.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_locations (client_id, label, address) values (test.cid('Zara North'), 'Home', '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id) values (test.cid('Zara North'), test.prog('NDIS'), 'Daily living', current_date, test.loc('Home'));
select test.ok((select status = 'planned' from public.client_services), 'a service starts as planned');
select test.ok((select gaps from jsonb_to_record(public.client_readiness(test.cid('Zara North'))) as r(ready boolean, gaps jsonb)) ? 'No active service.', 'a profile alone isn''t ready: no active service');
select test.refused($$update public.client_services set status = 'active' where label = 'Daily living'$$, 'a service can''t start while things are missing');
reset role;
select test.ok((select public.client_gaps(test.cid('Zara North'), test.prog('NDIS'), test.loc('Home'), true, null)) @> array[
  'The client isn''t active yet.', 'The service location isn''t approved and current.', 'No emergency contact.',
  'Date of birth is needed for this program.', 'Consent is needed and hasn''t been recorded.'], 'it lists each missing thing in plain words');
select test.act_as('boss@example.com');
set role authenticated;
update public.car_clients set status = 'active' where name = 'Zara North';
update public.client_locations set approved = true where label = 'Home';
insert into public.client_people (client_id, kind, name, phone) values (test.cid('Zara North'), 'emergency', 'Erin Emergency', '0400 222 222');
select test.refused($$update public.client_services set status = 'active' where label = 'Daily living'$$, 'NDIS needs a date of birth');
update public.client_details set date_of_birth = '1990-05-01' where client_id = test.cid('Zara North');
update public.client_services set status = 'active' where label = 'Daily living';
reset role;
select test.ok((select (public.client_readiness(test.cid('Zara North')) ->> 'ready')::boolean), 'with everything in place, the client is ready');
select test.ok(cardinality(public.client_service_gaps(test.svc('Daily living'))) = 0, 'and so is the service');
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_services (client_id, program_id, label, start_date, location_id, consent_required) values (test.cid('Zara North'), test.prog('Private'), 'Community outings', current_date, test.loc('Home'), true);
select test.refused($$update public.client_services set status = 'active' where label = 'Community outings'$$, 'a service needing consent can''t start without it');
update public.client_services set consent_given_on = current_date, status = 'active' where label = 'Community outings';
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.client_programs set active = false where name = 'Other';
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_services (client_id, program_id, label, start_date, location_id) values (test.cid('Zara North'), test.prog('Other'), 'x', current_date, test.loc('Home'))$$, 'a program not in use can''t be chosen');
insert into public.car_clients (name) values ('Other Client');
select test.refused($$insert into public.client_services (client_id, program_id, label, start_date, location_id) values (test.cid('Other Client'), test.prog('NDIS'), 'x', current_date, test.loc('Home'))$$, 'a service uses one of its own client''s locations');
reset role;
select test.ok((select status = 'active' from public.client_services where label = 'Community outings'), 'with consent recorded, it starts');
select test.ok(exists (select 1 from public.audit_log where action = 'client_services_changed'), 'service changes are logged');
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_services) = 0, 'support workers don''t see service arrangements (funding and programs)');
reset role;
\o
\echo 'All client care tests passed.'

-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 118): client details by scheme and archiving with a reason
-- (owner's choices).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

insert into public.client_locations (client_id, label, address) values (test.cid('Zara North'), 'Home', '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'NDIS daily living', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'ndis' and l.label = 'Home' limit 1;
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'Home support', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'support_at_home' and l.label = 'Home' limit 1;
create function test.svc(p_label text) returns uuid language sql security definer as $$ select id from public.client_services where label = p_label $$;
grant execute on all functions in schema test to authenticated;
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));



create function test.gaps(p_label text) returns text[] language sql security definer as $$
  select public.client_gaps(s.client_id, s.program_id, s.location_id, s.consent_required, s.consent_given_on) from public.client_services s where s.label = p_label $$;

-- Names.
select test.act_as('boss@example.com');
set role authenticated;
update public.car_clients set title = 'ms', given_name = 'Zara', middle_name = 'J', family_name = 'Northcott' where name = 'Zara North';
select test.refused($$update public.car_clients set given_name = 'Alex' where name = 'Alex South'$$, 'first and last name go together');
reset role;
select test.ok((select count(*) from public.car_clients where name = 'Zara Northcott') = 1, 'the name is made from first and last name');

-- Optional details: sensitive, managers and the assigned care manager only.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_details (client_id, gender, religion, marital_status, atsi_status, country_of_birth, tags)
values (test.cid('Zara Northcott'), 'female', 'Prefer to discuss', 'prefer_not_to_say', 'prefer_not_to_say', 'Australia', '{wheelchair}');
select test.refused($$update public.client_details set gender = 'unknown' where client_id = test.cid('Zara Northcott')$$, 'gender only from the list');
reset role;
select test.ok((select time_zone from public.client_details where client_id = test.cid('Zara Northcott')) = 'Australia/Sydney', 'time zone is Sydney unless changed');
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_details where religion <> '''')') = 1, 'assigned care manager sees them');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_details)') = 0, 'team staff don''t');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_details)') = 0, 'staff admins don''t');

-- Required by scheme (readiness).
select test.ok('The NDIS number is needed for an NDIS service.' = any(test.gaps('NDIS daily living')), 'NDIS service: needs the NDIS number');
select test.ok(not ('The My Aged Care ID is needed for a Support at Home or CHSP service.' = any(test.gaps('NDIS daily living'))), 'NDIS service: not the My Aged Care ID');
select test.ok('The My Aged Care ID is needed for a Support at Home or CHSP service.' = any(test.gaps('Home support')), 'Support at Home service: needs the My Aged Care ID');
select test.ok(not ('The NDIS number is needed for an NDIS service.' = any(test.gaps('Home support'))), 'Support at Home service: not the NDIS number');
update public.client_details set ndis_number = '431234567' where client_id = test.cid('Zara Northcott');
select test.ok(not ('The NDIS number is needed for an NDIS service.' = any(test.gaps('NDIS daily living'))), 'with the number, that gap goes');

-- Archiving with a reason.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.car_clients set status = 'discharged' where name = 'Alex South'$$, 'archiving needs a reason');
select test.refused($$update public.car_clients set status = 'discharged', archive_reason = 'other' where name = 'Alex South'$$, '"other" needs a note');
update public.car_clients set status = 'discharged', archive_reason = 'transferred', archive_note = 'To another provider' where name = 'Alex South';
reset role;
select test.ok((select archived_by = test.pid('boss@example.com') and not active and archived_at is not null from public.car_clients where name = 'Alex South'), 'records who and when, and hides them from Cars');
select test.act_as('sam@example.com');
set role authenticated;
update public.car_clients set status = 'discharged', archive_reason = 'passed_away' where name = 'Zara Northcott';
reset role;
select test.ok((select status from public.car_clients where name = 'Zara Northcott') <> 'discharged', 'team staff can''t archive');
select test.act_as('boss@example.com');
set role authenticated;
update public.car_clients set status = 'active' where name = 'Alex South';
reset role;
select test.ok((select active and archive_reason = 'transferred' from public.car_clients where name = 'Alex South'), 'made active again: shown again, last reason kept');
select test.ok((select count(*) from public.car_clients) = 2, 'nothing is deleted');

\o
